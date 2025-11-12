/* =========================================
 * BASE DE DATOS E-COMMERCE - POSTGRESQL
 * =========================================
 * Sistema completo de comercio electrónico con:
 * - Gestión de productos y categorías
 * - Carritos y pedidos
 * - Pagos y envíos
 * - Sistema de devoluciones
 * - Auditoría automática
 * - Soft delete en todas las tablas
 * =========================================
 */

/* * =========================================
 * 1. FUNCIÓN DE AUDITORÍA (Trigger)
 * =========================================
 * Esta función actualizará la columna 'fecha_modificacion'
 * a la hora actual CADA VEZ que se haga un UPDATE en una fila.
 */
CREATE OR REPLACE FUNCTION fn_actualizar_fecha_modificacion()
RETURNS TRIGGER AS $$
BEGIN
    -- Comprueba si la fila realmente cambió
    IF (OLD IS DISTINCT FROM NEW) THEN
        NEW.fecha_modificacion = NOW();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;



/* * =========================================
 * 2. TABLAS MAESTRAS (Sin dependencias)
 * =========================================
 */

-- Tabla de Categorías de Productos
CREATE TABLE categorias (
    categoria_id SERIAL PRIMARY KEY,
    nombre_categoria VARCHAR(100) NOT NULL UNIQUE,
    descripcion TEXT,
    -- Auditoría y Soft Delete
    estado VARCHAR(20) NOT NULL DEFAULT 'activo' CHECK (estado IN ('activo', 'inactivo')),
    fecha_creacion TIMESTAMP NOT NULL DEFAULT NOW(),
    fecha_modificacion TIMESTAMP
);

-- Tabla de Clientes
CREATE TABLE clientes (
    cliente_id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    hash_contrasena VARCHAR(255) NOT NULL,
    -- Auditoría y Soft Delete
    estado VARCHAR(20) NOT NULL DEFAULT 'activo' CHECK (estado IN ('activo', 'inactivo', 'suspendido')),
    fecha_creacion TIMESTAMP NOT NULL DEFAULT NOW(),
    fecha_modificacion TIMESTAMP
);

-- Tabla de Cupones de Descuento
CREATE TABLE cupones (
    cupon_id SERIAL PRIMARY KEY,
    codigo_cupon VARCHAR(50) NOT NULL UNIQUE,
    tipo_descuento VARCHAR(20) NOT NULL CHECK (tipo_descuento IN ('porcentaje', 'fijo')),
    valor_descuento NUMERIC(10, 2) NOT NULL CHECK (valor_descuento > 0),
    fecha_expiracion DATE,
    usos_disponibles INT CHECK (usos_disponibles >= 0),
    -- Auditoría y Soft Delete
    estado VARCHAR(20) NOT NULL DEFAULT 'activo' CHECK (estado IN ('activo', 'inactivo', 'expirado')),
    fecha_creacion TIMESTAMP NOT NULL DEFAULT NOW(),
    fecha_modificacion TIMESTAMP
);

/* * =========================================
 * 3. TABLAS DE PRODUCTOS E INVENTARIO
 * =========================================
 */

-- Tabla de Productos (Plantilla)
CREATE TABLE productos (
    producto_id SERIAL PRIMARY KEY,
    categoria_id INT NOT NULL REFERENCES categorias(categoria_id),
    nombre_producto VARCHAR(255) NOT NULL,
    descripcion_larga TEXT,
    -- Auditoría y Soft Delete
    estado VARCHAR(20) NOT NULL DEFAULT 'activo' CHECK (estado IN ('activo', 'inactivo', 'descontinuado')),
    fecha_creacion TIMESTAMP NOT NULL DEFAULT NOW(),
    fecha_modificacion TIMESTAMP
);

-- Tabla de Stock (Inventario real o Variantes/SKUs)
CREATE TABLE stock (
    stock_id SERIAL PRIMARY KEY,
    producto_id INT NOT NULL REFERENCES productos(producto_id),
    sku VARCHAR(100) NOT NULL UNIQUE, -- Stock Keeping Unit
    precio_unitario NUMERIC(10, 2) NOT NULL CHECK (precio_unitario > 0),
    cantidad_en_stock INT NOT NULL DEFAULT 0 CHECK (cantidad_en_stock >= 0),
    cantidad_reservada INT NOT NULL DEFAULT 0 CHECK (cantidad_reservada >= 0),
    -- Auditoría y Soft Delete
    estado VARCHAR(20) NOT NULL DEFAULT 'activo' CHECK (estado IN ('activo', 'inactivo')),
    fecha_creacion TIMESTAMP NOT NULL DEFAULT NOW(),
    fecha_modificacion TIMESTAMP,
    -- Restricción de negocio: Nunca reservar más de lo que hay
    CONSTRAINT chk_reserva_stock CHECK (cantidad_reservada <= cantidad_en_stock)
);

