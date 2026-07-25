# Mapeo endpoint → SQL

> Qué tabla / función / procedimiento toca cada uno de los 29 endpoints de `src/pages/api/`.
> Verificado con `ast-grep` + lectura de cada archivo (2026-07-23). El SQL está literal en el código.
> Detalle de cada función/procedimiento → [`../database/funciones-y-reglas.md`](../database/funciones-y-reglas.md).

## Analytics (`api/analytics/*`) — alimentan los charts

| Endpoint | Método | SQL que ejecuta |
|----------|--------|-----------------|
| `dashboard.ts` | GET | `fn_estadisticas_dashboard()` |
| `ventas-diarias.ts` | GET | `fn_ventas_diarias($dias)` |
| `ventas-categoria.ts` | GET | `fn_ventas_por_categoria($limite)` |
| `tendencia-pedidos.ts` | GET | `fn_tendencia_pedidos($dias)` |
| `distribucion-estados.ts` | GET | `fn_distribucion_estados_pedidos()` |
| `clientes-vip.ts` | GET / POST | GET lee `mv_clientes_vip`; **POST** hace `REFRESH MATERIALIZED VIEW CONCURRENTLY mv_clientes_vip` |
| `top-productos.ts` | GET / POST | GET lee `mv_productos_top_ventas`; **POST** hace `REFRESH ... mv_productos_top_ventas` |

## Pedidos (`api/pedidos/*`) — el núcleo transaccional

| Endpoint | Método | SQL que ejecuta |
|----------|--------|-----------------|
| `pedidos/index.ts` | GET | `SELECT` de `pedidos` ⨝ `clientes` ⨝ `direcciones` ⨝ `cupones` |
| | POST | `CALL sp_crear_pedido(...)` |
| | POST `_method=PATCH` | `CALL sp_aplicar_cupon_pedido($id,$codigo)` |
| | POST `_method=DELETE` | `CALL sp_cancelar_pedido($id,$motivo)` o `CALL sp_eliminar_pedido($id)` (según `eliminar_fisico`) |
| `pedidos/detalles.ts` | GET | `SELECT` de `detalle_pedido` ⨝ `stock` ⨝ `productos` ⨝ `categorias` |
| `pedidos/timeline.ts` | GET | `fn_obtener_timeline_pedido($id)` |
| | POST/PATCH | `fn_cambiar_estado_pedido(...)` |

## Clientes (`api/clientes/*`)

| Endpoint | Método | SQL que ejecuta |
|----------|--------|-----------------|
| `clientes/index.ts` | GET | `SELECT` de `clientes` |
| | POST | `INSERT INTO clientes (...)` |
| | PUT | `UPDATE clientes ...` |
| | DELETE | `CALL sp_eliminar_cliente($id)` |
| `clientes/direcciones.ts` | GET | `SELECT` de `direcciones` |
| `clientes/puntos-fidelidad.ts` | GET | `fn_calcular_puntos_fidelidad($id)` + `SELECT nombre,apellido FROM clientes` |
| `clientes/tiene-pedidos.ts` | GET | `fn_cliente_tiene_pedidos($id)` |

## Productos / stock / inventario

| Endpoint | Método | SQL que ejecuta |
|----------|--------|-----------------|
| `productos/index.ts` | GET | `SELECT` de `productos` ⨝ `categorias` ⨝ `stock` |
| | POST/PUT | `INSERT`/`UPDATE productos`, `UPDATE stock` |
| | DELETE | `CALL sp_eliminar_producto($id)` |
| `productos/ajustar-precios.ts` | POST | `CALL sp_ajustar_precios_categoria(...)` |
| `stock/index.ts` | GET | `SELECT` de `stock` ⨝ `productos` ⨝ `categorias` |
| | POST/PUT | `INSERT`/`UPDATE stock` |
| | DELETE | `CALL sp_eliminar_stock($id)` |
| `stock/reabastecer.ts` | POST | `CALL sp_reabastecer_stock(...)` |
| `inventario/alertas-stock.ts` | GET | `fn_alerta_stock_bajo($umbral)` |

## Cupones / devoluciones / pagos / envíos / categorías / direcciones / auditoría

| Endpoint | Método | SQL que ejecuta |
|----------|--------|-----------------|
| `categorias/index.ts` | GET/POST/PUT/DELETE | CRUD directo sobre `categorias` |
| `direcciones/index.ts` | POST/PUT | `INSERT`/`UPDATE direcciones` |
| `cupones/index.ts` | GET/POST/PUT/DELETE | CRUD directo sobre `cupones` |
| `cupones/validar.ts` | GET | `fn_validar_cupon_aplicable(...)` + `SELECT FROM cupones` |
| `devoluciones/index.ts` | GET | `SELECT` de `devoluciones` ⨝ `detalle_pedido` ⨝ `pedidos` ⨝ `clientes` ⨝ `stock` ⨝ `productos` |
| | POST | `CALL sp_procesar_devolucion(...)` |
| `devoluciones/validar.ts` | GET | `fn_validar_devolucion_permitida($id)` |
| `devoluciones/calcular-reembolso.ts` | GET | `fn_calcular_monto_reembolso(...)` |
| `pagos/index.ts` | GET | `SELECT` de `pagos` ⨝ `pedidos` ⨝ `clientes` |
| | POST | `CALL sp_procesar_pago(...)` |
| | DELETE | `CALL sp_eliminar_pago($id)` |
| `envios/index.ts` | GET | `SELECT` de `envios` ⨝ `pedidos` ⨝ `clientes` |
| | POST | `INSERT INTO envios (...)` |
| | PUT | `CALL sp_actualizar_estado_envio(...)` |
| `auditoria/historial.ts` | GET | `fn_historial_cambios($1,$2,$3)` + `SELECT FROM auditoria` |

---

## Comportamientos verificados de este mapeo

Descripción de cómo se comporta realmente la capa endpoint→SQL. Los **fixes accionables** de estos puntos están en [`../../remediacion.md`](../../remediacion.md).

### 1. Las vistas materializadas se refrescan a mano, no automáticamente
Los GET de `clientes-vip.ts` y `top-productos.ts` **leen** la matview sin refrescarla. El `REFRESH MATERIALIZED VIEW CONCURRENTLY` está en un **POST separado** de cada endpoint, que hay que invocar explícitamente. → Si nadie llama ese POST, los rankings quedan desactualizados. (Ver remediación D2.)

### 2. `hash_contrasena` NO es un hash — es texto plano disfrazado
En `clientes/index.ts` (líneas 43 y 72): `const hashContrasena = ` `` `hash_${contrasena}` ``. Es la contraseña en claro con el prefijo literal `"hash_"`, sin ninguna función criptográfica. Además **ningún endpoint la lee ni compara** → no hay login real. Es una columna cosmética de proyecto académico. `hash_contrasena` es un nombre engañoso. (Ver remediación S2.)

### 3. No todas las rutinas de la BD se invocan desde `api/`
El barrido de `api/` invoca 14 funciones + 13 procedimientos. Varias rutinas no se llaman desde los endpoints: las 10 funciones de trigger (correcto: las dispara la BD, no la app) y cálculos internos usados por los `sp_*` (`fn_calcular_descuento_cupon`, etc.). El cruce completo (endpoints + páginas `.astro` + llamadas internas) que confirma qué es realmente código muerto está en [`paginas-y-componentes.md`](./paginas-y-componentes.md).
