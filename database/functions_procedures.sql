/* =========================================
 * PROCEDIMIENTOS ALMACENADOS Y FUNCIONES
 * E-COMMERCE - TODA LA LÓGICA EN BD
 * =========================================
 * 
 * INSTRUCCIONES DE EJECUCIÓN:
 * 1. Abre DBeaver
 * 2. Conéctate a tu base de datos PostgreSQL
 * 3. Abre un nuevo SQL Editor
 * 4. Copia y pega este script COMPLETO
 * 5. Ejecuta todo el script (Ctrl + Enter o botón Execute)
 * 
 * IMPORTANTE: Ejecutar DESPUÉS de schema.sql y seed.sql
 * =========================================
 */

-- =========================================
-- FUNCIONES (6) - Solo retornan valores
-- =========================================

/* * =========================================
 * FUNCIÓN 1: Calcular total de un pedido
 * =========================================
 * Calcula el total de un pedido sumando todos los items
 * del detalle_pedido.
 * 
 * Parámetros:
 *   - p_pedido_id: ID del pedido
 * Retorna:
 *   - NUMERIC: Total del pedido
 */
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

/* * =========================================
 * FUNCIÓN 2: Validar stock disponible
 * =========================================
 * Verifica si hay suficiente stock disponible
 * (cantidad_en_stock - cantidad_reservada).
 * 
 * Parámetros:
 *   - p_stock_id: ID del SKU
 *   - p_cantidad_solicitada: Cantidad que se quiere comprar
 * Retorna:
 *   - BOOLEAN: TRUE si hay stock, FALSE si no
 */
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

/* * =========================================
 * FUNCIÓN 3: Calcular descuento de cupón
 * =========================================
 * Calcula el monto de descuento que aplica un cupón
 * sobre un subtotal dado.
 * 
 * Parámetros:
 *   - p_cupon_id: ID del cupón
 *   - p_subtotal: Subtotal del pedido
 * Retorna:
 *   - NUMERIC: Monto del descuento
 */
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
    -- Si no hay cupón, retorna 0
    IF p_cupon_id IS NULL THEN
        RETURN 0;
    END IF;
    
    -- Obtener datos del cupón
    SELECT tipo_descuento, valor_descuento
    INTO v_tipo_descuento, v_valor_descuento
    FROM cupones
    WHERE cupon_id = p_cupon_id
        AND estado = 'activo'
        AND (fecha_expiracion IS NULL OR fecha_expiracion >= CURRENT_DATE)
        AND (usos_disponibles IS NULL OR usos_disponibles > 0);
    
    -- Si no se encontró cupón válido
    IF NOT FOUND THEN
        RETURN 0;
    END IF;
    
    -- Calcular descuento según tipo
    IF v_tipo_descuento = 'porcentaje' THEN
        v_descuento := p_subtotal * (v_valor_descuento / 100);
    ELSE -- tipo 'fijo'
        v_descuento := v_valor_descuento;
    END IF;
    
    -- No puede ser mayor al subtotal
    IF v_descuento > p_subtotal THEN
        v_descuento := p_subtotal;
    END IF;
    
    RETURN v_descuento;
END;
$$ LANGUAGE plpgsql;

/* * =========================================
 * FUNCIÓN 4: Obtener precio final de producto
 * =========================================
 * Obtiene el precio de un SKU específico.
 * 
 * Parámetros:
 *   - p_stock_id: ID del SKU
 * Retorna:
 *   - NUMERIC: Precio unitario
 */
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

/* * =========================================
 * FUNCIÓN 5: Verificar si cliente tiene pedidos
 * =========================================
 * Verifica si un cliente ha realizado al menos un pedido.
 * 
 * Parámetros:
 *   - p_cliente_id: ID del cliente
 * Retorna:
 *   - BOOLEAN: TRUE si tiene pedidos, FALSE si no
 */
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

/* * =========================================
 * FUNCIÓN 6: Calcular comisión por venta
 * =========================================
 * Calcula una comisión del 5% sobre el total de un pedido.
 * Útil para calcular ganancias o comisiones de vendedores.
 * 
 * Parámetros:
 *   - p_pedido_id: ID del pedido
 * Retorna:
 *   - NUMERIC: Monto de la comisión
 */
CREATE OR REPLACE FUNCTION fn_calcular_comision_venta(p_pedido_id INT)
RETURNS NUMERIC(12, 2) AS $$
DECLARE
    v_total NUMERIC(12, 2);
    v_comision NUMERIC(12, 2);
BEGIN
    SELECT total_pedido
    INTO v_total
    FROM pedidos
    WHERE pedido_id = p_pedido_id;
    
    v_comision := v_total * 0.05; -- 5% de comisión
    
    RETURN COALESCE(v_comision, 0);
END;
$$ LANGUAGE plpgsql;


-- =========================================
-- PROCEDIMIENTOS ALMACENADOS (5)
-- =========================================

