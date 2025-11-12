/* =========================================
 * DATOS DE PRUEBA - E-COMMERCE
 * =========================================
 * Este script contiene datos de ejemplo para probar
 * todas las funcionalidades del sistema.
 * =========================================
 */

/* * =========================================
 * 1. TABLAS MAESTRAS (Sin dependencias)
 * =========================================
 */

-- Insertar 5 Categorías
INSERT INTO categorias (nombre_categoria, descripcion) VALUES
('Electrónica', 'Dispositivos y gadgets tecnológicos.'),
('Ropa', 'Prendas de vestir para todas las edades.'),
('Hogar y Cocina', 'Artículos para el hogar, decoración y utensilios de cocina.'),
('Libros', 'Libros físicos y digitales de diversos géneros.'),
('Deportes', 'Equipamiento, ropa y accesorios deportivos.');

-- Insertar 10 Clientes
-- La contraseña es un HASH BCRYPT de "password123" (es solo un placeholder)
INSERT INTO clientes (nombre, apellido, email, hash_contrasena) VALUES
('Ana', 'García', 'ana.garcia@email.com', '$2b$12$E/Vxk.S.G.a0b5C1.XY.a.CqY.qS.aG/a0b5C1.XY.a.CqY.qS'),
('Bruno', 'Martínez', 'bruno.martinez@email.com', '$2b$12$E/Vxk.S.G.a0b5C1.XY.a.CqY.qS.aG/a0b5C1.XY.a.CqY.qS'),
('Carla', 'Rodríguez', 'carla.rodriguez@email.com', '$2b$12$E/Vxk.S.G.a0b5C1.XY.a.CqY.qS.aG/a0b5C1.XY.a.CqY.qS'),
('David', 'López', 'david.lopez@email.com', '$2b$12$E/Vxk.S.G.a0b5C1.XY.a.CqY.qS.aG/a0b5C1.XY.a.CqY.qS'),
('Elena', 'Sánchez', 'elena.sanchez@email.com', '$2b$12$E/Vxk.S.G.a0b5C1.XY.a.CqY.qS.aG/a0b5C1.XY.a.CqY.qS'),
('Felipe', 'Gómez', 'felipe.gomez@email.com', '$2b$12$E/Vxk.S.G.a0b5C1.XY.a.CqY.qS.aG/a0b5C1.XY.a.CqY.qS'),
('Gabriela', 'Pérez', 'gabi.perez@email.com', '$2b$12$E/Vxk.S.G.a0b5C1.XY.a.CqY.qS.aG/a0b5C1.XY.a.CqY.qS'),
('Hugo', 'Torres', 'hugo.torres@email.com', '$2b$12$E/Vxk.S.G.a0b5C1.XY.a.CqY.qS.aG/a0b5C1.XY.a.CqY.qS'),
('Inés', 'Ramírez', 'ines.ramirez@email.com', '$2b$12$E/Vxk.S.G.a0b5C1.XY.a.CqY.qS.aG/a0b5C1.XY.a.CqY.qS'),
('Juan', 'Díaz', 'juan.diaz@email.com', '$2b$12$E/Vxk.S.G.a0b5C1.XY.a.CqY.qS.aG/a0b5C1.XY.a.CqY.qS');

-- Insertar 4 Cupones
INSERT INTO cupones (codigo_cupon, tipo_descuento, valor_descuento, fecha_expiracion, usos_disponibles, estado) VALUES
('BIENVENIDO10', 'porcentaje', 10.00, '2026-12-31', 100, 'activo'),
('VERANO20', 'fijo', 20.00, '2026-09-30', 50, 'activo'),
('FLASH50', 'porcentaje', 50.00, '2026-06-15', 5, 'activo'),
('OLD_CUPON', 'fijo', 5.00, '2020-01-01', 0, 'expirado');

/* * =========================================
 * 2. TABLAS DE PRODUCTOS (Dependen de Categorías)
 * =========================================
 */

