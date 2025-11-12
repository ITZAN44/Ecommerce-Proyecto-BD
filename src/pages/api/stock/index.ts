import type { APIRoute } from 'astro';
import { query } from '../../../lib/db';

export const GET: APIRoute = async () => {
  try {
    const result = await query(`
      SELECT s.stock_id, s.producto_id, s.sku, s.precio_unitario, 
             s.cantidad_en_stock, s.cantidad_reservada, s.estado, s.fecha_creacion,
             p.nombre_producto, c.nombre_categoria
      FROM stock s
      JOIN productos p ON s.producto_id = p.producto_id
      JOIN categorias c ON p.categoria_id = c.categoria_id
      ORDER BY s.stock_id DESC
    `);
    
    return new Response(JSON.stringify(result.rows), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    });
  } catch (error) {
    console.error('Error en GET /api/stock:', error);
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

    // Actualizar SKU (PUT) - Solo SKU, producto y precio, NO cantidad
    if (data._method === 'PUT') {
      await query(
        `UPDATE stock 
         SET sku = $1, producto_id = $2, precio_unitario = $3
         WHERE stock_id = $4`,
        [
          data.sku,
          parseInt(data.producto_id),
          parseFloat(data.precio_unitario),
          parseInt(data.stock_id)
        ]
      );
      return new Response(null, {
        status: 302,
        headers: { Location: '/stock' }
      });
    }

    // Cambiar estado (PATCH)
    if (data._method === 'PATCH') {
      await query(
        'UPDATE stock SET estado = $1 WHERE stock_id = $2',
        [data.estado, parseInt(data.stock_id)]
      );
      return new Response(JSON.stringify({ success: true }), {
        status: 200,
        headers: { 'Content-Type': 'application/json' }
      });
    }

    // Eliminar stock físicamente (DELETE)
    if (data._method === 'DELETE') {
      try {
        await query('CALL sp_eliminar_stock($1)', [parseInt(data.stock_id)]);
        
        return new Response(null, {
          status: 302,
          headers: { Location: '/stock' }
        });
      } catch (deleteError: any) {
        return new Response(null, {
          status: 302,
          headers: { 
            Location: '/stock?error=' + encodeURIComponent(deleteError.message || 'Error al eliminar stock')
          }
        });
      }
    }

    // Crear nuevo SKU
    await query(
      `INSERT INTO stock (producto_id, sku, precio_unitario, cantidad_en_stock, cantidad_reservada)
       VALUES ($1, $2, $3, $4, 0)`,
      [
        parseInt(data.producto_id),
        data.sku,
        parseFloat(data.precio_unitario),
        parseInt(data.cantidad_en_stock)
      ]
    );

    return new Response(null, {
      status: 302,
      headers: { Location: '/stock' }
    });
  } catch (error) {
    console.error('Error en POST /api/stock:', error);
    return new Response(JSON.stringify({ error: (error as Error).message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
};
