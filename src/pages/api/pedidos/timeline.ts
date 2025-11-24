import type { APIRoute } from 'astro';
import { query } from '../../../lib/db';
import type { HistorialEstado } from '../../../lib/types';

export const GET: APIRoute = async ({ url }) => {
  try {
    const pedidoId = url.searchParams.get('pedido_id');

    if (!pedidoId) {
      return new Response(JSON.stringify({
        error: 'El parámetro pedido_id es requerido'
      }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' }
      });
    }

    const pedidoIdNum = parseInt(pedidoId);
    if (isNaN(pedidoIdNum)) {
      return new Response(JSON.stringify({
        error: 'El pedido_id debe ser un número válido'
      }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' }
      });
    }

    const result = await query(
      'SELECT * FROM fn_obtener_timeline_pedido($1)',
      [pedidoIdNum]
    );

    if (result.rows.length === 0) {
      return new Response(JSON.stringify({
        error: 'No se encontró historial para este pedido',
        pedido_id: pedidoIdNum,
        timeline: []
      }), {
        status: 404,
        headers: { 'Content-Type': 'application/json' }
      });
    }

    return new Response(JSON.stringify({
      pedido_id: pedidoIdNum,
      total_cambios: result.rows.length,
      timeline: result.rows
    }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    });

  } catch (error) {
    console.error('Error en GET /api/pedidos/timeline:', error);
    return new Response(JSON.stringify({
      error: 'Error al obtener timeline del pedido',
      details: (error as Error).message
    }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
};

export const POST: APIRoute = async ({ request }) => {
  try {
    const body = await request.json();
    const { pedido_id, nuevo_estado, comentario } = body;

    if (!pedido_id || !nuevo_estado) {
      return new Response(JSON.stringify({
        error: 'Los campos pedido_id y nuevo_estado son requeridos'
      }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' }
      });
    }

    const estadosValidos = ['pendiente', 'pagado', 'enviado', 'cancelado', 'completado'];
    if (!estadosValidos.includes(nuevo_estado)) {
      return new Response(JSON.stringify({
        error: 'Estado inválido',
        estados_validos: estadosValidos
      }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' }
      });
    }

    const result = await query(
      'SELECT fn_cambiar_estado_pedido($1, $2, $3) as resultado',
      [pedido_id, nuevo_estado, comentario || null]
    );

    const exito = result.rows[0]?.resultado;

    if (!exito) {
      return new Response(JSON.stringify({
        error: 'No se pudo cambiar el estado',
        mensaje: 'El pedido ya está en ese estado o no existe'
      }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' }
      });
    }

    const timelineResult = await query(
      'SELECT * FROM fn_obtener_timeline_pedido($1)',
      [pedido_id]
    );

    return new Response(JSON.stringify({
      success: true,
      pedido_id,
      nuevo_estado,
      comentario,
      timeline: timelineResult.rows
    }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    });

  } catch (error) {
    console.error('Error en POST /api/pedidos/timeline:', error);
    return new Response(JSON.stringify({
      error: 'Error al cambiar estado del pedido',
      details: (error as Error).message
    }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
};
