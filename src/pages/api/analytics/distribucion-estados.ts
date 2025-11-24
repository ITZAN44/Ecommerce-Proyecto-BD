import type { APIRoute } from 'astro';
import { query } from '../../../lib/db';
import type { DistribucionEstado } from '../../../lib/types';

export const GET: APIRoute = async () => {
  try {
    const result = await query('SELECT * FROM fn_distribucion_estados_pedidos()');

    return new Response(JSON.stringify(result.rows), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    });
  } catch (error) {
    console.error('Error en GET /api/analytics/distribucion-estados:', error);
    return new Response(JSON.stringify({
      error: (error as Error).message
    }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
};
