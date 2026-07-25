# Funciones, procedimientos y reglas de negocio

> **Inventario + firmas** (retorno y argumentos) → [`docs/reference/database/README.md`](../../reference/database/README.md) (generado por `tbls`).
> Este documento explica **qué hace cada familia y qué reglas de negocio embebe**. No pega los cuerpos: viven en la base viva y en `database/functions_procedures_LIMPIO.sql`.
> Leer un cuerpo real:
> ```bash
> docker exec ecommerce_db psql -U postgres -d ecommerce_db -c "SELECT pg_get_functiondef('nombre'::regproc);"
> ```
> Verificado leyendo las 49 definiciones reales (2026-07-23).

Las 49 rutinas (35 funciones + 14 procedimientos) se agrupan en 5 familias.

## Familia 1 — Triggers (10 funciones `RETURNS trigger`)

- **`fn_auditoria_<tabla>`** (8: categorias, clientes, cupones, pagos, pedidos, productos, stock) + **`fn_auditoria_generica`** → en INSERT/UPDATE/DELETE insertan en `auditoria` el `row_to_json` de OLD/NEW (jsonb), tabla, operación, `registro_id` y `current_user`. La genérica hace lo mismo resolviendo la PK con `TG_TABLE_NAME`.
- **`fn_actualizar_fecha_modificacion`** → setea `fecha_modificacion = NOW()` en UPDATE si la fila cambió (`OLD IS DISTINCT FROM NEW`).
- **`fn_registrar_cambio_estado`** → sobre `pedidos`, al crear o cambiar `estado_pedido`, inserta en `historial_estados` con un comentario mapeado por estado (`pagado`→"Pago confirmado", etc.). Es lo que alimenta el timeline.

> ⚠️ **Hallazgo abierto**: coexisten los 8 triggers por-tabla **y** `fn_auditoria_generica` (misma lógica). `tbls` mostró que `pedidos` usa el específico (`trg_auditoria_pedidos`). Probable redundancia / código muerto — a confirmar qué usa cada tabla realmente.

## Familia 2 — Cálculos de negocio (8, retornan `numeric`/`int`)

| Función | Qué calcula | Regla verificada |
|---------|-------------|------------------|
| `fn_calcular_total_pedido` | Suma `cantidad * precio_unitario_compra` de `detalle_pedido` | — |
| `fn_calcular_descuento_cupon` | Descuento de un cupón sobre un subtotal | `porcentaje` o `fijo`; topeado al subtotal; 0 si cupón inválido/expirado |
| `fn_calcular_comision_venta` | Comisión de un pedido | **5%** del total |
| `fn_calcular_monto_reembolso` | Reembolso de una devolución | `precio_unitario_compra * cantidad`; excepción si se devuelve más de lo comprado |
| `fn_calcular_puntos_fidelidad` | Puntos de un cliente | **1 punto por cada $10** gastado (`FLOOR`), solo pedidos pagado/enviado/completado |
| `fn_calcular_tiempo_entrega` | Días desde `fecha_envio` | — |
| `fn_calcular_total_ventas_periodo` | Ventas entre 2 fechas | solo estados pagado/enviado/completado |
| `fn_obtener_precio_producto` | Precio de un SKU activo | — |

## Familia 3 — Validaciones y operaciones (5, retornan `boolean`)

- `fn_validar_stock_disponible` → `(cantidad_en_stock - cantidad_reservada) >= solicitado`.
- `fn_validar_cupon_aplicable` → cupón activo, no expirado, con usos disponibles.
- `fn_validar_devolucion_permitida` → pedido `completado`/`enviado`, con `fecha_envio`, **≤ 30 días**.
- `fn_cliente_tiene_pedidos` → boolean (lo usa `sp_eliminar_cliente`).
- `fn_cambiar_estado_pedido` → cambia `estado_pedido` (el trigger registra el cambio); admite comentario custom.

