# Vistas y vistas materializadas

> **Estructura** (columnas de cada vista) → [`docs/reference/database/`](../../reference/database/README.md) (generada por `tbls`).
> Este documento explica **qué resuelve cada vista y qué reglas embebe**.
> Leer una definición real:
> ```bash
> docker exec ecommerce_db psql -U postgres -d ecommerce_db -c "SELECT pg_get_viewdef('nombre'::regclass, true);"
> ```
> Verificado leyendo las 3 definiciones reales (2026-07-23).

Hay **1 vista normal** y **2 vistas materializadas**.

## `vw_timeline_pedidos` (vista normal)

Aplana el **historial de estados** de cada pedido con contexto de cliente y monto.
- **Une:** `historial_estados` → `pedidos` → `clientes`.
- **Expone:** `estado_anterior`/`estado_nuevo`, `usuario`, `comentario`, `fecha_cambio`, más `nombre_cliente` (concatenado), `total_pedido` y `fecha_pedido`.
- **Orden:** `fecha_cambio DESC`.
- **Alimenta:** el timeline de la app. Las filas de `historial_estados` las escribe el trigger `fn_registrar_cambio_estado` (ver [`funciones-y-reglas.md`](./funciones-y-reglas.md), Familia 1).

## `mv_clientes_vip` (materializada)

Segmenta clientes por valor de compra.
- **Une:** `clientes` → `pedidos`; solo estados `pagado`/`enviado`/`completado` y cliente `activo`.
- **Métricas:** `total_pedidos`, `total_gastado`, `ticket_promedio`, `primera_compra`, `ultima_compra`.
- **Filtro (HAVING):** entra si `total_pedidos >= 3` **o** `total_gastado >= 500`.
- **Categoría VIP (regla verificada):**

  | Nivel | Condición |
  |-------|-----------|
  | Platinum | `total_gastado >= 1000` |
  | Gold | `total_gastado >= 500` |
  | Silver | `total_pedidos >= 5` |
  | Bronze | resto |

- **Orden:** `total_gastado DESC`.

## `mv_productos_top_ventas` (materializada)

Ranking de productos por unidades vendidas.
- **Une:** `productos` → `categorias` → `stock` → `detalle_pedido` → `pedidos`; solo estados `pagado`/`enviado`/`completado` y producto `activo`.
- **Métricas:** `total_vendido` (unidades), `ingresos_totales`, `num_pedidos` (distinct), `precio_promedio`.
- **Orden:** `total_vendido DESC`.
- **Confirma la decisión de esquema**: el join al producto pasa por `detalle_pedido.stock_id → stock → productos`. `detalle_pedido` no referencia `productos` directamente (ver [`esquema.md`](./esquema.md)).

---

## Nota operativa: las matviews no se refrescan solas

`mv_clientes_vip` y `mv_productos_top_ventas` son **materializadas**: sus datos quedan congelados hasta un `REFRESH MATERIALIZED VIEW`.

> ⚠️ **Verificado (Capa 2)**: el `REFRESH` lo dispara un `POST` **manual** en los endpoints `clientes-vip.ts` / `top-productos.ts`; el `GET` (y el dashboard SSR) leen la matview **sin refrescarla**. Si nadie llama ese POST, los rankings quedan desactualizados → ver [`../../remediacion.md`](../../remediacion.md) (D2).
