--
-- PostgreSQL database dump
--

\restrict EXlVRB9WuFJwEzHj8QKh5UYv1kQSMD37R61tDcNfc7zJnQ62hsGvArtNjTEbZwK

-- Dumped from database version 16.11
-- Dumped by pg_dump version 16.11

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: fn_actualizar_fecha_modificacion(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_actualizar_fecha_modificacion() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Comprueba si la fila realmente cambió
    IF (OLD IS DISTINCT FROM NEW) THEN
        NEW.fecha_modificacion = NOW();
    END IF;
    RETURN NEW;
END;
$$;


--
-- Name: fn_alerta_stock_bajo(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_alerta_stock_bajo(p_limite integer DEFAULT 15) RETURNS TABLE(stock_id integer, producto_id integer, sku character varying, nombre_producto character varying, cantidad_disponible integer, cantidad_reservada integer, nivel_criticidad character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.stock_id,
        s.producto_id,
        s.sku,
        p.nombre_producto,
        s.cantidad_en_stock AS cantidad_disponible,
        s.cantidad_reservada,
        (CASE 
            WHEN (s.cantidad_en_stock - s.cantidad_reservada) = 0 THEN 'CRÍTICO'
            WHEN (s.cantidad_en_stock - s.cantidad_reservada) <= 3 THEN 'URGENTE'
            WHEN (s.cantidad_en_stock - s.cantidad_reservada) <= p_limite THEN 'ADVERTENCIA'
            ELSE 'NORMAL'
        END)::VARCHAR(20) AS nivel_criticidad
    FROM stock s
    JOIN productos p ON s.producto_id = p.producto_id
    WHERE (s.cantidad_en_stock - s.cantidad_reservada) <= p_limite
        AND s.estado = 'activo'
        AND p.estado = 'activo'
    ORDER BY (s.cantidad_en_stock - s.cantidad_reservada) ASC, p.nombre_producto;
END;
$$;


--
-- Name: fn_auditoria_categorias(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_auditoria_categorias() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        INSERT INTO auditoria (tabla, operacion, registro_id, usuario, datos_anteriores, datos_nuevos)
        VALUES ('categorias', 'UPDATE', NEW.categoria_id, current_user, row_to_json(OLD)::JSONB, row_to_json(NEW)::JSONB);
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO auditoria (tabla, operacion, registro_id, usuario, datos_anteriores)
        VALUES ('categorias', 'DELETE', OLD.categoria_id, current_user, row_to_json(OLD)::JSONB);
        RETURN OLD;
    ELSIF TG_OP = 'INSERT' THEN
        INSERT INTO auditoria (tabla, operacion, registro_id, usuario, datos_nuevos)
        VALUES ('categorias', 'INSERT', NEW.categoria_id, current_user, row_to_json(NEW)::JSONB);
        RETURN NEW;
    END IF;
END;
$$;


--
-- Name: fn_auditoria_clientes(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_auditoria_clientes() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        INSERT INTO auditoria (tabla, operacion, registro_id, usuario, datos_anteriores, datos_nuevos)
        VALUES ('clientes', 'UPDATE', NEW.cliente_id, current_user, row_to_json(OLD)::JSONB, row_to_json(NEW)::JSONB);
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO auditoria (tabla, operacion, registro_id, usuario, datos_anteriores)
        VALUES ('clientes', 'DELETE', OLD.cliente_id, current_user, row_to_json(OLD)::JSONB);
        RETURN OLD;
    ELSIF TG_OP = 'INSERT' THEN
        INSERT INTO auditoria (tabla, operacion, registro_id, usuario, datos_nuevos)
        VALUES ('clientes', 'INSERT', NEW.cliente_id, current_user, row_to_json(NEW)::JSONB);
        RETURN NEW;
    END IF;
END;
$$;


--
-- Name: fn_auditoria_cupones(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_auditoria_cupones() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        INSERT INTO auditoria (tabla, operacion, registro_id, usuario, datos_anteriores, datos_nuevos)
        VALUES ('cupones', 'UPDATE', NEW.cupon_id, current_user, row_to_json(OLD)::JSONB, row_to_json(NEW)::JSONB);
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO auditoria (tabla, operacion, registro_id, usuario, datos_anteriores)
        VALUES ('cupones', 'DELETE', OLD.cupon_id, current_user, row_to_json(OLD)::JSONB);
        RETURN OLD;
    ELSIF TG_OP = 'INSERT' THEN
        INSERT INTO auditoria (tabla, operacion, registro_id, usuario, datos_nuevos)
        VALUES ('cupones', 'INSERT', NEW.cupon_id, current_user, row_to_json(NEW)::JSONB);
        RETURN NEW;
    END IF;
END;
$$;


--
-- Name: fn_auditoria_generica(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_auditoria_generica() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        INSERT INTO auditoria (tabla, operacion, registro_id, usuario, datos_anteriores, datos_nuevos)
        VALUES (
            TG_TABLE_NAME,
            'UPDATE',
            CASE TG_TABLE_NAME
                WHEN 'productos' THEN NEW.producto_id
                WHEN 'clientes' THEN NEW.cliente_id
                WHEN 'stock' THEN NEW.stock_id
                WHEN 'pedidos' THEN NEW.pedido_id
                WHEN 'pagos' THEN NEW.pago_id
                WHEN 'cupones' THEN NEW.cupon_id
                WHEN 'categorias' THEN NEW.categoria_id
            END,
            current_user,
            row_to_json(OLD)::JSONB,
            row_to_json(NEW)::JSONB
        );
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO auditoria (tabla, operacion, registro_id, usuario, datos_anteriores)
        VALUES (
            TG_TABLE_NAME,
            'DELETE',
            CASE TG_TABLE_NAME
                WHEN 'productos' THEN OLD.producto_id
                WHEN 'clientes' THEN OLD.cliente_id
                WHEN 'stock' THEN OLD.stock_id
                WHEN 'pedidos' THEN OLD.pedido_id
                WHEN 'pagos' THEN OLD.pago_id
                WHEN 'cupones' THEN OLD.cupon_id
                WHEN 'categorias' THEN OLD.categoria_id
            END,
            current_user,
            row_to_json(OLD)::JSONB
        );
        RETURN OLD;
    ELSIF TG_OP = 'INSERT' THEN
        INSERT INTO auditoria (tabla, operacion, registro_id, usuario, datos_nuevos)
        VALUES (
            TG_TABLE_NAME,
            'INSERT',
            CASE TG_TABLE_NAME
                WHEN 'productos' THEN NEW.producto_id
                WHEN 'clientes' THEN NEW.cliente_id
                WHEN 'stock' THEN NEW.stock_id
                WHEN 'pedidos' THEN NEW.pedido_id
                WHEN 'pagos' THEN NEW.pago_id
                WHEN 'cupones' THEN NEW.cupon_id
                WHEN 'categorias' THEN NEW.categoria_id
            END,
            current_user,
            row_to_json(NEW)::JSONB
        );
        RETURN NEW;
    END IF;
END;
$$;


--
-- Name: fn_auditoria_pagos(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_auditoria_pagos() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        INSERT INTO auditoria (tabla, operacion, registro_id, usuario, datos_anteriores, datos_nuevos)
        VALUES ('pagos', 'UPDATE', NEW.pago_id, current_user, row_to_json(OLD)::JSONB, row_to_json(NEW)::JSONB);
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO auditoria (tabla, operacion, registro_id, usuario, datos_anteriores)
        VALUES ('pagos', 'DELETE', OLD.pago_id, current_user, row_to_json(OLD)::JSONB);
        RETURN OLD;
    ELSIF TG_OP = 'INSERT' THEN
        INSERT INTO auditoria (tabla, operacion, registro_id, usuario, datos_nuevos)
        VALUES ('pagos', 'INSERT', NEW.pago_id, current_user, row_to_json(NEW)::JSONB);
        RETURN NEW;
    END IF;
END;
$$;


--
-- Name: fn_auditoria_pedidos(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_auditoria_pedidos() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        INSERT INTO auditoria (tabla, operacion, registro_id, usuario, datos_anteriores, datos_nuevos)
        VALUES ('pedidos', 'UPDATE', NEW.pedido_id, current_user, row_to_json(OLD)::JSONB, row_to_json(NEW)::JSONB);
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO auditoria (tabla, operacion, registro_id, usuario, datos_anteriores)
        VALUES ('pedidos', 'DELETE', OLD.pedido_id, current_user, row_to_json(OLD)::JSONB);
        RETURN OLD;
    ELSIF TG_OP = 'INSERT' THEN
        INSERT INTO auditoria (tabla, operacion, registro_id, usuario, datos_nuevos)
        VALUES ('pedidos', 'INSERT', NEW.pedido_id, current_user, row_to_json(NEW)::JSONB);
        RETURN NEW;
    END IF;
END;
$$;


--
-- Name: fn_auditoria_productos(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_auditoria_productos() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        INSERT INTO auditoria (tabla, operacion, registro_id, usuario, datos_anteriores, datos_nuevos)
        VALUES ('productos', 'UPDATE', NEW.producto_id, current_user, row_to_json(OLD)::JSONB, row_to_json(NEW)::JSONB);
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO auditoria (tabla, operacion, registro_id, usuario, datos_anteriores)
        VALUES ('productos', 'DELETE', OLD.producto_id, current_user, row_to_json(OLD)::JSONB);
        RETURN OLD;
    ELSIF TG_OP = 'INSERT' THEN
        INSERT INTO auditoria (tabla, operacion, registro_id, usuario, datos_nuevos)
        VALUES ('productos', 'INSERT', NEW.producto_id, current_user, row_to_json(NEW)::JSONB);
        RETURN NEW;
    END IF;
END;
$$;


--
-- Name: fn_auditoria_stock(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_auditoria_stock() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        INSERT INTO auditoria (tabla, operacion, registro_id, usuario, datos_anteriores, datos_nuevos)
        VALUES ('stock', 'UPDATE', NEW.stock_id, current_user, row_to_json(OLD)::JSONB, row_to_json(NEW)::JSONB);
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO auditoria (tabla, operacion, registro_id, usuario, datos_anteriores)
        VALUES ('stock', 'DELETE', OLD.stock_id, current_user, row_to_json(OLD)::JSONB);
        RETURN OLD;
    ELSIF TG_OP = 'INSERT' THEN
        INSERT INTO auditoria (tabla, operacion, registro_id, usuario, datos_nuevos)
        VALUES ('stock', 'INSERT', NEW.stock_id, current_user, row_to_json(NEW)::JSONB);
        RETURN NEW;
    END IF;
END;
$$;


--
-- Name: fn_calcular_comision_venta(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_calcular_comision_venta(p_pedido_id integer) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_total NUMERIC(12, 2);
    v_comision NUMERIC(12, 2);
BEGIN
    SELECT total_pedido
    INTO v_total
    FROM pedidos
    WHERE pedido_id = p_pedido_id;
    
    v_comision := v_total * 0.05; -- 5% de comisión
    
    RETURN COALESCE(v_comision, 0);
END;
$$;


--
-- Name: fn_calcular_descuento_cupon(integer, numeric); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_calcular_descuento_cupon(p_cupon_id integer, p_subtotal numeric) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_tipo_descuento VARCHAR(20);
    v_valor_descuento NUMERIC(10, 2);
    v_descuento NUMERIC(12, 2);
BEGIN
    -- Si no hay cupón, retorna 0
    IF p_cupon_id IS NULL THEN
        RETURN 0;
    END IF;
    
    -- Obtener datos del cupón
    SELECT tipo_descuento, valor_descuento
    INTO v_tipo_descuento, v_valor_descuento
    FROM cupones
    WHERE cupon_id = p_cupon_id
        AND estado = 'activo'
        AND (fecha_expiracion IS NULL OR fecha_expiracion >= CURRENT_DATE)
        AND (usos_disponibles IS NULL OR usos_disponibles > 0);
    
    -- Si no se encontró cupón válido
    IF NOT FOUND THEN
        RETURN 0;
    END IF;
    
    -- Calcular descuento según tipo
    IF v_tipo_descuento = 'porcentaje' THEN
        v_descuento := p_subtotal * (v_valor_descuento / 100);
    ELSE -- tipo 'fijo'
        v_descuento := v_valor_descuento;
    END IF;
    
    -- No puede ser mayor al subtotal
    IF v_descuento > p_subtotal THEN
        v_descuento := p_subtotal;
    END IF;
    
    RETURN v_descuento;
END;
$$;


--
-- Name: fn_calcular_monto_reembolso(integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_calcular_monto_reembolso(p_detalle_id integer, p_cantidad_devuelta integer) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_precio_unitario NUMERIC(10, 2);
    v_cantidad_original INT;
    v_monto_reembolso NUMERIC(12, 2);
BEGIN
    -- Obtener precio y cantidad original
    SELECT precio_unitario_compra, cantidad
    INTO v_precio_unitario, v_cantidad_original
    FROM detalle_pedido
    WHERE detalle_id = p_detalle_id;
    
    IF NOT FOUND THEN
        RETURN 0;
    END IF;
    
    -- Validar que no se devuelva más de lo comprado
    IF p_cantidad_devuelta > v_cantidad_original THEN
        RAISE EXCEPTION 'No se puede devolver más items de los comprados';
    END IF;
    
    -- Calcular reembolso
    v_monto_reembolso := v_precio_unitario * p_cantidad_devuelta;
    
    RETURN v_monto_reembolso;
END;
$$;


--
-- Name: fn_calcular_puntos_fidelidad(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_calcular_puntos_fidelidad(p_cliente_id integer) RETURNS integer
    LANGUAGE plpgsql
    AS $_$
DECLARE
    v_total_gastado NUMERIC(12, 2);
    v_puntos INT;
BEGIN
    SELECT COALESCE(SUM(total_pedido), 0)
    INTO v_total_gastado
    FROM pedidos
    WHERE cliente_id = p_cliente_id
        AND estado_pedido IN ('pagado', 'enviado', 'completado');
    
    -- 1 punto por cada $10
    v_puntos := FLOOR(v_total_gastado / 10);
    
    RETURN v_puntos;
END;
$_$;


--
-- Name: fn_calcular_tiempo_entrega(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_calcular_tiempo_entrega(p_envio_id integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_fecha_envio TIMESTAMP;
    v_dias INT;
BEGIN
    SELECT fecha_envio
    INTO v_fecha_envio
    FROM envios
    WHERE envio_id = p_envio_id;
    
    IF v_fecha_envio IS NULL THEN
        RETURN NULL;
    END IF;
    
    v_dias := EXTRACT(DAY FROM (NOW() - v_fecha_envio));
    
    RETURN v_dias;
END;
$$;


--
-- Name: fn_calcular_total_pedido(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_calcular_total_pedido(p_pedido_id integer) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_total NUMERIC(12, 2);
BEGIN
    SELECT COALESCE(SUM(cantidad * precio_unitario_compra), 0)
    INTO v_total
    FROM detalle_pedido
    WHERE pedido_id = p_pedido_id;
    
    RETURN v_total;
END;
$$;


--
-- Name: fn_calcular_total_ventas_periodo(timestamp without time zone, timestamp without time zone); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_calcular_total_ventas_periodo(p_fecha_desde timestamp without time zone, p_fecha_hasta timestamp without time zone) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_total NUMERIC(12, 2);
BEGIN
    SELECT COALESCE(SUM(total_pedido), 0)
    INTO v_total
    FROM pedidos
    WHERE estado_pedido IN ('pagado', 'enviado', 'completado')
        AND fecha_creacion BETWEEN p_fecha_desde AND p_fecha_hasta;
    
    RETURN v_total;
END;
$$;


--
-- Name: fn_cambiar_estado_pedido(integer, character varying, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_cambiar_estado_pedido(p_pedido_id integer, p_nuevo_estado character varying, p_comentario text DEFAULT NULL::text) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_estado_actual VARCHAR(50);
BEGIN
    -- Obtener estado actual
    SELECT estado_pedido INTO v_estado_actual
    FROM pedidos
    WHERE pedido_id = p_pedido_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Pedido % no encontrado', p_pedido_id;
    END IF;
    
    -- Validar que el estado sea diferente
    IF v_estado_actual = p_nuevo_estado THEN
        RAISE NOTICE 'El pedido ya está en estado %', p_nuevo_estado;
        RETURN FALSE;
    END IF;
    
    -- Actualizar estado (el trigger registrará el cambio automáticamente)
    UPDATE pedidos
    SET estado_pedido = p_nuevo_estado
    WHERE pedido_id = p_pedido_id;
    
    -- Si se proporcionó un comentario personalizado, actualizar el último registro
    IF p_comentario IS NOT NULL THEN
        UPDATE historial_estados
        SET comentario = p_comentario
        WHERE historial_id = (
            SELECT historial_id 
            FROM historial_estados 
            WHERE pedido_id = p_pedido_id 
            ORDER BY fecha_cambio DESC 
            LIMIT 1
        );
    END IF;
    
    RETURN TRUE;
END;
$$;


--
-- Name: FUNCTION fn_cambiar_estado_pedido(p_pedido_id integer, p_nuevo_estado character varying, p_comentario text); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.fn_cambiar_estado_pedido(p_pedido_id integer, p_nuevo_estado character varying, p_comentario text) IS 'Cambia el estado de un pedido con comentario personalizado opcional. 
El trigger registra automáticamente el cambio en historial_estados.';


--
-- Name: fn_cliente_tiene_pedidos(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_cliente_tiene_pedidos(p_cliente_id integer) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_count INT;
BEGIN
    SELECT COUNT(*)
    INTO v_count
    FROM pedidos
    WHERE cliente_id = p_cliente_id;
    
    RETURN (v_count > 0);
END;
$$;


--
-- Name: fn_distribucion_estados_pedidos(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_distribucion_estados_pedidos() RETURNS TABLE(estado_pedido character varying, cantidad bigint, porcentaje numeric)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    WITH totales AS (
        SELECT COUNT(*)::NUMERIC AS total_pedidos
        FROM pedidos
    )
    SELECT 
        p.estado_pedido::VARCHAR(50),
        COUNT(p.pedido_id) AS cantidad,
        ROUND((COUNT(p.pedido_id)::NUMERIC / t.total_pedidos * 100), 2) AS porcentaje
    FROM pedidos p
    CROSS JOIN totales t
    GROUP BY p.estado_pedido, t.total_pedidos
    ORDER BY cantidad DESC;
END;
$$;


--
-- Name: FUNCTION fn_distribucion_estados_pedidos(); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.fn_distribucion_estados_pedidos() IS 'Retorna distribución porcentual de estados de pedidos para gráfico circular';


--
-- Name: fn_estadisticas_dashboard(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_estadisticas_dashboard() RETURNS TABLE(total_pedidos_hoy integer, total_pedidos_pendientes integer, total_pedidos_completados integer, ventas_hoy numeric, ventas_mes numeric, total_clientes_activos integer, total_productos_activos integer, productos_stock_bajo integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        (SELECT COUNT(*)::INT FROM pedidos WHERE DATE(fecha_pedido) = CURRENT_DATE),
        (SELECT COUNT(*)::INT FROM pedidos WHERE estado_pedido = 'pendiente'),
        (SELECT COUNT(*)::INT FROM pedidos WHERE estado_pedido = 'completado'),
        (SELECT COALESCE(SUM(total_pedido), 0) FROM pedidos WHERE DATE(fecha_pedido) = CURRENT_DATE),
        (SELECT COALESCE(SUM(total_pedido), 0) FROM pedidos WHERE fecha_pedido >= DATE_TRUNC('month', CURRENT_DATE)),
        (SELECT COUNT(*)::INT FROM clientes WHERE estado = 'activo'),
        (SELECT COUNT(*)::INT FROM productos WHERE estado = 'activo'),
        (SELECT COUNT(*)::INT FROM stock WHERE (cantidad_en_stock - cantidad_reservada) < 15 AND estado = 'activo');
END;
$$;


--
-- Name: fn_estadisticas_estados(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_estadisticas_estados(p_pedido_id integer) RETURNS TABLE(estado character varying, fecha_inicio timestamp without time zone, fecha_fin timestamp without time zone, duracion_horas numeric)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    WITH estados_con_siguiente AS (
        SELECT 
            h.estado_nuevo,
            h.fecha_cambio AS fecha_inicio,
            LEAD(h.fecha_cambio) OVER (ORDER BY h.fecha_cambio) AS fecha_fin
        FROM historial_estados h
        WHERE h.pedido_id = p_pedido_id
    )
    SELECT 
        e.estado_nuevo::VARCHAR(50) AS estado,
        e.fecha_inicio,
        e.fecha_fin,
        CASE 
            WHEN e.fecha_fin IS NOT NULL THEN 
                ROUND(EXTRACT(EPOCH FROM (e.fecha_fin - e.fecha_inicio)) / 3600, 2)
            ELSE 
                ROUND(EXTRACT(EPOCH FROM (NOW() - e.fecha_inicio)) / 3600, 2)
        END AS duracion_horas
    FROM estados_con_siguiente e
    ORDER BY e.fecha_inicio ASC;
END;
$$;


--
-- Name: FUNCTION fn_estadisticas_estados(p_pedido_id integer); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.fn_estadisticas_estados(p_pedido_id integer) IS 'Calcula la duración de cada estado del pedido en horas. 
Útil para métricas de rendimiento y tiempos de procesamiento.';


--
-- Name: fn_historial_cambios(character varying, integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_historial_cambios(p_tabla character varying, p_registro_id integer, p_limite integer DEFAULT 50) RETURNS TABLE(auditoria_id integer, operacion character varying, usuario character varying, fecha timestamp without time zone, cambios jsonb)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        a.auditoria_id,
        a.operacion::VARCHAR(10),
        a.usuario::VARCHAR(100),
        a.fecha,
        (CASE 
            WHEN a.operacion = 'UPDATE' THEN 
                jsonb_build_object(
                    'anterior', a.datos_anteriores,
                    'nuevo', a.datos_nuevos
                )
            WHEN a.operacion = 'DELETE' THEN a.datos_anteriores
            WHEN a.operacion = 'INSERT' THEN a.datos_nuevos
        END)::JSONB AS cambios
    FROM auditoria a
    WHERE a.tabla = p_tabla
        AND a.registro_id = p_registro_id
    ORDER BY a.fecha DESC
    LIMIT p_limite;
END;
$$;


--
-- Name: fn_metricas_producto(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_metricas_producto(p_producto_id integer) RETURNS TABLE(producto_id integer, nombre_producto character varying, total_vendido bigint, ingresos_totales numeric, numero_pedidos bigint, stock_total integer, stock_reservado integer, precio_promedio numeric)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.producto_id,
        p.nombre_producto,
        COALESCE(SUM(dp.cantidad), 0) AS total_vendido,
        COALESCE(SUM(dp.cantidad * dp.precio_unitario_compra), 0) AS ingresos_totales,
        COUNT(DISTINCT ped.pedido_id) AS numero_pedidos,
        COALESCE(SUM(s.cantidad_en_stock), 0)::INT AS stock_total,
        COALESCE(SUM(s.cantidad_reservada), 0)::INT AS stock_reservado,
        COALESCE(AVG(s.precio_unitario), 0) AS precio_promedio
    FROM productos p
    LEFT JOIN stock s ON p.producto_id = s.producto_id
    LEFT JOIN detalle_pedido dp ON s.stock_id = dp.stock_id
    LEFT JOIN pedidos ped ON dp.pedido_id = ped.pedido_id 
        AND ped.estado_pedido IN ('pagado', 'enviado', 'completado')
    WHERE p.producto_id = p_producto_id
    GROUP BY p.producto_id, p.nombre_producto;
END;
$$;


--
-- Name: fn_obtener_clientes_frecuentes(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_obtener_clientes_frecuentes(p_limite integer DEFAULT 10) RETURNS TABLE(cliente_id integer, nombre character varying, apellido character varying, email character varying, total_pedidos bigint, total_gastado numeric)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.cliente_id,
        c.nombre,
        c.apellido,
        c.email,
        COUNT(p.pedido_id) AS total_pedidos,
        COALESCE(SUM(p.total_pedido), 0) AS total_gastado
    FROM clientes c
    LEFT JOIN pedidos p ON c.cliente_id = p.cliente_id
        AND p.estado_pedido IN ('pagado', 'enviado', 'completado')
    GROUP BY c.cliente_id, c.nombre, c.apellido, c.email
    HAVING COUNT(p.pedido_id) > 0
    ORDER BY total_pedidos DESC, total_gastado DESC
    LIMIT p_limite;
END;
$$;


--
-- Name: fn_obtener_precio_producto(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_obtener_precio_producto(p_stock_id integer) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_precio NUMERIC(10, 2);
BEGIN
    SELECT precio_unitario
    INTO v_precio
    FROM stock
    WHERE stock_id = p_stock_id
        AND estado = 'activo';
    
    RETURN COALESCE(v_precio, 0);
END;
$$;


--
-- Name: fn_obtener_productos_mas_vendidos(integer, timestamp without time zone, timestamp without time zone); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_obtener_productos_mas_vendidos(p_limite integer DEFAULT 10, p_fecha_desde timestamp without time zone DEFAULT NULL::timestamp without time zone, p_fecha_hasta timestamp without time zone DEFAULT NULL::timestamp without time zone) RETURNS TABLE(producto_id integer, nombre_producto character varying, total_vendido bigint, ingresos_generados numeric)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.producto_id,
        p.nombre_producto,
        SUM(dp.cantidad) AS total_vendido,
        SUM(dp.cantidad * dp.precio_unitario_compra) AS ingresos_generados
    FROM detalle_pedido dp
    JOIN stock s ON dp.stock_id = s.stock_id
    JOIN productos p ON s.producto_id = p.producto_id
    JOIN pedidos ped ON dp.pedido_id = ped.pedido_id
    WHERE ped.estado_pedido IN ('pagado', 'enviado', 'completado')
        AND (p_fecha_desde IS NULL OR ped.fecha_creacion >= p_fecha_desde)
        AND (p_fecha_hasta IS NULL OR ped.fecha_creacion <= p_fecha_hasta)
    GROUP BY p.producto_id, p.nombre_producto
    ORDER BY total_vendido DESC
    LIMIT p_limite;
END;
$$;


--
-- Name: fn_obtener_timeline_pedido(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_obtener_timeline_pedido(p_pedido_id integer) RETURNS TABLE(historial_id integer, pedido_id integer, estado_anterior character varying, estado_nuevo character varying, usuario character varying, comentario text, fecha_cambio timestamp without time zone, orden integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        h.historial_id,
        h.pedido_id,
        h.estado_anterior,
        h.estado_nuevo,
        h.usuario,
        h.comentario,
        h.fecha_cambio,
        ROW_NUMBER() OVER (ORDER BY h.fecha_cambio ASC)::INT AS orden
    FROM historial_estados h
    WHERE h.pedido_id = p_pedido_id
    ORDER BY h.fecha_cambio ASC;
END;
$$;


--
-- Name: FUNCTION fn_obtener_timeline_pedido(p_pedido_id integer); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.fn_obtener_timeline_pedido(p_pedido_id integer) IS 'Obtiene el timeline completo de un pedido con estados ordenados cronológicamente. 
Incluye orden secuencial para renderizado frontend.';


--
-- Name: fn_registrar_cambio_estado(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_registrar_cambio_estado() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Solo registrar si cambió el estado_pedido
    IF (TG_OP = 'INSERT') THEN
        -- Primer estado (creación del pedido)
        INSERT INTO historial_estados (
            pedido_id,
            estado_anterior,
            estado_nuevo,
            usuario,
            comentario
        ) VALUES (
            NEW.pedido_id,
            NULL,
            NEW.estado_pedido,
            current_user,
            'Pedido creado'
        );
    ELSIF (TG_OP = 'UPDATE' AND OLD.estado_pedido IS DISTINCT FROM NEW.estado_pedido) THEN
        -- Cambio de estado
        INSERT INTO historial_estados (
            pedido_id,
            estado_anterior,
            estado_nuevo,
            usuario,
            comentario
        ) VALUES (
            NEW.pedido_id,
            OLD.estado_pedido,
            NEW.estado_pedido,
            current_user,
            CASE 
                WHEN NEW.estado_pedido = 'pagado' THEN 'Pago confirmado'
                WHEN NEW.estado_pedido = 'enviado' THEN 'Pedido en tránsito'
                WHEN NEW.estado_pedido = 'completado' THEN 'Pedido entregado'
                WHEN NEW.estado_pedido = 'cancelado' THEN 'Pedido cancelado'
                ELSE 'Estado actualizado'
            END
        );
    END IF;
    
    RETURN NEW;
END;
$$;


--
-- Name: FUNCTION fn_registrar_cambio_estado(); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.fn_registrar_cambio_estado() IS 'Trigger automático que registra cambios de estado en historial_estados. 
Se ejecuta DESPUÉS de INSERT o UPDATE en tabla pedidos.';


--
-- Name: fn_tendencia_pedidos(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_tendencia_pedidos(p_dias integer DEFAULT 30) RETURNS TABLE(fecha date, total_pedidos bigint, pedidos_completados bigint, pedidos_cancelados bigint)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        DATE(p.fecha_pedido) AS fecha,
        COUNT(p.pedido_id) AS total_pedidos,
        COUNT(CASE WHEN p.estado_pedido = 'completado' THEN 1 END) AS pedidos_completados,
        COUNT(CASE WHEN p.estado_pedido = 'cancelado' THEN 1 END) AS pedidos_cancelados
    FROM pedidos p
    WHERE p.fecha_pedido >= CURRENT_DATE - (p_dias || ' days')::INTERVAL
    GROUP BY DATE(p.fecha_pedido)
    ORDER BY fecha ASC;
END;
$$;


--
-- Name: FUNCTION fn_tendencia_pedidos(p_dias integer); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.fn_tendencia_pedidos(p_dias integer) IS 'Retorna tendencia de pedidos por día para análisis de volumen';


--
-- Name: fn_validar_cupon_aplicable(character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_validar_cupon_aplicable(p_codigo_cupon character varying) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_cupon_valido INT;
BEGIN
    SELECT COUNT(*)
    INTO v_cupon_valido
    FROM cupones
    WHERE codigo_cupon = p_codigo_cupon
        AND estado = 'activo'
        AND (fecha_expiracion IS NULL OR fecha_expiracion >= CURRENT_DATE)
        AND (usos_disponibles IS NULL OR usos_disponibles > 0);
    
    RETURN (v_cupon_valido > 0);
END;
$$;


--
-- Name: fn_validar_devolucion_permitida(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_validar_devolucion_permitida(p_pedido_id integer) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_estado_pedido VARCHAR(50);
    v_fecha_envio TIMESTAMP;
    v_dias_transcurridos INT;
BEGIN
    -- Obtener estado del pedido y fecha de envío
    SELECT p.estado_pedido, e.fecha_envio
    INTO v_estado_pedido, v_fecha_envio
    FROM pedidos p
    LEFT JOIN envios e ON p.pedido_id = e.pedido_id
    WHERE p.pedido_id = p_pedido_id;
    
    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;
    
    -- El pedido debe estar completado
    IF v_estado_pedido NOT IN ('completado', 'enviado') THEN
        RETURN FALSE;
    END IF;
    
    -- Si no hay fecha de envío, no se puede devolver
    IF v_fecha_envio IS NULL THEN
        RETURN FALSE;
    END IF;
    
    -- Calcular días transcurridos
    v_dias_transcurridos := EXTRACT(DAY FROM (NOW() - v_fecha_envio));
    
    -- Máximo 30 días para devolución
    RETURN (v_dias_transcurridos <= 30);
END;
$$;


--
-- Name: fn_validar_stock_disponible(integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_validar_stock_disponible(p_stock_id integer, p_cantidad_solicitada integer) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_disponible INT;
BEGIN
    SELECT (cantidad_en_stock - cantidad_reservada)
    INTO v_disponible
    FROM stock
    WHERE stock_id = p_stock_id;
    
    RETURN (v_disponible >= p_cantidad_solicitada);
END;
$$;


--
-- Name: fn_ventas_diarias(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_ventas_diarias(p_dias integer DEFAULT 7) RETURNS TABLE(fecha date, total_ventas numeric, numero_pedidos bigint)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    WITH fecha_series AS (
        SELECT generate_series(
            CURRENT_DATE - (p_dias - 1),
            CURRENT_DATE,
            '1 day'::interval
        )::DATE AS fecha
    )
    SELECT
        fs.fecha,
        COALESCE(SUM(p.total_pedido), 0)::NUMERIC(12,2) AS total_ventas,
        COUNT(p.pedido_id) AS numero_pedidos
    FROM fecha_series fs
    LEFT JOIN pedidos p ON DATE(p.fecha_pedido) = fs.fecha
        AND p.estado_pedido IN ('pagado', 'enviado', 'completado')
    GROUP BY fs.fecha
    ORDER BY fs.fecha ASC;
END;
$$;


--
-- Name: FUNCTION fn_ventas_diarias(p_dias integer); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.fn_ventas_diarias(p_dias integer) IS 'Retorna ventas diarias de los últimos N días incluyendo días sin ventas (genera serie completa de fechas)';


--
-- Name: fn_ventas_por_categoria(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_ventas_por_categoria(p_limite integer DEFAULT 10) RETURNS TABLE(categoria_id integer, nombre_categoria character varying, total_ventas numeric, cantidad_productos_vendidos bigint, numero_pedidos bigint)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.categoria_id,
        c.nombre_categoria,
        COALESCE(SUM(dp.cantidad * dp.precio_unitario_compra), 0) AS total_ventas,
        COALESCE(SUM(dp.cantidad), 0) AS cantidad_productos_vendidos,
        COUNT(DISTINCT ped.pedido_id) AS numero_pedidos
    FROM categorias c
    LEFT JOIN productos p ON c.categoria_id = p.categoria_id
    LEFT JOIN stock s ON p.producto_id = s.producto_id
    LEFT JOIN detalle_pedido dp ON s.stock_id = dp.stock_id
    LEFT JOIN pedidos ped ON dp.pedido_id = ped.pedido_id 
        AND ped.estado_pedido IN ('pagado', 'enviado', 'completado')
    WHERE c.estado = 'activo'
    GROUP BY c.categoria_id, c.nombre_categoria
    ORDER BY total_ventas DESC
    LIMIT p_limite;
END;
$$;


--
-- Name: FUNCTION fn_ventas_por_categoria(p_limite integer); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.fn_ventas_por_categoria(p_limite integer) IS 'Retorna ventas totales por categoría para gráfico de barras';


--
-- Name: sp_actualizar_estado_envio(integer, character varying, character varying, character varying); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.sp_actualizar_estado_envio(IN p_envio_id integer, IN p_nuevo_estado character varying, IN p_transportista character varying DEFAULT NULL::character varying, IN p_numero_tracking character varying DEFAULT NULL::character varying)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_pedido_id INT;
    v_estado_actual VARCHAR(50);
BEGIN
    -- Obtener pedido asociado y estado actual
    SELECT pedido_id, estado_envio
    INTO v_pedido_id, v_estado_actual
    FROM envios
    WHERE envio_id = p_envio_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Envío % no encontrado', p_envio_id;
    END IF;
    
    -- Validar transición de estado
    IF v_estado_actual = 'entregado' THEN
        RAISE EXCEPTION 'No se puede modificar un envío ya entregado';
    END IF;
    
    -- Actualizar envío
    UPDATE envios
    SET 
        estado_envio = p_nuevo_estado,
        transportista = COALESCE(p_transportista, transportista),
        numero_tracking = COALESCE(p_numero_tracking, numero_tracking),
        fecha_envio = CASE 
            WHEN p_nuevo_estado = 'en_transito' AND fecha_envio IS NULL 
            THEN NOW() 
            ELSE fecha_envio 
        END
    WHERE envio_id = p_envio_id;
    
    -- Si el estado es "entregado", marcar pedido como completado
    IF p_nuevo_estado = 'entregado' THEN
        UPDATE pedidos
        SET estado_pedido = 'completado'
        WHERE pedido_id = v_pedido_id;
        
        RAISE NOTICE 'Pedido % marcado como completado', v_pedido_id;
    END IF;
    
    -- Si el estado es "en_transito", actualizar pedido a "enviado"
    IF p_nuevo_estado = 'en_transito' THEN
        UPDATE pedidos
        SET estado_pedido = 'enviado'
        WHERE pedido_id = v_pedido_id
            AND estado_pedido = 'pagado';
    END IF;
    
    RAISE NOTICE 'Estado de envío actualizado a: %', p_nuevo_estado;
END;
$$;


--
-- Name: sp_actualizar_stock_compra(integer); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.sp_actualizar_stock_compra(IN p_pedido_id integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_detalle RECORD;
BEGIN
    -- Para cada item del pedido
    FOR v_detalle IN 
        SELECT stock_id, cantidad
        FROM detalle_pedido
        WHERE pedido_id = p_pedido_id
    LOOP
        -- Reducir stock y liberar reserva
        UPDATE stock
        SET 
            cantidad_en_stock = cantidad_en_stock - v_detalle.cantidad,
            cantidad_reservada = cantidad_reservada - v_detalle.cantidad
        WHERE stock_id = v_detalle.stock_id;
    END LOOP;
    
    RAISE NOTICE 'Stock actualizado para pedido %', p_pedido_id;
END;
$$;


--
-- Name: sp_ajustar_precios_categoria(integer, numeric); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.sp_ajustar_precios_categoria(IN p_categoria_id integer, IN p_porcentaje_ajuste numeric)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_productos_afectados INT;
BEGIN
    -- Validar que exista la categoría
    IF NOT EXISTS (SELECT 1 FROM categorias WHERE categoria_id = p_categoria_id) THEN
        RAISE EXCEPTION 'Categoría % no encontrada', p_categoria_id;
    END IF;
    
    -- Actualizar precios de todos los SKUs de productos de esa categoría
    UPDATE stock s
    SET precio_unitario = precio_unitario * (1 + p_porcentaje_ajuste / 100)
    FROM productos p
    WHERE s.producto_id = p.producto_id
        AND p.categoria_id = p_categoria_id
        AND s.estado = 'activo';
    
    GET DIAGNOSTICS v_productos_afectados = ROW_COUNT;
    
    RAISE NOTICE '% SKUs actualizados con ajuste del % porciento en categoría %', 
        v_productos_afectados, p_porcentaje_ajuste, p_categoria_id;
END;
$$;


--
-- Name: sp_aplicar_cupon_pedido(integer, character varying); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.sp_aplicar_cupon_pedido(IN p_pedido_id integer, IN p_codigo_cupon character varying)
    LANGUAGE plpgsql
    AS $_$
DECLARE
    v_cupon_id INT;
    v_estado_pedido VARCHAR(50);
    v_subtotal NUMERIC(12, 2);
    v_descuento NUMERIC(12, 2);
    v_impuestos NUMERIC(12, 2);
    v_total NUMERIC(12, 2);
BEGIN
    -- Verificar estado del pedido
    SELECT estado_pedido, subtotal
    INTO v_estado_pedido, v_subtotal
    FROM pedidos
    WHERE pedido_id = p_pedido_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Pedido % no encontrado', p_pedido_id;
    END IF;
    
    IF v_estado_pedido != 'pendiente' THEN
        RAISE EXCEPTION 'Solo se puede aplicar cupón a pedidos pendientes';
    END IF;
    
    -- Buscar y validar cupón
    SELECT cupon_id
    INTO v_cupon_id
    FROM cupones
    WHERE codigo_cupon = p_codigo_cupon
        AND estado = 'activo'
        AND (fecha_expiracion IS NULL OR fecha_expiracion >= CURRENT_DATE)
        AND (usos_disponibles IS NULL OR usos_disponibles > 0);
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Cupón % no válido o expirado', p_codigo_cupon;
    END IF;
    
    -- Calcular nuevo descuento
    v_descuento := fn_calcular_descuento_cupon(v_cupon_id, v_subtotal);
    
    -- Recalcular impuestos y total
    v_impuestos := (v_subtotal - v_descuento) * 0.15;
    v_total := v_subtotal - v_descuento + v_impuestos;
    
    -- Actualizar pedido
    UPDATE pedidos
    SET 
        cupon_id = v_cupon_id,
        descuento_aplicado = v_descuento,
        impuestos = v_impuestos,
        total_pedido = v_total
    WHERE pedido_id = p_pedido_id;
    
    -- Decrementar usos del cupón
    UPDATE cupones
    SET usos_disponibles = usos_disponibles - 1
    WHERE cupon_id = v_cupon_id
        AND usos_disponibles > 0;
    
    RAISE NOTICE 'Cupón aplicado. Nuevo total: $%', v_total;
END;
$_$;


--
-- Name: sp_cancelar_pedido(integer, text); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.sp_cancelar_pedido(IN p_pedido_id integer, IN p_motivo text)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_estado_actual VARCHAR(50);
    v_detalle RECORD;
    v_envio_id INT;
BEGIN
    -- Verificar estado del pedido
    SELECT estado_pedido
    INTO v_estado_actual
    FROM pedidos
    WHERE pedido_id = p_pedido_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Pedido % no encontrado', p_pedido_id;
    END IF;
    
    -- No se puede cancelar si ya está enviado o completado
    IF v_estado_actual IN ('enviado', 'completado') THEN
        RAISE EXCEPTION 'No se puede cancelar un pedido en estado %', v_estado_actual;
    END IF;
    
    -- Liberar stock reservado
    FOR v_detalle IN 
        SELECT stock_id, cantidad
        FROM detalle_pedido
        WHERE pedido_id = p_pedido_id
    LOOP
        UPDATE stock
        SET cantidad_reservada = cantidad_reservada - v_detalle.cantidad
        WHERE stock_id = v_detalle.stock_id;
    END LOOP;
    
    -- Actualizar estado del pedido
    UPDATE pedidos
    SET estado_pedido = 'cancelado'
    WHERE pedido_id = p_pedido_id;
    
    -- Si existe un envío asociado, marcarlo como "fallido"
    SELECT envio_id
    INTO v_envio_id
    FROM envios
    WHERE pedido_id = p_pedido_id;
    
    IF FOUND THEN
        UPDATE envios
        SET estado_envio = 'fallido'
        WHERE envio_id = v_envio_id;
        
        RAISE NOTICE 'Envío % marcado como fallido', v_envio_id;
    END IF;
    
    RAISE NOTICE 'Pedido % cancelado. Motivo: %', p_pedido_id, p_motivo;
END;
$$;


--
-- Name: sp_crear_pedido(integer, integer, integer, jsonb); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.sp_crear_pedido(IN p_cliente_id integer, IN p_direccion_envio_id integer, IN p_cupon_id integer, IN p_items jsonb, OUT p_pedido_id integer)
    LANGUAGE plpgsql
    AS $_$
DECLARE
    v_subtotal NUMERIC(12, 2) := 0;
    v_descuento NUMERIC(12, 2) := 0;
    v_impuestos NUMERIC(12, 2) := 0;
    v_total NUMERIC(12, 2) := 0;
    v_item JSONB;
    v_stock_id INT;
    v_cantidad INT;
    v_precio NUMERIC(10, 2);
BEGIN
    -- Crear el pedido inicial
    INSERT INTO pedidos (
        cliente_id,
        direccion_envio_id,
        cupon_id,
        estado_pedido,
        subtotal,
        descuento_aplicado,
        impuestos,
        total_pedido
    ) VALUES (
        p_cliente_id,
        p_direccion_envio_id,
        p_cupon_id,
        'pendiente',
        0, 0, 0, 0
    ) RETURNING pedido_id INTO p_pedido_id;
    
    -- Procesar cada item
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        v_stock_id := (v_item->>'stock_id')::INT;
        v_cantidad := (v_item->>'cantidad')::INT;
        
        -- Validar stock disponible
        IF NOT fn_validar_stock_disponible(v_stock_id, v_cantidad) THEN
            RAISE EXCEPTION 'Stock insuficiente para SKU %', v_stock_id;
        END IF;
        
        -- Obtener precio
        v_precio := fn_obtener_precio_producto(v_stock_id);
        
        -- Insertar detalle
        INSERT INTO detalle_pedido (
            pedido_id,
            stock_id,
            cantidad,
            precio_unitario_compra
        ) VALUES (
            p_pedido_id,
            v_stock_id,
            v_cantidad,
            v_precio
        );
        
        -- Reservar stock
        UPDATE stock
        SET cantidad_reservada = cantidad_reservada + v_cantidad
        WHERE stock_id = v_stock_id;
        
        -- Acumular subtotal
        v_subtotal := v_subtotal + (v_precio * v_cantidad);
    END LOOP;
    
    -- Calcular descuento
    v_descuento := fn_calcular_descuento_cupon(p_cupon_id, v_subtotal);
    
    -- Calcular impuestos (15% sobre subtotal - descuento)
    v_impuestos := (v_subtotal - v_descuento) * 0.15;
    
    -- Calcular total
    v_total := v_subtotal - v_descuento + v_impuestos;
    
    -- Actualizar pedido con totales
    UPDATE pedidos
    SET 
        subtotal = v_subtotal,
        descuento_aplicado = v_descuento,
        impuestos = v_impuestos,
        total_pedido = v_total
    WHERE pedido_id = p_pedido_id;
    
    -- Decrementar uso del cupón si existe
    IF p_cupon_id IS NOT NULL THEN
        UPDATE cupones
        SET usos_disponibles = usos_disponibles - 1
        WHERE cupon_id = p_cupon_id
            AND usos_disponibles > 0;
    END IF;
    
    RAISE NOTICE 'Pedido % creado exitosamente. Total: $%', p_pedido_id, v_total;
END;
$_$;


--
-- Name: sp_eliminar_cliente(integer); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.sp_eliminar_cliente(IN p_cliente_id integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_tiene_pedidos BOOLEAN;
    v_nombre_cliente VARCHAR(100);
BEGIN
    -- Obtener nombre del cliente para el mensaje
    SELECT nombre || ' ' || apellido
    INTO v_nombre_cliente
    FROM clientes
    WHERE cliente_id = p_cliente_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Cliente % no encontrado', p_cliente_id;
    END IF;
    
    -- Verificar si tiene pedidos usando la función existente
    v_tiene_pedidos := fn_cliente_tiene_pedidos(p_cliente_id);
    
    IF v_tiene_pedidos THEN
        RAISE EXCEPTION 'No se puede eliminar el cliente "%" porque tiene pedidos asociados. Usa desactivación en su lugar.', v_nombre_cliente;
    END IF;
    
    -- Eliminar direcciones del cliente primero (cascada manual)
    DELETE FROM direcciones WHERE cliente_id = p_cliente_id;
    
    -- Eliminar cliente
    DELETE FROM clientes WHERE cliente_id = p_cliente_id;
    
    RAISE NOTICE 'Cliente "%" eliminado exitosamente', v_nombre_cliente;
END;
$$;


--
-- Name: sp_eliminar_pago(integer); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.sp_eliminar_pago(IN p_pago_id integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_estado_pago VARCHAR(20);
    v_pedido_id INT;
BEGIN
    -- Obtener información del pago
    SELECT estado_pago, pedido_id
    INTO v_estado_pago, v_pedido_id
    FROM pagos
    WHERE pago_id = p_pago_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Pago % no encontrado', p_pago_id;
    END IF;
    
    -- Solo se pueden eliminar pagos fallidos o pendientes
    IF v_estado_pago NOT IN ('fallido', 'pendiente') THEN
        RAISE EXCEPTION 'Solo se pueden eliminar pagos fallidos o pendientes. Estado actual: "%"', v_estado_pago;
    END IF;
    
    -- Eliminar pago
    DELETE FROM pagos WHERE pago_id = p_pago_id;
    
    RAISE NOTICE 'Pago % (estado: %) del pedido % eliminado exitosamente', p_pago_id, v_estado_pago, v_pedido_id;
END;
$$;


--
-- Name: sp_eliminar_pedido(integer); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.sp_eliminar_pedido(IN p_pedido_id integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_estado_pedido VARCHAR(50);
BEGIN
    -- Obtener estado del pedido
    SELECT estado_pedido
    INTO v_estado_pedido
    FROM pedidos
    WHERE pedido_id = p_pedido_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Pedido % no encontrado', p_pedido_id;
    END IF;
    
    -- Solo se pueden eliminar pedidos cancelados
    IF v_estado_pedido != 'cancelado' THEN
        RAISE EXCEPTION 'Solo se pueden eliminar pedidos cancelados. Estado actual: "%"', v_estado_pedido;
    END IF;
    
    -- Eliminar devoluciones asociadas
    DELETE FROM devoluciones 
    WHERE detalle_id IN (
        SELECT detalle_id 
        FROM detalle_pedido 
        WHERE pedido_id = p_pedido_id
    );
    
    -- Eliminar detalles del pedido
    DELETE FROM detalle_pedido WHERE pedido_id = p_pedido_id;
    
    -- Eliminar envío asociado (si existe)
    DELETE FROM envios WHERE pedido_id = p_pedido_id;
    
    -- Eliminar pagos asociados
    DELETE FROM pagos WHERE pedido_id = p_pedido_id;
    
    -- Eliminar pedido
    DELETE FROM pedidos WHERE pedido_id = p_pedido_id;
    
    RAISE NOTICE 'Pedido % y sus registros asociados eliminados exitosamente', p_pedido_id;
END;
$$;


--
-- Name: sp_eliminar_producto(integer); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.sp_eliminar_producto(IN p_producto_id integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_nombre_producto VARCHAR(200);
    v_tiene_stock INT;
    v_en_pedidos INT;
BEGIN
    -- Obtener nombre del producto
    SELECT nombre_producto
    INTO v_nombre_producto
    FROM productos
    WHERE producto_id = p_producto_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Producto % no encontrado', p_producto_id;
    END IF;
    
    -- Verificar si tiene stock
    SELECT COUNT(*)
    INTO v_tiene_stock
    FROM stock
    WHERE producto_id = p_producto_id;
    
    IF v_tiene_stock > 0 THEN
        RAISE EXCEPTION 'No se puede eliminar el producto "%" porque tiene % registros de stock. Elimina el stock primero.', v_nombre_producto, v_tiene_stock;
    END IF;
    
    -- Verificar si está en algún pedido
    SELECT COUNT(*)
    INTO v_en_pedidos
    FROM detalle_pedido dp
    INNER JOIN stock s ON dp.stock_id = s.stock_id
    WHERE s.producto_id = p_producto_id;
    
    IF v_en_pedidos > 0 THEN
        RAISE EXCEPTION 'No se puede eliminar el producto "%" porque está en % pedidos. Usa desactivación en su lugar.', v_nombre_producto, v_en_pedidos;
    END IF;
    
    -- Eliminar producto
    DELETE FROM productos WHERE producto_id = p_producto_id;
    
    RAISE NOTICE 'Producto "%" eliminado exitosamente', v_nombre_producto;
END;
$$;


--
-- Name: sp_eliminar_stock(integer); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.sp_eliminar_stock(IN p_stock_id integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_sku VARCHAR(50);
    v_nombre_producto VARCHAR(200);
    v_cantidad_reservada INT;
    v_en_pedidos INT;
BEGIN
    -- Obtener información del stock
    SELECT s.sku, p.nombre_producto, s.cantidad_reservada
    INTO v_sku, v_nombre_producto, v_cantidad_reservada
    FROM stock s
    INNER JOIN productos p ON s.producto_id = p.producto_id
    WHERE s.stock_id = p_stock_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Stock % no encontrado', p_stock_id;
    END IF;
    
    -- Verificar si tiene cantidad reservada
    IF v_cantidad_reservada > 0 THEN
        RAISE EXCEPTION 'No se puede eliminar el SKU "%" del producto "%" porque tiene % unidades reservadas en pedidos.', 
            v_sku, v_nombre_producto, v_cantidad_reservada;
    END IF;
    
    -- Verificar si está en algún pedido (histórico)
    SELECT COUNT(*)
    INTO v_en_pedidos
    FROM detalle_pedido
    WHERE stock_id = p_stock_id;
    
    IF v_en_pedidos > 0 THEN
        RAISE EXCEPTION 'No se puede eliminar el SKU "%" porque está en % pedidos (histórico). Usa desactivación en su lugar.', 
            v_sku, v_en_pedidos;
    END IF;
    
    -- Eliminar stock
    DELETE FROM stock WHERE stock_id = p_stock_id;
    
    RAISE NOTICE 'Stock "%" del producto "%" eliminado exitosamente', v_sku, v_nombre_producto;
END;
$$;


--
-- Name: sp_procesar_devolucion(integer, integer, text); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.sp_procesar_devolucion(IN p_detalle_id integer, IN p_cantidad_devuelta integer, IN p_motivo text)
    LANGUAGE plpgsql
    AS $_$
DECLARE
    v_pedido_id INT;
    v_stock_id INT;
    v_monto_reembolso NUMERIC(12, 2);
    v_pago_id INT;
BEGIN
    SELECT pedido_id, stock_id
    INTO v_pedido_id, v_stock_id
    FROM detalle_pedido
    WHERE detalle_id = p_detalle_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Detalle de pedido % no encontrado', p_detalle_id;
    END IF;
    
    IF NOT fn_validar_devolucion_permitida(v_pedido_id) THEN
        RAISE EXCEPTION 'El pedido % no permite devoluciones', v_pedido_id;
    END IF;
    
    v_monto_reembolso := fn_calcular_monto_reembolso(p_detalle_id, p_cantidad_devuelta);
    
    INSERT INTO devoluciones (
        detalle_id,
        motivo,
        cantidad_devuelta,
        estado_devolucion
    ) VALUES (
        p_detalle_id,
        p_motivo,
        p_cantidad_devuelta,
        'aprobada'
    );
    
    -- Solo liberar la reserva, NO incrementar stock físico
    UPDATE stock
    SET cantidad_reservada = GREATEST(0, cantidad_reservada - p_cantidad_devuelta)
    WHERE stock_id = v_stock_id;
    
    SELECT pago_id
    INTO v_pago_id
    FROM pagos
    WHERE pedido_id = v_pedido_id
        AND estado_pago = 'exitoso'
    ORDER BY fecha_pago DESC
    LIMIT 1;
    
    IF v_pago_id IS NOT NULL THEN
        INSERT INTO pagos (
            pedido_id,
            monto,
            metodo_pago,
            estado_pago,
            id_transaccion_externa
        ) VALUES (
            v_pedido_id,
            v_monto_reembolso,
            'Reembolso',
            'reembolsado',
            'REFUND_' || p_detalle_id
        );
    END IF;
    
    UPDATE devoluciones
    SET estado_devolucion = 'reembolsada'
    WHERE detalle_id = p_detalle_id;
    
    RAISE NOTICE 'Devolución procesada. Reembolso: $%', v_monto_reembolso;
END;
$_$;


--
-- Name: sp_procesar_pago(integer, numeric, character varying, character varying); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.sp_procesar_pago(IN p_pedido_id integer, IN p_monto numeric, IN p_metodo_pago character varying, IN p_id_transaccion character varying)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_total_pedido NUMERIC(12, 2);
    v_estado_actual VARCHAR(50);
BEGIN
    -- Obtener total y estado del pedido
    SELECT total_pedido, estado_pedido
    INTO v_total_pedido, v_estado_actual
    FROM pedidos
    WHERE pedido_id = p_pedido_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Pedido % no encontrado', p_pedido_id;
    END IF;

    -- Validar que el pedido esté pendiente
    IF v_estado_actual != 'pendiente' THEN
        RAISE EXCEPTION 'El pedido % no está en estado pendiente', p_pedido_id;
    END IF;

    -- Validar que el monto sea correcto
    IF p_monto != v_total_pedido THEN
        RAISE EXCEPTION 'Monto incorrecto. Esperado: %, Recibido: %', v_total_pedido, p_monto;
    END IF;

    -- Registrar el pago
    INSERT INTO pagos (
        pedido_id,
        monto,
        metodo_pago,
        estado_pago,
        id_transaccion_externa
    ) VALUES (
        p_pedido_id,
        p_monto,
        p_metodo_pago,
        'exitoso',
        p_id_transaccion
    );

    -- Actualizar estado del pedido
    UPDATE pedidos
    SET estado_pedido = 'pagado'
    WHERE pedido_id = p_pedido_id;

    -- Descontar stock físico y liberar la reserva (fix V1: antes nunca ocurría)
    CALL sp_actualizar_stock_compra(p_pedido_id);

    -- Crear registro de envío
    INSERT INTO envios (
        pedido_id,
        estado_envio
    ) VALUES (
        p_pedido_id,
        'en_preparacion'
    );

    RAISE NOTICE 'Pago procesado exitosamente para pedido %', p_pedido_id;
END;
$$;


--
-- Name: sp_reabastecer_stock(integer, integer, numeric); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.sp_reabastecer_stock(IN p_stock_id integer, IN p_cantidad integer, IN p_costo_unitario numeric DEFAULT NULL::numeric)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_stock_actual INT;
BEGIN
    -- Validar que exista el SKU
    SELECT cantidad_en_stock
    INTO v_stock_actual
    FROM stock
    WHERE stock_id = p_stock_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'SKU % no encontrado', p_stock_id;
    END IF;
    
    -- Actualizar stock
    UPDATE stock
    SET 
        cantidad_en_stock = cantidad_en_stock + p_cantidad,
        precio_unitario = COALESCE(p_costo_unitario, precio_unitario)
    WHERE stock_id = p_stock_id;
    
    RAISE NOTICE 'Stock actualizado. Anterior: %, Nuevo: %', 
        v_stock_actual, v_stock_actual + p_cantidad;
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: auditoria; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.auditoria (
    auditoria_id integer NOT NULL,
    tabla character varying(100) NOT NULL,
    operacion character varying(10) NOT NULL,
    registro_id integer NOT NULL,
    usuario character varying(100),
    fecha timestamp without time zone DEFAULT now() NOT NULL,
    datos_anteriores jsonb,
    datos_nuevos jsonb,
    ip_address character varying(45),
    CONSTRAINT auditoria_operacion_check CHECK (((operacion)::text = ANY (ARRAY[('INSERT'::character varying)::text, ('UPDATE'::character varying)::text, ('DELETE'::character varying)::text])))
);


--
-- Name: auditoria_auditoria_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.auditoria_auditoria_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: auditoria_auditoria_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.auditoria_auditoria_id_seq OWNED BY public.auditoria.auditoria_id;


--
-- Name: categorias; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.categorias (
    categoria_id integer NOT NULL,
    nombre_categoria character varying(100) NOT NULL,
    descripcion text,
    estado character varying(20) DEFAULT 'activo'::character varying NOT NULL,
    fecha_creacion timestamp without time zone DEFAULT now() NOT NULL,
    fecha_modificacion timestamp without time zone,
    CONSTRAINT categorias_estado_check CHECK (((estado)::text = ANY (ARRAY[('activo'::character varying)::text, ('inactivo'::character varying)::text])))
);


--
-- Name: categorias_categoria_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.categorias_categoria_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: categorias_categoria_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.categorias_categoria_id_seq OWNED BY public.categorias.categoria_id;


--
-- Name: clientes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.clientes (
    cliente_id integer NOT NULL,
    nombre character varying(100) NOT NULL,
    apellido character varying(100) NOT NULL,
    email character varying(255) NOT NULL,
    hash_contrasena character varying(255) NOT NULL,
    estado character varying(20) DEFAULT 'activo'::character varying NOT NULL,
    fecha_creacion timestamp without time zone DEFAULT now() NOT NULL,
    fecha_modificacion timestamp without time zone,
    CONSTRAINT clientes_estado_check CHECK (((estado)::text = ANY (ARRAY[('activo'::character varying)::text, ('inactivo'::character varying)::text, ('suspendido'::character varying)::text])))
);


--
-- Name: clientes_cliente_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.clientes_cliente_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: clientes_cliente_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.clientes_cliente_id_seq OWNED BY public.clientes.cliente_id;


--
-- Name: cupones; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cupones (
    cupon_id integer NOT NULL,
    codigo_cupon character varying(50) NOT NULL,
    tipo_descuento character varying(20) NOT NULL,
    valor_descuento numeric(10,2) NOT NULL,
    fecha_expiracion date,
    usos_disponibles integer,
    estado character varying(20) DEFAULT 'activo'::character varying NOT NULL,
    fecha_creacion timestamp without time zone DEFAULT now() NOT NULL,
    fecha_modificacion timestamp without time zone,
    CONSTRAINT cupones_estado_check CHECK (((estado)::text = ANY (ARRAY[('activo'::character varying)::text, ('inactivo'::character varying)::text, ('expirado'::character varying)::text]))),
    CONSTRAINT cupones_tipo_descuento_check CHECK (((tipo_descuento)::text = ANY (ARRAY[('porcentaje'::character varying)::text, ('fijo'::character varying)::text]))),
    CONSTRAINT cupones_usos_disponibles_check CHECK ((usos_disponibles >= 0)),
    CONSTRAINT cupones_valor_descuento_check CHECK ((valor_descuento > (0)::numeric))
);


--
-- Name: cupones_cupon_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cupones_cupon_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cupones_cupon_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cupones_cupon_id_seq OWNED BY public.cupones.cupon_id;


--
-- Name: detalle_pedido; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.detalle_pedido (
    detalle_id integer NOT NULL,
    pedido_id integer NOT NULL,
    stock_id integer NOT NULL,
    cantidad integer NOT NULL,
    precio_unitario_compra numeric(10,2) NOT NULL,
    fecha_creacion timestamp without time zone DEFAULT now() NOT NULL,
    CONSTRAINT detalle_pedido_cantidad_check CHECK ((cantidad > 0))
);


--
-- Name: detalle_pedido_detalle_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.detalle_pedido_detalle_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: detalle_pedido_detalle_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.detalle_pedido_detalle_id_seq OWNED BY public.detalle_pedido.detalle_id;


--
-- Name: devoluciones; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.devoluciones (
    devolucion_id integer NOT NULL,
    detalle_id integer NOT NULL,
    motivo text,
    cantidad_devuelta integer NOT NULL,
    fecha_solicitud timestamp without time zone DEFAULT now() NOT NULL,
    estado_devolucion character varying(50) DEFAULT 'solicitada'::character varying NOT NULL,
    fecha_modificacion timestamp without time zone,
    CONSTRAINT devoluciones_cantidad_devuelta_check CHECK ((cantidad_devuelta > 0)),
    CONSTRAINT devoluciones_estado_devolucion_check CHECK (((estado_devolucion)::text = ANY (ARRAY[('solicitada'::character varying)::text, ('aprobada'::character varying)::text, ('recibida'::character varying)::text, ('reembolsada'::character varying)::text, ('rechazada'::character varying)::text])))
);


--
-- Name: devoluciones_devolucion_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.devoluciones_devolucion_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: devoluciones_devolucion_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.devoluciones_devolucion_id_seq OWNED BY public.devoluciones.devolucion_id;


--
-- Name: direcciones; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.direcciones (
    direccion_id integer NOT NULL,
    cliente_id integer NOT NULL,
    direccion_linea_1 character varying(255) NOT NULL,
    ciudad character varying(100) NOT NULL,
    codigo_postal character varying(20) NOT NULL,
    pais character varying(50) NOT NULL,
    estado character varying(20) DEFAULT 'activo'::character varying NOT NULL,
    fecha_creacion timestamp without time zone DEFAULT now() NOT NULL,
    fecha_modificacion timestamp without time zone,
    CONSTRAINT direcciones_estado_check CHECK (((estado)::text = ANY (ARRAY[('activo'::character varying)::text, ('inactivo'::character varying)::text])))
);


--
-- Name: direcciones_direccion_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.direcciones_direccion_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: direcciones_direccion_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.direcciones_direccion_id_seq OWNED BY public.direcciones.direccion_id;


--
-- Name: envios; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.envios (
    envio_id integer NOT NULL,
    pedido_id integer NOT NULL,
    fecha_envio timestamp without time zone,
    transportista character varying(100),
    numero_tracking character varying(100),
    estado_envio character varying(50) DEFAULT 'en_preparacion'::character varying NOT NULL,
    fecha_creacion timestamp without time zone DEFAULT now() NOT NULL,
    fecha_modificacion timestamp without time zone,
    CONSTRAINT envios_estado_envio_check CHECK (((estado_envio)::text = ANY (ARRAY[('en_preparacion'::character varying)::text, ('en_transito'::character varying)::text, ('entregado'::character varying)::text, ('fallido'::character varying)::text])))
);


--
-- Name: envios_envio_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.envios_envio_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: envios_envio_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.envios_envio_id_seq OWNED BY public.envios.envio_id;


--
-- Name: historial_estados; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.historial_estados (
    historial_id integer NOT NULL,
    pedido_id integer NOT NULL,
    estado_anterior character varying(50),
    estado_nuevo character varying(50) NOT NULL,
    usuario character varying(100) DEFAULT CURRENT_USER,
    comentario text,
    fecha_cambio timestamp without time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_estado_anterior CHECK ((((estado_anterior)::text = ANY (ARRAY[('pendiente'::character varying)::text, ('pagado'::character varying)::text, ('enviado'::character varying)::text, ('cancelado'::character varying)::text, ('completado'::character varying)::text])) OR (estado_anterior IS NULL))),
    CONSTRAINT chk_estado_nuevo CHECK (((estado_nuevo)::text = ANY (ARRAY[('pendiente'::character varying)::text, ('pagado'::character varying)::text, ('enviado'::character varying)::text, ('cancelado'::character varying)::text, ('completado'::character varying)::text])))
);


--
-- Name: TABLE historial_estados; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.historial_estados IS 'Historial de cambios de estado para timeline visual de pedidos. 
Complementa la tabla auditoria con información específica para UX.';


--
-- Name: COLUMN historial_estados.estado_anterior; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.historial_estados.estado_anterior IS 'Estado previo del pedido. NULL para el estado inicial (creación).';


--
-- Name: COLUMN historial_estados.comentario; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.historial_estados.comentario IS 'Nota o motivo del cambio de estado (ej: "Pedido enviado por FedEx", "Cancelado por cliente").';


--
-- Name: historial_estados_historial_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.historial_estados_historial_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: historial_estados_historial_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.historial_estados_historial_id_seq OWNED BY public.historial_estados.historial_id;


--
-- Name: pedidos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pedidos (
    pedido_id integer NOT NULL,
    cliente_id integer NOT NULL,
    direccion_envio_id integer NOT NULL,
    cupon_id integer,
    fecha_pedido timestamp without time zone DEFAULT now() NOT NULL,
    estado_pedido character varying(50) DEFAULT 'pendiente'::character varying NOT NULL,
    subtotal numeric(12,2) NOT NULL,
    descuento_aplicado numeric(12,2) DEFAULT 0 NOT NULL,
    impuestos numeric(12,2) DEFAULT 0 NOT NULL,
    total_pedido numeric(12,2) NOT NULL,
    fecha_modificacion timestamp without time zone,
    CONSTRAINT pedidos_estado_pedido_check CHECK (((estado_pedido)::text = ANY (ARRAY[('pendiente'::character varying)::text, ('pagado'::character varying)::text, ('enviado'::character varying)::text, ('cancelado'::character varying)::text, ('completado'::character varying)::text]))),
    CONSTRAINT pedidos_subtotal_check CHECK ((subtotal >= (0)::numeric)),
    CONSTRAINT pedidos_total_pedido_check CHECK ((total_pedido >= (0)::numeric))
);


--
-- Name: mv_clientes_vip; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW public.mv_clientes_vip AS
 SELECT c.cliente_id,
    c.nombre,
    c.apellido,
    c.email,
    count(p.pedido_id) AS total_pedidos,
    sum(p.total_pedido) AS total_gastado,
    avg(p.total_pedido) AS ticket_promedio,
    max(p.fecha_pedido) AS ultima_compra,
    min(p.fecha_pedido) AS primera_compra,
        CASE
            WHEN (sum(p.total_pedido) >= (1000)::numeric) THEN 'Platinum'::text
            WHEN (sum(p.total_pedido) >= (500)::numeric) THEN 'Gold'::text
            WHEN (count(p.pedido_id) >= 5) THEN 'Silver'::text
            ELSE 'Bronze'::text
        END AS categoria_vip
   FROM (public.clientes c
     JOIN public.pedidos p ON ((c.cliente_id = p.cliente_id)))
  WHERE (((p.estado_pedido)::text = ANY (ARRAY[('pagado'::character varying)::text, ('enviado'::character varying)::text, ('completado'::character varying)::text])) AND ((c.estado)::text = 'activo'::text))
  GROUP BY c.cliente_id, c.nombre, c.apellido, c.email
 HAVING ((count(p.pedido_id) >= 3) OR (sum(p.total_pedido) >= (500)::numeric))
  ORDER BY (sum(p.total_pedido)) DESC
  WITH NO DATA;


--
-- Name: productos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.productos (
    producto_id integer NOT NULL,
    categoria_id integer NOT NULL,
    nombre_producto character varying(255) NOT NULL,
    descripcion_larga text,
    estado character varying(20) DEFAULT 'activo'::character varying NOT NULL,
    fecha_creacion timestamp without time zone DEFAULT now() NOT NULL,
    fecha_modificacion timestamp without time zone,
    CONSTRAINT productos_estado_check CHECK (((estado)::text = ANY (ARRAY[('activo'::character varying)::text, ('inactivo'::character varying)::text, ('descontinuado'::character varying)::text])))
);


--
-- Name: stock; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.stock (
    stock_id integer NOT NULL,
    producto_id integer NOT NULL,
    sku character varying(100) NOT NULL,
    precio_unitario numeric(10,2) NOT NULL,
    cantidad_en_stock integer DEFAULT 0 NOT NULL,
    cantidad_reservada integer DEFAULT 0 NOT NULL,
    estado character varying(20) DEFAULT 'activo'::character varying NOT NULL,
    fecha_creacion timestamp without time zone DEFAULT now() NOT NULL,
    fecha_modificacion timestamp without time zone,
    CONSTRAINT chk_reserva_stock CHECK ((cantidad_reservada <= cantidad_en_stock)),
    CONSTRAINT stock_cantidad_en_stock_check CHECK ((cantidad_en_stock >= 0)),
    CONSTRAINT stock_cantidad_reservada_check CHECK ((cantidad_reservada >= 0)),
    CONSTRAINT stock_estado_check CHECK (((estado)::text = ANY (ARRAY[('activo'::character varying)::text, ('inactivo'::character varying)::text]))),
    CONSTRAINT stock_precio_unitario_check CHECK ((precio_unitario > (0)::numeric))
);


--
-- Name: mv_productos_top_ventas; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW public.mv_productos_top_ventas AS
 SELECT p.producto_id,
    p.nombre_producto,
    p.descripcion_larga,
    c.nombre_categoria,
    sum(dp.cantidad) AS total_vendido,
    sum(((dp.cantidad)::numeric * dp.precio_unitario_compra)) AS ingresos_totales,
    count(DISTINCT ped.pedido_id) AS num_pedidos,
    avg(dp.precio_unitario_compra) AS precio_promedio
   FROM ((((public.productos p
     JOIN public.categorias c ON ((p.categoria_id = c.categoria_id)))
     JOIN public.stock s ON ((p.producto_id = s.producto_id)))
     JOIN public.detalle_pedido dp ON ((s.stock_id = dp.stock_id)))
     JOIN public.pedidos ped ON ((dp.pedido_id = ped.pedido_id)))
  WHERE (((ped.estado_pedido)::text = ANY (ARRAY[('pagado'::character varying)::text, ('enviado'::character varying)::text, ('completado'::character varying)::text])) AND ((p.estado)::text = 'activo'::text))
  GROUP BY p.producto_id, p.nombre_producto, p.descripcion_larga, c.nombre_categoria
  ORDER BY (sum(dp.cantidad)) DESC
  WITH NO DATA;


--
-- Name: pagos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pagos (
    pago_id integer NOT NULL,
    pedido_id integer NOT NULL,
    fecha_pago timestamp without time zone DEFAULT now() NOT NULL,
    monto numeric(12,2) NOT NULL,
    metodo_pago character varying(50),
    estado_pago character varying(20) NOT NULL,
    id_transaccion_externa character varying(255),
    fecha_modificacion timestamp without time zone,
    CONSTRAINT pagos_estado_pago_check CHECK (((estado_pago)::text = ANY (ARRAY[('exitoso'::character varying)::text, ('fallido'::character varying)::text, ('pendiente'::character varying)::text, ('reembolsado'::character varying)::text]))),
    CONSTRAINT pagos_monto_check CHECK ((monto > (0)::numeric))
);


--
-- Name: pagos_pago_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pagos_pago_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pagos_pago_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pagos_pago_id_seq OWNED BY public.pagos.pago_id;


--
-- Name: pedidos_pedido_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pedidos_pedido_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pedidos_pedido_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pedidos_pedido_id_seq OWNED BY public.pedidos.pedido_id;


--
-- Name: productos_producto_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.productos_producto_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: productos_producto_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.productos_producto_id_seq OWNED BY public.productos.producto_id;


--
-- Name: stock_stock_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.stock_stock_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: stock_stock_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.stock_stock_id_seq OWNED BY public.stock.stock_id;


--
-- Name: vw_timeline_pedidos; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.vw_timeline_pedidos AS
 SELECT h.historial_id,
    h.pedido_id,
    h.estado_anterior,
    h.estado_nuevo,
    h.usuario,
    h.comentario,
    h.fecha_cambio,
    p.cliente_id,
    (((c.nombre)::text || ' '::text) || (c.apellido)::text) AS nombre_cliente,
    p.total_pedido,
    p.fecha_pedido
   FROM ((public.historial_estados h
     JOIN public.pedidos p ON ((h.pedido_id = p.pedido_id)))
     JOIN public.clientes c ON ((p.cliente_id = c.cliente_id)))
  ORDER BY h.fecha_cambio DESC;


--
-- Name: VIEW vw_timeline_pedidos; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON VIEW public.vw_timeline_pedidos IS 'Vista combinada de historial de estados con información del pedido y cliente. 
Optimizada para listados de actividad reciente.';


--
-- Name: auditoria auditoria_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditoria ALTER COLUMN auditoria_id SET DEFAULT nextval('public.auditoria_auditoria_id_seq'::regclass);


--
-- Name: categorias categoria_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categorias ALTER COLUMN categoria_id SET DEFAULT nextval('public.categorias_categoria_id_seq'::regclass);


--
-- Name: clientes cliente_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes ALTER COLUMN cliente_id SET DEFAULT nextval('public.clientes_cliente_id_seq'::regclass);


--
-- Name: cupones cupon_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cupones ALTER COLUMN cupon_id SET DEFAULT nextval('public.cupones_cupon_id_seq'::regclass);


--
-- Name: detalle_pedido detalle_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.detalle_pedido ALTER COLUMN detalle_id SET DEFAULT nextval('public.detalle_pedido_detalle_id_seq'::regclass);


--
-- Name: devoluciones devolucion_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.devoluciones ALTER COLUMN devolucion_id SET DEFAULT nextval('public.devoluciones_devolucion_id_seq'::regclass);


--
-- Name: direcciones direccion_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.direcciones ALTER COLUMN direccion_id SET DEFAULT nextval('public.direcciones_direccion_id_seq'::regclass);


--
-- Name: envios envio_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.envios ALTER COLUMN envio_id SET DEFAULT nextval('public.envios_envio_id_seq'::regclass);


--
-- Name: historial_estados historial_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.historial_estados ALTER COLUMN historial_id SET DEFAULT nextval('public.historial_estados_historial_id_seq'::regclass);


--
-- Name: pagos pago_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pagos ALTER COLUMN pago_id SET DEFAULT nextval('public.pagos_pago_id_seq'::regclass);


--
-- Name: pedidos pedido_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pedidos ALTER COLUMN pedido_id SET DEFAULT nextval('public.pedidos_pedido_id_seq'::regclass);


--
-- Name: productos producto_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.productos ALTER COLUMN producto_id SET DEFAULT nextval('public.productos_producto_id_seq'::regclass);


--
-- Name: stock stock_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stock ALTER COLUMN stock_id SET DEFAULT nextval('public.stock_stock_id_seq'::regclass);


--
-- Data for Name: auditoria; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.auditoria (auditoria_id, tabla, operacion, registro_id, usuario, fecha, datos_anteriores, datos_nuevos, ip_address) FROM stdin;
1	productos	UPDATE	1	postgres	2025-11-20 21:12:52.922429	{"estado": "activo", "producto_id": 1, "categoria_id": 1, "fecha_creacion": "2025-11-06T21:32:55.776688", "nombre_producto": "Laptop Pro 15\\"", "descripcion_larga": "Laptop de alto rendimiento con 16GB RAM y SSD 1TB.", "fecha_modificacion": null}	{"estado": "activo", "producto_id": 1, "categoria_id": 1, "fecha_creacion": "2025-11-06T21:32:55.776688", "nombre_producto": "Laptop Pro 15\\"", "descripcion_larga": "Laptop de alto rendimiento con 16GB RAM y SSD 1TB.", "fecha_modificacion": null}	\N
2	productos	UPDATE	1	postgres	2025-11-20 21:26:57.065881	{"estado": "activo", "producto_id": 1, "categoria_id": 1, "fecha_creacion": "2025-11-06T21:32:55.776688", "nombre_producto": "Laptop Pro 15\\"", "descripcion_larga": "Laptop de alto rendimiento con 16GB RAM y SSD 1TB.", "fecha_modificacion": null}	{"estado": "activo", "producto_id": 1, "categoria_id": 1, "fecha_creacion": "2025-11-06T21:32:55.776688", "nombre_producto": "Laptop Pro 15\\"", "descripcion_larga": "Laptop de alto rendimiento con 16GB RAM y SSD 1TB.", "fecha_modificacion": null}	\N
3	cupones	INSERT	6	postgres	2025-11-20 21:41:25.174844	\N	{"estado": "activo", "cupon_id": 6, "codigo_cupon": "TEST2024", "fecha_creacion": "2025-11-20T21:41:25.174844", "tipo_descuento": "porcentaje", "valor_descuento": 15.00, "fecha_expiracion": "2025-12-20", "usos_disponibles": 100, "fecha_modificacion": null}	\N
4	clientes	UPDATE	1	postgres	2025-11-20 21:41:30.922238	{"email": "ana.garcia@email.com", "estado": "activo", "nombre": "Ana", "apellido": "García", "cliente_id": 1, "fecha_creacion": "2025-11-06T21:32:49.147468", "hash_contrasena": "$2b$12$E/Vxk.S.G.a0b5C1.XY.a.CqY.qS.aG/a0b5C1.XY.a.CqY.qS", "fecha_modificacion": null}	{"email": "ana.garcia@email.com", "estado": "activo", "nombre": "Ana", "apellido": "García", "cliente_id": 1, "fecha_creacion": "2025-11-06T21:32:49.147468", "hash_contrasena": "$2b$12$E/Vxk.S.G.a0b5C1.XY.a.CqY.qS.aG/a0b5C1.XY.a.CqY.qS", "fecha_modificacion": null}	\N
5	stock	UPDATE	1	postgres	2025-11-20 21:41:34.631715	{"sku": "LAP-PRO-15-1TB", "estado": "activo", "stock_id": 1, "producto_id": 1, "fecha_creacion": "2025-11-06T21:33:04.911523", "precio_unitario": 1499.99, "cantidad_en_stock": 15, "cantidad_reservada": 0, "fecha_modificacion": null}	{"sku": "LAP-PRO-15-1TB", "estado": "activo", "stock_id": 1, "producto_id": 1, "fecha_creacion": "2025-11-06T21:33:04.911523", "precio_unitario": 1499.99, "cantidad_en_stock": 15, "cantidad_reservada": 0, "fecha_modificacion": null}	\N
6	stock	UPDATE	16	postgres	2025-11-21 14:52:53.556179	{"sku": "Express", "estado": "activo", "stock_id": 16, "producto_id": 6, "fecha_creacion": "2025-11-09T00:55:08.969144", "precio_unitario": 100.00, "cantidad_en_stock": 10, "cantidad_reservada": 0, "fecha_modificacion": "2025-11-11T22:16:43.843579"}	{"sku": "Express", "estado": "activo", "stock_id": 16, "producto_id": 6, "fecha_creacion": "2025-11-09T00:55:08.969144", "precio_unitario": 100.00, "cantidad_en_stock": 11, "cantidad_reservada": 0, "fecha_modificacion": "2025-11-21T14:52:53.556179"}	\N
7	pedidos	UPDATE	6	postgres	2025-11-21 21:39:47.016225	{"cupon_id": 5, "subtotal": 3899.97, "impuestos": 555.00, "pedido_id": 6, "cliente_id": 11, "fecha_pedido": "2025-11-10T20:26:37.295097", "total_pedido": 4254.97, "estado_pedido": "enviado", "descuento_aplicado": 200.00, "direccion_envio_id": 14, "fecha_modificacion": "2025-11-10T20:57:45.513871"}	{"cupon_id": 5, "subtotal": 3899.97, "impuestos": 555.00, "pedido_id": 6, "cliente_id": 11, "fecha_pedido": "2025-11-10T20:26:37.295097", "total_pedido": 4254.97, "estado_pedido": "completado", "descuento_aplicado": 200.00, "direccion_envio_id": 14, "fecha_modificacion": "2025-11-21T21:39:47.016225"}	\N
8	pedidos	INSERT	23	postgres	2025-12-01 17:12:06.572356	\N	{"cupon_id": null, "subtotal": 0.00, "impuestos": 0.00, "pedido_id": 23, "cliente_id": 12, "fecha_pedido": "2025-12-01T17:12:06.572356", "total_pedido": 0.00, "estado_pedido": "pendiente", "descuento_aplicado": 0.00, "direccion_envio_id": 15, "fecha_modificacion": null}	\N
9	stock	UPDATE	3	postgres	2025-12-01 17:12:06.572356	{"sku": "TWS-NOISE-WHT", "estado": "activo", "stock_id": 3, "producto_id": 3, "fecha_creacion": "2025-11-06T21:33:04.911523", "precio_unitario": 120.00, "cantidad_en_stock": 34, "cantidad_reservada": 0, "fecha_modificacion": "2025-11-10T22:42:39.641499"}	{"sku": "TWS-NOISE-WHT", "estado": "activo", "stock_id": 3, "producto_id": 3, "fecha_creacion": "2025-11-06T21:33:04.911523", "precio_unitario": 120.00, "cantidad_en_stock": 34, "cantidad_reservada": 1, "fecha_modificacion": "2025-12-01T17:12:06.572356"}	\N
10	pedidos	UPDATE	23	postgres	2025-12-01 17:12:06.572356	{"cupon_id": null, "subtotal": 0.00, "impuestos": 0.00, "pedido_id": 23, "cliente_id": 12, "fecha_pedido": "2025-12-01T17:12:06.572356", "total_pedido": 0.00, "estado_pedido": "pendiente", "descuento_aplicado": 0.00, "direccion_envio_id": 15, "fecha_modificacion": null}	{"cupon_id": null, "subtotal": 120.00, "impuestos": 18.00, "pedido_id": 23, "cliente_id": 12, "fecha_pedido": "2025-12-01T17:12:06.572356", "total_pedido": 138.00, "estado_pedido": "pendiente", "descuento_aplicado": 0.00, "direccion_envio_id": 15, "fecha_modificacion": "2025-12-01T17:12:06.572356"}	\N
11	pagos	INSERT	36	postgres	2025-12-01 17:13:29.486767	\N	{"monto": 138.00, "pago_id": 36, "pedido_id": 23, "fecha_pago": "2025-12-01T17:13:29.486767", "estado_pago": "exitoso", "metodo_pago": "tarjeta_debito", "fecha_modificacion": null, "id_transaccion_externa": "wdcsd_5188454"}	\N
12	pedidos	UPDATE	23	postgres	2025-12-01 17:13:29.486767	{"cupon_id": null, "subtotal": 120.00, "impuestos": 18.00, "pedido_id": 23, "cliente_id": 12, "fecha_pedido": "2025-12-01T17:12:06.572356", "total_pedido": 138.00, "estado_pedido": "pendiente", "descuento_aplicado": 0.00, "direccion_envio_id": 15, "fecha_modificacion": "2025-12-01T17:12:06.572356"}	{"cupon_id": null, "subtotal": 120.00, "impuestos": 18.00, "pedido_id": 23, "cliente_id": 12, "fecha_pedido": "2025-12-01T17:12:06.572356", "total_pedido": 138.00, "estado_pedido": "pagado", "descuento_aplicado": 0.00, "direccion_envio_id": 15, "fecha_modificacion": "2025-12-01T17:13:29.486767"}	\N
13	clientes	INSERT	15	postgres	2025-12-01 17:32:28.051922	\N	{"email": "tieso@gmail.com", "estado": "activo", "nombre": "mi niña tieso", "apellido": "mia", "cliente_id": 15, "fecha_creacion": "2025-12-01T17:32:28.051922", "hash_contrasena": "hash_12345678", "fecha_modificacion": null}	\N
14	pedidos	INSERT	24	postgres	2025-12-01 17:34:34.919918	\N	{"cupon_id": null, "subtotal": 0.00, "impuestos": 0.00, "pedido_id": 24, "cliente_id": 15, "fecha_pedido": "2025-12-01T17:34:34.919918", "total_pedido": 0.00, "estado_pedido": "pendiente", "descuento_aplicado": 0.00, "direccion_envio_id": 18, "fecha_modificacion": null}	\N
15	stock	UPDATE	3	postgres	2025-12-01 17:34:34.919918	{"sku": "TWS-NOISE-WHT", "estado": "activo", "stock_id": 3, "producto_id": 3, "fecha_creacion": "2025-11-06T21:33:04.911523", "precio_unitario": 120.00, "cantidad_en_stock": 34, "cantidad_reservada": 1, "fecha_modificacion": "2025-12-01T17:12:06.572356"}	{"sku": "TWS-NOISE-WHT", "estado": "activo", "stock_id": 3, "producto_id": 3, "fecha_creacion": "2025-11-06T21:33:04.911523", "precio_unitario": 120.00, "cantidad_en_stock": 34, "cantidad_reservada": 2, "fecha_modificacion": "2025-12-01T17:34:34.919918"}	\N
16	pedidos	UPDATE	24	postgres	2025-12-01 17:34:34.919918	{"cupon_id": null, "subtotal": 0.00, "impuestos": 0.00, "pedido_id": 24, "cliente_id": 15, "fecha_pedido": "2025-12-01T17:34:34.919918", "total_pedido": 0.00, "estado_pedido": "pendiente", "descuento_aplicado": 0.00, "direccion_envio_id": 18, "fecha_modificacion": null}	{"cupon_id": null, "subtotal": 120.00, "impuestos": 18.00, "pedido_id": 24, "cliente_id": 15, "fecha_pedido": "2025-12-01T17:34:34.919918", "total_pedido": 138.00, "estado_pedido": "pendiente", "descuento_aplicado": 0.00, "direccion_envio_id": 18, "fecha_modificacion": "2025-12-01T17:34:34.919918"}	\N
17	pagos	INSERT	37	postgres	2025-12-01 17:35:01.688097	\N	{"monto": 138.00, "pago_id": 37, "pedido_id": 24, "fecha_pago": "2025-12-01T17:35:01.688097", "estado_pago": "exitoso", "metodo_pago": "transferencia", "fecha_modificacion": null, "id_transaccion_externa": "54155616"}	\N
18	pedidos	UPDATE	24	postgres	2025-12-01 17:35:01.688097	{"cupon_id": null, "subtotal": 120.00, "impuestos": 18.00, "pedido_id": 24, "cliente_id": 15, "fecha_pedido": "2025-12-01T17:34:34.919918", "total_pedido": 138.00, "estado_pedido": "pendiente", "descuento_aplicado": 0.00, "direccion_envio_id": 18, "fecha_modificacion": "2025-12-01T17:34:34.919918"}	{"cupon_id": null, "subtotal": 120.00, "impuestos": 18.00, "pedido_id": 24, "cliente_id": 15, "fecha_pedido": "2025-12-01T17:34:34.919918", "total_pedido": 138.00, "estado_pedido": "pagado", "descuento_aplicado": 0.00, "direccion_envio_id": 18, "fecha_modificacion": "2025-12-01T17:35:01.688097"}	\N
19	productos	INSERT	11	postgres	2025-12-01 19:26:59.900897	\N	{"estado": "activo", "producto_id": 11, "categoria_id": 3, "fecha_creacion": "2025-12-01T19:26:59.900897", "nombre_producto": "tetera", "descripcion_larga": "para cocina ", "fecha_modificacion": null}	\N
20	productos	UPDATE	11	postgres	2025-12-01 19:27:10.605687	{"estado": "activo", "producto_id": 11, "categoria_id": 3, "fecha_creacion": "2025-12-01T19:26:59.900897", "nombre_producto": "tetera", "descripcion_larga": "para cocina ", "fecha_modificacion": null}	{"estado": "activo", "producto_id": 11, "categoria_id": 3, "fecha_creacion": "2025-12-01T19:26:59.900897", "nombre_producto": "tetera", "descripcion_larga": "para cocina ", "fecha_modificacion": null}	\N
21	productos	UPDATE	11	postgres	2025-12-01 19:27:22.675036	{"estado": "activo", "producto_id": 11, "categoria_id": 3, "fecha_creacion": "2025-12-01T19:26:59.900897", "nombre_producto": "tetera", "descripcion_larga": "para cocina ", "fecha_modificacion": null}	{"estado": "activo", "producto_id": 11, "categoria_id": 3, "fecha_creacion": "2025-12-01T19:26:59.900897", "nombre_producto": "tetera", "descripcion_larga": "para cocina ", "fecha_modificacion": null}	\N
22	productos	UPDATE	11	postgres	2025-12-01 19:27:37.55486	{"estado": "activo", "producto_id": 11, "categoria_id": 3, "fecha_creacion": "2025-12-01T19:26:59.900897", "nombre_producto": "tetera", "descripcion_larga": "para cocina ", "fecha_modificacion": null}	{"estado": "activo", "producto_id": 11, "categoria_id": 3, "fecha_creacion": "2025-12-01T19:26:59.900897", "nombre_producto": "tetera", "descripcion_larga": "para cocina ", "fecha_modificacion": null}	\N
23	pedidos	INSERT	25	postgres	2025-12-01 19:29:21.440718	\N	{"cupon_id": 3, "subtotal": 0.00, "impuestos": 0.00, "pedido_id": 25, "cliente_id": 10, "fecha_pedido": "2025-12-01T19:29:21.440718", "total_pedido": 0.00, "estado_pedido": "pendiente", "descuento_aplicado": 0.00, "direccion_envio_id": 11, "fecha_modificacion": null}	\N
24	stock	UPDATE	3	postgres	2025-12-01 19:29:21.440718	{"sku": "TWS-NOISE-WHT", "estado": "activo", "stock_id": 3, "producto_id": 3, "fecha_creacion": "2025-11-06T21:33:04.911523", "precio_unitario": 120.00, "cantidad_en_stock": 34, "cantidad_reservada": 2, "fecha_modificacion": "2025-12-01T17:34:34.919918"}	{"sku": "TWS-NOISE-WHT", "estado": "activo", "stock_id": 3, "producto_id": 3, "fecha_creacion": "2025-11-06T21:33:04.911523", "precio_unitario": 120.00, "cantidad_en_stock": 34, "cantidad_reservada": 4, "fecha_modificacion": "2025-12-01T19:29:21.440718"}	\N
25	pedidos	UPDATE	25	postgres	2025-12-01 19:29:21.440718	{"cupon_id": 3, "subtotal": 0.00, "impuestos": 0.00, "pedido_id": 25, "cliente_id": 10, "fecha_pedido": "2025-12-01T19:29:21.440718", "total_pedido": 0.00, "estado_pedido": "pendiente", "descuento_aplicado": 0.00, "direccion_envio_id": 11, "fecha_modificacion": null}	{"cupon_id": 3, "subtotal": 240.00, "impuestos": 18.00, "pedido_id": 25, "cliente_id": 10, "fecha_pedido": "2025-12-01T19:29:21.440718", "total_pedido": 138.00, "estado_pedido": "pendiente", "descuento_aplicado": 120.00, "direccion_envio_id": 11, "fecha_modificacion": "2025-12-01T19:29:21.440718"}	\N
26	cupones	UPDATE	3	postgres	2025-12-01 19:29:21.440718	{"estado": "activo", "cupon_id": 3, "codigo_cupon": "FLASH50", "fecha_creacion": "2025-11-06T21:32:52.284372", "tipo_descuento": "porcentaje", "valor_descuento": 50.00, "fecha_expiracion": "2026-06-15", "usos_disponibles": 2, "fecha_modificacion": "2025-11-11T19:28:14.306438"}	{"estado": "activo", "cupon_id": 3, "codigo_cupon": "FLASH50", "fecha_creacion": "2025-11-06T21:32:52.284372", "tipo_descuento": "porcentaje", "valor_descuento": 50.00, "fecha_expiracion": "2026-06-15", "usos_disponibles": 1, "fecha_modificacion": "2025-12-01T19:29:21.440718"}	\N
27	pagos	INSERT	38	postgres	2025-12-01 19:30:01.474389	\N	{"monto": 138.00, "pago_id": 38, "pedido_id": 25, "fecha_pago": "2025-12-01T19:30:01.474389", "estado_pago": "exitoso", "metodo_pago": "paypal", "fecha_modificacion": null, "id_transaccion_externa": "865545"}	\N
28	pedidos	UPDATE	25	postgres	2025-12-01 19:30:01.474389	{"cupon_id": 3, "subtotal": 240.00, "impuestos": 18.00, "pedido_id": 25, "cliente_id": 10, "fecha_pedido": "2025-12-01T19:29:21.440718", "total_pedido": 138.00, "estado_pedido": "pendiente", "descuento_aplicado": 120.00, "direccion_envio_id": 11, "fecha_modificacion": "2025-12-01T19:29:21.440718"}	{"cupon_id": 3, "subtotal": 240.00, "impuestos": 18.00, "pedido_id": 25, "cliente_id": 10, "fecha_pedido": "2025-12-01T19:29:21.440718", "total_pedido": 138.00, "estado_pedido": "pagado", "descuento_aplicado": 120.00, "direccion_envio_id": 11, "fecha_modificacion": "2025-12-01T19:30:01.474389"}	\N
29	pedidos	UPDATE	25	postgres	2025-12-01 19:31:04.771339	{"cupon_id": 3, "subtotal": 240.00, "impuestos": 18.00, "pedido_id": 25, "cliente_id": 10, "fecha_pedido": "2025-12-01T19:29:21.440718", "total_pedido": 138.00, "estado_pedido": "pagado", "descuento_aplicado": 120.00, "direccion_envio_id": 11, "fecha_modificacion": "2025-12-01T19:30:01.474389"}	{"cupon_id": 3, "subtotal": 240.00, "impuestos": 18.00, "pedido_id": 25, "cliente_id": 10, "fecha_pedido": "2025-12-01T19:29:21.440718", "total_pedido": 138.00, "estado_pedido": "enviado", "descuento_aplicado": 120.00, "direccion_envio_id": 11, "fecha_modificacion": "2025-12-01T19:31:04.771339"}	\N
30	pedidos	UPDATE	25	postgres	2025-12-01 19:31:28.98987	{"cupon_id": 3, "subtotal": 240.00, "impuestos": 18.00, "pedido_id": 25, "cliente_id": 10, "fecha_pedido": "2025-12-01T19:29:21.440718", "total_pedido": 138.00, "estado_pedido": "enviado", "descuento_aplicado": 120.00, "direccion_envio_id": 11, "fecha_modificacion": "2025-12-01T19:31:04.771339"}	{"cupon_id": 3, "subtotal": 240.00, "impuestos": 18.00, "pedido_id": 25, "cliente_id": 10, "fecha_pedido": "2025-12-01T19:29:21.440718", "total_pedido": 138.00, "estado_pedido": "completado", "descuento_aplicado": 120.00, "direccion_envio_id": 11, "fecha_modificacion": "2025-12-01T19:31:28.98987"}	\N
31	stock	UPDATE	3	postgres	2025-12-01 19:32:44.269528	{"sku": "TWS-NOISE-WHT", "estado": "activo", "stock_id": 3, "producto_id": 3, "fecha_creacion": "2025-11-06T21:33:04.911523", "precio_unitario": 120.00, "cantidad_en_stock": 34, "cantidad_reservada": 4, "fecha_modificacion": "2025-12-01T19:29:21.440718"}	{"sku": "TWS-NOISE-WHT", "estado": "activo", "stock_id": 3, "producto_id": 3, "fecha_creacion": "2025-11-06T21:33:04.911523", "precio_unitario": 120.00, "cantidad_en_stock": 34, "cantidad_reservada": 2, "fecha_modificacion": "2025-12-01T19:32:44.269528"}	\N
32	pagos	INSERT	39	postgres	2025-12-01 19:32:44.269528	\N	{"monto": 240.00, "pago_id": 39, "pedido_id": 25, "fecha_pago": "2025-12-01T19:32:44.269528", "estado_pago": "reembolsado", "metodo_pago": "Reembolso", "fecha_modificacion": null, "id_transaccion_externa": "REFUND_27"}	\N
33	productos	UPDATE	11	postgres	2025-12-01 19:44:41.871371	{"estado": "activo", "producto_id": 11, "categoria_id": 3, "fecha_creacion": "2025-12-01T19:26:59.900897", "nombre_producto": "tetera", "descripcion_larga": "para cocina ", "fecha_modificacion": null}	{"estado": "activo", "producto_id": 11, "categoria_id": 3, "fecha_creacion": "2025-12-01T19:26:59.900897", "nombre_producto": "tetera", "descripcion_larga": "para cocina ", "fecha_modificacion": null}	\N
34	productos	UPDATE	11	postgres	2025-12-01 19:44:58.976289	{"estado": "activo", "producto_id": 11, "categoria_id": 3, "fecha_creacion": "2025-12-01T19:26:59.900897", "nombre_producto": "tetera", "descripcion_larga": "para cocina ", "fecha_modificacion": null}	{"estado": "activo", "producto_id": 11, "categoria_id": 3, "fecha_creacion": "2025-12-01T19:26:59.900897", "nombre_producto": "tetera", "descripcion_larga": "para cocina ", "fecha_modificacion": null}	\N
35	stock	INSERT	18	postgres	2025-12-01 19:45:47.304812	\N	{"sku": "10", "estado": "activo", "stock_id": 18, "producto_id": 11, "fecha_creacion": "2025-12-01T19:45:47.304812", "precio_unitario": 100.00, "cantidad_en_stock": 10, "cantidad_reservada": 0, "fecha_modificacion": null}	\N
36	categorias	INSERT	7	postgres	2025-12-01 19:55:54.462409	\N	{"estado": "activo", "descripcion": null, "categoria_id": 7, "fecha_creacion": "2025-12-01T19:55:54.462409", "nombre_categoria": "COMIDA", "fecha_modificacion": null}	\N
37	productos	INSERT	12	postgres	2025-12-01 19:57:07.955546	\N	{"estado": "activo", "producto_id": 12, "categoria_id": 7, "fecha_creacion": "2025-12-01T19:57:07.955546", "nombre_producto": "SOPA", "descripcion_larga": "COMIDAS", "fecha_modificacion": null}	\N
38	productos	UPDATE	12	postgres	2025-12-01 19:57:18.952704	{"estado": "activo", "producto_id": 12, "categoria_id": 7, "fecha_creacion": "2025-12-01T19:57:07.955546", "nombre_producto": "SOPA", "descripcion_larga": "COMIDAS", "fecha_modificacion": null}	{"estado": "activo", "producto_id": 12, "categoria_id": 7, "fecha_creacion": "2025-12-01T19:57:07.955546", "nombre_producto": "SOPA", "descripcion_larga": "COMIDAS", "fecha_modificacion": null}	\N
39	stock	INSERT	19	postgres	2025-12-01 19:59:38.695488	\N	{"sku": "PREMIUN", "estado": "activo", "stock_id": 19, "producto_id": 12, "fecha_creacion": "2025-12-01T19:59:38.695488", "precio_unitario": 100.00, "cantidad_en_stock": 100, "cantidad_reservada": 0, "fecha_modificacion": null}	\N
40	productos	INSERT	13	postgres	2025-12-01 20:00:24.875073	\N	{"estado": "activo", "producto_id": 13, "categoria_id": 7, "fecha_creacion": "2025-12-01T20:00:24.875073", "nombre_producto": "SUSHI", "descripcion_larga": "JAPONESA\\r\\n", "fecha_modificacion": null}	\N
41	stock	INSERT	20	postgres	2025-12-01 20:00:56.578393	\N	{"sku": "PEZ", "estado": "activo", "stock_id": 20, "producto_id": 13, "fecha_creacion": "2025-12-01T20:00:56.578393", "precio_unitario": 100.00, "cantidad_en_stock": 20, "cantidad_reservada": 0, "fecha_modificacion": null}	\N
42	categorias	INSERT	8	postgres	2025-12-01 20:16:57.263179	\N	{"estado": "activo", "descripcion": "ewjfjw", "categoria_id": 8, "fecha_creacion": "2025-12-01T20:16:57.263179", "nombre_categoria": "ingles", "fecha_modificacion": null}	\N
43	productos	INSERT	14	postgres	2025-12-01 20:17:27.358322	\N	{"estado": "activo", "producto_id": 14, "categoria_id": 8, "fecha_creacion": "2025-12-01T20:17:27.358322", "nombre_producto": "texto ingles", "descripcion_larga": "ijwegfiwef", "fecha_modificacion": null}	\N
44	pedidos	INSERT	26	postgres	2025-12-05 20:09:41.376378	\N	{"cupon_id": null, "subtotal": 0.00, "impuestos": 0.00, "pedido_id": 26, "cliente_id": 2, "fecha_pedido": "2025-12-05T20:09:41.376378", "total_pedido": 0.00, "estado_pedido": "pendiente", "descuento_aplicado": 0.00, "direccion_envio_id": 3, "fecha_modificacion": null}	\N
45	stock	UPDATE	16	postgres	2025-12-05 20:09:41.376378	{"sku": "Express", "estado": "activo", "stock_id": 16, "producto_id": 6, "fecha_creacion": "2025-11-09T00:55:08.969144", "precio_unitario": 100.00, "cantidad_en_stock": 11, "cantidad_reservada": 0, "fecha_modificacion": "2025-11-21T14:52:53.556179"}	{"sku": "Express", "estado": "activo", "stock_id": 16, "producto_id": 6, "fecha_creacion": "2025-11-09T00:55:08.969144", "precio_unitario": 100.00, "cantidad_en_stock": 11, "cantidad_reservada": 1, "fecha_modificacion": "2025-12-05T20:09:41.376378"}	\N
46	pedidos	UPDATE	26	postgres	2025-12-05 20:09:41.376378	{"cupon_id": null, "subtotal": 0.00, "impuestos": 0.00, "pedido_id": 26, "cliente_id": 2, "fecha_pedido": "2025-12-05T20:09:41.376378", "total_pedido": 0.00, "estado_pedido": "pendiente", "descuento_aplicado": 0.00, "direccion_envio_id": 3, "fecha_modificacion": null}	{"cupon_id": null, "subtotal": 100.00, "impuestos": 15.00, "pedido_id": 26, "cliente_id": 2, "fecha_pedido": "2025-12-05T20:09:41.376378", "total_pedido": 115.00, "estado_pedido": "pendiente", "descuento_aplicado": 0.00, "direccion_envio_id": 3, "fecha_modificacion": "2025-12-05T20:09:41.376378"}	\N
47	pagos	INSERT	40	postgres	2025-12-05 20:10:25.809595	\N	{"monto": 115.00, "pago_id": 40, "pedido_id": 26, "fecha_pago": "2025-12-05T20:10:25.809595", "estado_pago": "exitoso", "metodo_pago": "paypal", "fecha_modificacion": null, "id_transaccion_externa": "7587257"}	\N
48	pedidos	UPDATE	26	postgres	2025-12-05 20:10:25.809595	{"cupon_id": null, "subtotal": 100.00, "impuestos": 15.00, "pedido_id": 26, "cliente_id": 2, "fecha_pedido": "2025-12-05T20:09:41.376378", "total_pedido": 115.00, "estado_pedido": "pendiente", "descuento_aplicado": 0.00, "direccion_envio_id": 3, "fecha_modificacion": "2025-12-05T20:09:41.376378"}	{"cupon_id": null, "subtotal": 100.00, "impuestos": 15.00, "pedido_id": 26, "cliente_id": 2, "fecha_pedido": "2025-12-05T20:09:41.376378", "total_pedido": 115.00, "estado_pedido": "pagado", "descuento_aplicado": 0.00, "direccion_envio_id": 3, "fecha_modificacion": "2025-12-05T20:10:25.809595"}	\N
49	pedidos	UPDATE	26	postgres	2025-12-05 20:11:13.811771	{"cupon_id": null, "subtotal": 100.00, "impuestos": 15.00, "pedido_id": 26, "cliente_id": 2, "fecha_pedido": "2025-12-05T20:09:41.376378", "total_pedido": 115.00, "estado_pedido": "pagado", "descuento_aplicado": 0.00, "direccion_envio_id": 3, "fecha_modificacion": "2025-12-05T20:10:25.809595"}	{"cupon_id": null, "subtotal": 100.00, "impuestos": 15.00, "pedido_id": 26, "cliente_id": 2, "fecha_pedido": "2025-12-05T20:09:41.376378", "total_pedido": 115.00, "estado_pedido": "enviado", "descuento_aplicado": 0.00, "direccion_envio_id": 3, "fecha_modificacion": "2025-12-05T20:11:13.811771"}	\N
50	pedidos	UPDATE	26	postgres	2025-12-05 20:11:32.775038	{"cupon_id": null, "subtotal": 100.00, "impuestos": 15.00, "pedido_id": 26, "cliente_id": 2, "fecha_pedido": "2025-12-05T20:09:41.376378", "total_pedido": 115.00, "estado_pedido": "enviado", "descuento_aplicado": 0.00, "direccion_envio_id": 3, "fecha_modificacion": "2025-12-05T20:11:13.811771"}	{"cupon_id": null, "subtotal": 100.00, "impuestos": 15.00, "pedido_id": 26, "cliente_id": 2, "fecha_pedido": "2025-12-05T20:09:41.376378", "total_pedido": 115.00, "estado_pedido": "completado", "descuento_aplicado": 0.00, "direccion_envio_id": 3, "fecha_modificacion": "2025-12-05T20:11:32.775038"}	\N
51	stock	UPDATE	16	postgres	2025-12-05 20:12:08.055992	{"sku": "Express", "estado": "activo", "stock_id": 16, "producto_id": 6, "fecha_creacion": "2025-11-09T00:55:08.969144", "precio_unitario": 100.00, "cantidad_en_stock": 11, "cantidad_reservada": 1, "fecha_modificacion": "2025-12-05T20:09:41.376378"}	{"sku": "Express", "estado": "activo", "stock_id": 16, "producto_id": 6, "fecha_creacion": "2025-11-09T00:55:08.969144", "precio_unitario": 100.00, "cantidad_en_stock": 11, "cantidad_reservada": 0, "fecha_modificacion": "2025-12-05T20:12:08.055992"}	\N
52	pagos	INSERT	41	postgres	2025-12-05 20:12:08.055992	\N	{"monto": 100.00, "pago_id": 41, "pedido_id": 26, "fecha_pago": "2025-12-05T20:12:08.055992", "estado_pago": "reembolsado", "metodo_pago": "Reembolso", "fecha_modificacion": null, "id_transaccion_externa": "REFUND_28"}	\N
53	pedidos	INSERT	27	postgres	2025-12-05 20:19:00.037848	\N	{"cupon_id": 1, "subtotal": 0.00, "impuestos": 0.00, "pedido_id": 27, "cliente_id": 3, "fecha_pedido": "2025-12-05T20:19:00.037848", "total_pedido": 0.00, "estado_pedido": "pendiente", "descuento_aplicado": 0.00, "direccion_envio_id": 12, "fecha_modificacion": null}	\N
54	stock	UPDATE	4	postgres	2025-12-05 20:19:00.037848	{"sku": "CAM-ALG-BLC-M", "estado": "activo", "stock_id": 4, "producto_id": 4, "fecha_creacion": "2025-11-06T21:33:04.911523", "precio_unitario": 19.99, "cantidad_en_stock": 100, "cantidad_reservada": 0, "fecha_modificacion": "2025-11-11T22:16:43.844545"}	{"sku": "CAM-ALG-BLC-M", "estado": "activo", "stock_id": 4, "producto_id": 4, "fecha_creacion": "2025-11-06T21:33:04.911523", "precio_unitario": 19.99, "cantidad_en_stock": 100, "cantidad_reservada": 1, "fecha_modificacion": "2025-12-05T20:19:00.037848"}	\N
55	pedidos	UPDATE	27	postgres	2025-12-05 20:19:00.037848	{"cupon_id": 1, "subtotal": 0.00, "impuestos": 0.00, "pedido_id": 27, "cliente_id": 3, "fecha_pedido": "2025-12-05T20:19:00.037848", "total_pedido": 0.00, "estado_pedido": "pendiente", "descuento_aplicado": 0.00, "direccion_envio_id": 12, "fecha_modificacion": null}	{"cupon_id": 1, "subtotal": 19.99, "impuestos": 2.70, "pedido_id": 27, "cliente_id": 3, "fecha_pedido": "2025-12-05T20:19:00.037848", "total_pedido": 20.69, "estado_pedido": "pendiente", "descuento_aplicado": 2.00, "direccion_envio_id": 12, "fecha_modificacion": "2025-12-05T20:19:00.037848"}	\N
56	cupones	UPDATE	1	postgres	2025-12-05 20:19:00.037848	{"estado": "activo", "cupon_id": 1, "codigo_cupon": "BIENVENIDO10", "fecha_creacion": "2025-11-06T21:32:52.284372", "tipo_descuento": "porcentaje", "valor_descuento": 10.00, "fecha_expiracion": "2026-12-31", "usos_disponibles": 97, "fecha_modificacion": "2025-11-11T21:15:43.464898"}	{"estado": "activo", "cupon_id": 1, "codigo_cupon": "BIENVENIDO10", "fecha_creacion": "2025-11-06T21:32:52.284372", "tipo_descuento": "porcentaje", "valor_descuento": 10.00, "fecha_expiracion": "2026-12-31", "usos_disponibles": 96, "fecha_modificacion": "2025-12-05T20:19:00.037848"}	\N
57	pagos	INSERT	42	postgres	2025-12-05 20:19:38.474407	\N	{"monto": 20.69, "pago_id": 42, "pedido_id": 27, "fecha_pago": "2025-12-05T20:19:38.474407", "estado_pago": "exitoso", "metodo_pago": "paypal", "fecha_modificacion": null, "id_transaccion_externa": "loulou"}	\N
58	pedidos	UPDATE	27	postgres	2025-12-05 20:19:38.474407	{"cupon_id": 1, "subtotal": 19.99, "impuestos": 2.70, "pedido_id": 27, "cliente_id": 3, "fecha_pedido": "2025-12-05T20:19:00.037848", "total_pedido": 20.69, "estado_pedido": "pendiente", "descuento_aplicado": 2.00, "direccion_envio_id": 12, "fecha_modificacion": "2025-12-05T20:19:00.037848"}	{"cupon_id": 1, "subtotal": 19.99, "impuestos": 2.70, "pedido_id": 27, "cliente_id": 3, "fecha_pedido": "2025-12-05T20:19:00.037848", "total_pedido": 20.69, "estado_pedido": "pagado", "descuento_aplicado": 2.00, "direccion_envio_id": 12, "fecha_modificacion": "2025-12-05T20:19:38.474407"}	\N
59	pedidos	UPDATE	27	postgres	2025-12-05 20:20:09.343046	{"cupon_id": 1, "subtotal": 19.99, "impuestos": 2.70, "pedido_id": 27, "cliente_id": 3, "fecha_pedido": "2025-12-05T20:19:00.037848", "total_pedido": 20.69, "estado_pedido": "pagado", "descuento_aplicado": 2.00, "direccion_envio_id": 12, "fecha_modificacion": "2025-12-05T20:19:38.474407"}	{"cupon_id": 1, "subtotal": 19.99, "impuestos": 2.70, "pedido_id": 27, "cliente_id": 3, "fecha_pedido": "2025-12-05T20:19:00.037848", "total_pedido": 20.69, "estado_pedido": "enviado", "descuento_aplicado": 2.00, "direccion_envio_id": 12, "fecha_modificacion": "2025-12-05T20:20:09.343046"}	\N
60	pedidos	UPDATE	27	postgres	2025-12-05 20:20:32.783112	{"cupon_id": 1, "subtotal": 19.99, "impuestos": 2.70, "pedido_id": 27, "cliente_id": 3, "fecha_pedido": "2025-12-05T20:19:00.037848", "total_pedido": 20.69, "estado_pedido": "enviado", "descuento_aplicado": 2.00, "direccion_envio_id": 12, "fecha_modificacion": "2025-12-05T20:20:09.343046"}	{"cupon_id": 1, "subtotal": 19.99, "impuestos": 2.70, "pedido_id": 27, "cliente_id": 3, "fecha_pedido": "2025-12-05T20:19:00.037848", "total_pedido": 20.69, "estado_pedido": "completado", "descuento_aplicado": 2.00, "direccion_envio_id": 12, "fecha_modificacion": "2025-12-05T20:20:32.783112"}	\N
61	stock	UPDATE	4	postgres	2025-12-05 20:21:11.47658	{"sku": "CAM-ALG-BLC-M", "estado": "activo", "stock_id": 4, "producto_id": 4, "fecha_creacion": "2025-11-06T21:33:04.911523", "precio_unitario": 19.99, "cantidad_en_stock": 100, "cantidad_reservada": 1, "fecha_modificacion": "2025-12-05T20:19:00.037848"}	{"sku": "CAM-ALG-BLC-M", "estado": "activo", "stock_id": 4, "producto_id": 4, "fecha_creacion": "2025-11-06T21:33:04.911523", "precio_unitario": 19.99, "cantidad_en_stock": 100, "cantidad_reservada": 0, "fecha_modificacion": "2025-12-05T20:21:11.47658"}	\N
62	pagos	INSERT	43	postgres	2025-12-05 20:21:11.47658	\N	{"monto": 19.99, "pago_id": 43, "pedido_id": 27, "fecha_pago": "2025-12-05T20:21:11.47658", "estado_pago": "reembolsado", "metodo_pago": "Reembolso", "fecha_modificacion": null, "id_transaccion_externa": "REFUND_29"}	\N
69	clientes	UPDATE	11	postgres	2026-07-25 22:20:12.342947	{"email": "sales.lol@gmail.com", "estado": "activo", "nombre": "Sororo", "apellido": "sales", "cliente_id": 11, "fecha_creacion": "2025-11-10T16:16:14.503449", "hash_contrasena": "hash_12345678", "fecha_modificacion": "2025-11-10T16:17:49.795318"}	{"email": "karina.flores@email.com", "estado": "activo", "nombre": "Karina", "apellido": "Flores", "cliente_id": 11, "fecha_creacion": "2025-11-10T16:16:14.503449", "hash_contrasena": "hash_12345678", "fecha_modificacion": "2026-07-25T22:20:12.342947"}	\N
70	clientes	UPDATE	12	postgres	2026-07-25 22:20:12.342947	{"email": "chile@gmail.com", "estado": "activo", "nombre": "chile", "apellido": "loco", "cliente_id": 12, "fecha_creacion": "2025-11-10T21:58:54.393373", "hash_contrasena": "hash_1234567", "fecha_modificacion": null}	{"email": "lucia.morales@email.com", "estado": "activo", "nombre": "Lucía", "apellido": "Morales", "cliente_id": 12, "fecha_creacion": "2025-11-10T21:58:54.393373", "hash_contrasena": "hash_1234567", "fecha_modificacion": "2026-07-25T22:20:12.342947"}	\N
71	clientes	UPDATE	13	postgres	2026-07-25 22:20:12.342947	{"email": "ijij@gmail.com", "estado": "activo", "nombre": "el loco", "apellido": "savio", "cliente_id": 13, "fecha_creacion": "2025-11-10T22:03:27.503107", "hash_contrasena": "hash_189274891", "fecha_modificacion": null}	{"email": "martin.herrera@email.com", "estado": "activo", "nombre": "Martín", "apellido": "Herrera", "cliente_id": 13, "fecha_creacion": "2025-11-10T22:03:27.503107", "hash_contrasena": "hash_189274891", "fecha_modificacion": "2026-07-25T22:20:12.342947"}	\N
72	clientes	UPDATE	14	postgres	2026-07-25 22:20:12.342947	{"email": "torque@gmail.com", "estado": "activo", "nombre": "el choca", "apellido": "torque", "cliente_id": 14, "fecha_creacion": "2025-11-10T22:21:31.444419", "hash_contrasena": "hash_09134u3209852", "fecha_modificacion": "2025-11-11T19:20:17.571082"}	{"email": "natalia.castro@email.com", "estado": "activo", "nombre": "Natalia", "apellido": "Castro", "cliente_id": 14, "fecha_creacion": "2025-11-10T22:21:31.444419", "hash_contrasena": "hash_09134u3209852", "fecha_modificacion": "2026-07-25T22:20:12.342947"}	\N
73	clientes	UPDATE	15	postgres	2026-07-25 22:20:12.342947	{"email": "tieso@gmail.com", "estado": "activo", "nombre": "mi niña tieso", "apellido": "mia", "cliente_id": 15, "fecha_creacion": "2025-12-01T17:32:28.051922", "hash_contrasena": "hash_12345678", "fecha_modificacion": null}	{"email": "oscar.vargas@email.com", "estado": "activo", "nombre": "Óscar", "apellido": "Vargas", "cliente_id": 15, "fecha_creacion": "2025-12-01T17:32:28.051922", "hash_contrasena": "hash_12345678", "fecha_modificacion": "2026-07-25T22:20:12.342947"}	\N
74	categorias	UPDATE	7	postgres	2026-07-25 22:20:12.342947	{"estado": "activo", "descripcion": null, "categoria_id": 7, "fecha_creacion": "2025-12-01T19:55:54.462409", "nombre_categoria": "COMIDA", "fecha_modificacion": null}	{"estado": "activo", "descripcion": null, "categoria_id": 7, "fecha_creacion": "2025-12-01T19:55:54.462409", "nombre_categoria": "Alimentos", "fecha_modificacion": "2026-07-25T22:20:12.342947"}	\N
75	productos	UPDATE	11	postgres	2026-07-25 22:20:12.342947	{"estado": "activo", "producto_id": 11, "categoria_id": 3, "fecha_creacion": "2025-12-01T19:26:59.900897", "nombre_producto": "tetera", "descripcion_larga": "para cocina ", "fecha_modificacion": null}	{"estado": "activo", "producto_id": 11, "categoria_id": 3, "fecha_creacion": "2025-12-01T19:26:59.900897", "nombre_producto": "Tetera de Cerámica 1.2L", "descripcion_larga": "Tetera de cerámica esmaltada con filtro, apta para inducción.", "fecha_modificacion": "2026-07-25T22:20:12.342947"}	\N
76	productos	UPDATE	12	postgres	2026-07-25 22:20:12.342947	{"estado": "activo", "producto_id": 12, "categoria_id": 7, "fecha_creacion": "2025-12-01T19:57:07.955546", "nombre_producto": "SOPA", "descripcion_larga": "COMIDAS", "fecha_modificacion": null}	{"estado": "activo", "producto_id": 12, "categoria_id": 7, "fecha_creacion": "2025-12-01T19:57:07.955546", "nombre_producto": "Sopa Instantánea Ramen (Pack x5)", "descripcion_larga": "Pack de 5 sopas ramen estilo japonés, listas en 3 minutos.", "fecha_modificacion": "2026-07-25T22:20:12.342947"}	\N
77	productos	UPDATE	13	postgres	2026-07-25 22:20:12.342947	{"estado": "activo", "producto_id": 13, "categoria_id": 7, "fecha_creacion": "2025-12-01T20:00:24.875073", "nombre_producto": "SUSHI", "descripcion_larga": "JAPONESA\\r\\n", "fecha_modificacion": null}	{"estado": "activo", "producto_id": 13, "categoria_id": 7, "fecha_creacion": "2025-12-01T20:00:24.875073", "nombre_producto": "Kit para Preparar Sushi", "descripcion_larga": "Kit completo con esterilla, palillos y molde para sushi casero.", "fecha_modificacion": "2026-07-25T22:20:12.342947"}	\N
78	stock	UPDATE	18	postgres	2026-07-25 22:20:12.342947	{"sku": "10", "estado": "activo", "stock_id": 18, "producto_id": 11, "fecha_creacion": "2025-12-01T19:45:47.304812", "precio_unitario": 100.00, "cantidad_en_stock": 10, "cantidad_reservada": 0, "fecha_modificacion": null}	{"sku": "TET-CER-12L", "estado": "activo", "stock_id": 18, "producto_id": 11, "fecha_creacion": "2025-12-01T19:45:47.304812", "precio_unitario": 100.00, "cantidad_en_stock": 10, "cantidad_reservada": 0, "fecha_modificacion": "2026-07-25T22:20:12.342947"}	\N
79	stock	UPDATE	19	postgres	2026-07-25 22:20:12.342947	{"sku": "PREMIUN", "estado": "activo", "stock_id": 19, "producto_id": 12, "fecha_creacion": "2025-12-01T19:59:38.695488", "precio_unitario": 100.00, "cantidad_en_stock": 100, "cantidad_reservada": 0, "fecha_modificacion": null}	{"sku": "RAM-PACK5", "estado": "activo", "stock_id": 19, "producto_id": 12, "fecha_creacion": "2025-12-01T19:59:38.695488", "precio_unitario": 100.00, "cantidad_en_stock": 100, "cantidad_reservada": 0, "fecha_modificacion": "2026-07-25T22:20:12.342947"}	\N
80	stock	UPDATE	20	postgres	2026-07-25 22:20:12.342947	{"sku": "PEZ", "estado": "activo", "stock_id": 20, "producto_id": 13, "fecha_creacion": "2025-12-01T20:00:56.578393", "precio_unitario": 100.00, "cantidad_en_stock": 20, "cantidad_reservada": 0, "fecha_modificacion": null}	{"sku": "SUSHI-KIT-01", "estado": "activo", "stock_id": 20, "producto_id": 13, "fecha_creacion": "2025-12-01T20:00:56.578393", "precio_unitario": 100.00, "cantidad_en_stock": 20, "cantidad_reservada": 0, "fecha_modificacion": "2026-07-25T22:20:12.342947"}	\N
81	productos	DELETE	14	postgres	2026-07-25 22:20:12.342947	{"estado": "activo", "producto_id": 14, "categoria_id": 8, "fecha_creacion": "2025-12-01T20:17:27.358322", "nombre_producto": "texto ingles", "descripcion_larga": "ijwegfiwef", "fecha_modificacion": null}	\N	\N
82	categorias	DELETE	8	postgres	2026-07-25 22:20:12.342947	{"estado": "activo", "descripcion": "ewjfjw", "categoria_id": 8, "fecha_creacion": "2025-12-01T20:16:57.263179", "nombre_categoria": "ingles", "fecha_modificacion": null}	\N	\N
\.


--
-- Data for Name: categorias; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.categorias (categoria_id, nombre_categoria, descripcion, estado, fecha_creacion, fecha_modificacion) FROM stdin;
1	Electrónica	Dispositivos y gadgets tecnológicos.	activo	2025-11-06 21:32:46.691439	\N
2	Ropa	Prendas de vestir para todas las edades.	activo	2025-11-06 21:32:46.691439	\N
4	Libros	Libros físicos y digitales de diversos géneros.	activo	2025-11-06 21:32:46.691439	\N
6	Juguetes	ya no	activo	2025-11-08 20:01:40.199918	2025-11-10 12:34:07.340357
3	Hogar y Cocina	Artículos para el hogar, decoración y utensilios de cocina.	activo	2025-11-06 21:32:46.691439	2025-11-11 21:11:54.768424
5	Deportes	Equipamiento, ropa y accesorios deportivos.	activo	2025-11-06 21:32:46.691439	2025-11-13 11:56:42.455775
7	Alimentos	\N	activo	2025-12-01 19:55:54.462409	2026-07-25 22:20:12.342947
\.


--
-- Data for Name: clientes; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.clientes (cliente_id, nombre, apellido, email, hash_contrasena, estado, fecha_creacion, fecha_modificacion) FROM stdin;
2	Bruno	Martínez	bruno.martinez@email.com	$2b$12$E/Vxk.S.G.a0b5C1.XY.a.CqY.qS.aG/a0b5C1.XY.a.CqY.qS	activo	2025-11-06 21:32:49.147468	\N
3	Carla	Rodríguez	carla.rodriguez@email.com	$2b$12$E/Vxk.S.G.a0b5C1.XY.a.CqY.qS.aG/a0b5C1.XY.a.CqY.qS	activo	2025-11-06 21:32:49.147468	\N
4	David	López	david.lopez@email.com	$2b$12$E/Vxk.S.G.a0b5C1.XY.a.CqY.qS.aG/a0b5C1.XY.a.CqY.qS	activo	2025-11-06 21:32:49.147468	\N
5	Elena	Sánchez	elena.sanchez@email.com	$2b$12$E/Vxk.S.G.a0b5C1.XY.a.CqY.qS.aG/a0b5C1.XY.a.CqY.qS	activo	2025-11-06 21:32:49.147468	\N
6	Felipe	Gómez	felipe.gomez@email.com	$2b$12$E/Vxk.S.G.a0b5C1.XY.a.CqY.qS.aG/a0b5C1.XY.a.CqY.qS	activo	2025-11-06 21:32:49.147468	\N
7	Gabriela	Pérez	gabi.perez@email.com	$2b$12$E/Vxk.S.G.a0b5C1.XY.a.CqY.qS.aG/a0b5C1.XY.a.CqY.qS	activo	2025-11-06 21:32:49.147468	\N
8	Hugo	Torres	hugo.torres@email.com	$2b$12$E/Vxk.S.G.a0b5C1.XY.a.CqY.qS.aG/a0b5C1.XY.a.CqY.qS	activo	2025-11-06 21:32:49.147468	\N
9	Inés	Ramírez	ines.ramirez@email.com	$2b$12$E/Vxk.S.G.a0b5C1.XY.a.CqY.qS.aG/a0b5C1.XY.a.CqY.qS	activo	2025-11-06 21:32:49.147468	\N
10	Juan	Díaz	juan.diaz@email.com	$2b$12$E/Vxk.S.G.a0b5C1.XY.a.CqY.qS.aG/a0b5C1.XY.a.CqY.qS	activo	2025-11-06 21:32:49.147468	\N
1	Ana	García	ana.garcia@email.com	$2b$12$E/Vxk.S.G.a0b5C1.XY.a.CqY.qS.aG/a0b5C1.XY.a.CqY.qS	activo	2025-11-06 21:32:49.147468	\N
11	Karina	Flores	karina.flores@email.com	hash_12345678	activo	2025-11-10 16:16:14.503449	2026-07-25 22:20:12.342947
12	Lucía	Morales	lucia.morales@email.com	hash_1234567	activo	2025-11-10 21:58:54.393373	2026-07-25 22:20:12.342947
13	Martín	Herrera	martin.herrera@email.com	hash_189274891	activo	2025-11-10 22:03:27.503107	2026-07-25 22:20:12.342947
14	Natalia	Castro	natalia.castro@email.com	hash_09134u3209852	activo	2025-11-10 22:21:31.444419	2026-07-25 22:20:12.342947
15	Óscar	Vargas	oscar.vargas@email.com	hash_12345678	activo	2025-12-01 17:32:28.051922	2026-07-25 22:20:12.342947
\.


--
-- Data for Name: cupones; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.cupones (cupon_id, codigo_cupon, tipo_descuento, valor_descuento, fecha_expiracion, usos_disponibles, estado, fecha_creacion, fecha_modificacion) FROM stdin;
2	VERANO20	fijo	20.00	2026-09-30	50	activo	2025-11-06 21:32:52.284372	\N
5	BLACK'FRIDAY	fijo	200.00	2025-11-11	4	activo	2025-11-10 13:05:09.306532	2025-11-11 19:21:40.759285
4	OLD_CUPON	fijo	5.00	2025-11-13	1	activo	2025-11-06 21:32:52.284372	2025-11-12 19:50:16.574287
6	TEST2024	porcentaje	15.00	2025-12-20	100	activo	2025-11-20 21:41:25.174844	\N
3	FLASH50	porcentaje	50.00	2026-06-15	1	activo	2025-11-06 21:32:52.284372	2025-12-01 19:29:21.440718
1	BIENVENIDO10	porcentaje	10.00	2026-12-31	96	activo	2025-11-06 21:32:52.284372	2025-12-05 20:19:00.037848
\.


--
-- Data for Name: detalle_pedido; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.detalle_pedido (detalle_id, pedido_id, stock_id, cantidad, precio_unitario_compra, fecha_creacion) FROM stdin;
1	1	1	1	1499.99	2025-11-06 21:33:11.360508
2	1	3	2	120.00	2025-11-06 21:33:11.360508
3	2	5	3	19.99	2025-11-06 21:33:11.360508
4	2	8	1	49.95	2025-11-06 21:33:11.360508
5	3	10	1	450.00	2025-11-06 21:33:11.360508
7	5	13	1	110.00	2025-11-06 21:33:11.360508
8	6	15	3	1299.99	2025-11-10 20:26:37.295097
9	7	16	1	100.00	2025-11-10 20:32:53.781194
10	8	4	1	19.99	2025-11-10 21:52:49.690983
11	9	2	1	799.50	2025-11-10 22:00:25.632035
12	10	12	1	160.00	2025-11-10 22:04:15.772148
13	11	3	1	120.00	2025-11-10 22:22:46.814692
14	12	12	1	160.00	2025-11-11 19:21:40.759285
15	13	12	1	160.00	2025-11-11 19:28:14.306438
16	14	15	1	1299.99	2025-11-11 20:05:23.049969
17	15	13	1	80.00	2025-11-11 21:15:43.464898
18	16	13	1	80.00	2025-11-11 21:24:53.508485
19	17	13	1	80.00	2025-11-11 21:26:04.181774
20	18	13	1	80.00	2025-11-11 21:27:52.121011
21	19	13	1	80.00	2025-11-11 21:45:08.800919
22	20	16	3	100.00	2025-11-11 22:00:38.645116
24	22	13	1	80.00	2025-11-13 12:04:07.805756
25	23	3	1	120.00	2025-12-01 17:12:06.572356
26	24	3	1	120.00	2025-12-01 17:34:34.919918
27	25	3	2	120.00	2025-12-01 19:29:21.440718
28	26	16	1	100.00	2025-12-05 20:09:41.376378
29	27	4	1	19.99	2025-12-05 20:19:00.037848
\.


--
-- Data for Name: devoluciones; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.devoluciones (devolucion_id, detalle_id, motivo, cantidad_devuelta, fecha_solicitud, estado_devolucion, fecha_modificacion) FROM stdin;
1	2	No me gustó el color, esperaba blanco puro.	1	2025-11-06 21:34:10.982763	solicitada	\N
2	3	Pedí talla M y me quedaron pequeñas.	3	2025-11-06 21:34:14.957419	aprobada	\N
10	9	ay no puede ser le di sin querer 	1	2025-11-10 21:37:19.985173	reembolsada	2025-11-10 21:37:19.985173
11	12	SE PONCHO	1	2025-11-10 22:07:41.174876	reembolsada	2025-11-10 22:07:41.174876
12	13	ay me lleva el chinguawat	1	2025-11-10 22:24:35.229847	reembolsada	2025-11-10 22:24:35.229847
13	15	no sirve 	1	2025-11-11 19:30:04.901816	reembolsada	2025-11-11 19:30:04.901816
14	1	prueba 	1	2025-11-11 22:04:34.292398	reembolsada	2025-11-11 22:04:34.292398
15	24	no me gusto	1	2025-11-13 12:11:53.340469	reembolsada	2025-11-13 12:11:53.340469
16	27	no funciona	2	2025-12-01 19:32:44.269528	reembolsada	2025-12-01 19:32:44.269528
17	28	tyruyu	1	2025-12-05 20:12:08.055992	reembolsada	2025-12-05 20:12:08.055992
18	29	fyjyurju	1	2025-12-05 20:21:11.47658	reembolsada	2025-12-05 20:21:11.47658
\.


--
-- Data for Name: direcciones; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.direcciones (direccion_id, cliente_id, direccion_linea_1, ciudad, codigo_postal, pais, estado, fecha_creacion, fecha_modificacion) FROM stdin;
1	1	Calle Falsa 123	Springfield	S1234	EEUU	activo	2025-11-06 21:33:01.972951	\N
2	1	Avenida Siempreviva 742	Springfield	S5678	EEUU	activo	2025-11-06 21:33:01.972951	\N
3	2	Plaza Mayor 1	Madrid	28001	España	activo	2025-11-06 21:33:01.972951	\N
4	3	Boulevard de los Sueños Rotos 44	Lima	LIMA01	Perú	activo	2025-11-06 21:33:01.972951	\N
5	4	Carrera 15 # 80-10	Bogotá	110111	Colombia	activo	2025-11-06 21:33:01.972951	\N
6	5	Av. Corrientes 1000	Buenos Aires	C1043	Argentina	activo	2025-11-06 21:33:01.972951	\N
7	6	Rua Augusta 500	São Paulo	01304-001	Brasil	activo	2025-11-06 21:33:01.972951	\N
8	7	Paseo de la Reforma 222	CDMX	06600	México	activo	2025-11-06 21:33:01.972951	\N
9	8	Merced 391	Santiago	8320000	Chile	activo	2025-11-06 21:33:01.972951	\N
10	9	Jr. de la Unión 899	Lima	LIMA01	Perú	activo	2025-11-06 21:33:01.972951	\N
11	10	Calle 8 # 12-30	Bogotá	111711	Colombia	activo	2025-11-06 21:33:01.972951	\N
12	3	Av. Larco 550	Lima	LIMA18	Perú	activo	2025-11-06 21:33:01.972951	\N
13	5	Defensa 100	Buenos Aires	C1065	Argentina	activo	2025-11-06 21:33:01.972951	\N
14	11	Doblé vía la guardia	Santa cruz de la sierra	0000	Bolivia	activo	2025-11-10 16:47:15.309249	2025-11-10 20:16:06.005513
15	12	Doblé vía la guardia	Santa cruz de la sierra	00000	Bolivia	activo	2025-11-10 21:59:23.864673	\N
16	13	Doblé vía la guardia	Santa cruz de la sierra	3222	Bolivia	activo	2025-11-10 22:03:39.922012	\N
17	14	Doblé vía la guardia	Santa cruz de la sierra	548494	Bolivia	activo	2025-11-10 22:22:03.580462	\N
18	15	Doblé vía la guardia	Santa cruz de la sierra	0000	Bolivia	activo	2025-12-01 17:32:39.628165	\N
\.


--
-- Data for Name: envios; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.envios (envio_id, pedido_id, fecha_envio, transportista, numero_tracking, estado_envio, fecha_creacion, fecha_modificacion) FROM stdin;
3	5	\N	UPS	UPS_777888999	entregado	2025-11-06 21:34:06.248837	\N
2	2	\N	Servientrega	SV_444555666	entregado	2025-11-06 21:34:06.248837	2025-11-10 18:25:30.38128
1	1	2025-11-10 18:27:41.187705	DHL	DHL_111222333	entregado	2025-11-06 21:34:06.248837	2025-11-10 18:27:59.46037
5	6	2025-11-10 20:57:45.513871	Servientrega	SV_444555666	en_transito	2025-11-10 20:56:19.441322	2025-11-10 20:57:45.513871
4	7	2025-11-10 20:58:08.650306	DHL	SV_444555666	entregado	2025-11-10 20:54:51.627996	2025-11-10 20:58:47.797158
6	3	\N	\N	\N	en_preparacion	2025-11-10 21:53:20.223208	\N
7	8	\N	\N	\N	entregado	2025-11-10 21:54:03.611545	2025-11-10 21:55:13.997383
8	9	\N	DHL	as_48845949	entregado	2025-11-10 22:00:55.838934	2025-11-10 22:01:32.553205
9	10	2025-11-10 22:05:31.107253	PSU	FLD_584948558	entregado	2025-11-10 22:04:48.831581	2025-11-10 22:05:43.764932
10	11	2025-11-10 22:23:48.398498	saudi	4945615198	entregado	2025-11-10 22:23:19.056591	2025-11-10 22:24:00.345162
11	13	2025-11-11 19:29:13.12272	hnj	651981	entregado	2025-11-11 19:28:40.440649	2025-11-11 19:29:27.260354
13	15	2025-11-11 21:23:02.055728	kmdlla	4945615198	entregado	2025-11-11 21:16:27.703083	2025-11-11 21:23:23.311305
14	17	\N	\N	\N	fallido	2025-11-11 21:26:40.754752	2025-11-11 21:30:14.849993
15	18	\N	\N	\N	fallido	2025-11-11 21:28:29.666143	2025-11-11 21:30:06.531517
16	19	\N	\N	\N	fallido	2025-11-11 21:47:47.408582	2025-11-11 21:48:01.89198
12	14	2025-11-11 20:07:09.834443	llol	898289	fallido	2025-11-11 20:06:16.64035	2025-11-11 21:57:38.915054
17	20	\N	\N	\N	fallido	2025-11-11 22:01:03.317628	2025-11-11 22:01:48.206223
18	22	2025-11-13 12:10:53.650665	\N	\N	entregado	2025-11-13 12:08:19.645391	2025-11-13 12:11:19.487788
19	23	\N	\N	\N	en_preparacion	2025-12-01 17:13:29.486767	\N
20	24	\N	\N	\N	en_preparacion	2025-12-01 17:35:01.688097	\N
21	25	2025-12-01 19:31:04.771339	loco	DHL_111222333	entregado	2025-12-01 19:30:01.474389	2025-12-01 19:31:28.98987
22	26	2025-12-05 20:11:13.811771	htikuk	dtyry	entregado	2025-12-05 20:10:25.809595	2025-12-05 20:11:32.775038
23	27	2025-12-05 20:20:09.343046	iluioyioy	yutu	entregado	2025-12-05 20:19:38.474407	2025-12-05 20:20:32.783112
\.


--
-- Data for Name: historial_estados; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.historial_estados (historial_id, pedido_id, estado_anterior, estado_nuevo, usuario, comentario, fecha_cambio) FROM stdin;
1	6	enviado	completado	postgres	Entregado exitosamente - Firmado por cliente	2025-11-21 21:39:47.016225
3	1	\N	completado	postgres	Estado inicial del pedido (migración histórica)	2025-11-06 21:33:08.671877
4	2	\N	completado	postgres	Estado inicial del pedido (migración histórica)	2025-11-06 21:33:08.671877
5	3	\N	pagado	postgres	Estado inicial del pedido (migración histórica)	2025-11-06 21:33:08.671877
6	5	\N	completado	postgres	Estado inicial del pedido (migración histórica)	2025-11-06 21:33:08.671877
7	7	\N	completado	postgres	Estado inicial del pedido (migración histórica)	2025-11-10 20:32:53.781194
8	8	\N	completado	postgres	Estado inicial del pedido (migración histórica)	2025-11-10 21:52:49.690983
9	9	\N	completado	postgres	Estado inicial del pedido (migración histórica)	2025-11-10 22:00:25.632035
10	10	\N	completado	postgres	Estado inicial del pedido (migración histórica)	2025-11-10 22:04:15.772148
11	11	\N	completado	postgres	Estado inicial del pedido (migración histórica)	2025-11-10 22:22:46.814692
12	12	\N	cancelado	postgres	Estado inicial del pedido (migración histórica)	2025-11-11 19:21:40.759285
13	13	\N	completado	postgres	Estado inicial del pedido (migración histórica)	2025-11-11 19:28:14.306438
14	14	\N	enviado	postgres	Estado inicial del pedido (migración histórica)	2025-11-11 20:05:23.049969
15	15	\N	completado	postgres	Estado inicial del pedido (migración histórica)	2025-11-11 21:15:43.464898
16	16	\N	cancelado	postgres	Estado inicial del pedido (migración histórica)	2025-11-11 21:24:53.508485
17	17	\N	cancelado	postgres	Estado inicial del pedido (migración histórica)	2025-11-11 21:26:04.181774
18	18	\N	cancelado	postgres	Estado inicial del pedido (migración histórica)	2025-11-11 21:27:52.121011
19	19	\N	cancelado	postgres	Estado inicial del pedido (migración histórica)	2025-11-11 21:45:08.800919
20	20	\N	cancelado	postgres	Estado inicial del pedido (migración histórica)	2025-11-11 22:00:38.645116
21	22	\N	completado	postgres	Estado inicial del pedido (migración histórica)	2025-11-13 12:04:07.805756
22	23	\N	pendiente	postgres	Pedido creado	2025-12-01 17:12:06.572356
23	23	pendiente	pagado	postgres	Pago confirmado	2025-12-01 17:13:29.486767
24	24	\N	pendiente	postgres	Pedido creado	2025-12-01 17:34:34.919918
25	24	pendiente	pagado	postgres	Pago confirmado	2025-12-01 17:35:01.688097
26	25	\N	pendiente	postgres	Pedido creado	2025-12-01 19:29:21.440718
27	25	pendiente	pagado	postgres	Pago confirmado	2025-12-01 19:30:01.474389
28	25	pagado	enviado	postgres	Pedido en tránsito	2025-12-01 19:31:04.771339
29	25	enviado	completado	postgres	Pedido entregado	2025-12-01 19:31:28.98987
30	26	\N	pendiente	postgres	Pedido creado	2025-12-05 20:09:41.376378
31	26	pendiente	pagado	postgres	Pago confirmado	2025-12-05 20:10:25.809595
32	26	pagado	enviado	postgres	Pedido en tránsito	2025-12-05 20:11:13.811771
33	26	enviado	completado	postgres	Pedido entregado	2025-12-05 20:11:32.775038
34	27	\N	pendiente	postgres	Pedido creado	2025-12-05 20:19:00.037848
35	27	pendiente	pagado	postgres	Pago confirmado	2025-12-05 20:19:38.474407
36	27	pagado	enviado	postgres	Pedido en tránsito	2025-12-05 20:20:09.343046
37	27	enviado	completado	postgres	Pedido entregado	2025-12-05 20:20:32.783112
\.


--
-- Data for Name: pagos; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.pagos (pago_id, pedido_id, fecha_pago, monto, metodo_pago, estado_pago, id_transaccion_externa, fecha_modificacion) FROM stdin;
1	1	2025-11-06 21:34:02.93935	1800.89	Tarjeta de Crédito	exitoso	txn_1a2b3c4d5e	\N
2	2	2025-11-06 21:34:02.93935	126.41	PayPal	exitoso	pp_6f7g8h9i0j	\N
3	3	2025-11-06 21:34:02.93935	494.50	Tarjeta de Débito	fallido	txn_k1l2m3n4o5	\N
4	3	2025-11-06 21:34:02.93935	494.50	PSE	pendiente	pse_p6q7r8s9t0	\N
5	5	2025-11-06 21:34:02.93935	126.50	Tarjeta de Crédito	exitoso	txn_u1v2w3x4y5	\N
7	7	2025-11-10 20:54:51.627996	57.50	tarjeta_credito	exitoso	qwsa_784785158	\N
8	6	2025-11-10 20:56:19.441322	4254.97	tarjeta_credito	exitoso	7878	\N
15	7	2025-11-10 21:37:19.985173	100.00	Reembolso	reembolsado	REFUND_9	\N
16	3	2025-11-10 21:53:20.223208	494.50	tarjeta_debito	exitoso	olp_89654	\N
17	8	2025-11-10 21:54:03.611545	20.69	tarjeta_credito	exitoso	964885	\N
18	9	2025-11-10 22:00:55.838934	919.43	paypal	exitoso	wdcsd_5188454	\N
19	10	2025-11-10 22:04:48.831581	165.60	paypal	exitoso	korngos_6155884	\N
20	10	2025-11-10 22:07:41.174876	160.00	Reembolso	reembolsado	REFUND_12	\N
21	11	2025-11-10 22:23:19.056591	69.00	paypal	exitoso	kldmfos_584894584	\N
22	11	2025-11-10 22:24:35.229847	120.00	Reembolso	reembolsado	REFUND_13	\N
23	13	2025-11-11 19:28:40.440649	92.00	paypal	exitoso	korngos_6155884	\N
24	13	2025-11-11 19:30:04.901816	160.00	Reembolso	reembolsado	REFUND_15	\N
25	14	2025-11-11 20:06:16.64035	1494.99	paypal	exitoso	89489551	\N
28	15	2025-11-11 21:16:27.703083	82.80	paypal	exitoso	8485181	\N
29	17	2025-11-11 21:26:40.754752	92.00	paypal	exitoso	141815118	\N
30	18	2025-11-11 21:28:29.666143	92.00	paypal	exitoso	5548148141	\N
31	19	2025-11-11 21:47:47.408582	92.00	paypal	exitoso	5187191	\N
32	20	2025-11-11 22:01:03.317628	345.00	paypal	exitoso	414881878	\N
33	1	2025-11-11 22:04:34.292398	1499.99	Reembolso	reembolsado	REFUND_1	\N
34	22	2025-11-13 12:08:19.645391	92.00	paypal	exitoso	65185156iuhu	\N
35	22	2025-11-13 12:11:53.340469	80.00	Reembolso	reembolsado	REFUND_24	\N
36	23	2025-12-01 17:13:29.486767	138.00	tarjeta_debito	exitoso	wdcsd_5188454	\N
37	24	2025-12-01 17:35:01.688097	138.00	transferencia	exitoso	54155616	\N
38	25	2025-12-01 19:30:01.474389	138.00	paypal	exitoso	865545	\N
39	25	2025-12-01 19:32:44.269528	240.00	Reembolso	reembolsado	REFUND_27	\N
40	26	2025-12-05 20:10:25.809595	115.00	paypal	exitoso	7587257	\N
41	26	2025-12-05 20:12:08.055992	100.00	Reembolso	reembolsado	REFUND_28	\N
42	27	2025-12-05 20:19:38.474407	20.69	paypal	exitoso	loulou	\N
43	27	2025-12-05 20:21:11.47658	19.99	Reembolso	reembolsado	REFUND_29	\N
\.


--
-- Data for Name: pedidos; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.pedidos (pedido_id, cliente_id, direccion_envio_id, cupon_id, fecha_pedido, estado_pedido, subtotal, descuento_aplicado, impuestos, total_pedido, fecha_modificacion) FROM stdin;
12	14	17	5	2025-11-11 19:21:40.759285	cancelado	160.00	160.00	0.00	0.00	2025-11-11 21:52:48.052943
5	4	5	\N	2025-11-06 21:33:08.671877	completado	110.00	0.00	16.50	126.50	2025-11-06 21:33:59.48322
2	2	3	\N	2025-11-06 21:33:08.671877	completado	109.92	0.00	16.49	126.41	2025-11-10 18:25:30.38128
1	1	1	1	2025-11-06 21:33:08.671877	completado	1739.99	174.00	234.90	1800.89	2025-11-10 18:27:59.46037
20	5	6	\N	2025-11-11 22:00:38.645116	cancelado	300.00	0.00	45.00	345.00	2025-11-11 22:01:48.206223
7	11	14	3	2025-11-10 20:32:53.781194	completado	100.00	50.00	7.50	57.50	2025-11-10 20:58:47.797158
3	3	4	2	2025-11-06 21:33:08.671877	pagado	450.00	20.00	64.50	494.50	2025-11-10 21:53:20.223208
8	11	14	1	2025-11-10 21:52:49.690983	completado	19.99	2.00	2.70	20.69	2025-11-10 21:55:13.997383
22	14	17	\N	2025-11-13 12:04:07.805756	completado	80.00	0.00	12.00	92.00	2025-11-13 12:11:19.487788
9	12	15	\N	2025-11-10 22:00:25.632035	completado	799.50	0.00	119.93	919.43	2025-11-10 22:01:32.553205
6	11	14	5	2025-11-10 20:26:37.295097	completado	3899.97	200.00	555.00	4254.97	2025-11-21 21:39:47.016225
10	13	16	1	2025-11-10 22:04:15.772148	completado	160.00	16.00	21.60	165.60	2025-11-10 22:05:43.764932
23	12	15	\N	2025-12-01 17:12:06.572356	pagado	120.00	0.00	18.00	138.00	2025-12-01 17:13:29.486767
11	14	17	3	2025-11-10 22:22:46.814692	completado	120.00	60.00	9.00	69.00	2025-11-10 22:24:00.345162
24	15	18	\N	2025-12-01 17:34:34.919918	pagado	120.00	0.00	18.00	138.00	2025-12-01 17:35:01.688097
13	14	17	3	2025-11-11 19:28:14.306438	completado	160.00	80.00	12.00	92.00	2025-11-11 19:29:27.260354
14	12	15	\N	2025-11-11 20:05:23.049969	enviado	1299.99	0.00	195.00	1494.99	2025-11-11 20:07:09.834443
25	10	11	3	2025-12-01 19:29:21.440718	completado	240.00	120.00	18.00	138.00	2025-12-01 19:31:28.98987
15	4	5	1	2025-11-11 21:15:43.464898	completado	80.00	8.00	10.80	82.80	2025-11-11 21:23:23.311305
16	5	6	\N	2025-11-11 21:24:53.508485	cancelado	80.00	0.00	12.00	92.00	2025-11-11 21:25:31.73841
26	2	3	\N	2025-12-05 20:09:41.376378	completado	100.00	0.00	15.00	115.00	2025-12-05 20:11:32.775038
17	5	6	\N	2025-11-11 21:26:04.181774	cancelado	80.00	0.00	12.00	92.00	2025-11-11 21:27:09.850255
18	7	8	\N	2025-11-11 21:27:52.121011	cancelado	80.00	0.00	12.00	92.00	2025-11-11 21:44:39.892689
19	6	7	\N	2025-11-11 21:45:08.800919	cancelado	80.00	0.00	12.00	92.00	2025-11-11 21:48:01.89198
27	3	12	1	2025-12-05 20:19:00.037848	completado	19.99	2.00	2.70	20.69	2025-12-05 20:20:32.783112
\.


--
-- Data for Name: productos; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.productos (producto_id, categoria_id, nombre_producto, descripcion_larga, estado, fecha_creacion, fecha_modificacion) FROM stdin;
2	1	Smartphone X100	Teléfono inteligente con cámara de 108MP y pantalla OLED.	activo	2025-11-06 21:32:55.776688	\N
3	1	Auriculares Inalámbricos TWS	Auriculares con cancelación de ruido activa.	activo	2025-11-06 21:32:55.776688	\N
4	2	Camiseta de Algodón	Camiseta básica de algodón pima.	activo	2025-11-06 21:32:55.776688	\N
5	2	Jeans Slim Fit	Pantalones vaqueros de corte moderno.	activo	2025-11-06 21:32:55.776688	\N
6	3	Cafetera Espresso Automática	Prepara café profesional en casa.	activo	2025-11-06 21:32:55.776688	\N
7	3	Sofá Cama 3 Plazas	Sofá convertible en cama, tela gris.	activo	2025-11-06 21:32:55.776688	\N
9	5	Balón de Fútbol Profesional	Balón tamaño 5, certificado por FIFA.	activo	2025-11-06 21:32:55.776688	\N
10	5	Zapatillas de Running	Zapatillas ligeras para correr largas distancias.	activo	2025-11-06 21:32:55.776688	2025-11-11 19:43:08.605956
1	1	Laptop Pro 15"	Laptop de alto rendimiento con 16GB RAM y SSD 1TB.	activo	2025-11-06 21:32:55.776688	\N
11	3	Tetera de Cerámica 1.2L	Tetera de cerámica esmaltada con filtro, apta para inducción.	activo	2025-12-01 19:26:59.900897	2026-07-25 22:20:12.342947
12	7	Sopa Instantánea Ramen (Pack x5)	Pack de 5 sopas ramen estilo japonés, listas en 3 minutos.	activo	2025-12-01 19:57:07.955546	2026-07-25 22:20:12.342947
13	7	Kit para Preparar Sushi	Kit completo con esterilla, palillos y molde para sushi casero.	activo	2025-12-01 20:00:24.875073	2026-07-25 22:20:12.342947
\.


--
-- Data for Name: stock; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.stock (stock_id, producto_id, sku, precio_unitario, cantidad_en_stock, cantidad_reservada, estado, fecha_creacion, fecha_modificacion) FROM stdin;
5	4	CAM-ALG-AZL-M	19.99	100	0	activo	2025-11-06 21:33:04.911523	\N
6	4	CAM-ALG-BLC-L	19.99	80	0	activo	2025-11-06 21:33:04.911523	\N
7	5	JEAN-SLIM-32	49.95	60	0	activo	2025-11-06 21:33:04.911523	\N
8	5	JEAN-SLIM-34	49.95	60	0	activo	2025-11-06 21:33:04.911523	\N
14	10	ZAP-RUN-AZ-43	80.00	40	0	activo	2025-11-06 21:33:04.911523	2025-11-11 19:47:42.061654
10	7	SOFA-CAMA-GRIS	420.00	10	0	activo	2025-11-06 21:33:04.911523	2025-11-10 12:47:05.869601
12	9	BALON-FUT-PRO	160.00	31	0	activo	2025-11-06 21:33:04.911523	2025-11-11 21:52:48.052943
15	1	LAP-PRO-15-512GB	1299.99	20	0	activo	2025-11-06 21:33:04.911523	2025-11-11 22:16:43.787425
2	2	SMART-X100-BLK	799.50	40	0	activo	2025-11-06 21:33:04.911523	2025-11-11 22:16:43.845305
13	10	ZAP-RUN-AZ-42	80.00	90	0	activo	2025-11-06 21:33:04.911523	2025-11-13 12:11:53.340469
1	1	LAP-PRO-15-1TB	1499.99	15	0	activo	2025-11-06 21:33:04.911523	\N
3	3	TWS-NOISE-WHT	120.00	34	2	activo	2025-11-06 21:33:04.911523	2025-12-01 19:32:44.269528
16	6	Express	100.00	11	0	activo	2025-11-09 00:55:08.969144	2025-12-05 20:12:08.055992
4	4	CAM-ALG-BLC-M	19.99	100	0	activo	2025-11-06 21:33:04.911523	2025-12-05 20:21:11.47658
18	11	TET-CER-12L	100.00	10	0	activo	2025-12-01 19:45:47.304812	2026-07-25 22:20:12.342947
19	12	RAM-PACK5	100.00	100	0	activo	2025-12-01 19:59:38.695488	2026-07-25 22:20:12.342947
20	13	SUSHI-KIT-01	100.00	20	0	activo	2025-12-01 20:00:56.578393	2026-07-25 22:20:12.342947
\.


--
-- Name: auditoria_auditoria_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.auditoria_auditoria_id_seq', 82, true);


--
-- Name: categorias_categoria_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.categorias_categoria_id_seq', 8, true);


--
-- Name: clientes_cliente_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.clientes_cliente_id_seq', 15, true);


--
-- Name: cupones_cupon_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.cupones_cupon_id_seq', 6, true);


--
-- Name: detalle_pedido_detalle_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.detalle_pedido_detalle_id_seq', 30, true);


--
-- Name: devoluciones_devolucion_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.devoluciones_devolucion_id_seq', 18, true);


--
-- Name: direcciones_direccion_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.direcciones_direccion_id_seq', 18, true);


--
-- Name: envios_envio_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.envios_envio_id_seq', 24, true);


--
-- Name: historial_estados_historial_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.historial_estados_historial_id_seq', 39, true);


--
-- Name: pagos_pago_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.pagos_pago_id_seq', 44, true);


--
-- Name: pedidos_pedido_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.pedidos_pedido_id_seq', 28, true);


--
-- Name: productos_producto_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.productos_producto_id_seq', 14, true);


--
-- Name: stock_stock_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.stock_stock_id_seq', 20, true);


--
-- Name: auditoria auditoria_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditoria
    ADD CONSTRAINT auditoria_pkey PRIMARY KEY (auditoria_id);


--
-- Name: categorias categorias_nombre_categoria_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categorias
    ADD CONSTRAINT categorias_nombre_categoria_key UNIQUE (nombre_categoria);


--
-- Name: categorias categorias_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categorias
    ADD CONSTRAINT categorias_pkey PRIMARY KEY (categoria_id);


--
-- Name: clientes clientes_email_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes
    ADD CONSTRAINT clientes_email_key UNIQUE (email);


--
-- Name: clientes clientes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes
    ADD CONSTRAINT clientes_pkey PRIMARY KEY (cliente_id);


--
-- Name: cupones cupones_codigo_cupon_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cupones
    ADD CONSTRAINT cupones_codigo_cupon_key UNIQUE (codigo_cupon);


--
-- Name: cupones cupones_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cupones
    ADD CONSTRAINT cupones_pkey PRIMARY KEY (cupon_id);


--
-- Name: detalle_pedido detalle_pedido_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.detalle_pedido
    ADD CONSTRAINT detalle_pedido_pkey PRIMARY KEY (detalle_id);


--
-- Name: devoluciones devoluciones_detalle_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.devoluciones
    ADD CONSTRAINT devoluciones_detalle_id_key UNIQUE (detalle_id);


--
-- Name: devoluciones devoluciones_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.devoluciones
    ADD CONSTRAINT devoluciones_pkey PRIMARY KEY (devolucion_id);


--
-- Name: direcciones direcciones_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.direcciones
    ADD CONSTRAINT direcciones_pkey PRIMARY KEY (direccion_id);


--
-- Name: envios envios_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.envios
    ADD CONSTRAINT envios_pkey PRIMARY KEY (envio_id);


--
-- Name: historial_estados historial_estados_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.historial_estados
    ADD CONSTRAINT historial_estados_pkey PRIMARY KEY (historial_id);


--
-- Name: pagos pagos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pagos
    ADD CONSTRAINT pagos_pkey PRIMARY KEY (pago_id);


--
-- Name: pedidos pedidos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pedidos
    ADD CONSTRAINT pedidos_pkey PRIMARY KEY (pedido_id);


--
-- Name: productos productos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.productos
    ADD CONSTRAINT productos_pkey PRIMARY KEY (producto_id);


--
-- Name: stock stock_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stock
    ADD CONSTRAINT stock_pkey PRIMARY KEY (stock_id);


--
-- Name: stock stock_sku_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stock
    ADD CONSTRAINT stock_sku_key UNIQUE (sku);


--
-- Name: idx_auditoria_fecha; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_auditoria_fecha ON public.auditoria USING btree (fecha);


--
-- Name: idx_auditoria_registro; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_auditoria_registro ON public.auditoria USING btree (registro_id);


--
-- Name: idx_auditoria_tabla; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_auditoria_tabla ON public.auditoria USING btree (tabla);


--
-- Name: idx_auditoria_usuario; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_auditoria_usuario ON public.auditoria USING btree (usuario);


--
-- Name: idx_cupones_codigo; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_cupones_codigo ON public.cupones USING btree (codigo_cupon);


--
-- Name: idx_detalle_pedido_pedido_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_detalle_pedido_pedido_id ON public.detalle_pedido USING btree (pedido_id);


--
-- Name: idx_detalle_pedido_stock; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_detalle_pedido_stock ON public.detalle_pedido USING btree (stock_id);


--
-- Name: idx_devoluciones_detalle; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_devoluciones_detalle ON public.devoluciones USING btree (detalle_id);


--
-- Name: idx_direcciones_cliente; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_direcciones_cliente ON public.direcciones USING btree (cliente_id);


--
-- Name: idx_envios_estado; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_envios_estado ON public.envios USING btree (estado_envio);


--
-- Name: idx_envios_numero_tracking; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_envios_numero_tracking ON public.envios USING btree (numero_tracking);


--
-- Name: idx_envios_pedido; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_envios_pedido ON public.envios USING btree (pedido_id);


--
-- Name: idx_historial_estados_fecha; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_historial_estados_fecha ON public.historial_estados USING btree (fecha_cambio DESC);


--
-- Name: idx_historial_estados_pedido; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_historial_estados_pedido ON public.historial_estados USING btree (pedido_id, fecha_cambio DESC);


--
-- Name: idx_mv_clientes_vip_categoria; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_mv_clientes_vip_categoria ON public.mv_clientes_vip USING btree (categoria_vip);


--
-- Name: idx_mv_clientes_vip_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_mv_clientes_vip_id ON public.mv_clientes_vip USING btree (cliente_id);


--
-- Name: idx_mv_productos_top_ventas_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_mv_productos_top_ventas_id ON public.mv_productos_top_ventas USING btree (producto_id);


--
-- Name: idx_pagos_id_transaccion_externa; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pagos_id_transaccion_externa ON public.pagos USING btree (id_transaccion_externa);


--
-- Name: idx_pagos_pedido_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pagos_pedido_id ON public.pagos USING btree (pedido_id);


--
-- Name: idx_pedidos_cliente_estado; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pedidos_cliente_estado ON public.pedidos USING btree (cliente_id, estado_pedido);


--
-- Name: idx_pedidos_cliente_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pedidos_cliente_id ON public.pedidos USING btree (cliente_id);


--
-- Name: idx_pedidos_estado; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pedidos_estado ON public.pedidos USING btree (estado_pedido);


--
-- Name: idx_pedidos_fecha; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pedidos_fecha ON public.pedidos USING btree (fecha_pedido);


--
-- Name: idx_pedidos_fecha_estado; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pedidos_fecha_estado ON public.pedidos USING btree (fecha_pedido, estado_pedido);


--
-- Name: idx_productos_categoria; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_productos_categoria ON public.productos USING btree (categoria_id) WHERE ((estado)::text = 'activo'::text);


--
-- Name: idx_productos_nombre; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_productos_nombre ON public.productos USING btree (nombre_producto);


--
-- Name: idx_stock_estado; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_stock_estado ON public.stock USING btree (estado);


--
-- Name: idx_stock_producto_estado; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_stock_producto_estado ON public.stock USING btree (producto_id, estado);


--
-- Name: idx_stock_producto_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_stock_producto_id ON public.stock USING btree (producto_id);


--
-- Name: idx_stock_sku; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_stock_sku ON public.stock USING btree (sku);


--
-- Name: categorias trg_auditoria_categorias; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_auditoria_categorias AFTER INSERT OR DELETE OR UPDATE ON public.categorias FOR EACH ROW EXECUTE FUNCTION public.fn_auditoria_categorias();


--
-- Name: clientes trg_auditoria_clientes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_auditoria_clientes AFTER INSERT OR DELETE OR UPDATE ON public.clientes FOR EACH ROW EXECUTE FUNCTION public.fn_auditoria_clientes();


--
-- Name: cupones trg_auditoria_cupones; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_auditoria_cupones AFTER INSERT OR DELETE OR UPDATE ON public.cupones FOR EACH ROW EXECUTE FUNCTION public.fn_auditoria_cupones();


--
-- Name: pagos trg_auditoria_pagos; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_auditoria_pagos AFTER INSERT OR DELETE OR UPDATE ON public.pagos FOR EACH ROW EXECUTE FUNCTION public.fn_auditoria_pagos();


--
-- Name: pedidos trg_auditoria_pedidos; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_auditoria_pedidos AFTER INSERT OR DELETE OR UPDATE ON public.pedidos FOR EACH ROW EXECUTE FUNCTION public.fn_auditoria_pedidos();


--
-- Name: productos trg_auditoria_productos; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_auditoria_productos AFTER INSERT OR DELETE OR UPDATE ON public.productos FOR EACH ROW EXECUTE FUNCTION public.fn_auditoria_productos();


--
-- Name: stock trg_auditoria_stock; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_auditoria_stock AFTER INSERT OR DELETE OR UPDATE ON public.stock FOR EACH ROW EXECUTE FUNCTION public.fn_auditoria_stock();


--
-- Name: categorias trg_categorias_modificacion; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_categorias_modificacion BEFORE UPDATE ON public.categorias FOR EACH ROW EXECUTE FUNCTION public.fn_actualizar_fecha_modificacion();


--
-- Name: clientes trg_clientes_modificacion; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_clientes_modificacion BEFORE UPDATE ON public.clientes FOR EACH ROW EXECUTE FUNCTION public.fn_actualizar_fecha_modificacion();


--
-- Name: cupones trg_cupones_modificacion; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_cupones_modificacion BEFORE UPDATE ON public.cupones FOR EACH ROW EXECUTE FUNCTION public.fn_actualizar_fecha_modificacion();


--
-- Name: devoluciones trg_devoluciones_modificacion; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_devoluciones_modificacion BEFORE UPDATE ON public.devoluciones FOR EACH ROW EXECUTE FUNCTION public.fn_actualizar_fecha_modificacion();


--
-- Name: direcciones trg_direcciones_modificacion; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_direcciones_modificacion BEFORE UPDATE ON public.direcciones FOR EACH ROW EXECUTE FUNCTION public.fn_actualizar_fecha_modificacion();


--
-- Name: envios trg_envios_modificacion; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_envios_modificacion BEFORE UPDATE ON public.envios FOR EACH ROW EXECUTE FUNCTION public.fn_actualizar_fecha_modificacion();


--
-- Name: pagos trg_pagos_modificacion; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_pagos_modificacion BEFORE UPDATE ON public.pagos FOR EACH ROW EXECUTE FUNCTION public.fn_actualizar_fecha_modificacion();


--
-- Name: pedidos trg_pedidos_modificacion; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_pedidos_modificacion BEFORE UPDATE ON public.pedidos FOR EACH ROW EXECUTE FUNCTION public.fn_actualizar_fecha_modificacion();


--
-- Name: productos trg_productos_modificacion; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_productos_modificacion BEFORE UPDATE ON public.productos FOR EACH ROW EXECUTE FUNCTION public.fn_actualizar_fecha_modificacion();


--
-- Name: pedidos trg_registrar_cambio_estado_pedido; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_registrar_cambio_estado_pedido AFTER INSERT OR UPDATE OF estado_pedido ON public.pedidos FOR EACH ROW EXECUTE FUNCTION public.fn_registrar_cambio_estado();


--
-- Name: TRIGGER trg_registrar_cambio_estado_pedido ON pedidos; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TRIGGER trg_registrar_cambio_estado_pedido ON public.pedidos IS 'Registra automáticamente cambios de estado en historial_estados para timeline visual.';


--
-- Name: stock trg_stock_modificacion; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_stock_modificacion BEFORE UPDATE ON public.stock FOR EACH ROW EXECUTE FUNCTION public.fn_actualizar_fecha_modificacion();


--
-- Name: detalle_pedido detalle_pedido_pedido_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.detalle_pedido
    ADD CONSTRAINT detalle_pedido_pedido_id_fkey FOREIGN KEY (pedido_id) REFERENCES public.pedidos(pedido_id) ON DELETE CASCADE;


--
-- Name: detalle_pedido detalle_pedido_stock_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.detalle_pedido
    ADD CONSTRAINT detalle_pedido_stock_id_fkey FOREIGN KEY (stock_id) REFERENCES public.stock(stock_id);


--
-- Name: devoluciones devoluciones_detalle_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.devoluciones
    ADD CONSTRAINT devoluciones_detalle_id_fkey FOREIGN KEY (detalle_id) REFERENCES public.detalle_pedido(detalle_id);


--
-- Name: direcciones direcciones_cliente_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.direcciones
    ADD CONSTRAINT direcciones_cliente_id_fkey FOREIGN KEY (cliente_id) REFERENCES public.clientes(cliente_id) ON DELETE CASCADE;


--
-- Name: envios envios_pedido_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.envios
    ADD CONSTRAINT envios_pedido_id_fkey FOREIGN KEY (pedido_id) REFERENCES public.pedidos(pedido_id);


--
-- Name: historial_estados historial_estados_pedido_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.historial_estados
    ADD CONSTRAINT historial_estados_pedido_id_fkey FOREIGN KEY (pedido_id) REFERENCES public.pedidos(pedido_id) ON DELETE CASCADE;


--
-- Name: pagos pagos_pedido_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pagos
    ADD CONSTRAINT pagos_pedido_id_fkey FOREIGN KEY (pedido_id) REFERENCES public.pedidos(pedido_id);


--
-- Name: pedidos pedidos_cliente_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pedidos
    ADD CONSTRAINT pedidos_cliente_id_fkey FOREIGN KEY (cliente_id) REFERENCES public.clientes(cliente_id);


--
-- Name: pedidos pedidos_cupon_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pedidos
    ADD CONSTRAINT pedidos_cupon_id_fkey FOREIGN KEY (cupon_id) REFERENCES public.cupones(cupon_id);


--
-- Name: pedidos pedidos_direccion_envio_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pedidos
    ADD CONSTRAINT pedidos_direccion_envio_id_fkey FOREIGN KEY (direccion_envio_id) REFERENCES public.direcciones(direccion_id);


--
-- Name: productos productos_categoria_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.productos
    ADD CONSTRAINT productos_categoria_id_fkey FOREIGN KEY (categoria_id) REFERENCES public.categorias(categoria_id);


--
-- Name: stock stock_producto_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stock
    ADD CONSTRAINT stock_producto_id_fkey FOREIGN KEY (producto_id) REFERENCES public.productos(producto_id);


--
-- Name: mv_clientes_vip; Type: MATERIALIZED VIEW DATA; Schema: public; Owner: -
--

REFRESH MATERIALIZED VIEW public.mv_clientes_vip;


--
-- Name: mv_productos_top_ventas; Type: MATERIALIZED VIEW DATA; Schema: public; Owner: -
--

REFRESH MATERIALIZED VIEW public.mv_productos_top_ventas;


--
-- PostgreSQL database dump complete
--

\unrestrict EXlVRB9WuFJwEzHj8QKh5UYv1kQSMD37R61tDcNfc7zJnQ62hsGvArtNjTEbZwK

