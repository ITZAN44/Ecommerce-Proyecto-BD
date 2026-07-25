# ecommerce_db

## Tables

| Name | Columns | Comment | Type |
| ---- | ------- | ------- | ---- |
| [public.auditoria](public.auditoria.md) | 9 |  | BASE TABLE |
| [public.categorias](public.categorias.md) | 6 |  | BASE TABLE |
| [public.clientes](public.clientes.md) | 8 |  | BASE TABLE |
| [public.cupones](public.cupones.md) | 9 |  | BASE TABLE |
| [public.detalle_pedido](public.detalle_pedido.md) | 6 |  | BASE TABLE |
| [public.devoluciones](public.devoluciones.md) | 7 |  | BASE TABLE |
| [public.direcciones](public.direcciones.md) | 9 |  | BASE TABLE |
| [public.envios](public.envios.md) | 8 |  | BASE TABLE |
| [public.historial_estados](public.historial_estados.md) | 7 | Historial de cambios de estado para timeline visual de pedidos. <br />Complementa la tabla auditoria con información específica para UX. | BASE TABLE |
| [public.pedidos](public.pedidos.md) | 11 |  | BASE TABLE |
| [public.mv_clientes_vip](public.mv_clientes_vip.md) | 10 |  | MATERIALIZED VIEW |
| [public.productos](public.productos.md) | 7 |  | BASE TABLE |
| [public.stock](public.stock.md) | 9 |  | BASE TABLE |
| [public.mv_productos_top_ventas](public.mv_productos_top_ventas.md) | 8 |  | MATERIALIZED VIEW |
| [public.pagos](public.pagos.md) | 8 |  | BASE TABLE |
| [public.vw_timeline_pedidos](public.vw_timeline_pedidos.md) | 11 | Vista combinada de historial de estados con información del pedido y cliente. <br />Optimizada para listados de actividad reciente. | VIEW |

## Stored procedures and functions

| Name | ReturnType | Arguments | Type |
| ---- | ------- | ------- | ---- |
| public.fn_actualizar_fecha_modificacion | trigger |  | FUNCTION |
| public.fn_alerta_stock_bajo | record | p_limite integer DEFAULT 15 | FUNCTION |
| public.fn_auditoria_categorias | trigger |  | FUNCTION |
| public.fn_auditoria_clientes | trigger |  | FUNCTION |
| public.fn_auditoria_cupones | trigger |  | FUNCTION |
| public.fn_auditoria_generica | trigger |  | FUNCTION |
| public.fn_auditoria_pagos | trigger |  | FUNCTION |
| public.fn_auditoria_pedidos | trigger |  | FUNCTION |
| public.fn_auditoria_productos | trigger |  | FUNCTION |
| public.fn_auditoria_stock | trigger |  | FUNCTION |
| public.fn_calcular_comision_venta | numeric | p_pedido_id integer | FUNCTION |
| public.fn_calcular_descuento_cupon | numeric | p_cupon_id integer, p_subtotal numeric | FUNCTION |
| public.fn_calcular_monto_reembolso | numeric | p_detalle_id integer, p_cantidad_devuelta integer | FUNCTION |
| public.fn_calcular_puntos_fidelidad | int4 | p_cliente_id integer | FUNCTION |
| public.fn_calcular_tiempo_entrega | int4 | p_envio_id integer | FUNCTION |
| public.fn_calcular_total_pedido | numeric | p_pedido_id integer | FUNCTION |
| public.fn_calcular_total_ventas_periodo | numeric | p_fecha_desde timestamp without time zone, p_fecha_hasta timestamp without time zone | FUNCTION |
| public.fn_cambiar_estado_pedido | bool | p_pedido_id integer, p_nuevo_estado character varying, p_comentario text DEFAULT NULL::text | FUNCTION |
| public.fn_cliente_tiene_pedidos | bool | p_cliente_id integer | FUNCTION |
| public.fn_distribucion_estados_pedidos | record |  | FUNCTION |
| public.fn_estadisticas_dashboard | record |  | FUNCTION |
| public.fn_estadisticas_estados | record | p_pedido_id integer | FUNCTION |
| public.fn_historial_cambios | record | p_tabla character varying, p_registro_id integer, p_limite integer DEFAULT 50 | FUNCTION |
| public.fn_metricas_producto | record | p_producto_id integer | FUNCTION |
| public.fn_obtener_clientes_frecuentes | record | p_limite integer DEFAULT 10 | FUNCTION |
| public.fn_obtener_precio_producto | numeric | p_stock_id integer | FUNCTION |
| public.fn_obtener_productos_mas_vendidos | record | p_limite integer DEFAULT 10, p_fecha_desde timestamp without time zone DEFAULT NULL::timestamp without time zone, p_fecha_hasta timestamp without time zone DEFAULT NULL::timestamp without time zone | FUNCTION |
| public.fn_obtener_timeline_pedido | record | p_pedido_id integer | FUNCTION |
| public.fn_registrar_cambio_estado | trigger |  | FUNCTION |
| public.fn_tendencia_pedidos | record | p_dias integer DEFAULT 30 | FUNCTION |
| public.fn_validar_cupon_aplicable | bool | p_codigo_cupon character varying | FUNCTION |
| public.fn_validar_devolucion_permitida | bool | p_pedido_id integer | FUNCTION |
| public.fn_validar_stock_disponible | bool | p_stock_id integer, p_cantidad_solicitada integer | FUNCTION |
| public.fn_ventas_diarias | record | p_dias integer DEFAULT 7 | FUNCTION |
| public.fn_ventas_por_categoria | record | p_limite integer DEFAULT 10 | FUNCTION |
| public.sp_actualizar_estado_envio | void | IN p_envio_id integer, IN p_nuevo_estado character varying, IN p_transportista character varying DEFAULT NULL::character varying, IN p_numero_tracking character varying DEFAULT NULL::character varying | PROCEDURE |
| public.sp_actualizar_stock_compra | void | IN p_pedido_id integer | PROCEDURE |
| public.sp_ajustar_precios_categoria | void | IN p_categoria_id integer, IN p_porcentaje_ajuste numeric | PROCEDURE |
| public.sp_aplicar_cupon_pedido | void | IN p_pedido_id integer, IN p_codigo_cupon character varying | PROCEDURE |
| public.sp_cancelar_pedido | void | IN p_pedido_id integer, IN p_motivo text | PROCEDURE |
| public.sp_crear_pedido | record | IN p_cliente_id integer, IN p_direccion_envio_id integer, IN p_cupon_id integer, IN p_items jsonb, OUT p_pedido_id integer | PROCEDURE |
| public.sp_eliminar_cliente | void | IN p_cliente_id integer | PROCEDURE |
| public.sp_eliminar_pago | void | IN p_pago_id integer | PROCEDURE |
| public.sp_eliminar_pedido | void | IN p_pedido_id integer | PROCEDURE |
| public.sp_eliminar_producto | void | IN p_producto_id integer | PROCEDURE |
| public.sp_eliminar_stock | void | IN p_stock_id integer | PROCEDURE |
| public.sp_procesar_devolucion | void | IN p_detalle_id integer, IN p_cantidad_devuelta integer, IN p_motivo text | PROCEDURE |
| public.sp_procesar_pago | void | IN p_pedido_id integer, IN p_monto numeric, IN p_metodo_pago character varying, IN p_id_transaccion character varying | PROCEDURE |
| public.sp_reabastecer_stock | void | IN p_stock_id integer, IN p_cantidad integer, IN p_costo_unitario numeric DEFAULT NULL::numeric | PROCEDURE |

