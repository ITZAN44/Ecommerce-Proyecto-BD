SELECT '=== PRUEBA: Ventas Diarias (últimos 7 días) ===' AS test;
SELECT * FROM fn_ventas_diarias(7);
SELECT '=== PRUEBA: Ventas Diarias (últimos 30 días) ===' AS test;
SELECT * FROM fn_ventas_diarias(30);
SELECT '=== PRUEBA: Top 5 Categorías ===' AS test;
SELECT * FROM fn_ventas_por_categoria(5);
SELECT '=== PRUEBA: Top 10 Categorías ===' AS test;
SELECT * FROM fn_ventas_por_categoria(10);
SELECT '=== PRUEBA: Tendencia Pedidos (últimos 7 días) ===' AS test;
SELECT * FROM fn_tendencia_pedidos(7);
SELECT '=== PRUEBA: Tendencia Pedidos (últimos 30 días) ===' AS test;
SELECT * FROM fn_tendencia_pedidos(30);
SELECT '=== PRUEBA: Distribución de Estados ===' AS test;
SELECT * FROM fn_distribucion_estados_pedidos();
SELECT '=== VERIFICACIÓN: Total de pedidos en BD ===' AS test;
SELECT COUNT(*) as total_pedidos FROM pedidos;
SELECT '=== VERIFICACIÓN: Pedidos por estado ===' AS test;
SELECT estado_pedido, COUNT(*) as cantidad
FROM pedidos
GROUP BY estado_pedido
ORDER BY cantidad DESC;
SELECT '=== VERIFICACIÓN: Categorías con ventas ===' AS test;
SELECT c.nombre_categoria, COUNT(DISTINCT ped.pedido_id) as num_pedidos
FROM categorias c
LEFT JOIN productos p ON c.categoria_id = p.categoria_id
LEFT JOIN stock s ON p.producto_id = s.producto_id
LEFT JOIN detalle_pedido dp ON s.stock_id = dp.stock_id
LEFT JOIN pedidos ped ON dp.pedido_id = ped.pedido_id
    AND ped.estado_pedido IN ('pagado', 'enviado', 'completado')
WHERE c.estado = 'activo'
GROUP BY c.nombre_categoria
ORDER BY num_pedidos DESC;
SELECT '=== VERIFICACIÓN: Rango de fechas de pedidos ===' AS test;
SELECT
    MIN(fecha_pedido) as fecha_primer_pedido,
    MAX(fecha_pedido) as fecha_ultimo_pedido,
    COUNT(*) as total_pedidos
FROM pedidos;