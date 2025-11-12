import type { APIRoute } from 'astro';
import { query } from '../../../lib/db';

export const GET: APIRoute = async () => {
  try {
    const result = await query(`
      SELECT cupon_id, codigo_cupon, tipo_descuento, valor_descuento, 
             fecha_expiracion, usos_disponibles, estado, fecha_creacion
      FROM cupones
      ORDER BY cupon_id DESC
    `);
    
    return new Response(JSON.stringify(result.rows), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    });
  } catch (error) {
    console.error('Error en GET /api/cupones:', error);
    return new Response(JSON.stringify({ error: (error as Error).message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
};

export const POST: APIRoute = async ({ request }) => {
  try {
    const contentType = request.headers.get('content-type');
    let data: any;

    if (contentType?.includes('application/json')) {
      data = await request.json();
    } else {
      const formData = await request.formData();
      data = Object.fromEntries(formData.entries());
    }

    // Actualizar cupón (PUT)
    if (data._method === 'PUT') {
      const fecha_exp = data.fecha_expiracion && data.fecha_expiracion.trim() !== '' 
        ? data.fecha_expiracion 
        : null;
      const usos = data.usos_disponibles && data.usos_disponibles.trim() !== '' 
        ? parseInt(data.usos_disponibles) 
        : null;

      await query(
        `UPDATE cupones 
         SET codigo_cupon = $1, tipo_descuento = $2, valor_descuento = $3, 
             fecha_expiracion = $4, usos_disponibles = $5
         WHERE cupon_id = $6`,
        [
          data.codigo_cupon.toUpperCase(),
          data.tipo_descuento,
          parseFloat(data.valor_descuento),
          fecha_exp,
          usos,
          parseInt(data.cupon_id)
        ]
      );
      return new Response(null, {
        status: 302,
        headers: { Location: '/cupones' }
      });
    }

    // Cambiar estado (PATCH)
    if (data._method === 'PATCH') {
      await query(
        'UPDATE cupones SET estado = $1 WHERE cupon_id = $2',
        [data.estado, parseInt(data.cupon_id)]
      );
      return new Response(JSON.stringify({ success: true }), {
        status: 200,
        headers: { 'Content-Type': 'application/json' }
      });
    }

    // Crear nuevo cupón
    const fecha_exp = data.fecha_expiracion && data.fecha_expiracion.trim() !== '' 
      ? data.fecha_expiracion 
      : null;
    const usos = data.usos_disponibles && data.usos_disponibles.trim() !== '' 
      ? parseInt(data.usos_disponibles) 
      : null;

    await query(
      `INSERT INTO cupones (codigo_cupon, tipo_descuento, valor_descuento, fecha_expiracion, usos_disponibles)
       VALUES ($1, $2, $3, $4, $5)`,
      [
        data.codigo_cupon.toUpperCase(),
        data.tipo_descuento,
        parseFloat(data.valor_descuento),
        fecha_exp,
        usos
      ]
    );

    return new Response(null, {
      status: 302,
      headers: { Location: '/cupones' }
    });
  } catch (error) {
    console.error('Error en POST /api/cupones:', error);
    return new Response(JSON.stringify({ error: (error as Error).message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
};