## Relations

```mermaid
erDiagram

"public.detalle_pedido" }o--|| "public.pedidos" : "FOREIGN KEY (pedido_id) REFERENCES pedidos(pedido_id) ON DELETE CASCADE"
"public.detalle_pedido" }o--|| "public.stock" : "FOREIGN KEY (stock_id) REFERENCES stock(stock_id)"
"public.devoluciones" |o--|| "public.detalle_pedido" : "FOREIGN KEY (detalle_id) REFERENCES detalle_pedido(detalle_id)"
"public.direcciones" }o--|| "public.clientes" : "FOREIGN KEY (cliente_id) REFERENCES clientes(cliente_id) ON DELETE CASCADE"
"public.envios" }o--|| "public.pedidos" : "FOREIGN KEY (pedido_id) REFERENCES pedidos(pedido_id)"
"public.historial_estados" }o--|| "public.pedidos" : "FOREIGN KEY (pedido_id) REFERENCES pedidos(pedido_id) ON DELETE CASCADE"
"public.pedidos" }o--|| "public.clientes" : "FOREIGN KEY (cliente_id) REFERENCES clientes(cliente_id)"
"public.pedidos" }o--o| "public.cupones" : "FOREIGN KEY (cupon_id) REFERENCES cupones(cupon_id)"
"public.pedidos" }o--|| "public.direcciones" : "FOREIGN KEY (direccion_envio_id) REFERENCES direcciones(direccion_id)"
"public.productos" }o--|| "public.categorias" : "FOREIGN KEY (categoria_id) REFERENCES categorias(categoria_id)"
"public.stock" }o--|| "public.productos" : "FOREIGN KEY (producto_id) REFERENCES productos(producto_id)"
"public.pagos" }o--|| "public.pedidos" : "FOREIGN KEY (pedido_id) REFERENCES pedidos(pedido_id)"

"public.auditoria" {
  integer auditoria_id
  varchar_100_ tabla
  varchar_10_ operacion
  integer registro_id
  varchar_100_ usuario
  timestamp_without_time_zone fecha
  jsonb datos_anteriores
  jsonb datos_nuevos
  varchar_45_ ip_address
}
"public.categorias" {
  integer categoria_id
  varchar_100_ nombre_categoria
  text descripcion
  varchar_20_ estado
  timestamp_without_time_zone fecha_creacion
  timestamp_without_time_zone fecha_modificacion
}
"public.clientes" {
  integer cliente_id
  varchar_100_ nombre
  varchar_100_ apellido
  varchar_255_ email
  varchar_255_ hash_contrasena
  varchar_20_ estado
  timestamp_without_time_zone fecha_creacion
  timestamp_without_time_zone fecha_modificacion
}
"public.cupones" {
  integer cupon_id
  varchar_50_ codigo_cupon
  varchar_20_ tipo_descuento
  numeric_10_2_ valor_descuento
  date fecha_expiracion
  integer usos_disponibles
  varchar_20_ estado
  timestamp_without_time_zone fecha_creacion
  timestamp_without_time_zone fecha_modificacion
}
"public.detalle_pedido" {
  integer detalle_id
  integer pedido_id FK
  integer stock_id FK
  integer cantidad
  numeric_10_2_ precio_unitario_compra
  timestamp_without_time_zone fecha_creacion
}
"public.devoluciones" {
  integer devolucion_id
  integer detalle_id FK
  text motivo
  integer cantidad_devuelta
  timestamp_without_time_zone fecha_solicitud
  varchar_50_ estado_devolucion
  timestamp_without_time_zone fecha_modificacion
}
"public.direcciones" {
  integer direccion_id
  integer cliente_id FK
  varchar_255_ direccion_linea_1
  varchar_100_ ciudad
  varchar_20_ codigo_postal
  varchar_50_ pais
  varchar_20_ estado
  timestamp_without_time_zone fecha_creacion
  timestamp_without_time_zone fecha_modificacion
}
"public.envios" {
  integer envio_id
  integer pedido_id FK
  timestamp_without_time_zone fecha_envio
  varchar_100_ transportista
  varchar_100_ numero_tracking
  varchar_50_ estado_envio
  timestamp_without_time_zone fecha_creacion
  timestamp_without_time_zone fecha_modificacion
}
"public.historial_estados" {
  integer historial_id
  integer pedido_id FK
  varchar_50_ estado_anterior
  varchar_50_ estado_nuevo
  varchar_100_ usuario
  text comentario
  timestamp_without_time_zone fecha_cambio
}
"public.pedidos" {
  integer pedido_id
  integer cliente_id FK
  integer direccion_envio_id FK
  integer cupon_id FK
  timestamp_without_time_zone fecha_pedido
  varchar_50_ estado_pedido
  numeric_12_2_ subtotal
  numeric_12_2_ descuento_aplicado
  numeric_12_2_ impuestos
  numeric_12_2_ total_pedido
  timestamp_without_time_zone fecha_modificacion
}
"public.mv_clientes_vip" {
  integer cliente_id
  varchar_100_ nombre
  varchar_100_ apellido
  varchar_255_ email
  bigint total_pedidos
  numeric total_gastado
  numeric ticket_promedio
  timestamp_without_time_zone ultima_compra
  timestamp_without_time_zone primera_compra
  text categoria_vip
}
"public.productos" {
  integer producto_id
  integer categoria_id FK
  varchar_255_ nombre_producto
  text descripcion_larga
  varchar_20_ estado
  timestamp_without_time_zone fecha_creacion
  timestamp_without_time_zone fecha_modificacion
}
"public.stock" {
  integer stock_id
  integer producto_id FK
  varchar_100_ sku
  numeric_10_2_ precio_unitario
  integer cantidad_en_stock
  integer cantidad_reservada
  varchar_20_ estado
  timestamp_without_time_zone fecha_creacion
  timestamp_without_time_zone fecha_modificacion
}
"public.mv_productos_top_ventas" {
  integer producto_id
  varchar_255_ nombre_producto
  text descripcion_larga
  varchar_100_ nombre_categoria
  bigint total_vendido
  numeric ingresos_totales
  bigint num_pedidos
  numeric precio_promedio
}
"public.pagos" {
  integer pago_id
  integer pedido_id FK
  timestamp_without_time_zone fecha_pago
  numeric_12_2_ monto
  varchar_50_ metodo_pago
  varchar_20_ estado_pago
  varchar_255_ id_transaccion_externa
  timestamp_without_time_zone fecha_modificacion
}
"public.vw_timeline_pedidos" {
  integer historial_id
  integer pedido_id
  varchar_50_ estado_anterior
  varchar_50_ estado_nuevo
  varchar_100_ usuario
  text comentario
  timestamp_without_time_zone fecha_cambio
  integer cliente_id
  text nombre_cliente
  numeric_12_2_ total_pedido
  timestamp_without_time_zone fecha_pedido
}
```

---

> Generated by [tbls](https://github.com/k1LoW/tbls)
