-- =========================================
-- MEJORAS FASE 1: ÍNDICES DE RENDIMIENTO
-- =========================================

-- Índices para filtrado por estado
CREATE INDEX IF NOT EXISTS idx_pedidos_estado ON pedidos(estado_pedido);
CREATE INDEX IF NOT EXISTS idx_stock_estado ON stock(estado);

-- Índices para filtrado por fecha
CREATE INDEX IF NOT EXISTS idx_pedidos_fecha ON pedidos(fecha_pedido);

-- Índices para relaciones frecuentes
CREATE INDEX IF NOT EXISTS idx_detalle_pedido_stock ON detalle_pedido(stock_id);
CREATE INDEX IF NOT EXISTS idx_stock_sku ON stock(sku);
CREATE INDEX IF NOT EXISTS idx_cupones_codigo ON cupones(codigo_cupon);
CREATE INDEX IF NOT EXISTS idx_direcciones_cliente ON direcciones(cliente_id);
CREATE INDEX IF NOT EXISTS idx_envios_pedido ON envios(pedido_id);
CREATE INDEX IF NOT EXISTS idx_devoluciones_detalle ON devoluciones(detalle_id);

-- Índices compuestos para queries complejas
CREATE INDEX IF NOT EXISTS idx_pedidos_cliente_estado ON pedidos(cliente_id, estado_pedido);
CREATE INDEX IF NOT EXISTS idx_stock_producto_estado ON stock(producto_id, estado);

-- Verificación
DO $$
DECLARE
    idx_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO idx_count
    FROM pg_indexes
    WHERE schemaname = 'public'
    AND indexname LIKE 'idx_%';
    
    RAISE NOTICE 'Total de índices creados: %', idx_count;
END $$;

-- =========================================
-- MEJORAS FASE 1: VISTAS MATERIALIZADAS
-- =========================================

-- Vista: Productos más vendidos
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

-- Vista: Clientes VIP
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

-- Verificación
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

-- =========================================
-- MEJORAS FASE 1: AUDITORÍA AVANZADA
-- =========================================

-- Tabla de auditoría
CREATE TABLE IF NOT EXISTS auditoria (
    auditoria_id SERIAL PRIMARY KEY,
    tabla VARCHAR(100) NOT NULL,
    operacion VARCHAR(10) NOT NULL CHECK (operacion IN ('INSERT', 'UPDATE', 'DELETE')),
    registro_id INT NOT NULL,
    usuario VARCHAR(100),
    fecha TIMESTAMP NOT NULL DEFAULT NOW(),
    datos_anteriores JSONB,
    datos_nuevos JSONB,
    ip_address VARCHAR(45)
);

CREATE INDEX IF NOT EXISTS idx_auditoria_tabla ON auditoria(tabla);
CREATE INDEX IF NOT EXISTS idx_auditoria_registro ON auditoria(registro_id);
CREATE INDEX IF NOT EXISTS idx_auditoria_fecha ON auditoria(fecha);
CREATE INDEX IF NOT EXISTS idx_auditoria_usuario ON auditoria(usuario);

