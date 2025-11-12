import type { APIRoute } from 'astro';
import { query } from '../../../lib/db';

export const GET: APIRoute = async ({ url }) => {
  try {
    const clienteId = url.searchParams.get('cliente_id');

    if (!clienteId) {
      return new Response(JSON.stringify({ error: 'cliente_id es requerido' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' }
      });
    }

    const result = await query(
      `SELECT 
        direccion_id,
        cliente_id,
        direccion_linea_1,
        ciudad,
        codigo_postal,
        pais,
        estado,
        fecha_creacion
      FROM direcciones
      WHERE cliente_id = $1
      ORDER BY fecha_creacion DESC`,
      [clienteId]
    );

    return new Response(JSON.stringify(result.rows), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    });
  } catch (error) {
    console.error('Error al obtener direcciones del cliente:', error);
    return new Response(JSON.stringify({ error: 'Error al obtener direcciones' }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
};
