import type { APIRoute } from 'astro';
import { query } from '../../../lib/db';

// Endpoint para validar si un pedido permite devoluciones
export const GET: APIRoute = async ({ url }) => {
  try {
    const pedidoId = url.searchParams.get('pedido_id');
    
    if (!pedidoId) {
      return new Response(JSON.stringify({ error: 'pedido_id requerido' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' }
      });
    }

    const result = await query(
      'SELECT fn_validar_devolucion_permitida($1) AS puede_devolver',
      [parseInt(pedidoId)]
    );

    return new Response(JSON.stringify(result.rows[0]), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    });
  } catch (error) {
    console.error('Error al validar devolución:', error);
    return new Response(JSON.stringify({ error: 'Error al validar devolución' }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
};
