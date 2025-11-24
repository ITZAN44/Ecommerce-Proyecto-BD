
export interface Categoria {
  categoria_id: number;
  nombre_categoria: string;
  descripcion: string | null;
  estado: 'activo' | 'inactivo';
  fecha_creacion: Date;
  fecha_modificacion: Date | null;
}

export interface Cliente {
  cliente_id: number;
  nombre: string;
  apellido: string;
  email: string;
  hash_contrasena: string;
  estado: 'activo' | 'inactivo' | 'suspendido';
  fecha_creacion: Date;
  fecha_modificacion: Date | null;
}

export interface Cupon {
  cupon_id: number;
  codigo_cupon: string;
  tipo_descuento: 'porcentaje' | 'fijo';
  valor_descuento: number;
  fecha_expiracion: Date | null;
  usos_disponibles: number | null;
  estado: 'activo' | 'inactivo' | 'expirado';
  fecha_creacion: Date;
  fecha_modificacion: Date | null;
}

export interface Producto {
  producto_id: number;
  categoria_id: number;
  nombre_producto: string;
  descripcion_larga: string | null;
  estado: 'activo' | 'inactivo' | 'descontinuado';
  fecha_creacion: Date;
  fecha_modificacion: Date | null;
}

export interface Stock {
  stock_id: number;
  producto_id: number;
  sku: string;
  precio_unitario: number;
  cantidad_en_stock: number;
  cantidad_reservada: number;
  estado: 'activo' | 'inactivo';
  fecha_creacion: Date;
  fecha_modificacion: Date | null;
}

export interface Direccion {
  direccion_id: number;
  cliente_id: number;
  direccion_linea_1: string;
  ciudad: string;
  codigo_postal: string;
  pais: string;
  estado: 'activo' | 'inactivo';
  fecha_creacion: Date;
  fecha_modificacion: Date | null;
}

export interface Pedido {
  pedido_id: number;
  cliente_id: number;
  direccion_envio_id: number;
  cupon_id: number | null;
  fecha_pedido: Date;
  estado_pedido: 'pendiente' | 'pagado' | 'enviado' | 'cancelado' | 'completado';
  subtotal: number;
  descuento_aplicado: number;
  impuestos: number;
  total_pedido: number;
  fecha_modificacion: Date | null;
}

export interface DetallePedido {
  detalle_id: number;
  pedido_id: number;
  stock_id: number;
  cantidad: number;
  precio_unitario_compra: number;
}

export interface Pago {
  pago_id: number;
  pedido_id: number;
  fecha_pago: Date;
  monto: number;
  metodo_pago: string;
  estado_pago: 'exitoso' | 'fallido' | 'pendiente' | 'reembolsado';
  id_transaccion_externa: string | null;
  fecha_modificacion: Date | null;
}

export interface Envio {
  envio_id: number;
  pedido_id: number;
  fecha_envio: Date | null;
  transportista: string | null;
  numero_tracking: string | null;
  estado_envio: 'en_preparacion' | 'en_transito' | 'entregado' | 'fallido';
  fecha_creacion: Date;
  fecha_modificacion: Date | null;
}

export interface Devolucion {
  devolucion_id: number;
  detalle_id: number;
  motivo: string | null;
  cantidad_devuelta: number;
  fecha_solicitud: Date;
  estado_devolucion: 'solicitada' | 'aprobada' | 'recibida' | 'reembolsada' | 'rechazada';
  fecha_modificacion: Date | null;
}

export interface ProductoMasVendido {
  producto_id: number;
  nombre_producto: string;
  total_vendido: number;
  ingresos_generados: number;
}

export interface ClienteFrecuente {
  cliente_id: number;
  nombre: string;
  apellido: string;
  email: string;
  total_pedidos: number;
  total_gastado: number;
}

export interface EstadisticasDashboard {
  total_pedidos_hoy: number;
  total_pedidos_pendientes: number;
  total_pedidos_completados: number;
  ventas_hoy: number;
  ventas_mes: number;
  total_clientes_activos: number;
  total_productos_activos: number;
  productos_stock_bajo: number;
}

export interface AlertaStock {
  stock_id: number;
  producto_id: number;
  sku: string;
  nombre_producto: string;
  cantidad_disponible: number;
  cantidad_reservada: number;
  nivel_criticidad: 'CRÍTICO' | 'URGENTE' | 'ADVERTENCIA' | 'NORMAL';
}

export interface ProductoTopVentas {
  producto_id: number;
  nombre_producto: string;
  descripcion_larga: string | null;
  nombre_categoria: string;
  total_vendido: number;
  ingresos_totales: number;
  num_pedidos: number;
  precio_promedio: number;
}

export interface ClienteVIP {
  cliente_id: number;
  nombre: string;
  apellido: string;
  email: string;
  total_pedidos: number;
  total_gastado: number;
  ticket_promedio: number;
  ultima_compra: Date;
  primera_compra: Date;
  categoria_vip: 'Platinum' | 'Gold' | 'Silver' | 'Bronze';
}

export interface RegistroAuditoria {
  auditoria_id: number;
  operacion: 'INSERT' | 'UPDATE' | 'DELETE';
  usuario: string;
  fecha: Date;
  cambios: {
    anterior?: any;
    nuevo?: any;
  } | any;
}

export interface MetricasProducto {
  producto_id: number;
  nombre_producto: string;
  total_vendido: number;
  ingresos_totales: number;
  numero_pedidos: number;
  stock_total: number;
  stock_reservado: number;
  precio_promedio: number;
}

export interface VentaDiaria {
  fecha: string;
  total_ventas: number;
  numero_pedidos: number;
}

export interface VentaCategoria {
  categoria_id: number;
  nombre_categoria: string;
  total_ventas: number;
  cantidad_productos_vendidos: number;
  numero_pedidos: number;
}

export interface TendenciaPedido {
  fecha: string;
  total_pedidos: number;
  pedidos_completados: number;
  pedidos_cancelados: number;
}

export interface DistribucionEstado {
  estado_pedido: string;
  cantidad: number;
  porcentaje: number;
}

export interface HistorialEstado {
  historial_id: number;
  pedido_id: number;
  estado_anterior: string | null;
  estado_nuevo: string;
  usuario: string;
  comentario: string | null;
  fecha_cambio: string;
  orden?: number;
}

export interface EstadisticasEstado {
  estado: string;
  fecha_inicio: string;
  fecha_fin: string | null;
  duracion_horas: number;
}

export interface TimelinePedidoCompleto {
  historial_id: number;
  pedido_id: number;
  estado_anterior: string | null;
  estado_nuevo: string;
  usuario: string;
  comentario: string | null;
  fecha_cambio: string;
  cliente_id: number;
  nombre_cliente: string;
  total_pedido: number;
  fecha_pedido: string;
}