/* * =========================================
 * PROCEDIMIENTO 1: Crear pedido completo
 * =========================================
 * Crea un pedido con todos sus detalles, calcula totales
 * y reserva el stock.
 * 
 * Parámetros:
 *   - p_cliente_id: ID del cliente
 *   - p_direccion_envio_id: ID de la dirección de envío
 *   - p_cupon_id: ID del cupón (opcional)
 *   - p_items: JSON array con items [{stock_id, cantidad}, ...]
 * Retorna:
 *   - ID del pedido creado
 */
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
    -- Crear el pedido inicial
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
    
    -- Procesar cada item
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        v_stock_id := (v_item->>'stock_id')::INT;
        v_cantidad := (v_item->>'cantidad')::INT;
        
        -- Validar stock disponible
        IF NOT fn_validar_stock_disponible(v_stock_id, v_cantidad) THEN
            RAISE EXCEPTION 'Stock insuficiente para SKU %', v_stock_id;
        END IF;
        
        -- Obtener precio
        v_precio := fn_obtener_precio_producto(v_stock_id);
        
        -- Insertar detalle
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
        
        -- Reservar stock
        UPDATE stock
        SET cantidad_reservada = cantidad_reservada + v_cantidad
        WHERE stock_id = v_stock_id;
        
        -- Acumular subtotal
        v_subtotal := v_subtotal + (v_precio * v_cantidad);
    END LOOP;
    
    -- Calcular descuento
    v_descuento := fn_calcular_descuento_cupon(p_cupon_id, v_subtotal);
    
    -- Calcular impuestos (15% sobre subtotal - descuento)
    v_impuestos := (v_subtotal - v_descuento) * 0.15;
    
    -- Calcular total
    v_total := v_subtotal - v_descuento + v_impuestos;
    
    -- Actualizar pedido con totales
    UPDATE pedidos
    SET 
        subtotal = v_subtotal,
        descuento_aplicado = v_descuento,
        impuestos = v_impuestos,
        total_pedido = v_total
    WHERE pedido_id = p_pedido_id;
    
    -- Decrementar uso del cupón si existe
    IF p_cupon_id IS NOT NULL THEN
        UPDATE cupones
        SET usos_disponibles = usos_disponibles - 1
        WHERE cupon_id = p_cupon_id
            AND usos_disponibles > 0;
    END IF;
    
    RAISE NOTICE 'Pedido % creado exitosamente. Total: $%', p_pedido_id, v_total;
END;
$$;

/* * =========================================
 * PROCEDIMIENTO 2: Procesar pago
 * =========================================
 * Procesa un pago y actualiza el estado del pedido.
 * 
 * Parámetros:
 *   - p_pedido_id: ID del pedido
 *   - p_monto: Monto pagado
 *   - p_metodo_pago: Método de pago usado
 *   - p_id_transaccion: ID de transacción externa
 */
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
    -- Obtener total y estado del pedido
    SELECT total_pedido, estado_pedido
    INTO v_total_pedido, v_estado_actual
    FROM pedidos
    WHERE pedido_id = p_pedido_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Pedido % no encontrado', p_pedido_id;
    END IF;
    
    -- Validar que el pedido esté pendiente
    IF v_estado_actual != 'pendiente' THEN
        RAISE EXCEPTION 'El pedido % no está en estado pendiente', p_pedido_id;
    END IF;
    
    -- Validar que el monto sea correcto
    IF p_monto != v_total_pedido THEN
        RAISE EXCEPTION 'Monto incorrecto. Esperado: %, Recibido: %', v_total_pedido, p_monto;
    END IF;
    
    -- Registrar el pago
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
    
    -- Actualizar estado del pedido
    UPDATE pedidos
    SET estado_pedido = 'pagado'
    WHERE pedido_id = p_pedido_id;
    
    -- Crear registro de envío
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

/* * =========================================
 * PROCEDIMIENTO 3: Actualizar stock después de compra
 * =========================================
 * Reduce el stock físico y libera la cantidad reservada
 * después de que un pedido fue pagado.
 * 
 * Parámetros:
 *   - p_pedido_id: ID del pedido
 */
CREATE OR REPLACE PROCEDURE sp_actualizar_stock_compra(p_pedido_id INT)
LANGUAGE plpgsql
AS $$
DECLARE
    v_detalle RECORD;
BEGIN
    -- Para cada item del pedido
    FOR v_detalle IN 
        SELECT stock_id, cantidad
        FROM detalle_pedido
        WHERE pedido_id = p_pedido_id
    LOOP
        -- Reducir stock y liberar reserva
        UPDATE stock
        SET 
            cantidad_en_stock = cantidad_en_stock - v_detalle.cantidad,
            cantidad_reservada = cantidad_reservada - v_detalle.cantidad
        WHERE stock_id = v_detalle.stock_id;
    END LOOP;
    
    RAISE NOTICE 'Stock actualizado para pedido %', p_pedido_id;
END;
$$;

