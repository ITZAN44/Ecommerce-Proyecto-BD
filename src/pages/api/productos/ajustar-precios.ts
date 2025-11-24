import type { APIRoute } from 'astro';
import { query } from '../../../lib/db';

export const POST: APIRoute = async ({ request }) => {
  try {
    const data = await request.json();

    await query(
      'CALL sp_ajustar_precios_categoria($1, $2)',
      [parseInt(data.categoria_id), parseFloat(data.porcentaje)]
    );

    return new Response(JSON.stringify({
      success: true,
      message: `Precios ajustados ${data.porcentaje > 0 ? '+' : ''}${data.porcentaje}%`
    }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    });
  } catch (error) {
    console.error('Error en ajustar-precios:', error);
    return new Response(JSON.stringify({ error: (error as Error).message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
};
