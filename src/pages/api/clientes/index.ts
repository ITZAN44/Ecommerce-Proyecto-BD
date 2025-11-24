import type { APIRoute } from 'astro';
import { query } from '../../../lib/db';

export const GET: APIRoute = async () => {
  try {
    const result = await query(`
      SELECT cliente_id, nombre, apellido, email, estado, fecha_creacion
      FROM clientes
      ORDER BY cliente_id DESC
    `);

    return new Response(JSON.stringify(result.rows), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    });
  } catch (error) {
    console.error('Error en GET /api/clientes:', error);
    return new Response(JSON.stringify({ error: 'Error al obtener clientes' }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
};

export const POST: APIRoute = async ({ request }) => {
  try {
    const formData = await request.formData();
    const method = formData.get('_method');

    if (!method) {
      const nombre = formData.get('nombre');
      const apellido = formData.get('apellido');
      const email = formData.get('email');
      const contrasena = formData.get('contrasena');

      if (!nombre || !apellido || !email || !contrasena) {
        return new Response(JSON.stringify({ error: 'Faltan campos requeridos' }), {
          status: 400,
          headers: { 'Content-Type': 'application/json' }
        });
      }

      const hashContrasena = `hash_${contrasena}`;

      await query(
        `INSERT INTO clientes (nombre, apellido, email, hash_contrasena)
         VALUES ($1, $2, $3, $4)`,
        [nombre, apellido, email, hashContrasena]
      );

      return new Response(null, {
        status: 303,
        headers: { Location: '/clientes' }
      });
    }

    if (method === 'PUT') {
      const clienteId = formData.get('cliente_id');
      const nombre = formData.get('nombre');
      const apellido = formData.get('apellido');
      const email = formData.get('email');
      const contrasena = formData.get('contrasena');

      if (!clienteId || !nombre || !apellido || !email) {
        return new Response(JSON.stringify({ error: 'Faltan campos requeridos' }), {
          status: 400,
          headers: { 'Content-Type': 'application/json' }
        });
      }

      if (contrasena && contrasena.toString().trim() !== '') {
        const hashContrasena = `hash_${contrasena}`;
        await query(
          `UPDATE clientes
           SET nombre = $1, apellido = $2, email = $3, hash_contrasena = $4, fecha_modificacion = NOW()
           WHERE cliente_id = $5`,
          [nombre, apellido, email, hashContrasena, clienteId]
        );
      } else {
        await query(
          `UPDATE clientes
           SET nombre = $1, apellido = $2, email = $3, fecha_modificacion = NOW()
           WHERE cliente_id = $4`,
          [nombre, apellido, email, clienteId]
        );
      }

      return new Response(null, {
        status: 303,
        headers: { Location: '/clientes' }
      });
    }

    if (method === 'PATCH') {
      const clienteId = formData.get('cliente_id');
      const estado = formData.get('estado');

      if (!clienteId || !estado) {
        return new Response(JSON.stringify({ error: 'Faltan campos requeridos' }), {
          status: 400,
          headers: { 'Content-Type': 'application/json' }
        });
      }

      await query(
        `UPDATE clientes SET estado = $1, fecha_modificacion = NOW() WHERE cliente_id = $2`,
        [estado, clienteId]
      );

      return new Response(JSON.stringify({ success: true }), {
        status: 200,
        headers: { 'Content-Type': 'application/json' }
      });
    }

    if (method === 'DELETE') {
      const clienteId = formData.get('cliente_id');

      if (!clienteId) {
        return new Response(JSON.stringify({ error: 'Falta el ID del cliente' }), {
          status: 400,
          headers: { 'Content-Type': 'application/json' }
        });
      }

      try {
        await query('CALL sp_eliminar_cliente($1)', [clienteId]);

        return new Response(null, {
          status: 303,
          headers: { Location: '/clientes' }
        });
      } catch (deleteError: any) {
        return new Response(null, {
          status: 303,
          headers: {
            Location: '/clientes?error=' + encodeURIComponent(deleteError.message || 'Error al eliminar cliente')
          }
        });
      }
    }

    return new Response(JSON.stringify({ error: 'Método no soportado' }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' }
    });

  } catch (error) {
    console.error('Error en POST /api/clientes:', error);
    return new Response(JSON.stringify({ error: 'Error al procesar solicitud' }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
};