/* * =========================================
 * PROCEDIMIENTO 4: Cancelar pedido
 * =========================================
 * Cancela un pedido y libera el stock reservado.
 * 
 * Parámetros:
 *   - p_pedido_id: ID del pedido
 *   - p_motivo: Motivo de la cancelación
 */
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
    -- Verificar estado del pedido
    SELECT estado_pedido
    INTO v_estado_actual
    FROM pedidos
    WHERE pedido_id = p_pedido_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Pedido % no encontrado', p_pedido_id;
    END IF;
    
    -- No se puede cancelar si ya está enviado o completado
    IF v_estado_actual IN ('enviado', 'completado') THEN
        RAISE EXCEPTION 'No se puede cancelar un pedido en estado %', v_estado_actual;
    END IF;
    
    -- Liberar stock reservado
    FOR v_detalle IN 
        SELECT stock_id, cantidad
        FROM detalle_pedido
        WHERE pedido_id = p_pedido_id
    LOOP
        UPDATE stock
        SET cantidad_reservada = cantidad_reservada - v_detalle.cantidad
        WHERE stock_id = v_detalle.stock_id;
    END LOOP;
    
    -- Actualizar estado del pedido
    UPDATE pedidos
    SET estado_pedido = 'cancelado'
    WHERE pedido_id = p_pedido_id;
    
    -- Si existe un envío asociado, marcarlo como "fallido"
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

/* * =========================================
 * PROCEDIMIENTO 5: Aplicar cupón a pedido existente
 * =========================================
 * Aplica un cupón a un pedido que aún no ha sido pagado
 * y recalcula los totales.
 * 
 * Parámetros:
 *   - p_pedido_id: ID del pedido
 *   - p_codigo_cupon: Código del cupón
 */
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
    -- Verificar estado del pedido
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
    
    -- Buscar y validar cupón
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
    
    -- Calcular nuevo descuento
    v_descuento := fn_calcular_descuento_cupon(v_cupon_id, v_subtotal);
    
    -- Recalcular impuestos y total
    v_impuestos := (v_subtotal - v_descuento) * 0.15;
    v_total := v_subtotal - v_descuento + v_impuestos;
    
    -- Actualizar pedido
    UPDATE pedidos
    SET 
        cupon_id = v_cupon_id,
        descuento_aplicado = v_descuento,
        impuestos = v_impuestos,
        total_pedido = v_total
    WHERE pedido_id = p_pedido_id;
    
    -- Decrementar usos del cupón
    UPDATE cupones
    SET usos_disponibles = usos_disponibles - 1
    WHERE cupon_id = v_cupon_id
        AND usos_disponibles > 0;
    
    RAISE NOTICE 'Cupón aplicado. Nuevo total: $%', v_total;
END;
$$;


-- =========================================
-- FUNCIONES ADICIONALES (8)
-- =========================================

/* * =========================================
 * FUNCIÓN 7: Validar si una devolución es permitida
 * =========================================
 * Verifica si un pedido puede ser devuelto según:
 * - Estado del pedido (debe estar completado o entregado)
 * - Tiempo desde la entrega (máximo 30 días)
 * 
 * Parámetros:
 *   - p_pedido_id: ID del pedido
 * Retorna:
 *   - BOOLEAN: TRUE si se puede devolver, FALSE si no
 */
CREATE OR REPLACE FUNCTION fn_validar_devolucion_permitida(p_pedido_id INT)
RETURNS BOOLEAN AS $$
DECLARE
    v_estado_pedido VARCHAR(50);
    v_fecha_envio TIMESTAMP;
    v_dias_transcurridos INT;
BEGIN
    -- Obtener estado del pedido y fecha de envío
    SELECT p.estado_pedido, e.fecha_envio
    INTO v_estado_pedido, v_fecha_envio
    FROM pedidos p
    LEFT JOIN envios e ON p.pedido_id = e.pedido_id
    WHERE p.pedido_id = p_pedido_id;
    
    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;
    
    -- El pedido debe estar completado
    IF v_estado_pedido NOT IN ('completado', 'enviado') THEN
        RETURN FALSE;
    END IF;
    
    -- Si no hay fecha de envío, no se puede devolver
    IF v_fecha_envio IS NULL THEN
        RETURN FALSE;
    END IF;
    
    -- Calcular días transcurridos
    v_dias_transcurridos := EXTRACT(DAY FROM (NOW() - v_fecha_envio));
    
    -- Máximo 30 días para devolución
    RETURN (v_dias_transcurridos <= 30);
END;
$$ LANGUAGE plpgsql;

/* * =========================================
 * FUNCIÓN 8: Calcular monto de reembolso
 * =========================================
 * Calcula el monto a reembolsar por una devolución.
 * 
 * Parámetros:
 *   - p_detalle_id: ID del detalle del pedido
 *   - p_cantidad_devuelta: Cantidad de items devueltos
 * Retorna:
 *   - NUMERIC: Monto a reembolsar
 */
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
    -- Obtener precio y cantidad original
    SELECT precio_unitario_compra, cantidad
    INTO v_precio_unitario, v_cantidad_original
    FROM detalle_pedido
    WHERE detalle_id = p_detalle_id;
    
    IF NOT FOUND THEN
        RETURN 0;
    END IF;
    
    -- Validar que no se devuelva más de lo comprado
    IF p_cantidad_devuelta > v_cantidad_original THEN
        RAISE EXCEPTION 'No se puede devolver más items de los comprados';
    END IF;
    
    -- Calcular reembolso
    v_monto_reembolso := v_precio_unitario * p_cantidad_devuelta;
    
    RETURN v_monto_reembolso;
