# 🗑️ DELETE FÍSICO - Procedimientos de Eliminación Permanente

## 📋 Resumen

Se han implementado **5 procedimientos almacenados** para eliminar registros de forma **permanente** (DELETE físico) en la base de datos, con validaciones integradas que previenen eliminaciones cuando los registros están en uso.

---

## 🔧 **PASO 1: Actualizar la Base de Datos**

### **Archivo a ejecutar:**
📁 `database/functions_procedures.sql`

### **Instrucciones:**

1. **Abre tu cliente de PostgreSQL** (pgAdmin, DBeaver, psql, etc.)
2. **Conéctate a tu base de datos del proyecto**
3. **Ejecuta TODO el archivo** `functions_procedures.sql` completo
4. Esto creará los 5 nuevos procedimientos:
   - `sp_eliminar_cliente(p_cliente_id)`
   - `sp_eliminar_producto(p_producto_id)`
   - `sp_eliminar_stock(p_stock_id)`
   - `sp_eliminar_pedido(p_pedido_id)`
   - `sp_eliminar_pago(p_pago_id)`

### **Verificación:**

```sql
-- Verifica que los procedimientos se crearon correctamente
SELECT proname, pronargs 
FROM pg_proc 
WHERE proname LIKE 'sp_eliminar_%'
ORDER BY proname;
```

Deberías ver 5 procedimientos listados.

---

## 📁 **PASO 2: Archivos API Actualizados**

Los siguientes endpoints de API **ya tienen soporte para DELETE físico**:

✅ `src/pages/api/clientes/index.ts` - Llama `sp_eliminar_cliente()`
✅ `src/pages/api/productos/index.ts` - Llama `sp_eliminar_producto()`
✅ `src/pages/api/stock/index.ts` - Llama `sp_eliminar_stock()`
✅ `src/pages/api/pedidos/index.ts` - Llama `sp_eliminar_pedido()` (con flag `eliminar_fisico=true`)
✅ `src/pages/api/pagos/index.ts` - Llama `sp_eliminar_pago()`

**No requieren cambios adicionales** - ya están listos para usar.

---

## 🖥️ **PASO 3: Interfaz de Usuario Actualizada**

Las siguientes páginas **ya tienen botones de eliminación (🗑️)**:

✅ `src/pages/clientes/index.astro` - Botón rojo "Eliminar Permanentemente" + función `eliminarCliente()`
✅ `src/pages/productos/index.astro` - Botón rose "Eliminar Permanentemente" + función `eliminarProducto()`
✅ `src/pages/stock/index.astro` - Botón rose "Eliminar Permanentemente" + función `eliminarStock()`
✅ `src/pages/pedidos/index.astro` - Botón 🗑️ solo para pedidos **cancelados** + función `eliminarPedido()`
✅ `src/pages/pagos/index.astro` - Botón rose solo para **fallidos/pendientes** + función `eliminarPago()`

**No requieren cambios adicionales** - interfaz lista para usar.

---

## 🚀 **PASO 4: Iniciar la Aplicación**

```bash
# Desde la raíz del proyecto
npm run dev
```

La aplicación se iniciará en `http://localhost:4321`

---

## 🔐 **Validaciones Implementadas**

### **1️⃣ sp_eliminar_cliente(p_cliente_id)**

❌ **NO se puede eliminar si:**
- El cliente tiene pedidos asociados

✅ **Elimina:**
- Direcciones del cliente (cascada manual)
- El cliente

📝 **Mensaje de error ejemplo:**
```
No se puede eliminar el cliente "Juan Pérez" porque tiene pedidos asociados. Usa desactivación en su lugar.
```

---

### **2️⃣ sp_eliminar_producto(p_producto_id)**

❌ **NO se puede eliminar si:**
- Tiene registros de stock
- Está en algún pedido (detalle_pedido)

✅ **Elimina:**
- El producto

📝 **Mensaje de error ejemplo:**
```
No se puede eliminar el producto "Laptop Dell" porque tiene 3 registros de stock. Elimina el stock primero.
```
```
No se puede eliminar el producto "Laptop Dell" porque está en 5 pedidos. Usa desactivación en su lugar.
```

