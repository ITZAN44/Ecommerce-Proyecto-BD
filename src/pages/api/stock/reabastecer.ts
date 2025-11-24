import type { APIRoute } from 'astro';
import { query } from '../../../lib/db';

export const POST: APIRoute = async ({ request }) => {
  try {
    const formData = await request.formData();
    const stock_id = parseInt(formData.get('stock_id') as string);
    const cantidad = parseInt(formData.get('cantidad') as string);
    const costo_unitario = formData.get('costo_unitario') as string;

    if (!stock_id || !cantidad || cantidad <= 0) {
      throw new Error('Datos inválidos');
    }

    if (costo_unitario && costo_unitario.trim() !== '') {
      await query(
        'CALL sp_reabastecer_stock($1, $2, $3)',
        [stock_id, cantidad, parseFloat(costo_unitario)]
      );
    } else {
      await query(
        'CALL sp_reabastecer_stock($1, $2, NULL)',
        [stock_id, cantidad]
      );
    }

    return new Response(null, {
      status: 302,
      headers: { Location: '/stock' }
    });
  } catch (error) {
    console.error('Error en reabastecer stock:', error);
    return new Response(JSON.stringify({ error: (error as Error).message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
};