## Familia 4 — Reportes / analytics (12, retornan `TABLE`)

Alimentan los charts de la app:
`fn_estadisticas_dashboard`, `fn_ventas_diarias`, `fn_ventas_por_categoria`, `fn_tendencia_pedidos`, `fn_distribucion_estados_pedidos`, `fn_obtener_productos_mas_vendidos`, `fn_metricas_producto`, `fn_obtener_clientes_frecuentes`, `fn_alerta_stock_bajo` (niveles CRÍTICO/URGENTE/ADVERTENCIA/NORMAL), `fn_obtener_timeline_pedido`, `fn_estadisticas_estados`, `fn_historial_cambios`.

> Se cruzan con los endpoints `api/analytics/*` en la Capa 2 (mapeo pendiente).

## Familia 5 — Procedimientos transaccionales (14)

**Ciclo de vida del pedido:**
- `sp_crear_pedido(cliente, direccion, cupon, items jsonb)` → crea pedido `pendiente`, valida stock, **reserva** stock, calcula subtotal/descuento/**impuesto 15%**/total.
- `sp_aplicar_cupon_pedido` → solo a pedidos `pendiente`; recalcula total; decrementa usos del cupón.
- `sp_procesar_pago` → valida `monto == total`; registra pago `exitoso`; pedido → `pagado`; **descuenta el stock físico y libera la reserva** (vía `CALL sp_actualizar_stock_compra`, fix V1); **crea envío** `en_preparacion`.
- `sp_actualizar_estado_envio` → envío `en_transito` ⇒ pedido `enviado`; `entregado` ⇒ pedido `completado`.
- `sp_cancelar_pedido` → solo si NO enviado/completado; **libera reserva** de stock; pedido → `cancelado`; envío → `fallido`.
- `sp_actualizar_stock_compra` → descuenta stock real (`cantidad_en_stock`) y libera reserva. La invoca **`sp_procesar_pago`** (tras marcar el pedido `pagado`, en la misma transacción). Hasta el 2026-07-24 era código muerto y el flujo crear→pagar nunca descontaba el físico; se cableó al resolver el bug → ver [`../../remediacion.md`](../../remediacion.md) (V1, `Resuelto`).
- `sp_procesar_devolucion` → valida permiso; registra devolución; **libera reserva sin reponer stock físico**; genera pago `reembolsado`.
- `sp_reabastecer_stock`, `sp_ajustar_precios_categoria` (ajuste % por categoría).

**Eliminaciones con guardas ("desactivar en vez de borrar"):**
- `sp_eliminar_cliente` (bloquea si tiene pedidos), `sp_eliminar_producto` (bloquea si tiene stock/pedidos), `sp_eliminar_stock` (bloquea si reservado o con histórico), `sp_eliminar_pedido` (solo `cancelado`), `sp_eliminar_pago` (solo `fallido`/`pendiente`).

---

## Reglas de negocio verificadas (constantes del dominio)

| Regla | Valor | Dónde |
|-------|-------|-------|
| Impuesto | **15%** sobre `(subtotal - descuento)` | `sp_crear_pedido`, `sp_aplicar_cupon_pedido` |
| Comisión de venta | **5%** del total | `fn_calcular_comision_venta` |
| Fidelidad | **1 punto / $10** gastado | `fn_calcular_puntos_fidelidad` |
| Ventana de devolución | **≤ 30 días** desde el envío | `fn_validar_devolucion_permitida` |

**Reserva de stock**: se reserva al crear el pedido, se libera al cancelar/devolver, se descuenta del físico al procesar la compra. La devolución **no repone stock físico** (solo libera la reserva).

## Máquina de estados del pedido (verificada en el código)

```
pendiente ──sp_procesar_pago──▶ pagado ──envío en_transito──▶ enviado ──envío entregado──▶ completado
   │
   └──sp_cancelar_pedido──▶ cancelado   (solo desde pendiente/pagado)
```
