import type { APIRoute } from 'astro';
import { query } from '../../../lib/db';

// Endpoint para calcular monto de reembolso
export const GET: APIRoute = async ({ url }) => {
  try {
    const detalleId = url.searchParams.get('detalle_id');
    const cantidad = url.searchParams.get('cantidad');
    
    if (!detalleId || !cantidad) {
      return new Response(JSON.stringify({ error: 'detalle_id y cantidad requeridos' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' }
      });
    }

    const result = await query(
      'SELECT fn_calcular_monto_reembolso($1, $2) AS monto_reembolso',
      [parseInt(detalleId), parseInt(cantidad)]
    );

    return new Response(JSON.stringify(result.rows[0]), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    });
  } catch (error) {
    console.error('Error al calcular reembolso:', error);
    return new Response(JSON.stringify({ 
      error: (error as Error).message || 'Error al calcular reembolso' 
    }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
};
