import type { APIRoute } from 'astro';
import { query } from '../../../lib/db';

export const GET: APIRoute = async () => {
  try {
    const result = await query(`
      SELECT 
        d.devolucion_id,
        d.detalle_id,
        d.motivo,
        d.cantidad_devuelta,
        d.fecha_solicitud,
        d.estado_devolucion,
        dp.pedido_id,
        dp.cantidad AS cantidad_original,
        dp.precio_unitario_compra,
        p.cliente_id,
        c.nombre,
        c.apellido,
        c.email,
        pr.nombre_producto,
        s.sku
      FROM devoluciones d
      INNER JOIN detalle_pedido dp ON d.detalle_id = dp.detalle_id
      INNER JOIN pedidos p ON dp.pedido_id = p.pedido_id
      INNER JOIN clientes c ON p.cliente_id = c.cliente_id
      INNER JOIN stock s ON dp.stock_id = s.stock_id
      INNER JOIN productos pr ON s.producto_id = pr.producto_id
      ORDER BY d.devolucion_id DESC
    `);

    return new Response(JSON.stringify(result.rows), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    });
  } catch (error) {
    console.error('Error al obtener devoluciones:', error);
    return new Response(JSON.stringify({ error: 'Error al obtener devoluciones' }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
};

export const POST: APIRoute = async ({ request }) => {
  try {
    const formData = await request.formData();
    
    const detalle_id = parseInt(formData.get('detalle_id') as string);
    const cantidad_devuelta = parseInt(formData.get('cantidad_devuelta') as string);
    const motivo = formData.get('motivo') as string;

    console.log('Procesando devolución:', { detalle_id, cantidad_devuelta, motivo });

    // Llamar al procedimiento almacenado sp_procesar_devolucion
    await query(
      'CALL sp_procesar_devolucion($1, $2, $3)',
      [detalle_id, cantidad_devuelta, motivo]
    );

    return new Response(null, {
      status: 303,
      headers: { Location: '/devoluciones' }
    });

  } catch (error: any) {
    console.error('Error al procesar devolución:', error);
    
    // Redirigir con mensaje de error
    return new Response(null, {
      status: 303,
      headers: { 
        Location: '/devoluciones?error=' + encodeURIComponent(error.message || 'Error al procesar devolución')
      }
    });
  }
};
