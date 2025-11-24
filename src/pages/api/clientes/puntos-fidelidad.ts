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
      `SELECT fn_calcular_puntos_fidelidad($1) as puntos`,
      [parseInt(clienteId)]
    );

    const puntos = result.rows[0]?.puntos || 0;

    const clienteResult = await query(
      `SELECT nombre, apellido FROM clientes WHERE cliente_id = $1`,
      [parseInt(clienteId)]
    );

    const cliente = clienteResult.rows[0];

    return new Response(JSON.stringify({
      cliente_id: parseInt(clienteId),
      nombre_completo: cliente ? `${cliente.nombre} ${cliente.apellido}` : 'N/A',
      puntos_fidelidad: puntos,
      mensaje: `Este cliente tiene ${puntos} puntos de fidelidad (1 punto por cada $10 gastados)`
    }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    });

  } catch (error) {
    console.error('Error al calcular puntos de fidelidad:', error);
    return new Response(JSON.stringify({ error: 'Error al calcular puntos' }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
};
