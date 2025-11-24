import type { APIRoute } from 'astro';
import { query } from '../../../lib/db';
import type { VentaCategoria } from '../../../lib/types';

export const GET: APIRoute = async ({ url }) => {
  try {
    const limite = parseInt(url.searchParams.get('limite') || '10');

    const result = await query('SELECT * FROM fn_ventas_por_categoria($1)', [limite]);

    return new Response(JSON.stringify(result.rows), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    });
  } catch (error) {
    console.error('Error en GET /api/analytics/ventas-categoria:', error);
    return new Response(JSON.stringify({
      error: (error as Error).message
    }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
};
