# 🔍 FLUJO DETALLADO DE PEDIDOS - REFERENCIAS EXACTAS

## 📋 ÍNDICE DEL FLUJO
1. [Carga Inicial de la Página](#1-carga-inicial)
2. [Interacción del Usuario](#2-interacción-usuario)
3. [Envío del Formulario](#3-envío-formulario)
4. [API Backend](#4-api-backend)
5. [Procedimientos de Base de Datos](#5-base-de-datos)
6. [Funciones Auxiliares](#6-funciones-auxiliares)

---

## 1️⃣ CARGA INICIAL DE LA PÁGINA {#1-carga-inicial}

### 📄 Archivo: `src/pages/pedidos/index.astro`

#### **Líneas 10-119: Consultas SQL al cargar la página**

```astro
LÍNEA 10-49: Consulta de Pedidos Existentes
─────────────────────────────────────────────
const resultPedidos = await query(`
  SELECT
    p.pedido_id,
    p.cliente_id,
    p.direccion_envio_id,
    p.cupon_id,
    p.fecha_pedido,
    p.estado_pedido,
    p.subtotal,
    p.descuento_aplicado,
    p.impuestos,
    p.total_pedido,
    c.nombre,
    c.apellido,
    c.email,
    d.direccion_linea_1,
    d.ciudad,
    d.pais,
    cu.codigo_cupon
  FROM pedidos p
  INNER JOIN clientes c ON p.cliente_id = c.cliente_id
  INNER JOIN direcciones d ON p.direccion_envio_id = d.direccion_id
  LEFT JOIN cupones cu ON p.cupon_id = cu.cupon_id
  ORDER BY p.pedido_id DESC
`);

🔑 TABLAS CONSULTADAS:
   - pedidos
   - clientes
   - direcciones
   - cupones
```

```astro
LÍNEA 51-72: Consulta de Clientes con sus Direcciones
──────────────────────────────────────────────────────
const resultClientes = await query(`
  SELECT
    c.cliente_id,
    c.nombre,
    c.apellido,
    c.email,
    COALESCE(
      json_agg(
        json_build_object(
          'direccion_id', d.direccion_id,
          'direccion_linea_1', d.direccion_linea_1,
          'ciudad', d.ciudad,
          'codigo_postal', d.codigo_postal,
          'pais', d.pais
        )
      ) FILTER (WHERE d.direccion_id IS NOT NULL),
      '[]'::json
    ) AS direcciones
  FROM clientes c
  LEFT JOIN direcciones d ON c.cliente_id = d.cliente_id AND d.estado = 'activo'
  WHERE c.estado = 'activo'
  GROUP BY c.cliente_id, c.nombre, c.apellido, c.email
  ORDER BY c.nombre, c.apellido
`);

🔑 FUNCIÓN ESPECIAL: json_agg() agrupa direcciones en formato JSON
🔑 FILTRO: Solo clientes y direcciones activos
```

```astro
LÍNEA 74-93: Consulta de Stock Disponible
──────────────────────────────────────────
const resultStock = await query(`
  SELECT
    s.stock_id,
    s.sku,
    s.precio_unitario,
    s.cantidad_en_stock,
    s.cantidad_reservada,
    (s.cantidad_en_stock - s.cantidad_reservada) AS disponible,
    pr.nombre_producto,
    c.nombre_categoria
  FROM stock s
  INNER JOIN productos pr ON s.producto_id = pr.producto_id
  INNER JOIN categorias c ON pr.categoria_id = c.categoria_id
  WHERE s.estado = 'activo' AND pr.estado = 'activo' AND c.estado = 'activo'
    AND (s.cantidad_en_stock - s.cantidad_reservada) > 0
  ORDER BY pr.nombre_producto, s.sku
`);

🔑 CÁLCULO CLAVE: disponible = cantidad_en_stock - cantidad_reservada
🔑 FILTRO: Solo muestra items con stock disponible > 0
```

```astro
LÍNEA 95-109: Consulta de Cupones Válidos
──────────────────────────────────────────
const resultCupones = await query(`
  SELECT
    cupon_id,
    codigo_cupon,
    tipo_descuento,
    valor_descuento,
    fecha_expiracion,
    usos_disponibles
  FROM cupones
  WHERE estado = 'activo'
    AND (fecha_expiracion IS NULL OR fecha_expiracion >= CURRENT_DATE)
    AND (usos_disponibles IS NULL OR usos_disponibles > 0)
  ORDER BY codigo_cupon
`);

🔑 VALIDACIONES:
   - Estado activo
   - No expirado
   - Tiene usos disponibles
```

---

## 2️⃣ INTERACCIÓN DEL USUARIO {#2-interacción-usuario}

### 📄 Archivo: `src/pages/pedidos/index.astro`

#### **Líneas 528-562: Función para cargar direcciones dinámicamente**

```javascript
LÍNEA 528: function cargarDirecciones()
───────────────────────────────────────────

LÍNEA 529-530: Obtiene los elementos del DOM
const selectCliente = document.getElementById('select-cliente');
const selectDireccion = document.getElementById('select-direccion');

LÍNEA 531: Obtiene la opción seleccionada
const selectedOption = selectCliente.options[selectCliente.selectedIndex];

LÍNEA 533-558: Si hay un cliente seleccionado
if (selectedOption.value) {
  LÍNEA 534: Parsea el JSON de direcciones
  const direcciones = JSON.parse(selectedOption.getAttribute('data-direcciones'));
  
  LÍNEA 536: Limpia el select
  selectDireccion.innerHTML = '';
  
  LÍNEA 538-549: Si tiene direcciones
  if (direcciones && direcciones.length > 0 && direcciones[0].direccion_id) {
    LÍNEA 539: Agrega opción placeholder
    selectDireccion.innerHTML = '<option value="">Seleccionar dirección...</option>';
    
    LÍNEA 540-545: Itera sobre cada dirección
    direcciones.forEach(dir => {
      const option = document.createElement('option');
      option.value = dir.direccion_id;
      option.textContent = `${dir.direccion_linea_1}, ${dir.ciudad}, ${dir.pais}`;
      selectDireccion.appendChild(option);
    });
    
    LÍNEA 546: Habilita el select
    selectDireccion.disabled = false;
    
  LÍNEA 547-553: Si NO tiene direcciones
  } else {
    selectDireccion.innerHTML = '<option value="">⚠️ Este cliente no tiene direcciones activas</option>';
    selectDireccion.disabled = true;
    alert('⚠️ El cliente seleccionado no tiene direcciones registradas...');
  }
}

🔑 EVENTO QUE LO DISPARA: onChange del select-cliente (línea 565)
```

#### **Líneas 585-612: Función para agregar items al pedido**

```javascript
LÍNEA 585: function agregarItem()
─────────────────────────────────────

LÍNEA 586: Obtiene el contenedor
const container = document.getElementById('items-container');

LÍNEA 587: Incrementa contador único
const itemId = itemCount++;

LÍNEA 589-591: Crea un nuevo div
const itemDiv = document.createElement('div');
itemDiv.className = 'flex gap-2 items-start';
itemDiv.id = `item-${itemId}`;

LÍNEA 592-608: HTML dinámico con stock disponible
itemDiv.innerHTML = `
  <select id="stock-${itemId}" required>
    <option value="">Seleccionar producto...</option>
    ${stockDisponible.map(s =>
      `<option value="${s.stock_id}" 
               data-precio="${s.precio_unitario}" 
               data-disponible="${s.disponible}">
        ${s.nombre_producto} (SKU: ${s.sku}) - 
        $${parseFloat(s.precio_unitario).toFixed(2)} - 
        Disponible: ${s.disponible}
      </option>`
    ).join('')}
  </select>
  <input type="number" id="cantidad-${itemId}" min="1" required />
  <button type="button" onclick="eliminarItem(${itemId})">❌</button>
`;

LÍNEA 610: Agrega al contenedor
container.appendChild(itemDiv);

🔑 DATOS IMPORTANTES EN CADA OPTION:
   - value: stock_id
   - data-precio: precio_unitario
   - data-disponible: cantidad disponible
```

---

## 3️⃣ ENVÍO DEL FORMULARIO {#3-envío-formulario}

### 📄 Archivo: `src/pages/pedidos/index.astro`

#### **Líneas 710-773: Validación y construcción del JSON de items**

```javascript
LÍNEA 710: document.getElementById('form-crear-pedido').addEventListener('submit', (e) => {
──────────────────────────────────────────────────────────────────────────────────────────

LÍNEA 711-716: Validación de cliente
const clienteId = document.getElementById('select-cliente').value;
if (!clienteId) {
  e.preventDefault();
  alert('Debe seleccionar un cliente');
  return false;
}

LÍNEA 718-723: Validación de dirección
const direccionId = document.getElementById('select-direccion').value;
if (!direccionId) {
  e.preventDefault();
  alert('Debe seleccionar una dirección de envío');
  return false;
}

LÍNEA 725-726: Inicializa array de items
const items = [];
const container = document.getElementById('items-container');

LÍNEA 727: Obtiene todos los divs de items
const itemDivs = container.querySelectorAll('[id^="item-"]');

LÍNEA 729-752: Itera sobre cada item agregado
itemDivs.forEach(div => {
  LÍNEA 730: Extrae el ID único
  const id = div.id.split('-')[1];
  
  LÍNEA 731-732: Obtiene los elementos
  const stockSelect = document.getElementById(`stock-${id}`);
  const cantidadInput = document.getElementById(`cantidad-${id}`);
  
  LÍNEA 734: Si ambos tienen valor
  if (stockSelect.value && cantidadInput.value) {
    LÍNEA 735-736: Extrae datos del option seleccionado
    const disponible = parseInt(stockSelect.options[stockSelect.selectedIndex]
                                .getAttribute('data-disponible'));
    const cantidad = parseInt(cantidadInput.value);
    
    LÍNEA 738-742: Valida disponibilidad
    if (cantidad > disponible) {
      e.preventDefault();
      alert(`La cantidad solicitada (${cantidad}) supera el stock disponible (${disponible})`);
      return false;
    }
    
    LÍNEA 744-747: Agrega al array
    items.push({
      stock_id: parseInt(stockSelect.value),
      cantidad: cantidad
    });
  }
});

LÍNEA 754-758: Valida que haya al menos 1 producto
if (items.length === 0) {
  e.preventDefault();
  alert('Debe agregar al menos un producto al pedido');
  return false;
}

LÍNEA 760: Convierte a JSON y lo guarda en input hidden
document.getElementById('items-json').value = JSON.stringify(items);

🔑 FORMATO DEL JSON ENVIADO:
[
  {"stock_id": 5, "cantidad": 2},
  {"stock_id": 8, "cantidad": 1}
]
```

#### **Líneas 318-356: Formulario HTML que envía los datos**

```astro
LÍNEA 318: <form action="/api/pedidos" method="POST" id="form-crear-pedido">
────────────────────────────────────────────────────────────────────────────

LÍNEA 321-333: Select de Cliente
<select name="cliente_id" id="select-cliente" required>
  <option value="">Seleccionar cliente...</option>
  {clientes.map((cliente) => (
    <option value={cliente.cliente_id} 
            data-direcciones={JSON.stringify(cliente.direcciones)}>
      {cliente.nombre} {cliente.apellido} ({cliente.email})
    </option>
  ))}
</select>

LÍNEA 337-348: Select de Dirección (inicialmente deshabilitado)
<select name="direccion_envio_id" id="select-direccion" required disabled>
  <option value="">Primero seleccione un cliente</option>
</select>

LÍNEA 352-365: Select de Cupón (opcional)
<select name="cupon_id">
  <option value="">Sin cupón</option>
  {cupones.map((cupon) => (
    <option value={cupon.cupon_id}>
      {cupon.codigo_cupon} - 
      {cupon.tipo_descuento === 'porcentaje' 
        ? `${cupon.valor_descuento}%` 
        : `$${cupon.valor_descuento}`} OFF
    </option>
  ))}
</select>

LÍNEA 369-383: Contenedor de items (dinámico)
<div id="items-container">
  <!-- Items se agregarán con JavaScript -->
</div>
<button type="button" onclick="agregarItem()">
  Agregar Producto
</button>

LÍNEA 385: Input hidden con el JSON de items
<input type="hidden" name="items" id="items-json" />

🔑 DATOS ENVIADOS VIA POST:
   - cliente_id: INT
   - direccion_envio_id: INT
   - cupon_id: INT (nullable)
   - items: STRING (JSON)
```

---

## 4️⃣ API BACKEND {#4-api-backend}

### 📄 Archivo: `src/pages/api/pedidos/index.ts`

#### **Líneas 1-4: Imports**

```typescript
LÍNEA 1: import type { APIRoute } from 'astro';
LÍNEA 2: import { query } from '../../../lib/db';

🔑 query: Función que ejecuta SQL en PostgreSQL
```

#### **Líneas 35-71: Handler POST para crear pedido**

```typescript
LÍNEA 35: export const POST: APIRoute = async ({ request }) => {
───────────────────────────────────────────────────────────────

LÍNEA 36-38: Parsea el FormData
try {
  const formData = await request.formData();
  const method = formData.get('_method') as string;

LÍNEA 40-95: Si es DELETE (cancelar pedido)
if (method === 'DELETE') {
  // ... lógica de cancelación ...
}

LÍNEA 97-108: Si es PATCH (aplicar cupón)
if (method === 'PATCH') {
  const pedido_id = parseInt(formData.get('pedido_id') as string);
  const codigo_cupon = formData.get('codigo_cupon') as string;
  
  LÍNEA 102-105: Llama al procedimiento sp_aplicar_cupon_pedido
  await query(
    'CALL sp_aplicar_cupon_pedido($1, $2)',
    [pedido_id, codigo_cupon]
  );
}

LÍNEA 110-117: Extrae datos del formulario (creación normal)
const cliente_id = parseInt(formData.get('cliente_id') as string);
const direccion_envio_id = parseInt(formData.get('direccion_envio_id') as string);
const cupon_id = formData.get('cupon_id') 
  ? parseInt(formData.get('cupon_id') as string) 
  : null;
const items = formData.get('items') as string;

LÍNEA 119: Log para debugging
console.log('Creando pedido:', { cliente_id, direccion_envio_id, cupon_id, items });

LÍNEA 121-125: ⭐ LLAMADA AL PROCEDIMIENTO PRINCIPAL
const result = await query(
  'CALL sp_crear_pedido($1, $2, $3, $4, NULL)',
  [cliente_id, direccion_envio_id, cupon_id, items]
);

🔑 PARÁMETROS ENVIADOS A LA BASE DE DATOS:
   $1: cliente_id (INT)
   $2: direccion_envio_id (INT)
   $3: cupon_id (INT o NULL)
   $4: items (STRING JSON)
   $5: NULL (para el OUT parameter pedido_id)

LÍNEA 127-130: Redirige exitosamente
return new Response(null, {
  status: 303,
  headers: { Location: '/pedidos' }
});

LÍNEA 132-139: Manejo de errores
} catch (error: any) {
  console.error('Error en operación de pedidos:', error);
  return new Response(null, {
    status: 303,
    headers: {
      Location: '/pedidos?error=' + encodeURIComponent(error.message)
    }
  });
}
```

---

## 5️⃣ PROCEDIMIENTOS DE BASE DE DATOS {#5-base-de-datos}

### 📄 Archivo: `database/functions_procedures_LIMPIO.sql`

#### **Líneas 152-245: sp_crear_pedido - PROCEDIMIENTO PRINCIPAL**

```sql
LÍNEA 152-158: Definición del procedimiento
────────────────────────────────────────────
CREATE OR REPLACE PROCEDURE sp_crear_pedido(
    p_cliente_id INT,              -- ID del cliente
    p_direccion_envio_id INT,      -- ID de dirección
    p_cupon_id INT,                -- ID del cupón (puede ser NULL)
    p_items JSONB,                 -- Array JSON de items
    OUT p_pedido_id INT            -- ID del pedido creado (output)
)

LÍNEA 159: LANGUAGE plpgsql
LÍNEA 160: AS $$

LÍNEA 161-167: Declaración de variables
DECLARE
    v_subtotal NUMERIC(12, 2) := 0;      -- Suma de productos
    v_descuento NUMERIC(12, 2) := 0;     -- Descuento del cupón
    v_impuestos NUMERIC(12, 2) := 0;     -- 15% de impuestos
    v_total NUMERIC(12, 2) := 0;         -- Total final
    v_item JSONB;                        -- Item actual del loop
    v_stock_id INT;                      -- ID del stock
    v_cantidad INT;                      -- Cantidad solicitada
    v_precio NUMERIC(10, 2);             -- Precio unitario
```

```sql
LÍNEA 168: BEGIN

LÍNEA 169-181: ⭐ PASO 1: Crear registro de pedido
INSERT INTO pedidos (
    cliente_id,
    direccion_envio_id,
    cupon_id,
    estado_pedido,
    subtotal,
    descuento_aplicado,
    impuestos,
    total_pedido
) VALUES (
    p_cliente_id,
    p_direccion_envio_id,
    p_cupon_id,
    'pendiente',          -- Estado inicial
    0, 0, 0, 0           -- Totales temporales
) RETURNING pedido_id INTO p_pedido_id;

🔑 TABLA AFECTADA: pedidos
🔑 ACCIÓN: INSERT
🔑 RESULTADO: Se obtiene el pedido_id generado
```

```sql
LÍNEA 183-222: ⭐ PASO 2: Procesar cada producto del JSON
FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
LOOP
    LÍNEA 185-186: Extrae datos del JSON
    v_stock_id := (v_item->>'stock_id')::INT;
    v_cantidad := (v_item->>'cantidad')::INT;

    LÍNEA 188-190: Valida stock disponible
    IF NOT fn_validar_stock_disponible(v_stock_id, v_cantidad) THEN
        RAISE EXCEPTION 'Stock insuficiente para SKU %', v_stock_id;
    END IF;

    LÍNEA 192: Obtiene precio actual
    v_precio := fn_obtener_precio_producto(v_stock_id);

    LÍNEA 194-200: Inserta detalle del pedido
    INSERT INTO detalle_pedido (
        pedido_id,
        stock_id,
        cantidad,
        precio_unitario_compra
    ) VALUES (
        p_pedido_id,
        v_stock_id,
        v_cantidad,
        v_precio
    );

    🔑 TABLA AFECTADA: detalle_pedido
    🔑 ACCIÓN: INSERT (uno por cada producto)

    LÍNEA 202-205: ⭐ RESERVA EL STOCK
    UPDATE stock
    SET cantidad_reservada = cantidad_reservada + v_cantidad
    WHERE stock_id = v_stock_id;

    🔑 TABLA AFECTADA: stock
    🔑 ACCIÓN: UPDATE (incrementa cantidad_reservada)
    🔑 IMPORTANCIA: ¡Stock queda reservado pero NO vendido!

    LÍNEA 207: Acumula subtotal
    v_subtotal := v_subtotal + (v_precio * v_cantidad);
END LOOP;
```

```sql
LÍNEA 224-225: ⭐ PASO 3: Calcula descuento del cupón
v_descuento := fn_calcular_descuento_cupon(p_cupon_id, v_subtotal);

🔑 LLAMA A: fn_calcular_descuento_cupon (línea 84)

LÍNEA 227: ⭐ PASO 4: Calcula impuestos (15%)
v_impuestos := (v_subtotal - v_descuento) * 0.15;

LÍNEA 229: ⭐ PASO 5: Calcula total
v_total := v_subtotal - v_descuento + v_impuestos;

FÓRMULA COMPLETA:
total = (subtotal - descuento) + ((subtotal - descuento) * 0.15)
```

```sql
LÍNEA 231-238: ⭐ PASO 6: Actualiza el pedido con totales
UPDATE pedidos
SET
    subtotal = v_subtotal,
    descuento_aplicado = v_descuento,
    impuestos = v_impuestos,
    total_pedido = v_total
WHERE pedido_id = p_pedido_id;

🔑 TABLA AFECTADA: pedidos
🔑 ACCIÓN: UPDATE (actualiza los totales calculados)
```

```sql
LÍNEA 240-245: ⭐ PASO 7: Reduce usos del cupón
IF p_cupon_id IS NOT NULL THEN
    UPDATE cupones
    SET usos_disponibles = usos_disponibles - 1
    WHERE cupon_id = p_cupon_id
        AND usos_disponibles > 0;
END IF;

🔑 TABLA AFECTADA: cupones
🔑 ACCIÓN: UPDATE (solo si hay cupón)

LÍNEA 247: Mensaje de éxito
RAISE NOTICE 'Pedido % creado exitosamente. Total: $%', p_pedido_id, v_total;

LÍNEA 248-249: Fin del procedimiento
END;
$$;
```

---

## 6️⃣ FUNCIONES AUXILIARES {#6-funciones-auxiliares}

### 📄 Archivo: `database/functions_procedures_LIMPIO.sql`

#### **Líneas 5-17: fn_validar_stock_disponible**

```sql
LÍNEA 5-8: Definición
CREATE OR REPLACE FUNCTION fn_validar_stock_disponible(
    p_stock_id INT,
    p_cantidad_solicitada INT
) RETURNS BOOLEAN AS $$

LÍNEA 9-10: Variable
DECLARE
    v_disponible INT;

LÍNEA 11: BEGIN

LÍNEA 12-16: Calcula stock disponible
SELECT (cantidad_en_stock - cantidad_reservada)
INTO v_disponible
FROM stock
WHERE stock_id = p_stock_id;

🔑 CÁLCULO: disponible = en_stock - reservada

LÍNEA 18: Retorna TRUE si hay suficiente
RETURN (v_disponible >= p_cantidad_solicitada);

LÍNEA 19-20: END;
END;
$$ LANGUAGE plpgsql;

🔑 USADA EN: sp_crear_pedido línea 188
```

#### **Líneas 84-114: fn_calcular_descuento_cupon**

```sql
LÍNEA 84-88: Definición
CREATE OR REPLACE FUNCTION fn_calcular_descuento_cupon(
    p_cupon_id INT,
    p_subtotal NUMERIC(12, 2)
) RETURNS NUMERIC(12, 2) AS $$

LÍNEA 89-92: Variables
DECLARE
    v_tipo_descuento VARCHAR(20);
    v_valor_descuento NUMERIC(10, 2);
    v_descuento NUMERIC(12, 2);

LÍNEA 93: BEGIN

LÍNEA 94-96: Si no hay cupón, retorna 0
IF p_cupon_id IS NULL THEN
    RETURN 0;
END IF;

LÍNEA 98-106: Obtiene datos del cupón
SELECT tipo_descuento, valor_descuento
INTO v_tipo_descuento, v_valor_descuento
FROM cupones
WHERE cupon_id = p_cupon_id
    AND estado = 'activo'
    AND (fecha_expiracion IS NULL OR fecha_expiracion >= CURRENT_DATE)
    AND (usos_disponibles IS NULL OR usos_disponibles > 0);

IF NOT FOUND THEN
    RETURN 0;
END IF;

LÍNEA 108-112: ⭐ Calcula descuento según tipo
IF v_tipo_descuento = 'porcentaje' THEN
    v_descuento := p_subtotal * (v_valor_descuento / 100);
ELSE  -- monto fijo
    v_descuento := v_valor_descuento;
END IF;

🔑 DOS TIPOS:
   - 'porcentaje': descuento = subtotal * (valor / 100)
   - 'fijo': descuento = valor

LÍNEA 114-117: Valida que no exceda el subtotal
IF v_descuento > p_subtotal THEN
    v_descuento := p_subtotal;
END IF;

LÍNEA 119: RETURN v_descuento;

LÍNEA 120-121: END;
END;
$$ LANGUAGE plpgsql;

🔑 USADA EN: sp_crear_pedido línea 224
```

#### **Líneas 187-201: fn_obtener_precio_producto**

```sql
LÍNEA 187-189: Definición
CREATE OR REPLACE FUNCTION fn_obtener_precio_producto(p_stock_id INT)
RETURNS NUMERIC(10, 2) AS $$

LÍNEA 190-191: Variable
DECLARE
    v_precio NUMERIC(10, 2);

LÍNEA 192: BEGIN

LÍNEA 193-198: Obtiene precio actual
SELECT precio_unitario
INTO v_precio
FROM stock
WHERE stock_id = p_stock_id
    AND estado = 'activo';

🔑 TABLA: stock
🔑 CAMPO: precio_unitario

LÍNEA 200: RETURN COALESCE(v_precio, 0);

🔑 COALESCE: Si es NULL, retorna 0

LÍNEA 201-202: END;
END;
$$ LANGUAGE plpgsql;

🔑 USADA EN: sp_crear_pedido línea 192
```

---

## 📊 RESUMEN DE TABLAS AFECTADAS

| Orden | Tabla | Operación | Línea en sp_crear_pedido | Descripción |
|-------|-------|-----------|--------------------------|-------------|
| 1 | `pedidos` | INSERT | 169-181 | Crea el pedido en estado pendiente |
| 2 | `detalle_pedido` | INSERT | 194-200 | Inserta cada producto (loop) |
| 3 | `stock` | UPDATE | 202-205 | Reserva cantidades (loop) |
| 4 | `pedidos` | UPDATE | 231-238 | Actualiza totales calculados |
| 5 | `cupones` | UPDATE | 240-245 | Reduce usos disponibles (si aplica) |

---

## 🔄 FLUJO DE DATOS COMPLETO

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. FRONTEND: src/pages/pedidos/index.astro                     │
│    - Líneas 528-562: cargarDirecciones()                       │
│    - Líneas 585-612: agregarItem()                             │
│    - Líneas 710-773: Validación y construcción JSON            │
│    - Línea 318: <form action="/api/pedidos" method="POST">     │
└──────────────────────┬──────────────────────────────────────────┘
                       │ POST FormData
                       │ { cliente_id, direccion_envio_id,
                       │   cupon_id, items: "[{...}]" }
                       ▼
┌─────────────────────────────────────────────────────────────────┐
│ 2. API: src/pages/api/pedidos/index.ts                         │
│    - Línea 35: export const POST                               │
│    - Líneas 110-117: Extrae datos del FormData                 │
│    - Línea 121-125: await query('CALL sp_crear_pedido...')     │
└──────────────────────┬──────────────────────────────────────────┘
                       │ SQL CALL
                       │ sp_crear_pedido($1, $2, $3, $4, NULL)
                       ▼
┌─────────────────────────────────────────────────────────────────┐
│ 3. DB: database/functions_procedures_LIMPIO.sql                 │
│    - Líneas 152-249: sp_crear_pedido()                         │
│                                                                 │
│    PASO 1 (Línea 169): INSERT INTO pedidos                     │
│    PASO 2 (Línea 183): FOR LOOP sobre items JSON               │
│      ├─ Línea 188: CALL fn_validar_stock_disponible()          │
│      ├─ Línea 192: CALL fn_obtener_precio_producto()           │
│      ├─ Línea 194: INSERT INTO detalle_pedido                  │
│      └─ Línea 202: UPDATE stock (reservar)                     │
│    PASO 3 (Línea 224): CALL fn_calcular_descuento_cupon()      │
│    PASO 4 (Línea 227): Calcular impuestos (15%)                │
│    PASO 5 (Línea 229): Calcular total                          │
│    PASO 6 (Línea 231): UPDATE pedidos (totales)                │
│    PASO 7 (Línea 240): UPDATE cupones (usos)                   │
└──────────────────────┬──────────────────────────────────────────┘
                       │ COMMIT / ROLLBACK
                       ▼
┌─────────────────────────────────────────────────────────────────┐
│ 4. RESPUESTA                                                    │
│    - API línea 127: Redirect 303 a /pedidos                    │
│    - Frontend recarga y muestra nuevo pedido                   │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🎯 PUNTOS CRÍTICOS A ANALIZAR

### 🔴 CRÍTICO 1: Reserva de Stock
**Ubicación:** `sp_crear_pedido` línea 202-205
```sql
UPDATE stock
SET cantidad_reservada = cantidad_reservada + v_cantidad
WHERE stock_id = v_stock_id;
```
**Impacto:** El stock queda bloqueado para otros pedidos

### 🔴 CRÍTICO 2: Validación de Stock
**Ubicación:** `fn_validar_stock_disponible` líneas 12-16
```sql
SELECT (cantidad_en_stock - cantidad_reservada)
INTO v_disponible
FROM stock
WHERE stock_id = p_stock_id;
```
**Impacto:** Si falla, el pedido se cancela completamente

### 🔴 CRÍTICO 3: Cálculo de Totales
**Ubicación:** `sp_crear_pedido` líneas 224-229
```sql
v_descuento := fn_calcular_descuento_cupon(p_cupon_id, v_subtotal);
v_impuestos := (v_subtotal - v_descuento) * 0.15;
v_total := v_subtotal - v_descuento + v_impuestos;
```
**Fórmula:** `total = subtotal - descuento + ((subtotal - descuento) * 0.15)`

### 🔴 CRÍTICO 4: Transaccionalidad
**Todo el procedimiento `sp_crear_pedido` es atómico:**
- Si cualquier INSERT/UPDATE falla, TODO se revierte
- No quedan datos inconsistentes
- El COMMIT solo ocurre si todo tiene éxito

---

## 📝 NOTAS FINALES

### Variables de Entrada (Frontend → API)
- `cliente_id`: INTEGER
- `direccion_envio_id`: INTEGER
- `cupon_id`: INTEGER | NULL
- `items`: STRING (JSON) ejemplo: `'[{"stock_id":5,"cantidad":2}]'`

### Variables Calculadas (Base de Datos)
- `subtotal`: Suma de (precio × cantidad) de todos los items
- `descuento`: Según tipo de cupón (% o fijo)
- `impuestos`: (subtotal - descuento) × 0.15
- `total_pedido`: subtotal - descuento + impuestos

### Estado del Pedido
- **Creación:** `'pendiente'` (línea 177)
- **Después de pago:** `'pagado'` (ver sp_procesar_pago)
- **Después de envío:** `'enviado'` (ver sp_actualizar_estado_envio)
- **Entregado:** `'completado'`
- **Si se cancela:** `'cancelado'` (ver sp_cancelar_pedido)

---

**📅 Generado:** Diciembre 1, 2025
**🎯 Propósito:** Documentación técnica para análisis del flujo de pedidos
