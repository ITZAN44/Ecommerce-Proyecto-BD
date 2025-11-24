import type { APIRoute } from 'astro';
import { query } from '../../../lib/db';

export const GET: APIRoute = async ({ url }) => {
  try {
    const clienteId = url.searchParams.get('cliente_id');

    if (!clienteId) {
      return new Response(JSON.stringify({ error: 'Se requiere cliente_id' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' }
      });
    }

    const result = await query(
      `SELECT fn_cliente_tiene_pedidos($1) as tiene_pedidos`,
      [parseInt(clienteId)]
    );

    const tienePedidos = result.rows[0]?.tiene_pedidos || false;

    return new Response(JSON.stringify({
      cliente_id: parseInt(clienteId),
      tiene_pedidos: tienePedidos,
      mensaje: tienePedidos
        ? 'Este cliente tiene pedidos registrados'
        : 'Este cliente no tiene pedidos'
    }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    });

  } catch (error) {
    console.error('Error al verificar pedidos del cliente:', error);
    return new Response(JSON.stringify({ error: 'Error al verificar pedidos' }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
};
