# 📊 Base de Datos E-Commerce - PostgreSQL

Sistema completo de base de datos para un e-commerce con todas las funcionalidades necesarias.

## 📁 Estructura de Archivos

```
database/
├── schema.sql          # DDL - Estructura completa de la BD
├── seed.sql           # Datos de prueba
└── README.md          # Esta documentación
```

## 🗃️ Estructura de la Base de Datos

### **Tablas Maestras** (Sin dependencias)
- `categorias` - Categorías de productos
- `clientes` - Usuarios del sistema
- `cupones` - Cupones de descuento

### **Gestión de Productos**
- `productos` - Catálogo de productos (plantilla)
- `stock` - Inventario real con SKUs y precios

### **Gestión de Clientes**
- `direcciones` - Direcciones de envío de clientes

### **Transacciones E-Commerce**
- `pedidos` - Órdenes de compra
- `detalle_pedido` - Líneas de productos en cada pedido
- `pagos` - Transacciones de pago
- `envios` - Seguimiento de entregas
- `devoluciones` - Logística inversa

## 🚀 Instalación

### 1. Crear la base de datos
```sql
CREATE DATABASE ecommerce_db;
\c ecommerce_db
```

### 2. Ejecutar el schema
```bash
psql -U tu_usuario -d ecommerce_db -f database/schema.sql
```

### 3. Cargar datos de prueba
```bash
psql -U tu_usuario -d ecommerce_db -f database/seed.sql
```

## 🔑 Características Principales

### ✅ **Auditoría Automática**
- Columnas `fecha_creacion` y `fecha_modificacion` en todas las tablas
- Trigger automático que actualiza `fecha_modificacion` en cada UPDATE

### ✅ **Soft Delete**
- Columna `estado` en todas las tablas principales
- Permite "eliminar" sin borrar datos físicamente

### ✅ **Validaciones de Negocio**
- Constraints CHECK en precios, cantidades, estados
- Foreign Keys con ON DELETE CASCADE cuando aplica
- Restricción: `cantidad_reservada <= cantidad_en_stock`

### ✅ **Índices para Performance**
- Índices en columnas más consultadas
- Búsquedas optimizadas de productos, pedidos, pagos

## 📊 Modelo de Datos

### Flujo de un Pedido

```
Cliente → Dirección
   ↓
Pedido (puede tener Cupón)
   ↓
Detalle_Pedido ← Stock (SKU)
   ↓
Pago → Estados: pendiente/exitoso/fallido
   ↓
Envío → Estados: preparación/tránsito/entregado
   ↓
Devolución (opcional)
```

### Estados del Sistema

**Pedidos:**
- `pendiente` - Esperando pago
- `pagado` - Pago confirmado
- `enviado` - En camino al cliente
- `completado` - Entregado exitosamente
- `cancelado` - Cancelado por cliente/sistema

**Pagos:**
- `exitoso` - Pago confirmado
- `fallido` - Pago rechazado
- `pendiente` - Esperando confirmación
- `reembolsado` - Dinero devuelto

**Envíos:**
- `en_preparacion` - Empaquetando
- `en_transito` - Con transportista
- `entregado` - Recibido por cliente
- `fallido` - No se pudo entregar

**Devoluciones:**
- `solicitada` - Cliente pidió devolución
- `aprobada` - Empresa autorizó
- `recibida` - Producto recibido
- `reembolsada` - Dinero devuelto
- `rechazada` - No se aceptó devolución

## 📦 Datos de Prueba Incluidos

- **5 Categorías**: Electrónica, Ropa, Hogar, Libros, Deportes
- **10 Clientes**: Con emails y contraseñas hash
- **4 Cupones**: Activos y expirados
- **10 Productos**: Variedad de categorías
- **15 SKUs**: Variantes con precios y stock
- **13 Direcciones**: Varios países de LATAM
- **5 Pedidos**: En diferentes estados
- **7 Líneas de pedido**: Productos comprados
- **5 Pagos**: Exitosos, fallidos, pendientes
- **3 Envíos**: En diferentes estados
- **2 Devoluciones**: Solicitada y aprobada

## 🔍 Consultas Útiles

### Ver productos con stock disponible
```sql
SELECT 
    p.nombre_producto,
    s.sku,
    s.precio_unitario,
    s.cantidad_en_stock
FROM productos p
JOIN stock s ON p.producto_id = s.producto_id
WHERE s.cantidad_en_stock > 0
    AND p.estado = 'activo';
```

### Ver pedidos de un cliente
```sql
SELECT 
    pe.pedido_id,
    pe.fecha_pedido,
    pe.estado_pedido,
    pe.total_pedido,
    d.direccion_linea_1,
    d.ciudad
FROM pedidos pe
JOIN direcciones d ON pe.direccion_envio_id = d.direccion_id
WHERE pe.cliente_id = 1
ORDER BY pe.fecha_pedido DESC;
```

### Ver detalle completo de un pedido
```sql
SELECT 
    dp.detalle_id,
    p.nombre_producto,
    s.sku,
    dp.cantidad,
    dp.precio_unitario_compra,
    (dp.cantidad * dp.precio_unitario_compra) as subtotal
FROM detalle_pedido dp
JOIN stock s ON dp.stock_id = s.stock_id
JOIN productos p ON s.producto_id = p.producto_id
WHERE dp.pedido_id = 1;
```

## 🔧 Mantenimiento

### Backup
```bash
pg_dump -U tu_usuario ecommerce_db > backup_$(date +%Y%m%d).sql
```

### Restaurar
```bash
psql -U tu_usuario ecommerce_db < backup_20251108.sql
```

## 📝 Notas Técnicas

- **PostgreSQL**: Versión 12 o superior recomendada
- **Codificación**: UTF-8
- **Timezone**: Timestamps en UTC
- **Contraseñas**: Usar bcrypt con cost factor 12
- **Precios**: NUMERIC(10,2) o NUMERIC(12,2)

## 🎯 Próximas Mejoras Sugeridas

- [ ] Tabla de `carritos` (carrito de compras temporal)
- [ ] Tabla de `wishlist` (lista de deseos)
- [ ] Tabla de `reviews` (reseñas de productos)
- [ ] Tabla de `imagenes_producto`
- [ ] Sistema de notificaciones
- [ ] Historial de precios de productos
- [ ] Programa de puntos/lealtad

---

**Desarrollado para:** Proyecto BS2 - Base de Datos  
**Fecha:** Noviembre 2025  
**Tecnología:** PostgreSQL + DBeaver
