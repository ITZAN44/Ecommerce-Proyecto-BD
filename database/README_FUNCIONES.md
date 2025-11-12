# 📚 Guía de Ejecución - Funciones y Procedimientos

## 🎯 PUNTO 4: Procedimientos Almacenados y Funciones

**IMPORTANTE:** Este archivo contiene toda la LÓGICA DEL NEGOCIO en la base de datos, tal como lo requiere la consigna.

---

## 📋 ¿Qué hay en este archivo?

### ✅ **6 FUNCIONES** (Solo retornan valores)
1. `fn_calcular_total_pedido()` - Calcula el total de un pedido
2. `fn_validar_stock_disponible()` - Verifica si hay stock suficiente
3. `fn_calcular_descuento_cupon()` - Calcula descuento según tipo de cupón
4. `fn_obtener_precio_producto()` - Obtiene precio de un SKU
5. `fn_cliente_tiene_pedidos()` - Verifica si cliente tiene órdenes
6. `fn_calcular_comision_venta()` - Calcula comisión del 5%

### ✅ **5 PROCEDIMIENTOS ALMACENADOS** (Modifican datos)
1. `sp_crear_pedido()` - Crea pedido completo con validaciones
2. `sp_procesar_pago()` - Procesa pago y actualiza estados
3. `sp_actualizar_stock_compra()` - Reduce stock después de pago
4. `sp_cancelar_pedido()` - Cancela pedido y libera stock
5. `sp_aplicar_cupon_pedido()` - Aplica cupón y recalcula totales

---

## 🚀 INSTRUCCIONES DE EJECUCIÓN

### **Paso 1: Abrir DBeaver**
1. Abre DBeaver
2. Conéctate a tu base de datos PostgreSQL (la que usas para el proyecto)

### **Paso 2: Abrir SQL Editor**
1. Click derecho en tu base de datos → **SQL Editor** → **New SQL Script**
2. O usa el atajo: `Ctrl + ]` (Windows) o `Cmd + ]` (Mac)

### **Paso 3: Copiar el Script**
1. Abre el archivo: `database/functions_procedures.sql`
2. Copia **TODO** el contenido (Ctrl + A, Ctrl + C)

### **Paso 4: Pegar y Ejecutar**
1. Pega el script en el SQL Editor de DBeaver
2. Ejecuta el script completo:
   - **Opción 1:** Click en el botón ▶️ (Execute SQL Script)
   - **Opción 2:** Presiona `Ctrl + Enter`

### **Paso 5: Verificar**
Deberías ver mensajes como:
```
CREATE FUNCTION
CREATE FUNCTION
...
CREATE PROCEDURE
CREATE PROCEDURE
...
```

Si ves errores, verifica que hayas ejecutado **primero** `schema.sql` y `seed.sql`.

---

## ✅ VERIFICACIÓN - Probar las funciones

Una vez ejecutado, puedes probar en DBeaver:

### **Prueba 1: Calcular total de un pedido**
```sql
SELECT fn_calcular_total_pedido(1) AS total;
```

### **Prueba 2: Validar stock disponible**
```sql
SELECT fn_validar_stock_disponible(1, 5) AS hay_stock;
```

### **Prueba 3: Calcular descuento de cupón**
```sql
SELECT fn_calcular_descuento_cupon(1, 1000.00) AS descuento;
```

### **Prueba 4: Crear un pedido nuevo**
```sql
DO $$
DECLARE
    v_pedido_id INT;
BEGIN
    CALL sp_crear_pedido(
        2, -- cliente_id (Bruno)
        3, -- direccion_envio_id
        NULL, -- sin cupón
        '[{"stock_id": 4, "cantidad": 3}]'::JSONB, -- 3 camisetas
        v_pedido_id
    );
    RAISE NOTICE 'Pedido creado con ID: %', v_pedido_id;
END $$;
```

### **Prueba 5: Procesar un pago**
```sql
CALL sp_procesar_pago(
    6, -- pedido_id (el que acabas de crear)
    68.97, -- monto total
    'Tarjeta de Crédito',
    'txn_test_123'
);
```

### **Prueba 6: Cancelar un pedido**
```sql
CALL sp_cancelar_pedido(4, 'Cliente cambió de opinión');
```

---

## 📊 Diagrama de Flujo de un Pedido

```
1. Cliente agrega productos al carrito
   ↓
2. sp_crear_pedido() 
   - Valida stock (fn_validar_stock_disponible)
   - Obtiene precios (fn_obtener_precio_producto)
   - Calcula descuento (fn_calcular_descuento_cupon)
   - Reserva stock
   - Crea pedido en estado 'pendiente'
   ↓
3. Cliente paga
   ↓
4. sp_procesar_pago()
   - Registra el pago
   - Cambia estado a 'pagado'
   - Crea registro de envío
   ↓
5. sp_actualizar_stock_compra()
   - Reduce stock físico
   - Libera cantidad reservada
   ↓
6. Pedido enviado → Entregado → Completado
```

---

## 🔧 Lógica de Negocio Implementada

### **Validaciones Automáticas:**
- ✅ Verificar stock antes de crear pedido
- ✅ Validar cupones activos y no expirados
- ✅ Validar estados de pedido antes de operaciones
- ✅ Validar montos de pago

### **Cálculos Automáticos:**
- ✅ Subtotal = Suma de (precio × cantidad)
- ✅ Descuento según tipo de cupón (% o fijo)
- ✅ Impuestos = 15% sobre (subtotal - descuento)
- ✅ Total = subtotal - descuento + impuestos

### **Gestión de Stock:**
- ✅ Reserva de stock al crear pedido
- ✅ Liberación de stock al cancelar
- ✅ Reducción de stock al pagar

### **Control de Cupones:**
- ✅ Validación de vigencia
- ✅ Decremento automático de usos disponibles
- ✅ Prevención de uso de cupones expirados

---

## ⚠️ Errores Comunes y Soluciones

### Error: "relation does not exist"
**Causa:** No ejecutaste `schema.sql` primero  
**Solución:** Ejecuta `schema.sql` antes de este script

### Error: "function already exists"
**Causa:** Ya ejecutaste este script antes  
**Solución:** Normal, puedes ignorar o usar `CREATE OR REPLACE`

### Error: "stock insuficiente"
**Causa:** No hay suficiente stock disponible  
**Solución:** Es una validación correcta del sistema

### Error: "Cupón no válido"
**Causa:** El cupón expiró o no tiene usos disponibles  
**Solución:** Verificar tabla `cupones` y actualizar datos

---

## 📝 Notas Importantes

1. **Todas las funciones usan `LANGUAGE plpgsql`** - Lenguaje procedural de PostgreSQL
2. **Los procedimientos usan transacciones implícitas** - Si algo falla, se hace ROLLBACK
3. **Los RAISE NOTICE** muestran mensajes informativos en DBeaver
4. **Los RAISE EXCEPTION** detienen la ejecución y hacen rollback

---

## 🎓 ¿Por qué esta arquitectura?

Esta implementación cumple con la consigna de tener **TODA LA LÓGICA EN LA BASE DE DATOS**:

- ✅ El frontend solo llamará a estos procedimientos
- ✅ Todas las validaciones están en la BD
- ✅ Todos los cálculos se hacen en la BD
- ✅ La integridad de datos está garantizada
- ✅ Es más seguro (el frontend no puede saltarse validaciones)
- ✅ Es más eficiente (menos idas y vueltas con la BD)

---

**📌 Siguiente paso:** Una vez ejecutado exitosamente, avisarme para pasar al **Punto 5: Interfaces de Usuario**