/* * =========================================
 * 4. TABLAS DE CLIENTE (Dependientes)
 * =========================================
 */

-- Tabla de Direcciones (Un cliente puede tener N direcciones)
CREATE TABLE direcciones (
    direccion_id SERIAL PRIMARY KEY,
    cliente_id INT NOT NULL REFERENCES clientes(cliente_id) ON DELETE CASCADE,
    direccion_linea_1 VARCHAR(255) NOT NULL,
    ciudad VARCHAR(100) NOT NULL,
    codigo_postal VARCHAR(20) NOT NULL,
    pais VARCHAR(50) NOT NULL,
    -- Auditoría y Soft Delete
    estado VARCHAR(20) NOT NULL DEFAULT 'activo' CHECK (estado IN ('activo', 'inactivo')),
    fecha_creacion TIMESTAMP NOT NULL DEFAULT NOW(),
    fecha_modificacion TIMESTAMP
);

/* * =========================================
 * 5. TABLAS TRANSACCIONALES (Núcleo E-commerce)
 * =========================================
 */

-- Tabla de Pedidos (La orden principal)
CREATE TABLE pedidos (
    pedido_id SERIAL PRIMARY KEY,
    cliente_id INT NOT NULL REFERENCES clientes(cliente_id),
    direccion_envio_id INT NOT NULL REFERENCES direcciones(direccion_id),
    cupon_id INT REFERENCES cupones(cupon_id), -- Puede ser nulo
    fecha_pedido TIMESTAMP NOT NULL DEFAULT NOW(),
    estado_pedido VARCHAR(50) NOT NULL DEFAULT 'pendiente' CHECK (estado_pedido IN ('pendiente', 'pagado', 'enviado', 'cancelado', 'completado')),
    subtotal NUMERIC(12, 2) NOT NULL CHECK (subtotal >= 0),
    descuento_aplicado NUMERIC(12, 2) NOT NULL DEFAULT 0,
    impuestos NUMERIC(12, 2) NOT NULL DEFAULT 0,
    total_pedido NUMERIC(12, 2) NOT NULL CHECK (total_pedido >= 0),
    -- Auditoría
    fecha_modificacion TIMESTAMP
);

