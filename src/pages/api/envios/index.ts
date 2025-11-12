import type { APIRoute } from 'astro';
import { query } from '../../../lib/db';

export const GET: APIRoute = async () => {
  try {
    const result = await query(`
      SELECT 
        e.envio_id,
        e.pedido_id,
        e.fecha_envio,
        e.transportista,
        e.numero_tracking,
        e.estado_envio,
        e.fecha_creacion,
        p.cliente_id,
        c.nombre,
        c.apellido,
        p.total_pedido
      FROM envios e
      INNER JOIN pedidos p ON e.pedido_id = p.pedido_id
      INNER JOIN clientes c ON p.cliente_id = c.cliente_id
      ORDER BY e.envio_id DESC
    `);

    return new Response(JSON.stringify(result.rows), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    });
  } catch (error) {
    console.error('Error al obtener envíos:', error);
    return new Response(JSON.stringify({ error: 'Error al obtener envíos' }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
};

export const POST: APIRoute = async ({ request }) => {
  try {
    const formData = await request.formData();
    const method = formData.get('_method') as string;

    // Actualizar estado de envío usando procedimiento almacenado (PATCH)
    if (method === 'PATCH') {
      const envio_id = parseInt(formData.get('envio_id') as string);
      const nuevo_estado = formData.get('estado_envio') as string;
      const transportista = formData.get('transportista') as string || null;
      const numero_tracking = formData.get('numero_tracking') as string || null;

      console.log('Actualizando envío:', { envio_id, nuevo_estado, transportista, numero_tracking });

      // Primero verificar el estado actual
      const checkResult = await query(
        'SELECT estado_envio FROM envios WHERE envio_id = $1',
        [envio_id]
      );

      if (checkResult.rows.length === 0) {
        throw new Error('Envío no encontrado');
      }

      const estadoActual = checkResult.rows[0].estado_envio;
      console.log('Estado actual en BD:', estadoActual);

      if (estadoActual === 'entregado') {
        throw new Error('No se puede modificar un envío ya entregado');
      }

      // Llamar al procedimiento almacenado
      await query(
        'CALL sp_actualizar_estado_envio($1, $2, $3, $4)',
        [envio_id, nuevo_estado, transportista, numero_tracking]
      );

      return new Response(null, {
        status: 303,
        headers: { Location: '/envios' }
      });
    }

    // Crear nuevo envío (POST)
    const pedido_id = parseInt(formData.get('pedido_id') as string);
    const transportista = formData.get('transportista') as string || null;
    const numero_tracking = formData.get('numero_tracking') as string || null;

    await query(
      `INSERT INTO envios (pedido_id, transportista, numero_tracking)
       VALUES ($1, $2, $3)`,
      [pedido_id, transportista, numero_tracking]
    );

    return new Response(null, {
      status: 303,
      headers: { Location: '/envios' }
    });

  } catch (error: any) {
    console.error('Error en operación de envíos:', error);
    
    // Si es un error del procedimiento, redirigir con mensaje
    if (error.message && error.message.includes('No se puede modificar')) {
      return new Response(null, {
        status: 303,
        headers: { 
          Location: '/envios?error=' + encodeURIComponent(error.message)
        }
      });
    }
    
    // Para otros errores, también redirigir con mensaje
    return new Response(null, {
      status: 303,
      headers: { 
        Location: '/envios?error=' + encodeURIComponent(error.message || 'Error en la operación')
      }
    });
  }
};
