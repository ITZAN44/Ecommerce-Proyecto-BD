CREATE OR REPLACE FUNCTION fn_alerta_stock_bajo(p_limite INT DEFAULT 15)
RETURNS TABLE(
    stock_id INT,
    producto_id INT,
    sku VARCHAR(100),
    nombre_producto VARCHAR(255),
    cantidad_disponible INT,
    cantidad_reservada INT,
    nivel_criticidad VARCHAR(20)
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        s.stock_id,
        s.producto_id,
        s.sku,
        p.nombre_producto,
        s.cantidad_en_stock AS cantidad_disponible,
        s.cantidad_reservada,
        (CASE
            WHEN (s.cantidad_en_stock - s.cantidad_reservada) = 0 THEN 'CRÍTICO'
            WHEN (s.cantidad_en_stock - s.cantidad_reservada) <= 3 THEN 'URGENTE'
            WHEN (s.cantidad_en_stock - s.cantidad_reservada) <= p_limite THEN 'ADVERTENCIA'
            ELSE 'NORMAL'
        END)::VARCHAR(20) AS nivel_criticidad
    FROM stock s
    JOIN productos p ON s.producto_id = p.producto_id
    WHERE (s.cantidad_en_stock - s.cantidad_reservada) <= p_limite
        AND s.estado = 'activo'
        AND p.estado = 'activo'
    ORDER BY (s.cantidad_en_stock - s.cantidad_reservada) ASC, p.nombre_producto;
END;
$$ LANGUAGE plpgsql;
CREATE OR REPLACE FUNCTION fn_estadisticas_dashboard()
RETURNS TABLE(
    total_pedidos_hoy INT,
    total_pedidos_pendientes INT,
    total_pedidos_completados INT,
    ventas_hoy NUMERIC(12,2),
    ventas_mes NUMERIC(12,2),
    total_clientes_activos INT,
    total_productos_activos INT,
    productos_stock_bajo INT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        (SELECT COUNT(*)::INT FROM pedidos WHERE DATE(fecha_pedido) = CURRENT_DATE),
        (SELECT COUNT(*)::INT FROM pedidos WHERE estado_pedido = 'pendiente'),
        (SELECT COUNT(*)::INT FROM pedidos WHERE estado_pedido = 'completado'),
        (SELECT COALESCE(SUM(total_pedido), 0) FROM pedidos WHERE DATE(fecha_pedido) = CURRENT_DATE),
        (SELECT COALESCE(SUM(total_pedido), 0) FROM pedidos WHERE fecha_pedido >= DATE_TRUNC('month', CURRENT_DATE)),
        (SELECT COUNT(*)::INT FROM clientes WHERE estado = 'activo'),
        (SELECT COUNT(*)::INT FROM productos WHERE estado = 'activo'),
        (SELECT COUNT(*)::INT FROM stock WHERE (cantidad_en_stock - cantidad_reservada) < 15 AND estado = 'activo');
END;
$$ LANGUAGE plpgsql;
CREATE OR REPLACE FUNCTION fn_metricas_producto(p_producto_id INT)
RETURNS TABLE(
    producto_id INT,
    nombre_producto VARCHAR(255),
    total_vendido BIGINT,
    ingresos_totales NUMERIC(12,2),
    numero_pedidos BIGINT,
    stock_total INT,
    stock_reservado INT,
    precio_promedio NUMERIC(10,2)
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        p.producto_id,
        p.nombre_producto,
        COALESCE(SUM(dp.cantidad), 0) AS total_vendido,
        COALESCE(SUM(dp.cantidad * dp.precio_unitario_compra), 0) AS ingresos_totales,
        COUNT(DISTINCT ped.pedido_id) AS numero_pedidos,
        COALESCE(SUM(s.cantidad_en_stock), 0)::INT AS stock_total,
        COALESCE(SUM(s.cantidad_reservada), 0)::INT AS stock_reservado,
        COALESCE(AVG(s.precio_unitario), 0) AS precio_promedio
    FROM productos p
    LEFT JOIN stock s ON p.producto_id = s.producto_id
    LEFT JOIN detalle_pedido dp ON s.stock_id = dp.stock_id
    LEFT JOIN pedidos ped ON dp.pedido_id = ped.pedido_id
        AND ped.estado_pedido IN ('pagado', 'enviado', 'completado')
    WHERE p.producto_id = p_producto_id
    GROUP BY p.producto_id, p.nombre_producto;
END;
$$ LANGUAGE plpgsql;
CREATE OR REPLACE FUNCTION fn_historial_cambios(
    p_tabla VARCHAR(100),
    p_registro_id INT,
    p_limite INT DEFAULT 50
)
RETURNS TABLE(
    auditoria_id INT,
    operacion VARCHAR(10),
    usuario VARCHAR(100),
    fecha TIMESTAMP,
    cambios JSONB
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        a.auditoria_id,
        a.operacion::VARCHAR(10),
        a.usuario::VARCHAR(100),
        a.fecha,
        (CASE
            WHEN a.operacion = 'UPDATE' THEN
                jsonb_build_object(
                    'anterior', a.datos_anteriores,
                    'nuevo', a.datos_nuevos
                )
            WHEN a.operacion = 'DELETE' THEN a.datos_anteriores
            WHEN a.operacion = 'INSERT' THEN a.datos_nuevos
        END)::JSONB AS cambios
    FROM auditoria a
    WHERE a.tabla = p_tabla
        AND a.registro_id = p_registro_id
    ORDER BY a.fecha DESC
    LIMIT p_limite;
END;
$$ LANGUAGE plpgsql;
DO $$
DECLARE
    func_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO func_count
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public'
    AND p.proname LIKE 'fn_%'
    AND p.proname IN ('fn_alerta_stock_bajo', 'fn_estadisticas_dashboard', 'fn_metricas_producto', 'fn_historial_cambios');
    RAISE NOTICE 'Total de funciones de utilidad: %', func_count;
END $$;