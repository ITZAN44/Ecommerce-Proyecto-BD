import type { APIRoute } from 'astro';
import { query } from '../../../../lib/db';

// Endpoint para obtener detalles de un pedido específico
export const GET: APIRoute = async ({ url }) => {
  try {
    const pedidoId = url.searchParams.get('pedido_id');
    
    if (!pedidoId) {
      return new Response(JSON.stringify({ error: 'pedido_id requerido' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' }
      });
    }

    const result = await query(`
      SELECT 
        dp.detalle_id,
        dp.pedido_id,
        dp.stock_id,
        dp.cantidad,
        dp.precio_unitario_compra,
        dp.fecha_creacion,
        s.sku,
        p.nombre_producto,
        pr.nombre_producto,
        c.nombre_categoria
      FROM detalle_pedido dp
      INNER JOIN stock s ON dp.stock_id = s.stock_id
      INNER JOIN productos pr ON s.producto_id = pr.producto_id
      INNER JOIN categorias c ON pr.categoria_id = c.categoria_id
      WHERE dp.pedido_id = $1
      ORDER BY dp.detalle_id
    `, [parseInt(pedidoId)]);

    return new Response(JSON.stringify(result.rows), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    });
  } catch (error) {
    console.error('Error al obtener detalles del pedido:', error);
    return new Response(JSON.stringify({ error: 'Error al obtener detalles del pedido' }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
};
