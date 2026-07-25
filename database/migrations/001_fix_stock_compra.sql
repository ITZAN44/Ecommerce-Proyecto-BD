-- Migration 001: fix physical stock never decremented on sale (remediacion V1)
--
-- Bug: sp_procesar_pago never decremented physical stock. sp_crear_pedido only
-- reserves (cantidad_reservada += qty); sp_procesar_pago touched pagos/pedidos/
-- envios but not stock; sp_actualizar_stock_compra (the routine that does the
-- decrement + releases the reservation) was dead code with zero callers.
--
-- Fix: call sp_actualizar_stock_compra inside sp_procesar_pago, right after the
-- order is marked 'pagado'. It runs in the same transaction, so payment and
-- stock decrement are atomic.
--
-- Verified against live DB ecommerce_db on 2026-07-24 (bodies via
-- pg_get_functiondef; 0 DB callers and 0 src/ references for the dead routine).

CREATE OR REPLACE PROCEDURE public.sp_procesar_pago(
    IN p_pedido_id integer,
    IN p_monto numeric,
    IN p_metodo_pago character varying,
    IN p_id_transaccion character varying
)
LANGUAGE plpgsql
AS $procedure$
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

    -- Descontar stock físico y liberar la reserva (fix V1: antes nunca ocurría)
    CALL sp_actualizar_stock_compra(p_pedido_id);

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
$procedure$;
