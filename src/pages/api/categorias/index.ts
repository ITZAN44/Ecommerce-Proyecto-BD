import type { APIRoute } from 'astro';
import { query } from '../../../lib/db';

export const GET: APIRoute = async () => {
  try {
    const result = await query('SELECT * FROM categorias ORDER BY categoria_id DESC');
    return new Response(JSON.stringify(result.rows), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: (error as Error).message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
};

export const POST: APIRoute = async ({ request, redirect }) => {
  try {
    const contentType = request.headers.get('content-type') || '';

    if (contentType.includes('application/json')) {
      const body = await request.json();
      const method = body._method;

      if (method === 'PATCH') {
        const { categoria_id, estado } = body;

        await query(
          'UPDATE categorias SET estado = $1 WHERE categoria_id = $2',
          [estado, categoria_id]
        );

        return new Response(JSON.stringify({ success: true }), {
          status: 200,
          headers: { 'Content-Type': 'application/json' }
        });
      }
    }

    let formData;
    try {
      formData = await request.formData();
    } catch (e) {
      return new Response(JSON.stringify({ error: 'Formato de datos inválido' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' }
      });
    }

    const method = formData.get('_method') as string;

    if (method === 'PUT') {
      const id = parseInt(formData.get('categoria_id') as string);
      const nombre = formData.get('nombre_categoria') as string;
      const descripcion = formData.get('descripcion') as string || null;

      if (!nombre) {
        return new Response(JSON.stringify({ error: 'El nombre es requerido' }), {
          status: 400,
          headers: { 'Content-Type': 'application/json' }
        });
      }

      await query(
        'UPDATE categorias SET nombre_categoria = $1, descripcion = $2 WHERE categoria_id = $3',
        [nombre, descripcion, id]
      );

      return redirect('/categorias');
    }

    const nombre = formData.get('nombre_categoria') as string;
    const descripcion = formData.get('descripcion') as string || null;

    if (!nombre) {
      return new Response(JSON.stringify({ error: 'El nombre es requerido' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' }
      });
    }

    await query(
      'INSERT INTO categorias (nombre_categoria, descripcion) VALUES ($1, $2)',
      [nombre, descripcion]
    );

    return redirect('/categorias');

  } catch (error) {
    console.error('Error en POST /api/categorias:', error);
    return new Response(JSON.stringify({ error: (error as Error).message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
};