-- Tabla de Detalle del Pedido (Líneas de la factura)
CREATE TABLE detalle_pedido (
    detalle_id SERIAL PRIMARY KEY,
    pedido_id INT NOT NULL REFERENCES pedidos(pedido_id) ON DELETE CASCADE,
    stock_id INT NOT NULL REFERENCES stock(stock_id),
    cantidad INT NOT NULL CHECK (cantidad > 0),
    precio_unitario_compra NUMERIC(10, 2) NOT NULL, -- Congela el precio al momento de la compra
    -- Auditoría (Simple, esta tabla no se modifica, se crea)
    fecha_creacion TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Tabla de Pagos (Un pedido puede tener N intentos de pago)
CREATE TABLE pagos (
    pago_id SERIAL PRIMARY KEY,
    pedido_id INT NOT NULL REFERENCES pedidos(pedido_id),
    fecha_pago TIMESTAMP NOT NULL DEFAULT NOW(),
    monto NUMERIC(12, 2) NOT NULL CHECK (monto > 0),
    metodo_pago VARCHAR(50),
    estado_pago VARCHAR(20) NOT NULL CHECK (estado_pago IN ('exitoso', 'fallido', 'pendiente', 'reembolsado')),
    id_transaccion_externa VARCHAR(255), -- ID de Stripe, PayPal, etc.
    -- Auditoría
    fecha_modificacion TIMESTAMP
);

-- Tabla de Envíos
CREATE TABLE envios (
    envio_id SERIAL PRIMARY KEY,
    pedido_id INT NOT NULL REFERENCES pedidos(pedido_id),
    fecha_envio TIMESTAMP,
    transportista VARCHAR(100),
    numero_tracking VARCHAR(100),
    estado_envio VARCHAR(50) NOT NULL DEFAULT 'en_preparacion' CHECK (estado_envio IN ('en_preparacion', 'en_transito', 'entregado', 'fallido')),
    -- Auditoría
    fecha_creacion TIMESTAMP NOT NULL DEFAULT NOW(),
    fecha_modificacion TIMESTAMP
);

-- Tabla de Devoluciones (Logística inversa)
CREATE TABLE devoluciones (
    devolucion_id SERIAL PRIMARY KEY,
    detalle_id INT NOT NULL UNIQUE REFERENCES detalle_pedido(detalle_id), -- Solo 1 devolución por línea de pedido
    motivo TEXT,
    cantidad_devuelta INT NOT NULL CHECK (cantidad_devuelta > 0),
    fecha_solicitud TIMESTAMP NOT NULL DEFAULT NOW(),
    estado_devolucion VARCHAR(50) NOT NULL DEFAULT 'solicitada' CHECK (estado_devolucion IN ('solicitada', 'aprobada', 'recibida', 'reembolsada', 'rechazada')),
    -- Auditoría
    fecha_modificacion TIMESTAMP
);


/* * =========================================
 * 6. ÍNDICES (Performance)
 * =========================================
 */
 
-- Para buscar productos por nombre
CREATE INDEX idx_productos_nombre ON productos(nombre_producto);

-- Para buscar productos en stock por su ID de producto (muy común)
CREATE INDEX idx_stock_producto_id ON stock(producto_id);

-- Para buscar pedidos de un cliente
CREATE INDEX idx_pedidos_cliente_id ON pedidos(cliente_id);

-- Para buscar detalles de un pedido
CREATE INDEX idx_detalle_pedido_pedido_id ON detalle_pedido(pedido_id);

-- Para buscar pagos de un pedido
CREATE INDEX idx_pagos_pedido_id ON pagos(pedido_id);

-- Para buscar envíos por tracking o estado
CREATE INDEX idx_envios_numero_tracking ON envios(numero_tracking);
CREATE INDEX idx_envios_estado ON envios(estado_envio);

-- Para buscar pagos por ID externo
CREATE INDEX idx_pagos_id_transaccion_externa ON pagos(id_transaccion_externa);



/* * =========================================
 * 7. ACTIVACIÓN DE TRIGGERS (Auditoría)
 * =========================================
 */

CREATE TRIGGER trg_categorias_modificacion
BEFORE UPDATE ON categorias
FOR EACH ROW
EXECUTE FUNCTION fn_actualizar_fecha_modificacion();

CREATE TRIGGER trg_clientes_modificacion
BEFORE UPDATE ON clientes
FOR EACH ROW
EXECUTE FUNCTION fn_actualizar_fecha_modificacion();

CREATE TRIGGER trg_cupones_modificacion
BEFORE UPDATE ON cupones
FOR EACH ROW
EXECUTE FUNCTION fn_actualizar_fecha_modificacion();

CREATE TRIGGER trg_productos_modificacion
BEFORE UPDATE ON productos
FOR EACH ROW
EXECUTE FUNCTION fn_actualizar_fecha_modificacion();

CREATE TRIGGER trg_stock_modificacion
BEFORE UPDATE ON stock
FOR EACH ROW
EXECUTE FUNCTION fn_actualizar_fecha_modificacion();

CREATE TRIGGER trg_direcciones_modificacion
BEFORE UPDATE ON direcciones
FOR EACH ROW
EXECUTE FUNCTION fn_actualizar_fecha_modificacion();

CREATE TRIGGER trg_pedidos_modificacion
BEFORE UPDATE ON pedidos
FOR EACH ROW
EXECUTE FUNCTION fn_actualizar_fecha_modificacion();

CREATE TRIGGER trg_pagos_modificacion
BEFORE UPDATE ON pagos
FOR EACH ROW
EXECUTE FUNCTION fn_actualizar_fecha_modificacion();

CREATE TRIGGER trg_envios_modificacion
BEFORE UPDATE ON envios
FOR EACH ROW
EXECUTE FUNCTION fn_actualizar_fecha_modificacion();

CREATE TRIGGER trg_devoluciones_modificacion
BEFORE UPDATE ON devoluciones
FOR EACH ROW
EXECUTE FUNCTION fn_actualizar_fecha_modificacion();
