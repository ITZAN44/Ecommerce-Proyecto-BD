CREATE TABLE IF NOT EXISTS historial_estados (
    historial_id SERIAL PRIMARY KEY,
    pedido_id INT NOT NULL REFERENCES pedidos(pedido_id) ON DELETE CASCADE,
    estado_anterior VARCHAR(50),
    estado_nuevo VARCHAR(50) NOT NULL,
    usuario VARCHAR(100) DEFAULT current_user,
    comentario TEXT,
    fecha_cambio TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_estado_anterior CHECK (estado_anterior IN ('pendiente', 'pagado', 'enviado', 'cancelado', 'completado') OR estado_anterior IS NULL),
    CONSTRAINT chk_estado_nuevo CHECK (estado_nuevo IN ('pendiente', 'pagado', 'enviado', 'cancelado', 'completado'))
);
CREATE INDEX IF NOT EXISTS idx_historial_estados_pedido ON historial_estados(pedido_id, fecha_cambio DESC);
CREATE INDEX IF NOT EXISTS idx_historial_estados_fecha ON historial_estados(fecha_cambio DESC);
COMMENT ON TABLE historial_estados IS
'Historial de cambios de estado para timeline visual de pedidos.
Complementa la tabla auditoria con información específica para UX.';
COMMENT ON COLUMN historial_estados.estado_anterior IS
'Estado previo del pedido. NULL para el estado inicial (creación).';
COMMENT ON COLUMN historial_estados.comentario IS
'Nota o motivo del cambio de estado (ej: "Pedido enviado por FedEx", "Cancelado por cliente").';
CREATE OR REPLACE FUNCTION fn_registrar_cambio_estado()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        INSERT INTO historial_estados (
            pedido_id,
            estado_anterior,
            estado_nuevo,
            usuario,
            comentario
        ) VALUES (
            NEW.pedido_id,
            NULL,
            NEW.estado_pedido,
            current_user,
            'Pedido creado'
        );
    ELSIF (TG_OP = 'UPDATE' AND OLD.estado_pedido IS DISTINCT FROM NEW.estado_pedido) THEN
        INSERT INTO historial_estados (
            pedido_id,
            estado_anterior,
            estado_nuevo,
            usuario,
            comentario
        ) VALUES (
            NEW.pedido_id,
            OLD.estado_pedido,
            NEW.estado_pedido,
            current_user,
            CASE
                WHEN NEW.estado_pedido = 'pagado' THEN 'Pago confirmado'
                WHEN NEW.estado_pedido = 'enviado' THEN 'Pedido en tránsito'
                WHEN NEW.estado_pedido = 'completado' THEN 'Pedido entregado'
                WHEN NEW.estado_pedido = 'cancelado' THEN 'Pedido cancelado'
                ELSE 'Estado actualizado'
            END
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
COMMENT ON FUNCTION fn_registrar_cambio_estado() IS
'Trigger automático que registra cambios de estado en historial_estados.
Se ejecuta DESPUÉS de INSERT o UPDATE en tabla pedidos.';
DROP TRIGGER IF EXISTS trg_registrar_cambio_estado_pedido ON pedidos;
CREATE TRIGGER trg_registrar_cambio_estado_pedido
AFTER INSERT OR UPDATE OF estado_pedido ON pedidos
FOR EACH ROW
EXECUTE FUNCTION fn_registrar_cambio_estado();
COMMENT ON TRIGGER trg_registrar_cambio_estado_pedido ON pedidos IS
'Registra automáticamente cambios de estado en historial_estados para timeline visual.';
CREATE OR REPLACE FUNCTION fn_obtener_timeline_pedido(p_pedido_id INT)
RETURNS TABLE (
    historial_id INT,
    pedido_id INT,
    estado_anterior VARCHAR(50),
    estado_nuevo VARCHAR(50),
    usuario VARCHAR(100),
    comentario TEXT,
    fecha_cambio TIMESTAMP,
    orden INT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        h.historial_id,
        h.pedido_id,
        h.estado_anterior,
        h.estado_nuevo,
        h.usuario,
        h.comentario,
        h.fecha_cambio,
        ROW_NUMBER() OVER (ORDER BY h.fecha_cambio ASC)::INT AS orden
    FROM historial_estados h
    WHERE h.pedido_id = p_pedido_id
    ORDER BY h.fecha_cambio ASC;
END;
$$ LANGUAGE plpgsql;
COMMENT ON FUNCTION fn_obtener_timeline_pedido(INT) IS
'Obtiene el timeline completo de un pedido con estados ordenados cronológicamente.
Incluye orden secuencial para renderizado frontend.';
CREATE OR REPLACE FUNCTION fn_estadisticas_estados(p_pedido_id INT)
RETURNS TABLE (
    estado VARCHAR(50),
    fecha_inicio TIMESTAMP,
    fecha_fin TIMESTAMP,
    duracion_horas NUMERIC(10,2)
) AS $$
BEGIN
    RETURN QUERY
    WITH estados_con_siguiente AS (
        SELECT
            h.estado_nuevo,
            h.fecha_cambio AS fecha_inicio,
            LEAD(h.fecha_cambio) OVER (ORDER BY h.fecha_cambio) AS fecha_fin
        FROM historial_estados h
        WHERE h.pedido_id = p_pedido_id
    )
    SELECT
        e.estado_nuevo::VARCHAR(50) AS estado,
        e.fecha_inicio,
        e.fecha_fin,
        CASE
            WHEN e.fecha_fin IS NOT NULL THEN
                ROUND(EXTRACT(EPOCH FROM (e.fecha_fin - e.fecha_inicio)) / 3600, 2)
            ELSE
                ROUND(EXTRACT(EPOCH FROM (NOW() - e.fecha_inicio)) / 3600, 2)
        END AS duracion_horas
    FROM estados_con_siguiente e
    ORDER BY e.fecha_inicio ASC;
END;
$$ LANGUAGE plpgsql;
COMMENT ON FUNCTION fn_estadisticas_estados(INT) IS
'Calcula la duración de cada estado del pedido en horas.
Útil para métricas de rendimiento y tiempos de procesamiento.';
CREATE OR REPLACE VIEW vw_timeline_pedidos AS
SELECT
    h.historial_id,
    h.pedido_id,
    h.estado_anterior,
    h.estado_nuevo,
    h.usuario,
    h.comentario,
    h.fecha_cambio,
    p.cliente_id,
    c.nombre || ' ' || c.apellido AS nombre_cliente,
    p.total_pedido,
    p.fecha_pedido
FROM historial_estados h
INNER JOIN pedidos p ON h.pedido_id = p.pedido_id
INNER JOIN clientes c ON p.cliente_id = c.cliente_id
ORDER BY h.fecha_cambio DESC;
COMMENT ON VIEW vw_timeline_pedidos IS
'Vista combinada de historial de estados con información del pedido y cliente.
Optimizada para listados de actividad reciente.';
CREATE OR REPLACE FUNCTION fn_cambiar_estado_pedido(
    p_pedido_id INT,
    p_nuevo_estado VARCHAR(50),
    p_comentario TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
    v_estado_actual VARCHAR(50);
BEGIN
    SELECT estado_pedido INTO v_estado_actual
    FROM pedidos
    WHERE pedido_id = p_pedido_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Pedido % no encontrado', p_pedido_id;
    END IF;
    IF v_estado_actual = p_nuevo_estado THEN
        RAISE NOTICE 'El pedido ya está en estado %', p_nuevo_estado;
        RETURN FALSE;
    END IF;
    UPDATE pedidos
    SET estado_pedido = p_nuevo_estado
    WHERE pedido_id = p_pedido_id;
    IF p_comentario IS NOT NULL THEN
        UPDATE historial_estados
        SET comentario = p_comentario
        WHERE historial_id = (
            SELECT historial_id
            FROM historial_estados
            WHERE pedido_id = p_pedido_id
            ORDER BY fecha_cambio DESC
            LIMIT 1
        );
    END IF;
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;
COMMENT ON FUNCTION fn_cambiar_estado_pedido(INT, VARCHAR, TEXT) IS
'Cambia el estado de un pedido con comentario personalizado opcional.
El trigger registra automáticamente el cambio en historial_estados.';
DO $$
DECLARE
    tabla_existe BOOLEAN;
    trigger_existe BOOLEAN;
    funciones_creadas INT;
BEGIN
    SELECT EXISTS (
        SELECT FROM pg_tables
        WHERE schemaname = 'public'
        AND tablename = 'historial_estados'
    ) INTO tabla_existe;
    SELECT EXISTS (
        SELECT FROM pg_trigger
        WHERE tgname = 'trg_registrar_cambio_estado_pedido'
    ) INTO trigger_existe;
    SELECT COUNT(*) INTO funciones_creadas
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public'
    AND p.proname IN (
        'fn_registrar_cambio_estado',
        'fn_obtener_timeline_pedido',
        'fn_estadisticas_estados',
        'fn_cambiar_estado_pedido'
    );
    RAISE NOTICE '=== FASE 3: VERIFICACION ===';
    RAISE NOTICE 'Tabla historial_estados: %', CASE WHEN tabla_existe THEN '[OK] Creada' ELSE '[ERROR] No creada' END;
    RAISE NOTICE 'Trigger automatico: %', CASE WHEN trigger_existe THEN '[OK] Activo' ELSE '[ERROR] No activo' END;
    RAISE NOTICE 'Funciones creadas: % de 4', funciones_creadas;
    RAISE NOTICE '============================';
END $$;