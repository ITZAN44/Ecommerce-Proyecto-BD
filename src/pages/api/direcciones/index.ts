import type { APIRoute } from 'astro';
import { query } from '../../../lib/db';

export const POST: APIRoute = async ({ request }) => {
  try {
    const formData = await request.formData();
    const method = formData.get('_method') as string;

    if (method === 'PUT') {
      const direccion_id = parseInt(formData.get('direccion_id') as string);
      const direccion_linea_1 = formData.get('direccion_linea_1') as string;
      const ciudad = formData.get('ciudad') as string;
      const codigo_postal = formData.get('codigo_postal') as string;
      const pais = formData.get('pais') as string;

      await query(
        `UPDATE direcciones
         SET direccion_linea_1 = $1,
             ciudad = $2,
             codigo_postal = $3,
             pais = $4
         WHERE direccion_id = $5`,
        [direccion_linea_1, ciudad, codigo_postal, pais, direccion_id]
      );

      return new Response(JSON.stringify({ success: true }), {
        status: 200,
        headers: { 'Content-Type': 'application/json' }
      });
    }

    const cliente_id = parseInt(formData.get('cliente_id') as string);
    const direccion_linea_1 = formData.get('direccion_linea_1') as string;
    const ciudad = formData.get('ciudad') as string;
    const codigo_postal = formData.get('codigo_postal') as string;
    const pais = formData.get('pais') as string;

    await query(
      `INSERT INTO direcciones (cliente_id, direccion_linea_1, ciudad, codigo_postal, pais)
       VALUES ($1, $2, $3, $4, $5)`,
      [cliente_id, direccion_linea_1, ciudad, codigo_postal, pais]
    );

    return new Response(JSON.stringify({ success: true }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    });

  } catch (error) {
    console.error('Error en operación de dirección:', error);
    return new Response(JSON.stringify({ error: 'Error en la operación' }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
};