---

### **3️⃣ sp_eliminar_stock(p_stock_id)**

❌ **NO se puede eliminar si:**
- `cantidad_reservada > 0` (hay pedidos pendientes)
- Está en algún pedido histórico (detalle_pedido)

✅ **Elimina:**
- El registro de stock (SKU específico)

📝 **Mensaje de error ejemplo:**
```
No se puede eliminar el SKU "LAPTOP-DELL-15-BLK" porque tiene 3 unidades reservadas en pedidos.
```
```
No se puede eliminar el SKU "LAPTOP-DELL-15-BLK" porque está en 10 pedidos (histórico). Usa desactivación en su lugar.
```

---

### **4️⃣ sp_eliminar_pedido(p_pedido_id)**

❌ **NO se puede eliminar si:**
- `estado_pedido != 'cancelado'`

✅ **Elimina (en orden):**
1. Devoluciones asociadas
2. Detalle del pedido
3. Envío asociado
4. Pagos asociados
5. El pedido

📝 **Mensaje de error ejemplo:**
```
Solo se pueden eliminar pedidos cancelados. Estado actual: "pagado"
```

---

### **5️⃣ sp_eliminar_pago(p_pago_id)**

❌ **NO se puede eliminar si:**
- `estado_pago NOT IN ('fallido', 'pendiente')`
- Es decir, NO se pueden eliminar pagos exitosos o reembolsados

✅ **Elimina:**
- El registro de pago

📝 **Mensaje de error ejemplo:**
```
Solo se pueden eliminar pagos fallidos o pendientes. Estado actual: "exitoso"
```

---

## 🎯 **Flujo de Usuario Completo**

### **Ejemplo: Eliminar un Cliente**

1. Usuario entra a **http://localhost:4321/clientes**
2. Ve la lista de clientes con botón 🗑️ rojo al final
3. **Click en 🗑️**
4. **Primera confirmación:**
   ```
   ⚠️ ELIMINAR PERMANENTEMENTE
   
   ¿Estás seguro de eliminar al cliente "Juan Pérez"?
   
   Esta acción NO se puede deshacer y solo funciona si el cliente 
   NO tiene pedidos asociados.
   ```
5. **Segunda confirmación:**
   ```
   Confirma nuevamente: ¿Eliminar a "Juan Pérez" de la base de datos?
   ```
6. **Si el cliente NO tiene pedidos:**
   - ✅ Se elimina exitosamente
   - Alert: `✅ Cliente eliminado exitosamente`
   - Redirección a `/clientes`

7. **Si el cliente TIENE pedidos:**
   - ❌ Error del procedimiento almacenado
   - Alert: `❌ Error: No se puede eliminar el cliente "Juan Pérez" porque tiene pedidos asociados. Usa desactivación en su lugar.`
   - Permanece en `/clientes`

---

## 📊 **Tabla de Módulos con DELETE Físico**

| Módulo      | Botón DELETE | Condición para Eliminar                      | Función JS           | Stored Procedure        |
|-------------|--------------|----------------------------------------------|----------------------|-------------------------|
| **Clientes**| 🗑️ (rojo)   | Sin pedidos                                  | `eliminarCliente()`  | `sp_eliminar_cliente()` |
| **Productos**| 🗑️ (rose)   | Sin stock y sin pedidos                      | `eliminarProducto()` | `sp_eliminar_producto()`|
| **Stock**   | 🗑️ (rose)   | Sin reservas y sin pedidos históricos        | `eliminarStock()`    | `sp_eliminar_stock()`   |
| **Pedidos** | 🗑️ (emoji)  | Solo si `estado_pedido = 'cancelado'`        | `eliminarPedido()`   | `sp_eliminar_pedido()`  |
| **Pagos**   | 🗑️ (rose)   | Solo si `estado_pago IN ('fallido', 'pendiente')` | `eliminarPago()`| `sp_eliminar_pago()`    |

---

## 🧪 **Cómo Probar la Funcionalidad**