END;
$$ LANGUAGE plpgsql;

/* * =========================================
 * FUNCIÓN 9: Obtener productos más vendidos
 * =========================================
 * Retorna los N productos más vendidos en un periodo.
 * 
 * Parámetros:
 *   - p_limite: Cantidad de productos a retornar
 *   - p_fecha_desde: Fecha inicio (NULL = sin límite)
 *   - p_fecha_hasta: Fecha fin (NULL = sin límite)
 * Retorna:
 *   - TABLE con producto_id, nombre, total_vendido
 */
CREATE OR REPLACE FUNCTION fn_obtener_productos_mas_vendidos(
    p_limite INT DEFAULT 10,
    p_fecha_desde TIMESTAMP DEFAULT NULL,
    p_fecha_hasta TIMESTAMP DEFAULT NULL
)
RETURNS TABLE(
    producto_id INT,
    nombre_producto VARCHAR(255),
    total_vendido BIGINT,
    ingresos_generados NUMERIC(12, 2)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.producto_id,
        p.nombre_producto,
        SUM(dp.cantidad) AS total_vendido,
        SUM(dp.cantidad * dp.precio_unitario_compra) AS ingresos_generados
    FROM detalle_pedido dp
    JOIN stock s ON dp.stock_id = s.stock_id
    JOIN productos p ON s.producto_id = p.producto_id
    JOIN pedidos ped ON dp.pedido_id = ped.pedido_id
    WHERE ped.estado_pedido IN ('pagado', 'enviado', 'completado')
        AND (p_fecha_desde IS NULL OR ped.fecha_creacion >= p_fecha_desde)
        AND (p_fecha_hasta IS NULL OR ped.fecha_creacion <= p_fecha_hasta)
    GROUP BY p.producto_id, p.nombre_producto
    ORDER BY total_vendido DESC
    LIMIT p_limite;
END;
$$ LANGUAGE plpgsql;

/* * =========================================
 * FUNCIÓN 10: Calcular total de ventas en periodo
 * =========================================
 * Calcula el total de ventas completadas en un rango de fechas.
 * 
 * Parámetros:
 *   - p_fecha_desde: Fecha inicio
 *   - p_fecha_hasta: Fecha fin
 * Retorna:
 *   - NUMERIC: Total de ventas
 */
CREATE OR REPLACE FUNCTION fn_calcular_total_ventas_periodo(
    p_fecha_desde TIMESTAMP,
    p_fecha_hasta TIMESTAMP
)
RETURNS NUMERIC(12, 2) AS $$
DECLARE
    v_total NUMERIC(12, 2);
BEGIN
    SELECT COALESCE(SUM(total_pedido), 0)
    INTO v_total
    FROM pedidos
    WHERE estado_pedido IN ('pagado', 'enviado', 'completado')
        AND fecha_creacion BETWEEN p_fecha_desde AND p_fecha_hasta;
    
    RETURN v_total;
END;
$$ LANGUAGE plpgsql;

/* * =========================================
 * FUNCIÓN 11: Obtener clientes frecuentes
 * =========================================
 * Retorna los clientes con más pedidos completados.
 * 
 * Parámetros:
 *   - p_limite: Cantidad de clientes a retornar
 * Retorna:
 *   - TABLE con cliente_id, nombre, apellido, total_pedidos, total_gastado
 */
CREATE OR REPLACE FUNCTION fn_obtener_clientes_frecuentes(p_limite INT DEFAULT 10)
RETURNS TABLE(
    cliente_id INT,
    nombre VARCHAR(100),
    apellido VARCHAR(100),
    email VARCHAR(255),
    total_pedidos BIGINT,
    total_gastado NUMERIC(12, 2)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.cliente_id,
        c.nombre,
        c.apellido,
        c.email,
        COUNT(p.pedido_id) AS total_pedidos,
        COALESCE(SUM(p.total_pedido), 0) AS total_gastado
    FROM clientes c
    LEFT JOIN pedidos p ON c.cliente_id = p.cliente_id
        AND p.estado_pedido IN ('pagado', 'enviado', 'completado')
    GROUP BY c.cliente_id, c.nombre, c.apellido, c.email
    HAVING COUNT(p.pedido_id) > 0
    ORDER BY total_pedidos DESC, total_gastado DESC
    LIMIT p_limite;
END;
$$ LANGUAGE plpgsql;

/* * =========================================
 * FUNCIÓN 12: Validar si cupón es aplicable
 * =========================================
 * Valida si un cupón puede ser usado actualmente.
 * 
 * Parámetros:
 *   - p_codigo_cupon: Código del cupón
 * Retorna:
 *   - BOOLEAN: TRUE si es válido, FALSE si no
 */
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

/* * =========================================
 * FUNCIÓN 13: Calcular puntos de fidelidad
 * =========================================
 * Calcula puntos de fidelidad (1 punto por cada $10 gastados).
 * 
 * Parámetros:
 *   - p_cliente_id: ID del cliente
 * Retorna:
 *   - INT: Total de puntos acumulados
 */
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
    
    -- 1 punto por cada $10
    v_puntos := FLOOR(v_total_gastado / 10);
    
    RETURN v_puntos;
END;
$$ LANGUAGE plpgsql;

/* * =========================================
 * FUNCIÓN 14: Calcular días estimados de entrega
 * =========================================
 * Calcula días estimados desde que se envió hasta hoy.
 * 
 * Parámetros:
 *   - p_envio_id: ID del envío
 * Retorna:
 *   - INT: Días desde el envío
 */
CREATE OR REPLACE FUNCTION fn_calcular_tiempo_entrega(p_envio_id INT)
RETURNS INT AS $$
DECLARE
    v_fecha_envio TIMESTAMP;
    v_dias INT;
BEGIN
    SELECT fecha_envio
    INTO v_fecha_envio
    FROM envios
    WHERE envio_id = p_envio_id;
    
    IF v_fecha_envio IS NULL THEN
        RETURN NULL;
    END IF;
    
    v_dias := EXTRACT(DAY FROM (NOW() - v_fecha_envio));
    
    RETURN v_dias;
END;
$$ LANGUAGE plpgsql;


-- =========================================
-- PROCEDIMIENTOS ALMACENADOS ADICIONALES (4)
-- =========================================

/* * =========================================
 * PROCEDIMIENTO 6: Actualizar estado de envío
 * =========================================
 * Actualiza el estado de un envío y marca el pedido
 * como completado cuando se entrega.
 * 
 * Parámetros:
 *   - p_envio_id: ID del envío
 *   - p_nuevo_estado: Nuevo estado del envío
 *   - p_transportista: Nombre del transportista
 *   - p_numero_tracking: Número de seguimiento
 */
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
    -- Obtener pedido asociado y estado actual
    SELECT pedido_id, estado_envio
    INTO v_pedido_id, v_estado_actual
    FROM envios
    WHERE envio_id = p_envio_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Envío % no encontrado', p_envio_id;
    END IF;
    
    -- Validar transición de estado
    IF v_estado_actual = 'entregado' THEN
        RAISE EXCEPTION 'No se puede modificar un envío ya entregado';
    END IF;
    
    -- Actualizar envío
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
    
    -- Si el estado es "entregado", marcar pedido como completado
    IF p_nuevo_estado = 'entregado' THEN
        UPDATE pedidos
        SET estado_pedido = 'completado'
        WHERE pedido_id = v_pedido_id;
        
        RAISE NOTICE 'Pedido % marcado como completado', v_pedido_id;
    END IF;
    
    -- Si el estado es "en_transito", actualizar pedido a "enviado"
    IF p_nuevo_estado = 'en_transito' THEN
        UPDATE pedidos
        SET estado_pedido = 'enviado'
        WHERE pedido_id = v_pedido_id
            AND estado_pedido = 'pagado';
    END IF;
    
    RAISE NOTICE 'Estado de envío actualizado a: %', p_nuevo_estado;
END;
$$;

/* * =========================================
 * PROCEDIMIENTO 7: Procesar devolución completa
 * =========================================
 * Procesa una devolución: crea registro, devuelve stock,
 * genera reembolso.
 * 
 * Parámetros:
 *   - p_detalle_id: ID del detalle del pedido
 *   - p_cantidad_devuelta: Cantidad a devolver
 *   - p_motivo: Motivo de la devolución
 */
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
    -- Obtener pedido y stock asociado
    SELECT pedido_id, stock_id
    INTO v_pedido_id, v_stock_id
    FROM detalle_pedido
    WHERE detalle_id = p_detalle_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Detalle de pedido % no encontrado', p_detalle_id;
    END IF;
    
    -- Validar que la devolución sea permitida
    IF NOT fn_validar_devolucion_permitida(v_pedido_id) THEN
        RAISE EXCEPTION 'El pedido % no permite devoluciones', v_pedido_id;
    END IF;
    
    -- Calcular monto de reembolso
    v_monto_reembolso := fn_calcular_monto_reembolso(p_detalle_id, p_cantidad_devuelta);
    
    -- Crear registro de devolución
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
    
    -- Solo liberar la reserva, NO incrementar stock físico
    UPDATE stock
    SET cantidad_reservada = GREATEST(0, cantidad_reservada - p_cantidad_devuelta)
    WHERE stock_id = v_stock_id;
    
    -- Obtener el pago exitoso del pedido
    SELECT pago_id
    INTO v_pago_id
    FROM pagos
    WHERE pedido_id = v_pedido_id
        AND estado_pago = 'exitoso'
    ORDER BY fecha_pago DESC
    LIMIT 1;
    
    -- Crear registro de reembolso (nuevo pago con monto positivo)
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
    
    -- Actualizar estado de devolución a "reembolsada"
    UPDATE devoluciones
    SET estado_devolucion = 'reembolsada'
    WHERE detalle_id = p_detalle_id;
    
    RAISE NOTICE 'Devolución procesada. Reembolso: $%', v_monto_reembolso;
END;
$$;

/* * =========================================
 * PROCEDIMIENTO 8: Reabastecer stock
 * =========================================
 * Registra ingreso de mercadería al inventario.
 * 
 * Parámetros:
 *   - p_stock_id: ID del SKU
 *   - p_cantidad: Cantidad a agregar
 *   - p_costo_unitario: Costo unitario (opcional, para actualizar precio)
 */
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
    -- Validar que exista el SKU
    SELECT cantidad_en_stock
    INTO v_stock_actual
    FROM stock
    WHERE stock_id = p_stock_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'SKU % no encontrado', p_stock_id;
    END IF;
    
    -- Actualizar stock
    UPDATE stock
    SET 
        cantidad_en_stock = cantidad_en_stock + p_cantidad,
        precio_unitario = COALESCE(p_costo_unitario, precio_unitario)
    WHERE stock_id = p_stock_id;
    
    RAISE NOTICE 'Stock actualizado. Anterior: %, Nuevo: %', 
        v_stock_actual, v_stock_actual + p_cantidad;
END;
$$;

/* * =========================================
 * PROCEDIMIENTO 9: Ajustar precios por categoría
 * =========================================
 * Actualiza precios masivamente aplicando un porcentaje
 * de incremento/descuento a todos los productos de una categoría.
 * 
 * Parámetros:
 *   - p_categoria_id: ID de la categoría
 *   - p_porcentaje_ajuste: Porcentaje de ajuste (positivo = incremento, negativo = descuento)
 */
CREATE OR REPLACE PROCEDURE sp_ajustar_precios_categoria(
    p_categoria_id INT,
    p_porcentaje_ajuste NUMERIC(5, 2)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_productos_afectados INT;
BEGIN
    -- Validar que exista la categoría
    IF NOT EXISTS (SELECT 1 FROM categorias WHERE categoria_id = p_categoria_id) THEN
        RAISE EXCEPTION 'Categoría % no encontrada', p_categoria_id;
    END IF;
    
    -- Actualizar precios de todos los SKUs de productos de esa categoría
    UPDATE stock s
    SET precio_unitario = precio_unitario * (1 + p_porcentaje_ajuste / 100)
    FROM productos p
    WHERE s.producto_id = p.producto_id
        AND p.categoria_id = p_categoria_id
        AND s.estado = 'activo';
    
    GET DIAGNOSTICS v_productos_afectados = ROW_COUNT;
    
    RAISE NOTICE '% SKUs actualizados con ajuste del % porciento en categoría %', 
        v_productos_afectados, p_porcentaje_ajuste, p_categoria_id;
END;
$$;


-- =========================================
-- EJEMPLOS DE USO - FUNCIONES ORIGINALES
-- =========================================

/* 
-- Ejemplo 1: Calcular total de un pedido
SELECT fn_calcular_total_pedido(1) AS total;

-- Ejemplo 2: Validar stock
SELECT fn_validar_stock_disponible(1, 5) AS hay_stock;

-- Ejemplo 3: Calcular descuento
SELECT fn_calcular_descuento_cupon(1, 1000.00) AS descuento;

-- Ejemplo 4: Crear un nuevo pedido
DO $$
DECLARE
    v_pedido_id INT;
BEGIN
    CALL sp_crear_pedido(
        1, -- cliente_id
        1, -- direccion_envio_id
        1, -- cupon_id
        '[{"stock_id": 2, "cantidad": 1}, {"stock_id": 3, "cantidad": 2}]'::JSONB,
        v_pedido_id
    );
    RAISE NOTICE 'Pedido creado con ID: %', v_pedido_id;
END $$;

-- Ejemplo 5: Procesar pago
CALL sp_procesar_pago(
    1, -- pedido_id
    1800.89, -- monto
    'Tarjeta de Crédito', -- metodo_pago
    'txn_abc123xyz' -- id_transaccion
);

-- Ejemplo 6: Cancelar pedido
CALL sp_cancelar_pedido(4, 'Cliente cambió de opinión');

-- Ejemplo 7: Aplicar cupón
CALL sp_aplicar_cupon_pedido(3, 'VERANO20');
*/


-- =========================================
-- EJEMPLOS DE USO - NUEVAS FUNCIONES
-- =========================================

/*
-- Ejemplo 8: Validar si un pedido puede ser devuelto
SELECT fn_validar_devolucion_permitida(1) AS puede_devolver;

-- Ejemplo 9: Calcular monto de reembolso
SELECT fn_calcular_monto_reembolso(1, 1) AS monto_reembolso;

-- Ejemplo 10: Top 5 productos más vendidos
SELECT * FROM fn_obtener_productos_mas_vendidos(5);

-- Ejemplo 11: Ventas del último mes
SELECT fn_calcular_total_ventas_periodo(
    NOW() - INTERVAL '30 days',
    NOW()
) AS ventas_mes;

-- Ejemplo 12: Top 10 clientes frecuentes
SELECT * FROM fn_obtener_clientes_frecuentes(10);

-- Ejemplo 13: Validar cupón
SELECT fn_validar_cupon_aplicable('VERANO20') AS cupon_valido;

-- Ejemplo 14: Puntos de fidelidad de un cliente
SELECT fn_calcular_puntos_fidelidad(1) AS puntos;

-- Ejemplo 15: Días desde envío
SELECT fn_calcular_tiempo_entrega(1) AS dias_envio;

-- Ejemplo 16: Actualizar estado de envío
CALL sp_actualizar_estado_envio(
    1, -- envio_id
    'en_transito', -- nuevo_estado
    'DHL', -- transportista
    'DHL123456789' -- numero_tracking
);

-- Ejemplo 17: Procesar devolución
CALL sp_procesar_devolucion(
    1, -- detalle_id
    1, -- cantidad_devuelta
    'Producto defectuoso' -- motivo
);

-- Ejemplo 18: Reabastecer stock
CALL sp_reabastecer_stock(
    1, -- stock_id
    50, -- cantidad
    25.00 -- nuevo_costo_unitario (opcional)
);

-- Ejemplo 19: Ajustar precios en una categoría (incremento del 10%)
CALL sp_ajustar_precios_categoria(1, 10.00);

-- Ejemplo 20: Descuento del 15% en toda una categoría
CALL sp_ajustar_precios_categoria(2, -15.00);
*/

/* =========================================
 * PROCEDIMIENTOS DE ELIMINACIÓN (DELETE FÍSICO)
 * =========================================
 * Estos procedimientos permiten eliminar registros de la base de datos
 * de forma segura, validando que no estén en uso.
 */

/* * =========================================
 * PROCEDIMIENTO 9: Eliminar Cliente
 * =========================================
 * Elimina un cliente de la base de datos solo si NO tiene pedidos asociados.
 * Si tiene pedidos, lanza una excepción.
 * 
 * Parámetros:
 *   - p_cliente_id: ID del cliente a eliminar
 */
CREATE OR REPLACE PROCEDURE sp_eliminar_cliente(
    p_cliente_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_tiene_pedidos BOOLEAN;
    v_nombre_cliente VARCHAR(100);
BEGIN
    -- Obtener nombre del cliente para el mensaje
    SELECT nombre || ' ' || apellido
    INTO v_nombre_cliente
    FROM clientes
    WHERE cliente_id = p_cliente_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Cliente % no encontrado', p_cliente_id;
    END IF;
    
    -- Verificar si tiene pedidos usando la función existente
    v_tiene_pedidos := fn_cliente_tiene_pedidos(p_cliente_id);
    
    IF v_tiene_pedidos THEN
        RAISE EXCEPTION 'No se puede eliminar el cliente "%" porque tiene pedidos asociados. Usa desactivación en su lugar.', v_nombre_cliente;
    END IF;
    
    -- Eliminar direcciones del cliente primero (cascada manual)
    DELETE FROM direcciones WHERE cliente_id = p_cliente_id;
    
    -- Eliminar cliente
    DELETE FROM clientes WHERE cliente_id = p_cliente_id;
    
    RAISE NOTICE 'Cliente "%" eliminado exitosamente', v_nombre_cliente;
END;
$$;

/* * =========================================
 * PROCEDIMIENTO 10: Eliminar Producto
 * =========================================
 * Elimina un producto de la base de datos solo si NO tiene:
 * - Stock asociado
 * - Apariciones en pedidos (detalle_pedido)
 * 
 * Parámetros:
 *   - p_producto_id: ID del producto a eliminar
 */
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
    -- Obtener nombre del producto
    SELECT nombre_producto
    INTO v_nombre_producto
    FROM productos
    WHERE producto_id = p_producto_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Producto % no encontrado', p_producto_id;
    END IF;
    
    -- Verificar si tiene stock
    SELECT COUNT(*)
    INTO v_tiene_stock
    FROM stock
    WHERE producto_id = p_producto_id;
    
    IF v_tiene_stock > 0 THEN
        RAISE EXCEPTION 'No se puede eliminar el producto "%" porque tiene % registros de stock. Elimina el stock primero.', v_nombre_producto, v_tiene_stock;
    END IF;
    
    -- Verificar si está en algún pedido
    SELECT COUNT(*)
    INTO v_en_pedidos
    FROM detalle_pedido dp
    INNER JOIN stock s ON dp.stock_id = s.stock_id
    WHERE s.producto_id = p_producto_id;
    
    IF v_en_pedidos > 0 THEN
        RAISE EXCEPTION 'No se puede eliminar el producto "%" porque está en % pedidos. Usa desactivación en su lugar.', v_nombre_producto, v_en_pedidos;
    END IF;
    
    -- Eliminar producto
    DELETE FROM productos WHERE producto_id = p_producto_id;
    
    RAISE NOTICE 'Producto "%" eliminado exitosamente', v_nombre_producto;
END;
$$;

/* * =========================================
 * PROCEDIMIENTO 11: Eliminar Stock (SKU específico)
 * =========================================
 * Elimina un registro de stock (SKU) solo si NO está:
 * - Reservado (cantidad_reservada > 0)
 * - En algún pedido (detalle_pedido)
 * 
 * Parámetros:
 *   - p_stock_id: ID del stock a eliminar
 */
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
    -- Obtener información del stock
    SELECT s.sku, p.nombre_producto, s.cantidad_reservada
    INTO v_sku, v_nombre_producto, v_cantidad_reservada
    FROM stock s
    INNER JOIN productos p ON s.producto_id = p.producto_id
    WHERE s.stock_id = p_stock_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Stock % no encontrado', p_stock_id;
    END IF;
    
    -- Verificar si tiene cantidad reservada
    IF v_cantidad_reservada > 0 THEN
        RAISE EXCEPTION 'No se puede eliminar el SKU "%" del producto "%" porque tiene % unidades reservadas en pedidos.', 
            v_sku, v_nombre_producto, v_cantidad_reservada;
    END IF;
    
    -- Verificar si está en algún pedido (histórico)
    SELECT COUNT(*)
    INTO v_en_pedidos
    FROM detalle_pedido
    WHERE stock_id = p_stock_id;
    
    IF v_en_pedidos > 0 THEN
        RAISE EXCEPTION 'No se puede eliminar el SKU "%" porque está en % pedidos (histórico). Usa desactivación en su lugar.', 
            v_sku, v_en_pedidos;
    END IF;
    
    -- Eliminar stock
    DELETE FROM stock WHERE stock_id = p_stock_id;
    
    RAISE NOTICE 'Stock "%" del producto "%" eliminado exitosamente', v_sku, v_nombre_producto;
END;
$$;

/* * =========================================
 * PROCEDIMIENTO 12: Eliminar Pedido
 * =========================================
 * Elimina un pedido solo si está en estado "cancelado".
 * Elimina también sus detalles, pagos y envíos asociados.
 * 
 * Parámetros:
 *   - p_pedido_id: ID del pedido a eliminar
 */
CREATE OR REPLACE PROCEDURE sp_eliminar_pedido(
    p_pedido_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_estado_pedido VARCHAR(50);
BEGIN
    -- Obtener estado del pedido
    SELECT estado_pedido
    INTO v_estado_pedido
    FROM pedidos
    WHERE pedido_id = p_pedido_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Pedido % no encontrado', p_pedido_id;
    END IF;
    
    -- Solo se pueden eliminar pedidos cancelados
    IF v_estado_pedido != 'cancelado' THEN
        RAISE EXCEPTION 'Solo se pueden eliminar pedidos cancelados. Estado actual: "%"', v_estado_pedido;
    END IF;
    
    -- Eliminar devoluciones asociadas
    DELETE FROM devoluciones 
    WHERE detalle_id IN (
        SELECT detalle_id 
        FROM detalle_pedido 
        WHERE pedido_id = p_pedido_id
    );
    
    -- Eliminar detalles del pedido
    DELETE FROM detalle_pedido WHERE pedido_id = p_pedido_id;
    
    -- Eliminar envío asociado (si existe)
    DELETE FROM envios WHERE pedido_id = p_pedido_id;
    
    -- Eliminar pagos asociados
    DELETE FROM pagos WHERE pedido_id = p_pedido_id;
    
    -- Eliminar pedido
    DELETE FROM pedidos WHERE pedido_id = p_pedido_id;
    
    RAISE NOTICE 'Pedido % y sus registros asociados eliminados exitosamente', p_pedido_id;
END;
$$;

/* * =========================================
 * PROCEDIMIENTO 13: Eliminar Pago
 * =========================================
 * Elimina un registro de pago solo si está en estado "fallido" o "pendiente".
 * NO se pueden eliminar pagos exitosos o reembolsados.
 * 
 * Parámetros:
 *   - p_pago_id: ID del pago a eliminar
 */
CREATE OR REPLACE PROCEDURE sp_eliminar_pago(
    p_pago_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_estado_pago VARCHAR(20);
    v_pedido_id INT;
BEGIN
    -- Obtener información del pago
    SELECT estado_pago, pedido_id
    INTO v_estado_pago, v_pedido_id
    FROM pagos
    WHERE pago_id = p_pago_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Pago % no encontrado', p_pago_id;
    END IF;
    
    -- Solo se pueden eliminar pagos fallidos o pendientes
    IF v_estado_pago NOT IN ('fallido', 'pendiente') THEN
        RAISE EXCEPTION 'Solo se pueden eliminar pagos fallidos o pendientes. Estado actual: "%"', v_estado_pago;
    END IF;
    
    -- Eliminar pago
    DELETE FROM pagos WHERE pago_id = p_pago_id;
    
    RAISE NOTICE 'Pago % (estado: %) del pedido % eliminado exitosamente', p_pago_id, v_estado_pago, v_pedido_id;
END;
$$;
