SELECT '=== VERIFICACIÓN: Clientes disponibles ===' AS test;
SELECT cliente_id, nombre, apellido, email
FROM clientes
WHERE estado = 'activo'
LIMIT 3;
SELECT '=== VERIFICACIÓN: Direcciones disponibles ===' AS test;
SELECT direccion_id, cliente_id, ciudad, pais
FROM direcciones
WHERE estado = 'activo'
LIMIT 3;
SELECT '=== PRUEBA 1: Verificar tabla historial_estados ===' AS test;
SELECT
    COUNT(*) as registros_existentes,
    MIN(fecha_cambio) as primer_cambio,
    MAX(fecha_cambio) as ultimo_cambio
FROM historial_estados;
SELECT '=== PRUEBA 1: Verificar trigger activo ===' AS test;
SELECT
    tgname AS nombre_trigger,
    tgenabled AS estado
FROM pg_trigger
WHERE tgname = 'trg_registrar_cambio_estado_pedido';
SELECT '=== PRUEBA 2: Crear pedido de prueba ===' AS test;
SELECT
    pedido_id,
    estado_pedido,
    fecha_pedido
FROM pedidos
ORDER BY pedido_id DESC
LIMIT 1;
SELECT '=== PRUEBA 2: Verificar registro automático del último pedido ===' AS test;
SELECT
    h.historial_id,
    h.pedido_id,
    h.estado_anterior,
    h.estado_nuevo,
    h.comentario,
    h.fecha_cambio
FROM historial_estados h
WHERE h.pedido_id = (SELECT MAX(pedido_id) FROM pedidos)
ORDER BY h.fecha_cambio ASC;
SELECT '=== PRUEBA 3: Actualizar estado de pedido ===' AS test;
DO $$
DECLARE
    v_pedido_id INT;
BEGIN
    SELECT pedido_id INTO v_pedido_id
    FROM pedidos
    WHERE estado_pedido = 'pendiente'
    LIMIT 1;
    IF v_pedido_id IS NOT NULL THEN
        UPDATE pedidos
        SET estado_pedido = 'pagado'
        WHERE pedido_id = v_pedido_id;
        RAISE NOTICE 'Pedido % actualizado a estado: pagado', v_pedido_id;
        PERFORM pg_sleep(1);
        UPDATE pedidos
        SET estado_pedido = 'enviado'
        WHERE pedido_id = v_pedido_id;
        RAISE NOTICE 'Pedido % actualizado a estado: enviado', v_pedido_id;
    ELSE
        RAISE NOTICE 'No se encontró ningún pedido en estado pendiente';
    END IF;
END $$;
SELECT '=== PRUEBA 3: Ver historial después de cambios ===' AS test;
SELECT
    h.historial_id,
    h.pedido_id,
    h.estado_anterior,
    h.estado_nuevo,
    h.usuario,
    h.comentario,
    h.fecha_cambio
FROM historial_estados h
WHERE h.pedido_id = (
    SELECT pedido_id
    FROM pedidos
    WHERE estado_pedido IN ('pagado', 'enviado')
    ORDER BY pedido_id DESC
    LIMIT 1
)
ORDER BY h.fecha_cambio ASC;
SELECT '=== PRUEBA 4: Obtener timeline completo ===' AS test;
SELECT * FROM fn_obtener_timeline_pedido(
    (SELECT pedido_id FROM historial_estados GROUP BY pedido_id ORDER BY COUNT(*) DESC LIMIT 1)
);
SELECT '=== PRUEBA 5: Estadísticas de duración por estado ===' AS test;
SELECT * FROM fn_estadisticas_estados(
    (SELECT pedido_id FROM historial_estados GROUP BY pedido_id ORDER BY COUNT(*) DESC LIMIT 1)
);
SELECT '=== PRUEBA 6: Cambiar estado con comentario personalizado ===' AS test;
DO $$
DECLARE
    v_pedido_id INT;
    v_resultado BOOLEAN;
BEGIN
    SELECT pedido_id INTO v_pedido_id
    FROM pedidos
    WHERE estado_pedido IN ('pagado', 'enviado')
    LIMIT 1;
    IF v_pedido_id IS NOT NULL THEN
        SELECT fn_cambiar_estado_pedido(
            v_pedido_id,
            'completado',
            'Entregado exitosamente - Firmado por cliente'
        ) INTO v_resultado;
        RAISE NOTICE 'Cambio de estado: %', CASE WHEN v_resultado THEN 'Exitoso' ELSE 'Fallido' END;
    ELSE
        RAISE NOTICE 'No hay pedidos disponibles para la prueba';
    END IF;
END $$;
SELECT '=== PRUEBA 6: Verificar comentario personalizado ===' AS test;
SELECT
    h.pedido_id,
    h.estado_nuevo,
    h.comentario,
    h.fecha_cambio
FROM historial_estados h
WHERE h.comentario LIKE '%Entregado exitosamente%'
ORDER BY h.fecha_cambio DESC
LIMIT 1;
SELECT '=== PRUEBA 7: Consultar vista combinada ===' AS test;
SELECT
    historial_id,
    pedido_id,
    estado_nuevo,
    nombre_cliente,
    total_pedido,
    comentario,
    fecha_cambio
FROM vw_timeline_pedidos
ORDER BY fecha_cambio DESC
LIMIT 10;
SELECT '=== PRUEBA 8: Validar relaciones con pedidos ===' AS test;
SELECT
    COUNT(DISTINCT h.pedido_id) as pedidos_en_historial,
    COUNT(DISTINCT p.pedido_id) as pedidos_existentes,
    CASE
        WHEN COUNT(DISTINCT h.pedido_id) = COUNT(DISTINCT p.pedido_id)
        THEN '[OK] Todos los registros son validos'
        ELSE '[ERROR] Hay inconsistencias'
    END AS resultado
FROM historial_estados h
INNER JOIN pedidos p ON h.pedido_id = p.pedido_id;
SELECT '=== PRUEBA 9: Verificar constraint de estados ===' AS test;
DO $$
BEGIN
    BEGIN
        INSERT INTO historial_estados (pedido_id, estado_nuevo, comentario)
        VALUES (1, 'estado_invalido', 'Prueba de constraint');
        RAISE NOTICE '[ERROR] Constraint NO funciono - estado invalido aceptado';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE '[OK] Constraint funcionando - estado invalido rechazado correctamente';
    END;
END $$;
SELECT '=== PRUEBA 10: Verificar índices creados ===' AS test;
SELECT
    indexname,
    indexdef
FROM pg_indexes
WHERE tablename = 'historial_estados'
ORDER BY indexname;
SELECT '=== RESUMEN: Estadísticas generales ===' AS test;
SELECT
    (SELECT COUNT(*) FROM historial_estados) as total_cambios_registrados,
    (SELECT COUNT(DISTINCT pedido_id) FROM historial_estados) as pedidos_con_historial,
    (SELECT COUNT(*) FROM pedidos) as total_pedidos,
    (SELECT COUNT(*) FROM pg_trigger WHERE tgname = 'trg_registrar_cambio_estado_pedido') as trigger_activo,
    (SELECT COUNT(*) FROM pg_proc WHERE proname LIKE 'fn_%estado%') as funciones_timeline;