-- Función de auditoría para productos
CREATE OR REPLACE FUNCTION fn_auditoria_productos()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        INSERT INTO auditoria (tabla, operacion, registro_id, usuario, datos_anteriores, datos_nuevos)
        VALUES ('productos', 'UPDATE', NEW.producto_id, current_user, row_to_json(OLD)::JSONB, row_to_json(NEW)::JSONB);
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO auditoria (tabla, operacion, registro_id, usuario, datos_anteriores)
        VALUES ('productos', 'DELETE', OLD.producto_id, current_user, row_to_json(OLD)::JSONB);
        RETURN OLD;
    ELSIF TG_OP = 'INSERT' THEN
        INSERT INTO auditoria (tabla, operacion, registro_id, usuario, datos_nuevos)
        VALUES ('productos', 'INSERT', NEW.producto_id, current_user, row_to_json(NEW)::JSONB);
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Función de auditoría para clientes
CREATE OR REPLACE FUNCTION fn_auditoria_clientes()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        INSERT INTO auditoria (tabla, operacion, registro_id, usuario, datos_anteriores, datos_nuevos)
        VALUES ('clientes', 'UPDATE', NEW.cliente_id, current_user, row_to_json(OLD)::JSONB, row_to_json(NEW)::JSONB);
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO auditoria (tabla, operacion, registro_id, usuario, datos_anteriores)
        VALUES ('clientes', 'DELETE', OLD.cliente_id, current_user, row_to_json(OLD)::JSONB);
        RETURN OLD;
    ELSIF TG_OP = 'INSERT' THEN
        INSERT INTO auditoria (tabla, operacion, registro_id, usuario, datos_nuevos)
        VALUES ('clientes', 'INSERT', NEW.cliente_id, current_user, row_to_json(NEW)::JSONB);
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Función de auditoría para stock
CREATE OR REPLACE FUNCTION fn_auditoria_stock()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        INSERT INTO auditoria (tabla, operacion, registro_id, usuario, datos_anteriores, datos_nuevos)
        VALUES ('stock', 'UPDATE', NEW.stock_id, current_user, row_to_json(OLD)::JSONB, row_to_json(NEW)::JSONB);
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO auditoria (tabla, operacion, registro_id, usuario, datos_anteriores)
        VALUES ('stock', 'DELETE', OLD.stock_id, current_user, row_to_json(OLD)::JSONB);
        RETURN OLD;
    ELSIF TG_OP = 'INSERT' THEN
        INSERT INTO auditoria (tabla, operacion, registro_id, usuario, datos_nuevos)
        VALUES ('stock', 'INSERT', NEW.stock_id, current_user, row_to_json(NEW)::JSONB);
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Función de auditoría para pedidos
CREATE OR REPLACE FUNCTION fn_auditoria_pedidos()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        INSERT INTO auditoria (tabla, operacion, registro_id, usuario, datos_anteriores, datos_nuevos)
        VALUES ('pedidos', 'UPDATE', NEW.pedido_id, current_user, row_to_json(OLD)::JSONB, row_to_json(NEW)::JSONB);
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO auditoria (tabla, operacion, registro_id, usuario, datos_anteriores)
        VALUES ('pedidos', 'DELETE', OLD.pedido_id, current_user, row_to_json(OLD)::JSONB);
        RETURN OLD;
    ELSIF TG_OP = 'INSERT' THEN
        INSERT INTO auditoria (tabla, operacion, registro_id, usuario, datos_nuevos)
        VALUES ('pedidos', 'INSERT', NEW.pedido_id, current_user, row_to_json(NEW)::JSONB);
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Función de auditoría para pagos
CREATE OR REPLACE FUNCTION fn_auditoria_pagos()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        INSERT INTO auditoria (tabla, operacion, registro_id, usuario, datos_anteriores, datos_nuevos)
        VALUES ('pagos', 'UPDATE', NEW.pago_id, current_user, row_to_json(OLD)::JSONB, row_to_json(NEW)::JSONB);
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO auditoria (tabla, operacion, registro_id, usuario, datos_anteriores)
        VALUES ('pagos', 'DELETE', OLD.pago_id, current_user, row_to_json(OLD)::JSONB);
        RETURN OLD;
    ELSIF TG_OP = 'INSERT' THEN
        INSERT INTO auditoria (tabla, operacion, registro_id, usuario, datos_nuevos)
        VALUES ('pagos', 'INSERT', NEW.pago_id, current_user, row_to_json(NEW)::JSONB);
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Función de auditoría para cupones
CREATE OR REPLACE FUNCTION fn_auditoria_cupones()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        INSERT INTO auditoria (tabla, operacion, registro_id, usuario, datos_anteriores, datos_nuevos)
        VALUES ('cupones', 'UPDATE', NEW.cupon_id, current_user, row_to_json(OLD)::JSONB, row_to_json(NEW)::JSONB);
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO auditoria (tabla, operacion, registro_id, usuario, datos_anteriores)
        VALUES ('cupones', 'DELETE', OLD.cupon_id, current_user, row_to_json(OLD)::JSONB);
        RETURN OLD;
    ELSIF TG_OP = 'INSERT' THEN
        INSERT INTO auditoria (tabla, operacion, registro_id, usuario, datos_nuevos)
        VALUES ('cupones', 'INSERT', NEW.cupon_id, current_user, row_to_json(NEW)::JSONB);
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Función de auditoría para categorias
CREATE OR REPLACE FUNCTION fn_auditoria_categorias()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        INSERT INTO auditoria (tabla, operacion, registro_id, usuario, datos_anteriores, datos_nuevos)
        VALUES ('categorias', 'UPDATE', NEW.categoria_id, current_user, row_to_json(OLD)::JSONB, row_to_json(NEW)::JSONB);
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO auditoria (tabla, operacion, registro_id, usuario, datos_anteriores)
        VALUES ('categorias', 'DELETE', OLD.categoria_id, current_user, row_to_json(OLD)::JSONB);
        RETURN OLD;
    ELSIF TG_OP = 'INSERT' THEN
        INSERT INTO auditoria (tabla, operacion, registro_id, usuario, datos_nuevos)
        VALUES ('categorias', 'INSERT', NEW.categoria_id, current_user, row_to_json(NEW)::JSONB);
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Triggers de auditoría en tablas críticas
DROP TRIGGER IF EXISTS trg_auditoria_productos ON productos;
CREATE TRIGGER trg_auditoria_productos
AFTER INSERT OR UPDATE OR DELETE ON productos
FOR EACH ROW EXECUTE FUNCTION fn_auditoria_productos();

