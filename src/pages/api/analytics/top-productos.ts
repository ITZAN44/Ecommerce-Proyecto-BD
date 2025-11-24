import type { APIRoute } from 'astro';
import { query } from '../../../lib/db';
import type { ProductoTopVentas } from '../../../lib/types';

export const GET: APIRoute = async ({ url }) => {
  try {
    const limit = parseInt(url.searchParams.get('limit') || '10');

    const result = await query(
      `SELECT * FROM mv_productos_top_ventas LIMIT $1`,
      [limit]
    );

    return new Response(JSON.stringify(result.rows), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    });
  } catch (error) {
    console.error('Error en GET /api/analytics/top-productos:', error);
    return new Response(JSON.stringify({
      error: (error as Error).message
    }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
};

export const POST: APIRoute = async () => {
  try {
    await query('REFRESH MATERIALIZED VIEW CONCURRENTLY mv_productos_top_ventas');

    return new Response(JSON.stringify({
      success: true,
      message: 'Vista actualizada correctamente'
    }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    });
  } catch (error) {
    console.error('Error en POST /api/analytics/top-productos:', error);
    return new Response(JSON.stringify({
      error: (error as Error).message
    }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
};
