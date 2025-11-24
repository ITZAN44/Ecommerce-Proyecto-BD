import type { APIRoute } from 'astro';
import { query } from '../../../lib/db';
import type { RegistroAuditoria } from '../../../lib/types';

export const GET: APIRoute = async ({ url }) => {
  try {
    const tabla = url.searchParams.get('tabla');
    const registro_id = url.searchParams.get('registro_id');
    const limite = parseInt(url.searchParams.get('limite') || '50');

    if (!tabla || !registro_id) {
      return new Response(JSON.stringify({
        error: 'Se requieren los parámetros: tabla y registro_id'
      }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' }
      });
    }

    const result = await query(
      'SELECT * FROM fn_historial_cambios($1, $2, $3)',
      [tabla, parseInt(registro_id), limite]
    );

    return new Response(JSON.stringify(result.rows), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    });
  } catch (error) {
    console.error('Error en GET /api/auditoria/historial:', error);
    return new Response(JSON.stringify({
      error: (error as Error).message
    }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
};

export const POST: APIRoute = async ({ request }) => {
  try {
    const data = await request.json();
    const { tabla, operacion, usuario, limite = 100 } = data;

    let sql = 'SELECT * FROM auditoria WHERE 1=1';
    const params: any[] = [];
    let paramIndex = 1;

    if (tabla) {
      sql += ` AND tabla = $${paramIndex}`;
      params.push(tabla);
      paramIndex++;
    }

    if (operacion) {
      sql += ` AND operacion = $${paramIndex}`;
      params.push(operacion);
      paramIndex++;
    }

    if (usuario) {
      sql += ` AND usuario = $${paramIndex}`;
      params.push(usuario);
      paramIndex++;
    }

    sql += ` ORDER BY fecha DESC LIMIT $${paramIndex}`;
    params.push(limite);

    const result = await query(sql, params);

    return new Response(JSON.stringify(result.rows), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    });
  } catch (error) {
    console.error('Error en POST /api/auditoria/historial/todas:', error);
    return new Response(JSON.stringify({
      error: (error as Error).message
    }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
};
