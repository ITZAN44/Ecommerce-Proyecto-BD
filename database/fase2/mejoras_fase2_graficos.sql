CREATE OR REPLACE FUNCTION fn_ventas_diarias(p_dias INT DEFAULT 7)
RETURNS TABLE(
    fecha DATE,
    total_ventas NUMERIC(12,2),
    numero_pedidos BIGINT
) AS $$
DECLARE
    fecha_inicio DATE;
BEGIN
    SELECT COALESCE(
        NULLIF(
            (SELECT MAX(DATE(fecha_pedido)) FROM pedidos
             WHERE fecha_pedido >= CURRENT_DATE - (p_dias || ' days')::INTERVAL
               AND estado_pedido IN ('pagado', 'enviado', 'completado')),
            NULL
        ),
        (SELECT MAX(DATE(fecha_pedido)) - (p_dias || ' days')::INTERVAL FROM pedidos)
    ) INTO fecha_inicio;
    RETURN QUERY
    SELECT
        DATE(p.fecha_pedido) AS fecha,
        COALESCE(SUM(p.total_pedido), 0) AS total_ventas,
        COUNT(p.pedido_id) AS numero_pedidos
    FROM pedidos p
    WHERE p.fecha_pedido >= fecha_inicio
        AND p.estado_pedido IN ('pagado', 'enviado', 'completado')
    GROUP BY DATE(p.fecha_pedido)
    ORDER BY fecha ASC;
END;
$$ LANGUAGE plpgsql;
CREATE OR REPLACE FUNCTION fn_ventas_por_categoria(p_limite INT DEFAULT 10)
RETURNS TABLE(
    categoria_id INT,
    nombre_categoria VARCHAR(100),
    total_ventas NUMERIC(12,2),
    cantidad_productos_vendidos BIGINT,
    numero_pedidos BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        c.categoria_id,
        c.nombre_categoria,
        COALESCE(SUM(dp.cantidad * dp.precio_unitario_compra), 0) AS total_ventas,
        COALESCE(SUM(dp.cantidad), 0) AS cantidad_productos_vendidos,
        COUNT(DISTINCT ped.pedido_id) AS numero_pedidos
    FROM categorias c
    LEFT JOIN productos p ON c.categoria_id = p.categoria_id
    LEFT JOIN stock s ON p.producto_id = s.producto_id
    LEFT JOIN detalle_pedido dp ON s.stock_id = dp.stock_id
    LEFT JOIN pedidos ped ON dp.pedido_id = ped.pedido_id
        AND ped.estado_pedido IN ('pagado', 'enviado', 'completado')
    WHERE c.estado = 'activo'
    GROUP BY c.categoria_id, c.nombre_categoria
    ORDER BY total_ventas DESC
    LIMIT p_limite;
END;
$$ LANGUAGE plpgsql;
CREATE OR REPLACE FUNCTION fn_tendencia_pedidos(p_dias INT DEFAULT 30)
RETURNS TABLE(
    fecha DATE,
    total_pedidos BIGINT,
    pedidos_completados BIGINT,
    pedidos_cancelados BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        DATE(p.fecha_pedido) AS fecha,
        COUNT(p.pedido_id) AS total_pedidos,
        COUNT(CASE WHEN p.estado_pedido = 'completado' THEN 1 END) AS pedidos_completados,
        COUNT(CASE WHEN p.estado_pedido = 'cancelado' THEN 1 END) AS pedidos_cancelados
    FROM pedidos p
    WHERE p.fecha_pedido >= CURRENT_DATE - (p_dias || ' days')::INTERVAL
    GROUP BY DATE(p.fecha_pedido)
    ORDER BY fecha ASC;
END;
$$ LANGUAGE plpgsql;
CREATE OR REPLACE FUNCTION fn_distribucion_estados_pedidos()
RETURNS TABLE(
    estado_pedido VARCHAR(50),
    cantidad BIGINT,
    porcentaje NUMERIC(5,2)
) AS $$
BEGIN
    RETURN QUERY
    WITH totales AS (
        SELECT COUNT(*)::NUMERIC AS total_pedidos
        FROM pedidos
    )
    SELECT
        p.estado_pedido::VARCHAR(50),
        COUNT(p.pedido_id) AS cantidad,
        ROUND((COUNT(p.pedido_id)::NUMERIC / t.total_pedidos * 100), 2) AS porcentaje
    FROM pedidos p
    CROSS JOIN totales t
    GROUP BY p.estado_pedido, t.total_pedidos
    ORDER BY cantidad DESC;
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
    AND p.proname IN ('fn_ventas_diarias', 'fn_ventas_por_categoria', 'fn_tendencia_pedidos', 'fn_distribucion_estados_pedidos');
    RAISE NOTICE 'Total de funciones para gráficos creadas: %', func_count;
END $$;
COMMENT ON FUNCTION fn_ventas_diarias IS 'Retorna ventas diarias de los últimos N días para gráfico de líneas';
COMMENT ON FUNCTION fn_ventas_por_categoria IS 'Retorna ventas totales por categoría para gráfico de barras';
COMMENT ON FUNCTION fn_tendencia_pedidos IS 'Retorna tendencia de pedidos por día para análisis de volumen';
COMMENT ON FUNCTION fn_distribucion_estados_pedidos IS 'Retorna distribución porcentual de estados de pedidos para gráfico circular';
SELECT * FROM fn_ventas_diarias(7);
SELECT * FROM fn_ventas_por_categoria(5);
SELECT * FROM fn_tendencia_pedidos(30);
SELECT * FROM fn_distribucion_estados_pedidos();