DROP TRIGGER IF EXISTS trg_auditoria_clientes ON clientes;
CREATE TRIGGER trg_auditoria_clientes
AFTER INSERT OR UPDATE OR DELETE ON clientes
FOR EACH ROW EXECUTE FUNCTION fn_auditoria_clientes();

DROP TRIGGER IF EXISTS trg_auditoria_stock ON stock;
CREATE TRIGGER trg_auditoria_stock
AFTER INSERT OR UPDATE OR DELETE ON stock
FOR EACH ROW EXECUTE FUNCTION fn_auditoria_stock();

DROP TRIGGER IF EXISTS trg_auditoria_pedidos ON pedidos;
CREATE TRIGGER trg_auditoria_pedidos
AFTER INSERT OR UPDATE OR DELETE ON pedidos
FOR EACH ROW EXECUTE FUNCTION fn_auditoria_pedidos();

DROP TRIGGER IF EXISTS trg_auditoria_pagos ON pagos;
CREATE TRIGGER trg_auditoria_pagos
AFTER INSERT OR UPDATE OR DELETE ON pagos
FOR EACH ROW EXECUTE FUNCTION fn_auditoria_pagos();

DROP TRIGGER IF EXISTS trg_auditoria_cupones ON cupones;
CREATE TRIGGER trg_auditoria_cupones
AFTER INSERT OR UPDATE OR DELETE ON cupones
FOR EACH ROW EXECUTE FUNCTION fn_auditoria_cupones();

DROP TRIGGER IF EXISTS trg_auditoria_categorias ON categorias;
CREATE TRIGGER trg_auditoria_categorias
AFTER INSERT OR UPDATE OR DELETE ON categorias
FOR EACH ROW EXECUTE FUNCTION fn_auditoria_categorias();

-- Verificación
DO $$
DECLARE
    trigger_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO trigger_count
    FROM pg_trigger
    WHERE tgname LIKE 'trg_auditoria_%';
    
    RAISE NOTICE 'Total de triggers de auditoría: %', trigger_count;
END $$;


-- =========================================
-- MEJORAS FASE 1: FUNCIONES DE UTILIDAD
-- =========================================

-- Función: Alerta de stock bajo
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

-- Función: Calcular métricas de producto
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

-- Función: Historial de cambios de un registro
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

-- Verificación
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


-- Verificar que todo se instaló correctamente
SELECT 
    'Índices' AS componente,
    COUNT(*)::TEXT AS cantidad
FROM pg_indexes
WHERE schemaname = 'public'
AND indexname LIKE 'idx_%'

UNION ALL

SELECT 
    'Vistas Materializadas',
    COUNT(*)::TEXT
FROM pg_matviews
WHERE schemaname = 'public'

UNION ALL

SELECT 
    'Triggers de Auditoría',
    COUNT(*)::TEXT
FROM pg_trigger
WHERE tgname LIKE 'trg_auditoria_%'

UNION ALL

SELECT 
    'Funciones de Utilidad',
    COUNT(*)::TEXT
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
AND p.proname IN ('fn_alerta_stock_bajo', 'fn_estadisticas_dashboard', 'fn_metricas_producto', 'fn_historial_cambios');

-- Probar vista de productos top
SELECT * FROM mv_productos_top_ventas LIMIT 5;

-- Probar vista de clientes VIP
SELECT * FROM mv_clientes_vip LIMIT 5;

-- Probar función de alertas (puede estar vacía si tienes stock suficiente)
SELECT * FROM fn_alerta_stock_bajo(10);

-- Probar dashboard
SELECT * FROM fn_estadisticas_dashboard();

-- Verificar que la auditoría funciona
UPDATE productos SET nombre_producto = nombre_producto WHERE producto_id = 1;
SELECT * FROM auditoria ORDER BY fecha DESC LIMIT 1;



-- Verificación completa de Fase 1
SELECT 
    'Índices' as componente,
    COUNT(*) as cantidad
FROM pg_indexes 
WHERE schemaname = 'public' 
AND indexname LIKE 'idx_%'

UNION ALL

SELECT 
    'Vistas Materializadas',
    COUNT(*)
FROM pg_matviews 
WHERE schemaname = 'public'

UNION ALL

SELECT 
    'Triggers de Auditoría',
    COUNT(*)
FROM pg_trigger t
JOIN pg_class c ON t.tgrelid = c.oid
WHERE t.tgname LIKE 'trg_auditoria_%'

UNION ALL

SELECT 
    'Funciones de Utilidad',
    COUNT(*)
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public' 
AND p.proname IN ('fn_alerta_stock_bajo', 'fn_estadisticas_dashboard', 'fn_metricas_producto', 'fn_historial_cambios')