-- Insertar 10 Productos
INSERT INTO productos (categoria_id, nombre_producto, descripcion_larga) VALUES
(1, 'Laptop Pro 15"', 'Laptop de alto rendimiento con 16GB RAM y SSD 1TB.'),
(1, 'Smartphone X100', 'Teléfono inteligente con cámara de 108MP y pantalla OLED.'),
(1, 'Auriculares Inalámbricos TWS', 'Auriculares con cancelación de ruido activa.'),
(2, 'Camiseta de Algodón', 'Camiseta básica de algodón pima.'),
(2, 'Jeans Slim Fit', 'Pantalones vaqueros de corte moderno.'),
(3, 'Cafetera Espresso Automática', 'Prepara café profesional en casa.'),
(3, 'Sofá Cama 3 Plazas', 'Sofá convertible en cama, tela gris.'),
(4, 'El Nombre del Viento', 'Novela de fantasía épica.'),
(5, 'Balón de Fútbol Profesional', 'Balón tamaño 5, certificado por FIFA.'),
(5, 'Zapatillas de Running', 'Zapatillas ligeras para correr largas distancias.');

/* * =========================================
 * 3. TABLAS DE CLIENTE (Dependen de Clientes)
 * =========================================
 */
 
-- Insertar 13 Direcciones (Algunos clientes tienen varias)
INSERT INTO direcciones (cliente_id, direccion_linea_1, ciudad, codigo_postal, pais) VALUES
(1, 'Calle Falsa 123', 'Springfield', 'S1234', 'EEUU'), -- Ana (ID: 1)
(1, 'Avenida Siempreviva 742', 'Springfield', 'S5678', 'EEUU'), -- Ana (ID: 2)
(2, 'Plaza Mayor 1', 'Madrid', '28001', 'España'), -- Bruno (ID: 3)
(3, 'Boulevard de los Sueños Rotos 44', 'Lima', 'LIMA01', 'Perú'), -- Carla (ID: 4)
(4, 'Carrera 15 # 80-10', 'Bogotá', '110111', 'Colombia'), -- David (ID: 5)
(5, 'Av. Corrientes 1000', 'Buenos Aires', 'C1043', 'Argentina'), -- Elena (ID: 6)
(6, 'Rua Augusta 500', 'São Paulo', '01304-001', 'Brasil'), -- Felipe (ID: 7)
(7, 'Paseo de la Reforma 222', 'CDMX', '06600', 'México'), -- Gabriela (ID: 8)
(8, 'Merced 391', 'Santiago', '8320000', 'Chile'), -- Hugo (ID: 9)
(9, 'Jr. de la Unión 899', 'Lima', 'LIMA01', 'Perú'), -- Inés (ID: 10)
(10, 'Calle 8 # 12-30', 'Bogotá', '111711', 'Colombia'), -- Juan (ID: 11)
(3, 'Av. Larco 550', 'Lima', 'LIMA18', 'Perú'), -- Carla (ID: 12)
(5, 'Defensa 100', 'Buenos Aires', 'C1065', 'Argentina'); -- Elena (ID: 13)


/* * =========================================
 * 4. TABLA DE STOCK (Depende de Productos)
 * =========================================
 */
 
