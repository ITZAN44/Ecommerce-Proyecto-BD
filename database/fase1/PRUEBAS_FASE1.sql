UPDATE productos
SET nombre_producto = nombre_producto
WHERE producto_id = 1 AND estado = 'activo';
SELECT
    auditoria_id,
    tabla,
    operacion,
    registro_id,
    usuario,
    fecha,
    datos_anteriores->>'nombre_producto' as nombre_anterior,
    datos_nuevos->>'nombre_producto' as nombre_nuevo
FROM auditoria
WHERE tabla = 'productos'
ORDER BY fecha DESC
LIMIT 5;
SELECT * FROM fn_alerta_stock_bajo();
SELECT
    producto_id,
    nombre_producto,
    total_vendido,
    ingresos_totales
FROM mv_productos_top_ventas
ORDER BY ingresos_totales DESC
LIMIT 10;
SELECT
    cliente_id,
    nombre,
    apellido,
    email,
    total_gastado,
    total_pedidos,
    categoria_vip
FROM mv_clientes_vip
ORDER BY total_gastado DESC
LIMIT 10;
SELECT * FROM fn_estadisticas_dashboard();
SELECT * FROM fn_metricas_producto(1);
SELECT * FROM fn_historial_cambios('productos', 10);
EXPLAIN ANALYZE
SELECT p.pedido_id, p.fecha_pedido, p.total_pedido
FROM pedidos p
WHERE p.cliente_id = 1
AND p.estado_pedido = 'completado';
EXPLAIN ANALYZE
SELECT producto_id, nombre_producto
FROM productos
WHERE categoria_id = 1
AND estado = 'activo';
EXPLAIN ANALYZE
SELECT s.stock_id, s.cantidad_en_stock, p.nombre_producto
FROM stock s
JOIN productos p ON s.producto_id = p.producto_id
WHERE s.producto_id = 1
AND s.estado = 'activo';
REFRESH MATERIALIZED VIEW CONCURRENTLY mv_productos_top_ventas;
REFRESH MATERIALIZED VIEW CONCURRENTLY mv_clientes_vip;
SELECT
    schemaname,
    matviewname,
    ispopulated
FROM pg_matviews
WHERE schemaname = 'public'
AND matviewname IN ('mv_productos_top_ventas', 'mv_clientes_vip');
BEGIN;
INSERT INTO cupones (codigo_cupon, tipo_descuento, valor_descuento, fecha_expiracion, usos_disponibles)
VALUES ('TEST2024', 'porcentaje', 15.00, NOW() + INTERVAL '30 days', 100);
UPDATE clientes
SET nombre = nombre
WHERE cliente_id = 1 AND estado = 'activo';
UPDATE stock
SET cantidad_en_stock = cantidad_en_stock
WHERE stock_id = 1 AND estado = 'activo';
COMMIT;
SELECT
    auditoria_id,
    tabla,
    operacion,
    usuario,
    fecha,
    CASE
        WHEN operacion = 'INSERT' THEN datos_nuevos
        WHEN operacion = 'UPDATE' THEN jsonb_build_object(
            'antes', datos_anteriores,
            'despues', datos_nuevos
        )
        ELSE datos_anteriores
    END as cambios
FROM auditoria
WHERE fecha >= NOW() - INTERVAL '5 minutes'
ORDER BY fecha DESC;
SELECT
    '[OK] Auditoria' as prueba,
    CASE WHEN COUNT(*) > 0 THEN 'OK' ELSE 'FALLO' END as resultado
FROM auditoria
WHERE fecha >= NOW() - INTERVAL '10 minutes'
UNION ALL
SELECT
    '[OK] Alerta Stock',
    CASE WHEN EXISTS(SELECT 1 FROM fn_alerta_stock_bajo()) THEN 'OK' ELSE 'OK (sin alertas)' END
FROM (SELECT 1) x
UNION ALL
SELECT
    '[OK] Vista Top Ventas',
    CASE WHEN COUNT(*) > 0 THEN 'OK' ELSE 'FALLO' END
FROM mv_productos_top_ventas
UNION ALL
SELECT
    '[OK] Vista Clientes VIP',
    CASE WHEN COUNT(*) > 0 THEN 'OK' ELSE 'FALLO' END
FROM mv_clientes_vip
UNION ALL
SELECT
    '[OK] Dashboard',
    CASE WHEN (SELECT total_productos_activos FROM fn_estadisticas_dashboard()) > 0 THEN 'OK' ELSE 'FALLO' END
FROM (SELECT 1) x;