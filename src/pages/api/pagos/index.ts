import type { APIRoute } from 'astro';
import { query } from '../../../lib/db';

export const GET: APIRoute = async () => {
  try {
    const result = await query(`
      SELECT
        pa.pago_id,
        pa.pedido_id,
        pa.fecha_pago,
        pa.monto,
        pa.metodo_pago,
        pa.estado_pago,
        pa.id_transaccion_externa,
        p.cliente_id,
        p.total_pedido,
        p.estado_pedido,
        c.nombre,
        c.apellido,
        c.email
      FROM pagos pa
      INNER JOIN pedidos p ON pa.pedido_id = p.pedido_id
      INNER JOIN clientes c ON p.cliente_id = c.cliente_id
      ORDER BY pa.pago_id DESC
    `);

    return new Response(JSON.stringify(result.rows), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    });
  } catch (error) {
    console.error('Error al obtener pagos:', error);
    return new Response(JSON.stringify({ error: 'Error al obtener pagos' }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
};

export const POST: APIRoute = async ({ request }) => {
  try {
    const formData = await request.formData();
    const method = formData.get('_method') as string;

    if (method === 'DELETE') {
      const pago_id = parseInt(formData.get('pago_id') as string);

      console.log('Eliminando pago:', { pago_id });

      try {
        await query('CALL sp_eliminar_pago($1)', [pago_id]);

        return new Response(null, {
          status: 303,
          headers: { Location: '/pagos' }
        });
      } catch (deleteError: any) {
        return new Response(null, {
          status: 303,
          headers: {
            Location: '/pagos?error=' + encodeURIComponent(deleteError.message || 'Error al eliminar pago')
          }
        });
      }
    }

    const pedido_id = parseInt(formData.get('pedido_id') as string);
    const monto = parseFloat(formData.get('monto') as string);
    const metodo_pago = formData.get('metodo_pago') as string;
    const id_transaccion = formData.get('id_transaccion_externa') as string || null;

    console.log('Procesando pago:', { pedido_id, monto, metodo_pago, id_transaccion });

    await query(
      'CALL sp_procesar_pago($1, $2, $3, $4)',
      [pedido_id, monto, metodo_pago, id_transaccion]
    );

    return new Response(null, {
      status: 303,
      headers: { Location: '/pagos' }
    });

  } catch (error: any) {
    console.error('Error al procesar pago:', error);

    return new Response(null, {
      status: 303,
      headers: {
        Location: '/pagos?error=' + encodeURIComponent(error.message || 'Error al procesar pago')
      }
    });
  }
};