-- Insertar 15 SKUs (Variantes de los productos)
INSERT INTO stock (producto_id, sku, precio_unitario, cantidad_en_stock) VALUES
(1, 'LAP-PRO-15-1TB', 1499.99, 15), -- ID: 1
(2, 'SMART-X100-BLK', 799.50, 40), -- ID: 2
(3, 'TWS-NOISE-WHT', 120.00, 75), -- ID: 3
(4, 'CAM-ALG-BLC-M', 19.99, 100), -- ID: 4 (Camiseta Blanca M)
(4, 'CAM-ALG-AZL-M', 19.99, 100), -- ID: 5 (Camiseta Azul M)
(4, 'CAM-ALG-BLC-L', 19.99, 80), -- ID: 6 (Camiseta Blanca L)
(5, 'JEAN-SLIM-32', 49.95, 60), -- ID: 7 (Talla 32)
(5, 'JEAN-SLIM-34', 49.95, 60), -- ID: 8 (Talla 34)
(6, 'CAF-AUTO-BREV', 349.90, 25), -- ID: 9
(7, 'SOFA-CAMA-GRIS', 450.00, 10), -- ID: 10
(8, 'LIB-VIENTO-TAPA', 25.00, 50), -- ID: 11
(9, 'BALON-FUT-PRO', 89.99, 30), -- ID: 12
(10, 'ZAP-RUN-AZ-42', 110.00, 40), -- ID: 13 (Talla 42)
(10, 'ZAP-RUN-AZ-43', 110.00, 40), -- ID: 14 (Talla 43)
(1, 'LAP-PRO-15-512GB', 1299.99, 20); -- ID: 15


/* * =========================================
 * 5. TABLAS DE PEDIDOS (Depende de Clientes, Direcciones, Cupones)
 * =========================================
 * Insertamos los pedidos con totales en 0.
 * Los actualizaremos después de insertar los detalles.
 */
 
INSERT INTO pedidos (cliente_id, direccion_envio_id, cupon_id, estado_pedido, subtotal, descuento_aplicado, impuestos, total_pedido) VALUES
-- Pedido 1: Ana, pagado, con cupón BIENVENIDO10
(1, 1, 1, 'pagado', 0, 0, 0, 0), -- ID: 1
-- Pedido 2: Bruno, enviado, sin cupón
(2, 3, NULL, 'enviado', 0, 0, 0, 0), -- ID: 2
-- Pedido 3: Carla, pendiente (fallo de pago)
(3, 4, 2, 'pendiente', 0, 0, 0, 0), -- ID: 3
-- Pedido 4: Ana, cancelado
(1, 2, NULL, 'cancelado', 0, 0, 0, 0), -- ID: 4
-- Pedido 5: David, completado
(4, 5, NULL, 'completado', 0, 0, 0, 0); -- ID: 5


/* * =========================================
 * 6. DETALLES DE PEDIDO (Depende de Pedidos y Stock)
 * =========================================
 */
 
INSERT INTO detalle_pedido (pedido_id, stock_id, cantidad, precio_unitario_compra) VALUES
-- Pedido 1 (Ana)
(1, 1, 1, 1499.99), -- 1x Laptop Pro (ID Detalle: 1)
(1, 3, 2, 120.00),  -- 2x Auriculares TWS (ID Detalle: 2)
-- Pedido 2 (Bruno)
(2, 5, 3, 19.99),   -- 3x Camiseta Azul M (ID Detalle: 3)
(2, 8, 1, 49.95),   -- 1x Jean Slim 34 (ID Detalle: 4)
-- Pedido 3 (Carla)
(3, 10, 1, 450.00), -- 1x Sofá Cama (ID Detalle: 5)
-- Pedido 4 (Ana, cancelado)
(4, 11, 1, 25.00),  -- 1x Libro (ID Detalle: 6)
-- Pedido 5 (David, completado)
(5, 13, 1, 110.00); -- 1x Zapatillas Talla 42 (ID Detalle: 7)


/* * =========================================
 * 7. (IMPORTANTE) ACTUALIZAR TOTALES DE PEDIDOS
 * =========================================
 * Ahora que tenemos los detalles, calculamos y actualizamos los pedidos.
 * Asumiremos un impuesto fijo del 15% (IVA/IGV/etc)
 */

-- Pedido 1: (1499.99) + (2 * 120.00) = 1739.99
-- Descuento (10%): 174.00
-- Subtotal - Desc: 1565.99
-- Impuestos (15%): 234.90
-- Total: 1800.89
UPDATE pedidos
SET 
    subtotal = 1739.99,
    descuento_aplicado = 174.00,
    impuestos = 234.90,
    total_pedido = 1800.89
