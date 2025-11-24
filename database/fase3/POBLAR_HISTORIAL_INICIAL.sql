SELECT '=== ESTADO ACTUAL ===' AS info;
SELECT
    (SELECT COUNT(*) FROM pedidos) as total_pedidos,
    (SELECT COUNT(DISTINCT pedido_id) FROM historial_estados) as pedidos_con_historial,
    (SELECT COUNT(*) FROM pedidos WHERE pedido_id NOT IN (SELECT DISTINCT pedido_id FROM historial_estados)) as pedidos_sin_historial;
SELECT '=== CREANDO REGISTROS INICIALES ===' AS info;
INSERT INTO historial_estados (pedido_id, estado_anterior, estado_nuevo, comentario, fecha_cambio)
SELECT
    p.pedido_id,
    NULL as estado_anterior,
    p.estado_pedido as estado_nuevo,
    'Estado inicial del pedido (migración histórica)' as comentario,
    p.fecha_pedido as fecha_cambio
FROM pedidos p
WHERE p.pedido_id NOT IN (
    SELECT DISTINCT pedido_id
    FROM historial_estados
)
ORDER BY p.pedido_id;
SELECT '=== REGISTROS CREADOS ===' AS info;
SELECT
    (SELECT COUNT(*) FROM historial_estados) as total_registros_historial,
    (SELECT COUNT(DISTINCT pedido_id) FROM historial_estados) as pedidos_con_historial,
    (SELECT COUNT(*) FROM pedidos WHERE pedido_id NOT IN (SELECT DISTINCT pedido_id FROM historial_estados)) as pedidos_sin_historial;
SELECT '=== EJEMPLOS DE TIMELINE ===' AS info;
SELECT
    h.pedido_id,
    h.estado_nuevo,
    h.comentario,
    h.fecha_cambio
FROM historial_estados h
WHERE h.pedido_id IN (
    SELECT pedido_id
    FROM pedidos
    ORDER BY pedido_id
    LIMIT 5
)
ORDER BY h.pedido_id, h.fecha_cambio;