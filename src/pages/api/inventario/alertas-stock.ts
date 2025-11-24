import type { APIRoute } from 'astro';
import { query } from '../../../lib/db';
import type { AlertaStock } from '../../../lib/types';

export const GET: APIRoute = async ({ url }) => {
  try {
    const limite = parseInt(url.searchParams.get('limite') || '15');
    const criticidad = url.searchParams.get('criticidad');

    let sql = 'SELECT * FROM fn_alerta_stock_bajo($1)';
    const params: any[] = [limite];

    if (criticidad) {
      sql += ' WHERE nivel_criticidad = $2';
      params.push(criticidad);
    }

    sql += ' ORDER BY cantidad_disponible ASC';

    const result = await query(sql, params);

    return new Response(JSON.stringify(result.rows), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    });
  } catch (error) {
    console.error('Error en GET /api/inventario/alertas-stock:', error);
    return new Response(JSON.stringify({
      error: (error as Error).message
    }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
};
