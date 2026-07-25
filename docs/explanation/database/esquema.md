# Esquema y decisiones de diseño

> Estructura exhaustiva por tabla → [`docs/reference/database/`](../../reference/database/README.md) (generada por `tbls`).
> Este documento explica los **patrones y decisiones** que la reference no cuenta. Verificado contra la base viva.

## Las 13 tablas

`auditoria`, `categorias`, `clientes`, `cupones`, `detalle_pedido`, `devoluciones`, `direcciones`, `envios`, `historial_estados`, `pagos`, `pedidos`, `productos`, `stock`.

## Patrones de diseño (verificados)

- **Convención uniforme**: casi toda tabla tiene PK `serial` (`<tabla>_id`), una columna `estado varchar` con default `'activo'`, y `fecha_creacion` / `fecha_modificacion`.
- **Borrado lógico**: el `estado` habilita el patrón "desactivar en vez de borrar" (lo aplican los procedimientos `sp_eliminar_*`, ver [`funciones-y-reglas.md`](./funciones-y-reglas.md)).
- **Montos**: `numeric(12,2)` para totales de `pedidos`/`pagos`; `numeric(10,2)` para precios y descuentos unitarios. Sin floats: precisión monetaria correcta.
- **`clientes.hash_contrasena`** existe → sugiere credenciales, pero **verificado (Capa 2)**: guarda la contraseña en **texto plano** con prefijo `"hash_"` (sin hashing real) y **ningún endpoint la usa para login**. Nombre engañoso → ver [`../../remediacion.md`](../../remediacion.md) (S2).

## Relaciones (las 12 FKs)

```
categorias ─< productos ─< stock ─< detalle_pedido >─ pedidos >─ clientes
                                                        │           └─< direcciones
                                                        ├─< envios
                                                        ├─< pagos
                                                        ├─< historial_estados
                                                        └── cupones (opcional)
detalle_pedido ─< devoluciones
```

- **Decisión clave**: `detalle_pedido` referencia **`stock`**, no `productos` directamente. Un ítem de pedido apunta a una fila de stock concreta (`stock_id`), y desde ahí se llega al producto (`stock.producto_id`). Esto se confirmó de forma independiente en la vista `mv_productos_top_ventas`, que hace el join `detalle_pedido → stock → productos`.
- `direcciones` cuelga de `clientes`; `pedidos` referencia una `direccion_id` (dirección de envío) y opcionalmente un `cupon_id`.

## Ciclo de vida del pedido (CHECK constraint)

`pedidos.estado_pedido` está restringido por un CHECK a:
```
{ pendiente, pagado, enviado, completado, cancelado }
```
La transición entre estos estados no es libre: la gobiernan los procedimientos transaccionales. Ver la máquina de estados en [`funciones-y-reglas.md`](./funciones-y-reglas.md).

## Auditoría por triggers

Cada operación (INSERT/UPDATE/DELETE) sobre las tablas de negocio queda registrada en la tabla **`auditoria`** (con `datos_anteriores` / `datos_nuevos` en `jsonb`). Lo hacen triggers como `trg_auditoria_pedidos`. La lógica de esos triggers se explica en [`funciones-y-reglas.md`](./funciones-y-reglas.md) (Familia 1).
