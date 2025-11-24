import type { APIRoute } from 'astro';
import { query } from '../../../lib/db';
import type { VentaDiaria } from '../../../lib/types';

export const GET: APIRoute = async ({ url }) => {
  try {
    const dias = parseInt(url.searchParams.get('dias') || '7');

    const result = await query('SELECT * FROM fn_ventas_diarias($1)', [dias]);

    return new Response(JSON.stringify(result.rows), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    });
  } catch (error) {
    console.error('Error en GET /api/analytics/ventas-diarias:', error);
    return new Response(JSON.stringify({
      error: (error as Error).message
    }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
};
