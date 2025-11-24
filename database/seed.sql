

INSERT INTO categorias (nombre_categoria, descripcion) VALUES
('Electrónica', 'Dispositivos y gadgets tecnológicos.'),
('Ropa', 'Prendas de vestir para todas las edades.'),
('Hogar y Cocina', 'Artículos para el hogar, decoración y utensilios de cocina.'),
('Libros', 'Libros físicos y digitales de diversos géneros.'),
('Deportes', 'Equipamiento, ropa y accesorios deportivos.');

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

INSERT INTO cupones (codigo_cupon, tipo_descuento, valor_descuento, fecha_expiracion, usos_disponibles, estado) VALUES
('BIENVENIDO10', 'porcentaje', 10.00, '2026-12-31', 100, 'activo'),
('VERANO20', 'fijo', 20.00, '2026-09-30', 50, 'activo'),
('FLASH50', 'porcentaje', 50.00, '2026-06-15', 5, 'activo'),
('OLD_CUPON', 'fijo', 5.00, '2020-01-01', 0, 'expirado');

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

INSERT INTO direcciones (cliente_id, direccion_linea_1, ciudad, codigo_postal, pais) VALUES
(1, 'Calle Falsa 123', 'Springfield', 'S1234', 'EEUU'),
(1, 'Avenida Siempreviva 742', 'Springfield', 'S5678', 'EEUU'),
(2, 'Plaza Mayor 1', 'Madrid', '28001', 'España'),
(3, 'Boulevard de los Sueños Rotos 44', 'Lima', 'LIMA01', 'Perú'),
(4, 'Carrera 15 # 80-10', 'Bogotá', '110111', 'Colombia'),
(5, 'Av. Corrientes 1000', 'Buenos Aires', 'C1043', 'Argentina'),
(6, 'Rua Augusta 500', 'São Paulo', '01304-001', 'Brasil'),
(7, 'Paseo de la Reforma 222', 'CDMX', '06600', 'México'),
(8, 'Merced 391', 'Santiago', '8320000', 'Chile'),
(9, 'Jr. de la Unión 899', 'Lima', 'LIMA01', 'Perú'),
(10, 'Calle 8 # 12-30', 'Bogotá', '111711', 'Colombia'),
(3, 'Av. Larco 550', 'Lima', 'LIMA18', 'Perú'),
(5, 'Defensa 100', 'Buenos Aires', 'C1065', 'Argentina');

INSERT INTO stock (producto_id, sku, precio_unitario, cantidad_en_stock) VALUES
(1, 'LAP-PRO-15-1TB', 1499.99, 15),
(2, 'SMART-X100-BLK', 799.50, 40),
(3, 'TWS-NOISE-WHT', 120.00, 75),
(4, 'CAM-ALG-BLC-M', 19.99, 100),
(4, 'CAM-ALG-AZL-M', 19.99, 100),
(4, 'CAM-ALG-BLC-L', 19.99, 80),
(5, 'JEAN-SLIM-32', 49.95, 60),
(5, 'JEAN-SLIM-34', 49.95, 60),
(6, 'CAF-AUTO-BREV', 349.90, 25),
(7, 'SOFA-CAMA-GRIS', 450.00, 10),
(8, 'LIB-VIENTO-TAPA', 25.00, 50),
(9, 'BALON-FUT-PRO', 89.99, 30),
(10, 'ZAP-RUN-AZ-42', 110.00, 40),
(10, 'ZAP-RUN-AZ-43', 110.00, 40),
(1, 'LAP-PRO-15-512GB', 1299.99, 20);

INSERT INTO pedidos (cliente_id, direccion_envio_id, cupon_id, estado_pedido, subtotal, descuento_aplicado, impuestos, total_pedido) VALUES
(1, 1, 1, 'pagado', 0, 0, 0, 0),
(2, 3, NULL, 'enviado', 0, 0, 0, 0),
(3, 4, 2, 'pendiente', 0, 0, 0, 0),
(1, 2, NULL, 'cancelado', 0, 0, 0, 0),
(4, 5, NULL, 'completado', 0, 0, 0, 0);

INSERT INTO detalle_pedido (pedido_id, stock_id, cantidad, precio_unitario_compra) VALUES
(1, 1, 1, 1499.99),
(1, 3, 2, 120.00),
(2, 5, 3, 19.99),
(2, 8, 1, 49.95),
(3, 10, 1, 450.00),
(4, 11, 1, 25.00),
(5, 13, 1, 110.00);

UPDATE pedidos
SET
    subtotal = 1739.99,
    descuento_aplicado = 174.00,
    impuestos = 234.90,
    total_pedido = 1800.89
WHERE pedido_id = 1;

UPDATE pedidos
SET
    subtotal = 109.92,
    descuento_aplicado = 0.00,
    impuestos = 16.49,
    total_pedido = 126.41
WHERE pedido_id = 2;

UPDATE pedidos
SET
    subtotal = 450.00,
    descuento_aplicado = 20.00,
    impuestos = 64.50,
    total_pedido = 494.50
WHERE pedido_id = 3;

UPDATE pedidos SET subtotal = 25.00, impuestos = 3.75, total_pedido = 28.75 WHERE pedido_id = 4;

UPDATE pedidos SET subtotal = 110.00, impuestos = 16.50, total_pedido = 126.50 WHERE pedido_id = 5;

INSERT INTO pagos (pedido_id, monto, metodo_pago, estado_pago, id_transaccion_externa) VALUES
(1, 1800.89, 'Tarjeta de Crédito', 'exitoso', 'txn_1a2b3c4d5e'),
(2, 126.41, 'PayPal', 'exitoso', 'pp_6f7g8h9i0j'),
(3, 494.50, 'Tarjeta de Débito', 'fallido', 'txn_k1l2m3n4o5'),
(3, 494.50, 'PSE', 'pendiente', 'pse_p6q7r8s9t0'),
(5, 126.50, 'Tarjeta de Crédito', 'exitoso', 'txn_u1v2w3x4y5');

INSERT INTO envios (pedido_id, transportista, numero_tracking, estado_envio) VALUES
(1, 'DHL', 'DHL_111222333', 'en_preparacion'),
(2, 'Servientrega', 'SV_444555666', 'en_transito'),
(5, 'UPS', 'UPS_777888999', 'entregado');

INSERT INTO devoluciones (detalle_id, motivo, cantidad_devuelta, estado_devolucion) VALUES
(2, 'No me gustó el color, esperaba blanco puro.', 1, 'solicitada');

INSERT INTO devoluciones (detalle_id, motivo, cantidad_devuelta, estado_devolucion) VALUES
(3, 'Pedí talla M y me quedaron pequeñas.', 3, 'aprobada');