UNION ALL

SELECT 
    'Tabla Auditoría',
    COUNT(*)
FROM information_schema.tables
WHERE table_schema = 'public' 
AND table_name = 'auditoria';

-- =========================================
-- PRUEBAS FUNCIONALES - FASE 1
-- =========================================

-- ===================
-- 1. PRUEBA: AUDITORÍA
-- ===================
-- Actualizar un producto para generar registro de auditoría
UPDATE productos 
SET nombre_producto = nombre_producto 
WHERE producto_id = 1 AND estado = 'activo';

-- Ver el registro de auditoría generado
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

-- ===================
-- 2. PRUEBA: ALERTA DE STOCK BAJO
-- ===================
-- Ver productos con stock bajo
SELECT * FROM fn_alerta_stock_bajo();

-- ===================
-- 3. PRUEBA: VISTAS MATERIALIZADAS
-- ===================
-- Ver productos más vendidos
SELECT 
    producto_id,
    nombre_producto,
    total_vendido,
    ingresos_totales
FROM mv_productos_top_ventas
ORDER BY ingresos_totales DESC
LIMIT 10;

-- Ver clientes VIP
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

-- ===================
-- 4. PRUEBA: ESTADÍSTICAS DEL DASHBOARD
-- ===================
SELECT * FROM fn_estadisticas_dashboard();

-- ===================
-- 5. PRUEBA: MÉTRICAS DE PRODUCTO
-- ===================
-- Obtener métricas del producto #1
SELECT * FROM fn_metricas_producto(1);

-- ===================
-- 6. PRUEBA: HISTORIAL DE CAMBIOS
-- ===================
-- Ver últimos 10 cambios en la tabla productos
SELECT * FROM fn_historial_cambios('productos', 10);

-- ===================
-- 7. PRUEBA: RENDIMIENTO DE ÍNDICES
-- ===================
-- Consulta que debe usar índice idx_pedidos_cliente_estado
EXPLAIN ANALYZE
SELECT p.pedido_id, p.fecha_pedido, p.total_pedido
FROM pedidos p
WHERE p.cliente_id = 1 
AND p.estado_pedido = 'completado';

-- Consulta que debe usar índice idx_productos_categoria_precio
EXPLAIN ANALYZE
SELECT producto_id, nombre_producto
FROM productos
WHERE categoria_id = 1 
AND estado = 'activo';

-- Consulta que debe usar índice idx_stock_producto_estado
EXPLAIN ANALYZE
SELECT s.stock_id, s.cantidad_en_stock, p.nombre_producto
FROM stock s
JOIN productos p ON s.producto_id = p.producto_id
WHERE s.producto_id = 1 
AND s.estado = 'activo';

-- ===================
-- 8. PRUEBA: REFRESH VISTAS MATERIALIZADAS
-- ===================
-- Refrescar vistas (hacer después de cambios en datos)
REFRESH MATERIALIZED VIEW CONCURRENTLY mv_productos_top_ventas;
REFRESH MATERIALIZED VIEW CONCURRENTLY mv_clientes_vip;

-- Verificar última actualización
SELECT 
    schemaname,
    matviewname,
    ispopulated
FROM pg_matviews
WHERE schemaname = 'public' 
AND matviewname IN ('mv_productos_top_ventas', 'mv_clientes_vip');

-- ===================
-- 9. PRUEBA: AUDITORÍA MÚLTIPLE
-- ===================
-- Hacer varias operaciones y verificar auditoría completa
BEGIN;

-- Insertar nuevo cupón
INSERT INTO cupones (codigo_cupon, tipo_descuento, valor_descuento, fecha_expiracion, usos_disponibles)
VALUES ('TEST2024', 'porcentaje', 15.00, NOW() + INTERVAL '30 days', 100);

-- Actualizar cliente
UPDATE clientes 
SET nombre = nombre
WHERE cliente_id = 1 AND estado = 'activo';

-- Actualizar stock
UPDATE stock
SET cantidad_en_stock = cantidad_en_stock
WHERE stock_id = 1 AND estado = 'activo';

COMMIT;

-- Ver todos los registros de auditoría generados
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

-- ===================
-- 10. RESUMEN DE PRUEBAS
-- ===================
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

-- Ver cuántos clientes califican para VIP
SELECT 
    COUNT(*) as clientes_que_califican
FROM clientes c
JOIN pedidos p ON c.cliente_id = p.cliente_id
WHERE p.estado_pedido IN ('pagado', 'enviado', 'completado')
    AND c.estado = 'activo'
GROUP BY c.cliente_id, c.nombre, c.apellido, c.email
HAVING COUNT(p.pedido_id) >= 3 OR SUM(p.total_pedido) >= 500;

REFRESH MATERIALIZED VIEW mv_clientes_vip;