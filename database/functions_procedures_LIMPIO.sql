

CREATE OR REPLACE FUNCTION fn_validar_stock_disponible(
    p_stock_id INT,
    p_cantidad_solicitada INT
)
RETURNS BOOLEAN AS $$
DECLARE
    v_disponible INT;
BEGIN
    SELECT (cantidad_en_stock - cantidad_reservada)
    INTO v_disponible
    FROM stock
    WHERE stock_id = p_stock_id;

    RETURN (v_disponible >= p_cantidad_solicitada);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_validar_devolucion_permitida(p_pedido_id INT)
RETURNS BOOLEAN AS $$
DECLARE
    v_estado_pedido VARCHAR(50);
    v_fecha_envio TIMESTAMP;
    v_dias_transcurridos INT;
BEGIN
    SELECT p.estado_pedido, e.fecha_envio
    INTO v_estado_pedido, v_fecha_envio
    FROM pedidos p
    LEFT JOIN envios e ON p.pedido_id = e.pedido_id
    WHERE p.pedido_id = p_pedido_id;

    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;

    IF v_estado_pedido NOT IN ('completado', 'enviado') THEN
        RETURN FALSE;
    END IF;

    IF v_fecha_envio IS NULL THEN
        RETURN FALSE;
    END IF;

    v_dias_transcurridos := EXTRACT(DAY FROM (NOW() - v_fecha_envio));

    RETURN (v_dias_transcurridos <= 30);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_validar_cupon_aplicable(p_codigo_cupon VARCHAR(50))
RETURNS BOOLEAN AS $$
DECLARE
    v_cupon_valido INT;
BEGIN
    SELECT COUNT(*)
    INTO v_cupon_valido
    FROM cupones
    WHERE codigo_cupon = p_codigo_cupon
        AND estado = 'activo'
        AND (fecha_expiracion IS NULL OR fecha_expiracion >= CURRENT_DATE)
        AND (usos_disponibles IS NULL OR usos_disponibles > 0);

    RETURN (v_cupon_valido > 0);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_cliente_tiene_pedidos(p_cliente_id INT)
RETURNS BOOLEAN AS $$
DECLARE
    v_count INT;
BEGIN
    SELECT COUNT(*)
    INTO v_count
    FROM pedidos
    WHERE cliente_id = p_cliente_id;

    RETURN (v_count > 0);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_calcular_descuento_cupon(
    p_cupon_id INT,
    p_subtotal NUMERIC(12, 2)
)
RETURNS NUMERIC(12, 2) AS $$
DECLARE
    v_tipo_descuento VARCHAR(20);
    v_valor_descuento NUMERIC(10, 2);
    v_descuento NUMERIC(12, 2);
BEGIN
    IF p_cupon_id IS NULL THEN
        RETURN 0;
    END IF;

    SELECT tipo_descuento, valor_descuento
    INTO v_tipo_descuento, v_valor_descuento
    FROM cupones
    WHERE cupon_id = p_cupon_id
        AND estado = 'activo'
        AND (fecha_expiracion IS NULL OR fecha_expiracion >= CURRENT_DATE)
        AND (usos_disponibles IS NULL OR usos_disponibles > 0);

    IF NOT FOUND THEN
        RETURN 0;
    END IF;

    IF v_tipo_descuento = 'porcentaje' THEN
        v_descuento := p_subtotal * (v_valor_descuento / 100);
    ELSE
        v_descuento := v_valor_descuento;
    END IF;

    IF v_descuento > p_subtotal THEN
        v_descuento := p_subtotal;
    END IF;

    RETURN v_descuento;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_calcular_monto_reembolso(
    p_detalle_id INT,
    p_cantidad_devuelta INT
)
RETURNS NUMERIC(12, 2) AS $$
DECLARE
    v_precio_unitario NUMERIC(10, 2);
    v_cantidad_original INT;
    v_monto_reembolso NUMERIC(12, 2);
