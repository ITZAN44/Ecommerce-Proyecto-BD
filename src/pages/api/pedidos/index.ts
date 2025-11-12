import type { APIRoute } from 'astro';
import { query } from '../../../lib/db';

export const GET: APIRoute = async () => {
  try {
    const result = await query(`
      SELECT 
        p.pedido_id,
        p.cliente_id,
        p.direccion_envio_id,
        p.cupon_id,
        p.fecha_pedido,
        p.estado_pedido,
        p.subtotal,
        p.descuento_aplicado,
        p.impuestos,
        p.total_pedido,
        c.nombre,
        c.apellido,
        c.email,
        d.direccion_linea_1,
        d.ciudad,
        d.pais,
        cu.codigo_cupon
      FROM pedidos p
      INNER JOIN clientes c ON p.cliente_id = c.cliente_id
      INNER JOIN direcciones d ON p.direccion_envio_id = d.direccion_id
      LEFT JOIN cupones cu ON p.cupon_id = cu.cupon_id
      ORDER BY p.pedido_id DESC
    `);

    return new Response(JSON.stringify(result.rows), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    });
  } catch (error) {
    console.error('Error al obtener pedidos:', error);
    return new Response(JSON.stringify({ error: 'Error al obtener pedidos' }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
};

export const POST: APIRoute = async ({ request }) => {
  try {
    const formData = await request.formData();
    const method = formData.get('_method') as string;

    // CANCELAR PEDIDO (cambio de estado a 'cancelado')
    if (method === 'DELETE') {
      const pedido_id = parseInt(formData.get('pedido_id') as string);
      const motivo = formData.get('motivo') as string;
      const eliminar_fisico = formData.get('eliminar_fisico') === 'true';

      console.log('Procesando pedido:', { pedido_id, motivo, eliminar_fisico });

      // Si se solicita eliminación física
      if (eliminar_fisico) {
        try {
          await query('CALL sp_eliminar_pedido($1)', [pedido_id]);
          
          return new Response(null, {
            status: 303,
            headers: { Location: '/pedidos' }
          });
        } catch (deleteError: any) {
          return new Response(null, {
            status: 303,
            headers: { 
              Location: '/pedidos?error=' + encodeURIComponent(deleteError.message || 'Error al eliminar pedido')
            }
          });
        }
      }

      // Si no, solo cancelar (cambio de estado)
      await query(
        'CALL sp_cancelar_pedido($1, $2)',
        [pedido_id, motivo]
      );

      return new Response(null, {
        status: 303,
        headers: { Location: '/pedidos' }
      });
    }

    // APLICAR CUPÓN
    if (method === 'PATCH') {
      const pedido_id = parseInt(formData.get('pedido_id') as string);
      const codigo_cupon = formData.get('codigo_cupon') as string;

      console.log('Aplicando cupón:', { pedido_id, codigo_cupon });

      await query(
        'CALL sp_aplicar_cupon_pedido($1, $2)',
        [pedido_id, codigo_cupon]
      );

      return new Response(null, {
        status: 303,
        headers: { Location: '/pedidos' }
      });
    }

    // CREAR PEDIDO
    const cliente_id = parseInt(formData.get('cliente_id') as string);
    const direccion_envio_id = parseInt(formData.get('direccion_envio_id') as string);
    const cupon_id = formData.get('cupon_id') ? parseInt(formData.get('cupon_id') as string) : null;
    const items = formData.get('items') as string;

    console.log('Creando pedido:', { cliente_id, direccion_envio_id, cupon_id, items });

    // Llamar al procedimiento almacenado sp_crear_pedido
    const result = await query(
      'CALL sp_crear_pedido($1, $2, $3, $4, NULL)',
      [cliente_id, direccion_envio_id, cupon_id, items]
    );

    return new Response(null, {
      status: 303,
      headers: { Location: '/pedidos' }
    });

  } catch (error: any) {
    console.error('Error en operación de pedidos:', error);
    
    // Redirigir con mensaje de error
    return new Response(null, {
      status: 303,
      headers: { 
        Location: '/pedidos?error=' + encodeURIComponent(error.message || 'Error en la operación')
      }
    });
  }
};
