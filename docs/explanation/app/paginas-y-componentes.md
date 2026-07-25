# Páginas y componentes

> Las 10 páginas `.astro` y los componentes de `src/components/`, y cómo obtienen datos.
> Verificado con `ast-grep` + lectura directa (2026-07-23).

## Arquitectura de acceso a datos: tres vías

La app **no** centraliza el acceso a datos en los endpoints. Cada página `.astro` usa hasta tres vías:

1. **SSR directo** — el frontmatter de la página importa `query` de `src/lib/db` y hace `SELECT` en el servidor para la **carga inicial** (render). Se salta los endpoints.
2. **Form POST** — `<form action="/api/..." method="POST">` para mutaciones (crear/editar/eliminar), con redirect 303. Usa el patrón `_method` (PATCH/DELETE simulados por campo oculto).
3. **Client `fetch`** — JavaScript del navegador que llama `/api/...` para consultas dinámicas (validar cupón, ver puntos, timeline).

## Mapeo página → datos

| Página | SSR (lectura directa a BD) | Endpoints que consume (form/fetch) | Componentes |
|--------|----------------------------|------------------------------------|-------------|
| `index.astro` (dashboard) | `fn_estadisticas_dashboard()`, `fn_alerta_stock_bajo(15)`, `mv_productos_top_ventas`, `mv_clientes_vip`, `auditoria` | — | charts |
| `categorias/index.astro` | `SELECT categorias` | `POST /api/categorias` | — |
| `clientes/index.astro` | `SELECT clientes` | `POST /api/clientes`; `fetch` tiene-pedidos, puntos-fidelidad, direcciones; `/api/direcciones` | — |
| `cupones/index.astro` | `SELECT cupones` | `POST /api/cupones`; `fetch /api/cupones/validar` | — |
| `devoluciones/index.astro` | `SELECT devoluciones` + detalles | `POST /api/devoluciones` | — |
| `envios/index.astro` | `SELECT envios` + pedidos | `POST /api/envios` (×2) | — |
| `pagos/index.astro` | `SELECT pagos` | `POST /api/pagos`; `fetch /api/pagos` | — |
| `pedidos/index.astro` | `SELECT pedidos` | `POST /api/pedidos` (×3: crear/cancelar/cupón); `fetch /api/pedidos/timeline` | timeline |
| `productos/index.astro` | `SELECT productos` + categorías | `POST /api/productos`; `fetch /api/productos/ajustar-precios` | — |
| `stock/index.astro` | `SELECT stock` + productos | `POST /api/stock`, `/api/stock/reabastecer` | — |

## Componentes (`src/components/`)

Todos son **presentacionales** (patrón container-presentational): reciben datos por props, no tocan la BD.

- **`charts/`** (`BarChart`, `LineChart`, `DoughnutChart`, `ChartWrapper`) — envuelven `chart.js`. Los alimenta el dashboard con los datos que trae por SSR / los endpoints `analytics/*`.
- **`timeline/`** (`Timeline`, `TimelineItem`) — renderizan el historial de estados; se nutren de `/api/pedidos/timeline` (→ `fn_obtener_timeline_pedido`).
- **`Icon.astro`** — utilitario de iconos.

---

## Comportamientos verificados

Descripción de cómo la app accede realmente a los datos. Los **fixes accionables** están en [`../../remediacion.md`](../../remediacion.md).

### 1. No hay una única capa de acceso a datos (deuda arquitectónica)
La misma información se consulta en **dos lugares con SQL duplicado**: el SSR de una página y el `GET` de su endpoint homónimo hacen `SELECT` casi idénticos. Ej.: `productos/index.astro` (SSR) y `GET /api/productos` consultan `productos ⨝ categorias ⨝ stock` por separado. Cualquier cambio de esquema obliga a tocar los dos.

### 2. El dashboard lee las matviews sin refrescarlas
`index.astro` lee `mv_productos_top_ventas` y `mv_clientes_vip` directamente, sin `REFRESH`. Refuerza el hallazgo de la 2.2: la pantalla principal puede mostrar rankings desactualizados salvo que alguien invoque el POST de refresh a mano.

### 3. Código muerto confirmado por triple cruce
Estas rutinas **no se invocan desde ningún lado** — verificado en (a) `api/`, (b) páginas `.astro` + componentes, (c) llamadas internas entre funciones de la BD (dump de las 49 definiciones, 1 sola aparición = solo su `CREATE`):

| Rutina | Tipo | Uso |
|--------|------|-----|
| `fn_obtener_productos_mas_vendidos` | reporte | ninguno |
| `fn_metricas_producto` | reporte | ninguno |
| `fn_obtener_clientes_frecuentes` | reporte | ninguno |
| `fn_estadisticas_estados` | reporte | ninguno |
| `fn_calcular_total_pedido` | cálculo | ninguno |
| `fn_calcular_comision_venta` | cálculo | ninguno |
| `fn_calcular_tiempo_entrega` | cálculo | ninguno |
| `fn_calcular_total_ventas_periodo` | cálculo | ninguno |

En cambio, sí se usan internamente (no son muertas): `fn_calcular_descuento_cupon`, `fn_validar_stock_disponible`, `fn_obtener_precio_producto`.

> ✅ `sp_actualizar_stock_compra` **salió de esta lista el 2026-07-24**: era la 9ª rutina muerta y era la causa de un bug (el flujo crear→pagar no descontaba el stock físico). Se cableó dentro de `sp_procesar_pago` y quedó viva. Ver remediación V1 (`Resuelto`) → [`../../remediacion.md`](../../remediacion.md).