BEGIN
    SELECT precio_unitario_compra, cantidad
    INTO v_precio_unitario, v_cantidad_original
    FROM detalle_pedido
    WHERE detalle_id = p_detalle_id;

    IF NOT FOUND THEN
        RETURN 0;
    END IF;

    IF p_cantidad_devuelta > v_cantidad_original THEN
        RAISE EXCEPTION 'No se puede devolver más items de los comprados';
    END IF;

    v_monto_reembolso := v_precio_unitario * p_cantidad_devuelta;

    RETURN v_monto_reembolso;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_calcular_puntos_fidelidad(p_cliente_id INT)
RETURNS INT AS $$
DECLARE
    v_total_gastado NUMERIC(12, 2);
    v_puntos INT;
BEGIN
    SELECT COALESCE(SUM(total_pedido), 0)
    INTO v_total_gastado
    FROM pedidos
    WHERE cliente_id = p_cliente_id
        AND estado_pedido IN ('pagado', 'enviado', 'completado');

    v_puntos := FLOOR(v_total_gastado / 10);

    RETURN v_puntos;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_obtener_precio_producto(p_stock_id INT)
RETURNS NUMERIC(10, 2) AS $$
DECLARE
    v_precio NUMERIC(10, 2);
BEGIN
    SELECT precio_unitario
    INTO v_precio
    FROM stock
    WHERE stock_id = p_stock_id
        AND estado = 'activo';

    RETURN COALESCE(v_precio, 0);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_calcular_total_pedido(p_pedido_id INT)
RETURNS NUMERIC(12, 2) AS $$
DECLARE
    v_total NUMERIC(12, 2);