### **Test 1: Eliminar Cliente SIN Pedidos**

1. Crear un cliente nuevo sin hacer pedidos
2. Click en 🗑️
3. Confirmar dos veces
4. **Resultado:** ✅ Cliente eliminado

### **Test 2: Eliminar Cliente CON Pedidos**

1. Seleccionar un cliente que tenga pedidos
2. Click en 🗑️
3. Confirmar dos veces
4. **Resultado:** ❌ Error - "tiene pedidos asociados"

### **Test 3: Eliminar Producto SIN Stock**

1. Crear un producto sin agregar stock
2. Click en 🗑️
3. Confirmar dos veces
4. **Resultado:** ✅ Producto eliminado

### **Test 4: Eliminar Stock Reservado**

1. Crear un pedido con un producto específico
2. Intentar eliminar el stock de ese producto
3. Click en 🗑️
4. **Resultado:** ❌ Error - "tiene X unidades reservadas"

### **Test 5: Eliminar Pedido Cancelado**

1. Crear un pedido
2. Cancelarlo con el botón ❌
3. Aparecerá botón 🗑️
4. Click en 🗑️, confirmar dos veces
5. **Resultado:** ✅ Pedido eliminado (con detalles, pagos, envío)

### **Test 6: Eliminar Pago Fallido**

1. Procesar un pago (auto-falla si el monto no coincide)
2. Aparecerá botón 🗑️ en pagos fallidos
3. Click en 🗑️, confirmar dos veces
4. **Resultado:** ✅ Pago eliminado

---

## ⚠️ **Diferencias: Soft Delete vs DELETE Físico**

### **Soft Delete (Desactivación) - Módulos:**
- **Categorías** - `UPDATE categorias SET estado = 'inactivo'`
- **Cupones** - `UPDATE cupones SET estado = 'inactivo'`
- **Devoluciones** - Solo lectura
- **Envíos** - Solo actualización de estado
- **Direcciones** - `UPDATE direcciones SET estado = 'inactivo'`

### **DELETE Físico (Esta Implementación) - Módulos:**
- **Clientes** - `DELETE FROM clientes` (con validación de pedidos)
- **Productos** - `DELETE FROM productos` (con validación de stock/pedidos)
- **Stock** - `DELETE FROM stock` (con validación de reservas/pedidos)
- **Pedidos** - `DELETE FROM pedidos` (solo cancelados, cascada completa)
- **Pagos** - `DELETE FROM pagos` (solo fallidos/pendientes)

---

## 🎓 **Requisitos del Proyecto Cumplidos**

✅ **TODA LA LÓGICA INTEGRADA EN LA BASE DE DATOS**
   - Los 5 procedimientos almacenados manejan todas las validaciones
   - La API solo llama al procedimiento, no tiene lógica de negocio

✅ **Operaciones CRUD Completas**
   - CREATE ✅
   - READ ✅
   - UPDATE ✅
   - **DELETE ✅** (Soft delete en 6 módulos + DELETE físico en 5 módulos)

✅ **Validación de Integridad Referencial**
   - Los procedimientos verifican relaciones antes de eliminar
   - Mensajes de error descriptivos para el usuario
   - Prevención de eliminaciones que romperían la integridad

---

## 📞 **Soporte y Dudas**

Si encuentras algún error:

1. **Verifica que ejecutaste** `functions_procedures.sql` **completo**
2. **Revisa la consola del navegador** (F12) para errores JavaScript
3. **Revisa los logs de la aplicación** en la terminal donde corre `npm run dev`
4. **Verifica que la base de datos** tenga los procedimientos creados

---

## ✨ **Características Adicionales**

- **Doble confirmación** en todos los DELETE físicos
- **Iconos visuales** (🗑️) para identificar eliminación
- **Mensajes descriptivos** de éxito/error con emojis
- **Botones condicionales** (solo aparecen cuando es válido eliminar)
- **Redirección automática** después de eliminar
- **Validación en base de datos** (lógica centralizada)

---

**¡Listo para usar!** 🚀