WHERE pedido_id = 1;

-- Pedido 2: (3 * 19.99) + (1 * 49.95) = 109.92
-- Descuento: 0
-- Impuestos (15%): 16.49
-- Total: 126.41
UPDATE pedidos
SET 
    subtotal = 109.92,
    descuento_aplicado = 0.00,
    impuestos = 16.49,
    total_pedido = 126.41
WHERE pedido_id = 2;

-- Pedido 3: (1 * 450.00) = 450.00
-- Descuento (Fijo $20): 20.00
-- Subtotal - Desc: 430.00
-- Impuestos (15%): 64.50
-- Total: 494.50
UPDATE pedidos
SET 
    subtotal = 450.00,
    descuento_aplicado = 20.00,
    impuestos = 64.50,
    total_pedido = 494.50
WHERE pedido_id = 3;

-- Pedido 4 (Cancelado): (1 * 25.00) = 25.00
UPDATE pedidos SET subtotal = 25.00, impuestos = 3.75, total_pedido = 28.75 WHERE pedido_id = 4;

-- Pedido 5 (Completado): (1 * 110.00) = 110.00
UPDATE pedidos SET subtotal = 110.00, impuestos = 16.50, total_pedido = 126.50 WHERE pedido_id = 5;


/* * =========================================
 * 8. TABLAS DE PAGOS (Depende de Pedidos)
 * =========================================
 */

INSERT INTO pagos (pedido_id, monto, metodo_pago, estado_pago, id_transaccion_externa) VALUES
-- Pedido 1 (Pagado)
(1, 1800.89, 'Tarjeta de Crédito', 'exitoso', 'txn_1a2b3c4d5e'),
-- Pedido 2 (Pagado)
(2, 126.41, 'PayPal', 'exitoso', 'pp_6f7g8h9i0j'),
-- Pedido 3 (Pendiente)
(3, 494.50, 'Tarjeta de Débito', 'fallido', 'txn_k1l2m3n4o5'), -- Intento fallido
(3, 494.50, 'PSE', 'pendiente', 'pse_p6q7r8s9t0'), -- Intento pendiente
-- Pedido 5 (Pagado)
(5, 126.50, 'Tarjeta de Crédito', 'exitoso', 'txn_u1v2w3x4y5');


/* * =========================================
 * 9. TABLAS DE ENVÍOS (Depende de Pedidos)
 * =========================================
 */
 
INSERT INTO envios (pedido_id, transportista, numero_tracking, estado_envio) VALUES
-- Pedido 1 (Se pagó, está en preparación)
(1, 'DHL', 'DHL_111222333', 'en_preparacion'),
-- Pedido 2 (Se pagó y se envió)
(2, 'Servientrega', 'SV_444555666', 'en_transito'),
-- Pedido 5 (Se pagó, envió y entregó)
(5, 'UPS', 'UPS_777888999', 'entregado');
-- El pedido 3 (pendiente) y 4 (cancelado) no generan envío.


/* * =========================================
 * 10. TABLA DE DEVOLUCIONES (Depende de Detalle_Pedido)
 * =========================================
 */

-- Vamos a devolver 1 de los 2 auriculares del Pedido 1 (Detalle_ID: 2)
INSERT INTO devoluciones (detalle_id, motivo, cantidad_devuelta, estado_devolucion) VALUES
(2, 'No me gustó el color, esperaba blanco puro.', 1, 'solicitada');

-- Vamos a devolver las 3 camisetas del Pedido 2 (Detalle_ID: 3)
INSERT INTO devoluciones (detalle_id, motivo, cantidad_devuelta, estado_devolucion) VALUES
(3, 'Pedí talla M y me quedaron pequeñas.', 3, 'aprobada');
