CREATE MATERIALIZED VIEW IF NOT EXISTS mv_productos_top_ventas AS
SELECT
    p.producto_id,
    p.nombre_producto,
    p.descripcion_larga,
    c.nombre_categoria,
    SUM(dp.cantidad) AS total_vendido,
    SUM(dp.cantidad * dp.precio_unitario_compra) AS ingresos_totales,
    COUNT(DISTINCT ped.pedido_id) AS num_pedidos,
    AVG(dp.precio_unitario_compra) AS precio_promedio
FROM productos p
JOIN categorias c ON p.categoria_id = c.categoria_id
JOIN stock s ON p.producto_id = s.producto_id
JOIN detalle_pedido dp ON s.stock_id = dp.stock_id
JOIN pedidos ped ON dp.pedido_id = ped.pedido_id
WHERE ped.estado_pedido IN ('pagado', 'enviado', 'completado')
    AND p.estado = 'activo'
GROUP BY p.producto_id, p.nombre_producto, p.descripcion_larga, c.nombre_categoria
ORDER BY total_vendido DESC;
CREATE UNIQUE INDEX IF NOT EXISTS idx_mv_productos_top_ventas_id ON mv_productos_top_ventas(producto_id);
CREATE MATERIALIZED VIEW IF NOT EXISTS mv_clientes_vip AS
SELECT
    c.cliente_id,
    c.nombre,
    c.apellido,
    c.email,
    COUNT(p.pedido_id) AS total_pedidos,
    SUM(p.total_pedido) AS total_gastado,
    AVG(p.total_pedido) AS ticket_promedio,
    MAX(p.fecha_pedido) AS ultima_compra,
    MIN(p.fecha_pedido) AS primera_compra,
    CASE
        WHEN SUM(p.total_pedido) >= 1000 THEN 'Platinum'
        WHEN SUM(p.total_pedido) >= 500 THEN 'Gold'
        WHEN COUNT(p.pedido_id) >= 5 THEN 'Silver'
        ELSE 'Bronze'
    END AS categoria_vip
FROM clientes c
JOIN pedidos p ON c.cliente_id = p.cliente_id
WHERE p.estado_pedido IN ('pagado', 'enviado', 'completado')
    AND c.estado = 'activo'
GROUP BY c.cliente_id, c.nombre, c.apellido, c.email
HAVING COUNT(p.pedido_id) >= 3 OR SUM(p.total_pedido) >= 500
ORDER BY total_gastado DESC;
CREATE UNIQUE INDEX IF NOT EXISTS idx_mv_clientes_vip_id ON mv_clientes_vip(cliente_id);
CREATE INDEX IF NOT EXISTS idx_mv_clientes_vip_categoria ON mv_clientes_vip(categoria_vip);
DO $$
DECLARE
    vista_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO vista_count
    FROM pg_matviews
    WHERE schemaname = 'public'
    AND matviewname LIKE 'mv_%';
    RAISE NOTICE 'Total de vistas materializadas: %', vista_count;
END $$;