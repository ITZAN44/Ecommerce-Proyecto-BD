import type { APIRoute } from 'astro';
import { query } from '../../../lib/db';
import type { ClienteVIP } from '../../../lib/types';

export const GET: APIRoute = async ({ url }) => {
  try {
    const categoria = url.searchParams.get('categoria');
    const limit = parseInt(url.searchParams.get('limit') || '50');

    let sql = 'SELECT * FROM mv_clientes_vip';
    const params: any[] = [];

    if (categoria) {
      sql += ' WHERE categoria_vip = $1';
      params.push(categoria);
      sql += ' LIMIT $2';
      params.push(limit);
    } else {
      sql += ' LIMIT $1';
      params.push(limit);
    }

    const result = await query(sql, params);

    return new Response(JSON.stringify(result.rows), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    });
  } catch (error) {
    console.error('Error en GET /api/analytics/clientes-vip:', error);
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
    await query('REFRESH MATERIALIZED VIEW CONCURRENTLY mv_clientes_vip');

    return new Response(JSON.stringify({
      success: true,
      message: 'Vista actualizada correctamente'
    }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    });
  } catch (error) {
    console.error('Error en POST /api/analytics/clientes-vip:', error);
    return new Response(JSON.stringify({
      error: (error as Error).message
    }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
};
