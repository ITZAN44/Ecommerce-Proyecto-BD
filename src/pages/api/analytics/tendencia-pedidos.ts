import type { APIRoute } from 'astro';
import { query } from '../../../lib/db';
import type { TendenciaPedido } from '../../../lib/types';

export const GET: APIRoute = async ({ url }) => {
  try {
    const dias = parseInt(url.searchParams.get('dias') || '30');

    const result = await query('SELECT * FROM fn_tendencia_pedidos($1)', [dias]);

    return new Response(JSON.stringify(result.rows), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    });
  } catch (error) {
    console.error('Error en GET /api/analytics/tendencia-pedidos:', error);
    return new Response(JSON.stringify({
      error: (error as Error).message
    }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
};
