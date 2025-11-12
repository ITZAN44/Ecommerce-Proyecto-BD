import type { APIRoute } from 'astro';
import { query } from '../../../lib/db';

export const GET: APIRoute = async () => {
  try {
    const result = await query(`
      SELECT p.producto_id, p.categoria_id, p.nombre_producto, 
             p.descripcion_larga, p.estado, p.fecha_creacion,
             c.nombre_categoria, 
             COALESCE(s.cantidad_en_stock, 0) as cantidad_en_stock,
             COALESCE(s.precio_unitario, 0) as precio_unitario
      FROM productos p
      LEFT JOIN categorias c ON p.categoria_id = c.categoria_id
      LEFT JOIN stock s ON p.producto_id = s.producto_id
      ORDER BY p.producto_id DESC
    `);
    
    return new Response(JSON.stringify(result.rows), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    });
  } catch (error) {
    console.error('Error en GET /api/productos:', error);
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

    // Actualizar producto (PUT)
    if (data._method === 'PUT') {
      // Actualizar información del producto
      await query(
        `UPDATE productos 
         SET nombre_producto = $1, descripcion_larga = $2, categoria_id = $3
         WHERE producto_id = $4`,
        [
          data.nombre_producto,
          data.descripcion,
          parseInt(data.categoria_id),
          parseInt(data.producto_id)
        ]
      );
      
      // Si se proporcionó un precio, actualizar en la tabla stock
      if (data.precio) {
        await query(
          `UPDATE stock 
           SET precio_unitario = $1 
           WHERE producto_id = $2`,
          [
            parseFloat(data.precio),
            parseInt(data.producto_id)
          ]
        );
      }
      
      return new Response(null, {
        status: 302,
        headers: { Location: '/productos' }
      });
    }

    // Cambiar estado (PATCH)
    if (data._method === 'PATCH') {
      await query(
        'UPDATE productos SET estado = $1 WHERE producto_id = $2',
        [data.estado, parseInt(data.producto_id)]
      );
      return new Response(JSON.stringify({ success: true }), {
        status: 200,
        headers: { 'Content-Type': 'application/json' }
      });
    }

    // Eliminar producto físicamente (DELETE)
    if (data._method === 'DELETE') {
      try {
        await query('CALL sp_eliminar_producto($1)', [parseInt(data.producto_id)]);
        
        return new Response(null, {
          status: 302,
          headers: { Location: '/productos' }
        });
      } catch (deleteError: any) {
        return new Response(null, {
          status: 302,
          headers: { 
            Location: '/productos?error=' + encodeURIComponent(deleteError.message || 'Error al eliminar producto')
          }
        });
      }
    }

    // Crear nuevo producto
    await query(
      `INSERT INTO productos (nombre_producto, descripcion_larga, categoria_id)
       VALUES ($1, $2, $3)`,
      [
        data.nombre_producto,
        data.descripcion,
        parseInt(data.categoria_id)
      ]
    );

    return new Response(null, {
      status: 302,
      headers: { Location: '/productos' }
    });
  } catch (error) {
    console.error('Error en POST /api/productos:', error);
    return new Response(JSON.stringify({ error: (error as Error).message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
};
