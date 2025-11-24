import type { APIRoute } from 'astro';
import { query } from '../../../lib/db';

export const GET: APIRoute = async ({ url }) => {
  try {
    const codigo = url.searchParams.get('codigo');

    if (!codigo) {
      return new Response(JSON.stringify({
        valido: false,
        mensaje: 'Código de cupón no proporcionado'
      }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' }
      });
    }

    const result = await query(
      'SELECT fn_validar_cupon_aplicable($1) as es_valido',
      [codigo]
    );

    const esValido = result.rows[0]?.es_valido;

    if (esValido) {
      const cuponResult = await query(
        `SELECT codigo_cupon, tipo_descuento, valor_descuento, fecha_expiracion, usos_disponibles
         FROM cupones
         WHERE codigo_cupon = $1`,
        [codigo]
      );

      const cupon = cuponResult.rows[0];
      const descuento = cupon.tipo_descuento === 'porcentaje'
        ? `${cupon.valor_descuento}%`
        : `$${parseFloat(cupon.valor_descuento).toFixed(2)}`;

      return new Response(JSON.stringify({
        valido: true,
        mensaje: `Cupón válido\n- Descuento: ${descuento}\n- Usos disponibles: ${cupon.usos_disponibles || 'Ilimitado'}\n- Expira: ${cupon.fecha_expiracion ? new Date(cupon.fecha_expiracion).toLocaleDateString('es-ES') : 'Sin expiración'}`,
        cupon: cupon
      }), {
        status: 200,
        headers: { 'Content-Type': 'application/json' }
      });
    } else {
      return new Response(JSON.stringify({
        valido: false,
        mensaje: 'Cupón inválido, expirado o sin usos disponibles'
      }), {
        status: 200,
        headers: { 'Content-Type': 'application/json' }
      });
    }
  } catch (error) {
    console.error('Error al validar cupón:', error);
    return new Response(JSON.stringify({
      valido: false,
      mensaje: 'Error al validar el cupón: ' + (error as Error).message
    }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
};