BEGIN
    SELECT COALESCE(SUM(cantidad * precio_unitario_compra), 0)
    INTO v_total
    FROM detalle_pedido
    WHERE pedido_id = p_pedido_id;

    RETURN v_total;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE sp_crear_pedido(
    p_cliente_id INT,
    p_direccion_envio_id INT,
    p_cupon_id INT,
    p_items JSONB,
    OUT p_pedido_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_subtotal NUMERIC(12, 2) := 0;
    v_descuento NUMERIC(12, 2) := 0;
    v_impuestos NUMERIC(12, 2) := 0;
    v_total NUMERIC(12, 2) := 0;
    v_item JSONB;
    v_stock_id INT;
    v_cantidad INT;
    v_precio NUMERIC(10, 2);
BEGIN
    INSERT INTO pedidos (
        cliente_id,
        direccion_envio_id,
        cupon_id,
        estado_pedido,
        subtotal,
        descuento_aplicado,
        impuestos,
        total_pedido
    ) VALUES (
        p_cliente_id,
        p_direccion_envio_id,
        p_cupon_id,
        'pendiente',
        0, 0, 0, 0
    ) RETURNING pedido_id INTO p_pedido_id;

    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        v_stock_id := (v_item->>'stock_id')::INT;
        v_cantidad := (v_item->>'cantidad')::INT;

        IF NOT fn_validar_stock_disponible(v_stock_id, v_cantidad) THEN
            RAISE EXCEPTION 'Stock insuficiente para SKU %', v_stock_id;
        END IF;

        v_precio := fn_obtener_precio_producto(v_stock_id);

        INSERT INTO detalle_pedido (
            pedido_id,
            stock_id,
            cantidad,
            precio_unitario_compra
        ) VALUES (
            p_pedido_id,
            v_stock_id,
            v_cantidad,
            v_precio
        );

        UPDATE stock
        SET cantidad_reservada = cantidad_reservada + v_cantidad
        WHERE stock_id = v_stock_id;

        v_subtotal := v_subtotal + (v_precio * v_cantidad);
    END LOOP;

    v_descuento := fn_calcular_descuento_cupon(p_cupon_id, v_subtotal);

    v_impuestos := (v_subtotal - v_descuento) * 0.15;

    v_total := v_subtotal - v_descuento + v_impuestos;

    UPDATE pedidos
    SET
        subtotal = v_subtotal,
        descuento_aplicado = v_descuento,
        impuestos = v_impuestos,
        total_pedido = v_total
    WHERE pedido_id = p_pedido_id;

    IF p_cupon_id IS NOT NULL THEN
        UPDATE cupones
        SET usos_disponibles = usos_disponibles - 1
        WHERE cupon_id = p_cupon_id
            AND usos_disponibles > 0;
    END IF;

    RAISE NOTICE 'Pedido % creado exitosamente. Total: $%', p_pedido_id, v_total;
END;
$$;

CREATE OR REPLACE PROCEDURE sp_aplicar_cupon_pedido(
    p_pedido_id INT,
    p_codigo_cupon VARCHAR(50)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_cupon_id INT;
    v_estado_pedido VARCHAR(50);
    v_subtotal NUMERIC(12, 2);
    v_descuento NUMERIC(12, 2);
    v_impuestos NUMERIC(12, 2);
    v_total NUMERIC(12, 2);
BEGIN
    SELECT estado_pedido, subtotal
    INTO v_estado_pedido, v_subtotal
    FROM pedidos
    WHERE pedido_id = p_pedido_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Pedido % no encontrado', p_pedido_id;
    END IF;

    IF v_estado_pedido != 'pendiente' THEN
        RAISE EXCEPTION 'Solo se puede aplicar cupón a pedidos pendientes';
    END IF;

    SELECT cupon_id
    INTO v_cupon_id
    FROM cupones
    WHERE codigo_cupon = p_codigo_cupon
        AND estado = 'activo'
        AND (fecha_expiracion IS NULL OR fecha_expiracion >= CURRENT_DATE)
        AND (usos_disponibles IS NULL OR usos_disponibles > 0);

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Cupón % no válido o expirado', p_codigo_cupon;
    END IF;

    v_descuento := fn_calcular_descuento_cupon(v_cupon_id, v_subtotal);

    v_impuestos := (v_subtotal - v_descuento) * 0.15;
    v_total := v_subtotal - v_descuento + v_impuestos;

    UPDATE pedidos
    SET
        cupon_id = v_cupon_id,
        descuento_aplicado = v_descuento,
        impuestos = v_impuestos,
        total_pedido = v_total
    WHERE pedido_id = p_pedido_id;

    UPDATE cupones
    SET usos_disponibles = usos_disponibles - 1
    WHERE cupon_id = v_cupon_id
        AND usos_disponibles > 0;

    RAISE NOTICE 'Cupón aplicado. Nuevo total: $%', v_total;
END;
$$;

CREATE OR REPLACE PROCEDURE sp_cancelar_pedido(
    p_pedido_id INT,
    p_motivo TEXT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_estado_actual VARCHAR(50);
    v_detalle RECORD;
    v_envio_id INT;
BEGIN
    SELECT estado_pedido
    INTO v_estado_actual
    FROM pedidos
    WHERE pedido_id = p_pedido_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Pedido % no encontrado', p_pedido_id;
    END IF;

    IF v_estado_actual IN ('enviado', 'completado') THEN
        RAISE EXCEPTION 'No se puede cancelar un pedido en estado %', v_estado_actual;
    END IF;

    FOR v_detalle IN
        SELECT stock_id, cantidad
        FROM detalle_pedido
        WHERE pedido_id = p_pedido_id
    LOOP
        UPDATE stock
        SET cantidad_reservada = cantidad_reservada - v_detalle.cantidad
        WHERE stock_id = v_detalle.stock_id;
    END LOOP;

    UPDATE pedidos
    SET estado_pedido = 'cancelado'
    WHERE pedido_id = p_pedido_id;

    SELECT envio_id
    INTO v_envio_id
    FROM envios
    WHERE pedido_id = p_pedido_id;

    IF FOUND THEN
        UPDATE envios
        SET estado_envio = 'fallido'
        WHERE envio_id = v_envio_id;

        RAISE NOTICE 'Envío % marcado como fallido', v_envio_id;
    END IF;

    RAISE NOTICE 'Pedido % cancelado. Motivo: %', p_pedido_id, p_motivo;
END;
$$;

CREATE OR REPLACE PROCEDURE sp_procesar_pago(
    p_pedido_id INT,
    p_monto NUMERIC(12, 2),
    p_metodo_pago VARCHAR(50),
    p_id_transaccion VARCHAR(255)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_total_pedido NUMERIC(12, 2);
    v_estado_actual VARCHAR(50);
BEGIN
    SELECT total_pedido, estado_pedido
    INTO v_total_pedido, v_estado_actual
    FROM pedidos
    WHERE pedido_id = p_pedido_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Pedido % no encontrado', p_pedido_id;
    END IF;

    IF v_estado_actual != 'pendiente' THEN
        RAISE EXCEPTION 'El pedido % no está en estado pendiente', p_pedido_id;
    END IF;

    IF p_monto != v_total_pedido THEN
        RAISE EXCEPTION 'Monto incorrecto. Esperado: %, Recibido: %', v_total_pedido, p_monto;
    END IF;

    INSERT INTO pagos (
        pedido_id,
        monto,
        metodo_pago,
        estado_pago,
        id_transaccion_externa
    ) VALUES (
        p_pedido_id,
        p_monto,
        p_metodo_pago,
        'exitoso',
        p_id_transaccion
    );

    UPDATE pedidos
    SET estado_pedido = 'pagado'
    WHERE pedido_id = p_pedido_id;

    INSERT INTO envios (
        pedido_id,
        estado_envio
    ) VALUES (
        p_pedido_id,
        'en_preparacion'
    );

    RAISE NOTICE 'Pago procesado exitosamente para pedido %', p_pedido_id;
END;
$$;

CREATE OR REPLACE PROCEDURE sp_actualizar_estado_envio(
    p_envio_id INT,
    p_nuevo_estado VARCHAR(50),
    p_transportista VARCHAR(100) DEFAULT NULL,
    p_numero_tracking VARCHAR(100) DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_pedido_id INT;
    v_estado_actual VARCHAR(50);
BEGIN
    SELECT pedido_id, estado_envio
    INTO v_pedido_id, v_estado_actual
    FROM envios
    WHERE envio_id = p_envio_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Envío % no encontrado', p_envio_id;
    END IF;

    IF v_estado_actual = 'entregado' THEN
        RAISE EXCEPTION 'No se puede modificar un envío ya entregado';
    END IF;

    UPDATE envios
    SET
        estado_envio = p_nuevo_estado,
        transportista = COALESCE(p_transportista, transportista),
        numero_tracking = COALESCE(p_numero_tracking, numero_tracking),
        fecha_envio = CASE
            WHEN p_nuevo_estado = 'en_transito' AND fecha_envio IS NULL
            THEN NOW()
            ELSE fecha_envio
        END
    WHERE envio_id = p_envio_id;

    IF p_nuevo_estado = 'entregado' THEN
        UPDATE pedidos
        SET estado_pedido = 'completado'
        WHERE pedido_id = v_pedido_id;

        RAISE NOTICE 'Pedido % marcado como completado', v_pedido_id;
    END IF;

    IF p_nuevo_estado = 'en_transito' THEN
        UPDATE pedidos
        SET estado_pedido = 'enviado'
        WHERE pedido_id = v_pedido_id
            AND estado_pedido = 'pagado';
    END IF;

    RAISE NOTICE 'Estado de envío actualizado a: %', p_nuevo_estado;
END;
$$;

CREATE OR REPLACE PROCEDURE sp_procesar_devolucion(
    p_detalle_id INT,
    p_cantidad_devuelta INT,
    p_motivo TEXT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_pedido_id INT;
    v_stock_id INT;
    v_monto_reembolso NUMERIC(12, 2);
    v_pago_id INT;
BEGIN
    SELECT pedido_id, stock_id
    INTO v_pedido_id, v_stock_id
    FROM detalle_pedido
    WHERE detalle_id = p_detalle_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Detalle de pedido % no encontrado', p_detalle_id;
    END IF;

    IF NOT fn_validar_devolucion_permitida(v_pedido_id) THEN
        RAISE EXCEPTION 'El pedido % no permite devoluciones', v_pedido_id;
    END IF;

    v_monto_reembolso := fn_calcular_monto_reembolso(p_detalle_id, p_cantidad_devuelta);

    INSERT INTO devoluciones (
        detalle_id,
        motivo,
        cantidad_devuelta,
        estado_devolucion
    ) VALUES (
        p_detalle_id,
        p_motivo,
        p_cantidad_devuelta,
        'aprobada'
    );

    UPDATE stock
    SET cantidad_reservada = GREATEST(0, cantidad_reservada - p_cantidad_devuelta)
    WHERE stock_id = v_stock_id;

    SELECT pago_id
    INTO v_pago_id
    FROM pagos
    WHERE pedido_id = v_pedido_id
        AND estado_pago = 'exitoso'
    ORDER BY fecha_pago DESC
    LIMIT 1;

    IF v_pago_id IS NOT NULL THEN
        INSERT INTO pagos (
            pedido_id,
            monto,
            metodo_pago,
            estado_pago,
            id_transaccion_externa
        ) VALUES (
            v_pedido_id,
            v_monto_reembolso,
            'Reembolso',
            'reembolsado',
            'REFUND_' || p_detalle_id
        );
    END IF;

    UPDATE devoluciones
    SET estado_devolucion = 'reembolsada'
    WHERE detalle_id = p_detalle_id;

    RAISE NOTICE 'Devolución procesada. Reembolso: $%', v_monto_reembolso;
END;
$$;

CREATE OR REPLACE PROCEDURE sp_reabastecer_stock(
    p_stock_id INT,
    p_cantidad INT,
    p_costo_unitario NUMERIC(10, 2) DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_stock_actual INT;
BEGIN
    SELECT cantidad_en_stock
    INTO v_stock_actual
    FROM stock
    WHERE stock_id = p_stock_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'SKU % no encontrado', p_stock_id;
    END IF;

    UPDATE stock
    SET
        cantidad_en_stock = cantidad_en_stock + p_cantidad,
        precio_unitario = COALESCE(p_costo_unitario, precio_unitario)
    WHERE stock_id = p_stock_id;

    RAISE NOTICE 'Stock actualizado. Anterior: %, Nuevo: %',
        v_stock_actual, v_stock_actual + p_cantidad;
END;
$$;

CREATE OR REPLACE PROCEDURE sp_ajustar_precios_categoria(
    p_categoria_id INT,
    p_porcentaje_ajuste NUMERIC(5, 2)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_productos_afectados INT;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM categorias WHERE categoria_id = p_categoria_id) THEN
        RAISE EXCEPTION 'Categoría % no encontrada', p_categoria_id;
    END IF;

    UPDATE stock s
    SET precio_unitario = precio_unitario * (1 + p_porcentaje_ajuste / 100)
    FROM productos p
    WHERE s.producto_id = p.producto_id
        AND p.categoria_id = p_categoria_id
        AND s.estado = 'activo';

    GET DIAGNOSTICS v_productos_afectados = ROW_COUNT;

    RAISE NOTICE '% SKUs actualizados con ajuste del %% en categoría %',
        v_productos_afectados, p_porcentaje_ajuste, p_categoria_id;
END;
$$;

CREATE OR REPLACE PROCEDURE sp_eliminar_cliente(
    p_cliente_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_tiene_pedidos BOOLEAN;
    v_nombre_cliente VARCHAR(100);
BEGIN
    SELECT nombre || ' ' || apellido
    INTO v_nombre_cliente
    FROM clientes
    WHERE cliente_id = p_cliente_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Cliente % no encontrado', p_cliente_id;
    END IF;

    v_tiene_pedidos := fn_cliente_tiene_pedidos(p_cliente_id);

    IF v_tiene_pedidos THEN
        RAISE EXCEPTION 'No se puede eliminar el cliente "%" porque tiene pedidos asociados', v_nombre_cliente;
    END IF;

    DELETE FROM direcciones WHERE cliente_id = p_cliente_id;

    DELETE FROM clientes WHERE cliente_id = p_cliente_id;

    RAISE NOTICE 'Cliente "%" eliminado exitosamente', v_nombre_cliente;
END;
$$;

CREATE OR REPLACE PROCEDURE sp_eliminar_producto(
    p_producto_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_nombre_producto VARCHAR(200);
    v_tiene_stock INT;
    v_en_pedidos INT;
BEGIN
    SELECT nombre_producto
    INTO v_nombre_producto
    FROM productos
    WHERE producto_id = p_producto_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Producto % no encontrado', p_producto_id;
    END IF;

    SELECT COUNT(*)
    INTO v_tiene_stock
    FROM stock
    WHERE producto_id = p_producto_id;

    IF v_tiene_stock > 0 THEN
        RAISE EXCEPTION 'No se puede eliminar el producto "%" porque tiene % registros de stock', v_nombre_producto, v_tiene_stock;
    END IF;

    SELECT COUNT(*)
    INTO v_en_pedidos
    FROM detalle_pedido dp
    INNER JOIN stock s ON dp.stock_id = s.stock_id
    WHERE s.producto_id = p_producto_id;

    IF v_en_pedidos > 0 THEN
        RAISE EXCEPTION 'No se puede eliminar el producto "%" porque está en % pedidos', v_nombre_producto, v_en_pedidos;
    END IF;

    DELETE FROM productos WHERE producto_id = p_producto_id;

    RAISE NOTICE 'Producto "%" eliminado exitosamente', v_nombre_producto;
END;
$$;

CREATE OR REPLACE PROCEDURE sp_eliminar_stock(
    p_stock_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_sku VARCHAR(50);
    v_nombre_producto VARCHAR(200);
    v_cantidad_reservada INT;
    v_en_pedidos INT;
BEGIN
    SELECT s.sku, p.nombre_producto, s.cantidad_reservada
    INTO v_sku, v_nombre_producto, v_cantidad_reservada
    FROM stock s
    INNER JOIN productos p ON s.producto_id = p.producto_id
    WHERE s.stock_id = p_stock_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Stock % no encontrado', p_stock_id;
    END IF;

    IF v_cantidad_reservada > 0 THEN
        RAISE EXCEPTION 'No se puede eliminar el SKU "%" porque tiene % unidades reservadas',
            v_sku, v_cantidad_reservada;
    END IF;

    SELECT COUNT(*)
    INTO v_en_pedidos
    FROM detalle_pedido
    WHERE stock_id = p_stock_id;

    IF v_en_pedidos > 0 THEN
        RAISE EXCEPTION 'No se puede eliminar el SKU "%" porque está en % pedidos',
            v_sku, v_en_pedidos;
    END IF;

    DELETE FROM stock WHERE stock_id = p_stock_id;

    RAISE NOTICE 'Stock "%" del producto "%" eliminado exitosamente', v_sku, v_nombre_producto;
END;
$$;

CREATE OR REPLACE PROCEDURE sp_eliminar_pedido(
    p_pedido_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_estado_pedido VARCHAR(50);
BEGIN
    SELECT estado_pedido
    INTO v_estado_pedido
    FROM pedidos
    WHERE pedido_id = p_pedido_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Pedido % no encontrado', p_pedido_id;
    END IF;

    IF v_estado_pedido != 'cancelado' THEN
        RAISE EXCEPTION 'Solo se pueden eliminar pedidos cancelados. Estado actual: "%"', v_estado_pedido;
    END IF;

    DELETE FROM devoluciones
    WHERE detalle_id IN (
        SELECT detalle_id
        FROM detalle_pedido
        WHERE pedido_id = p_pedido_id
    );

    DELETE FROM detalle_pedido WHERE pedido_id = p_pedido_id;

    DELETE FROM envios WHERE pedido_id = p_pedido_id;

    DELETE FROM pagos WHERE pedido_id = p_pedido_id;

    DELETE FROM pedidos WHERE pedido_id = p_pedido_id;

    RAISE NOTICE 'Pedido % y sus registros asociados eliminados exitosamente', p_pedido_id;
END;
$$;

CREATE OR REPLACE PROCEDURE sp_eliminar_pago(
    p_pago_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_estado_pago VARCHAR(20);
    v_pedido_id INT;
BEGIN
    SELECT estado_pago, pedido_id
    INTO v_estado_pago, v_pedido_id
    FROM pagos
    WHERE pago_id = p_pago_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Pago % no encontrado', p_pago_id;
    END IF;

    IF v_estado_pago NOT IN ('fallido', 'pendiente') THEN
        RAISE EXCEPTION 'Solo se pueden eliminar pagos fallidos o pendientes. Estado actual: "%"', v_estado_pago;
    END IF;

    DELETE FROM pagos WHERE pago_id = p_pago_id;

    RAISE NOTICE 'Pago % (estado: %) del pedido % eliminado exitosamente',
        p_pago_id, v_estado_pago, v_pedido_id;
END;
$$;

