CREATE INDEX IF NOT EXISTS idx_pedidos_estado ON pedidos(estado_pedido);
CREATE INDEX IF NOT EXISTS idx_stock_estado ON stock(estado);
CREATE INDEX IF NOT EXISTS idx_pedidos_fecha ON pedidos(fecha_pedido);
CREATE INDEX IF NOT EXISTS idx_detalle_pedido_stock ON detalle_pedido(stock_id);
CREATE INDEX IF NOT EXISTS idx_stock_sku ON stock(sku);
CREATE INDEX IF NOT EXISTS idx_cupones_codigo ON cupones(codigo_cupon);
CREATE INDEX IF NOT EXISTS idx_direcciones_cliente ON direcciones(cliente_id);
CREATE INDEX IF NOT EXISTS idx_envios_pedido ON envios(pedido_id);
CREATE INDEX IF NOT EXISTS idx_devoluciones_detalle ON devoluciones(detalle_id);
CREATE INDEX IF NOT EXISTS idx_pedidos_cliente_estado ON pedidos(cliente_id, estado_pedido);
CREATE INDEX IF NOT EXISTS idx_stock_producto_estado ON stock(producto_id, estado);
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