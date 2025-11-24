import type { APIRoute } from 'astro';
import { query } from '../../../lib/db';
import type { EstadisticasDashboard } from '../../../lib/types';

export const GET: APIRoute = async () => {
  try {
    const result = await query('SELECT * FROM fn_estadisticas_dashboard()');

    if (result.rows.length === 0) {
      return new Response(JSON.stringify({
        error: 'No se pudieron obtener estadísticas'
      }), {
        status: 500,
        headers: { 'Content-Type': 'application/json' }
      });
    }

    return new Response(JSON.stringify(result.rows[0]), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    });
  } catch (error) {
    console.error('Error en GET /api/analytics/dashboard:', error);
    return new Response(JSON.stringify({
      error: (error as Error).message
    }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
};
