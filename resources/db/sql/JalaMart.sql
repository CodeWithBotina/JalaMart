--
-- PostgreSQL database dump
--

-- Dumped from database version 16.9
-- Dumped by pg_dump version 17.5

-- Started on 2025-06-17 15:35:27 -05

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 6 (class 2615 OID 17404)
-- Name: auditoria; Type: SCHEMA; Schema: -; Owner: developer
--

CREATE SCHEMA auditoria;


ALTER SCHEMA auditoria OWNER TO developer;

--
-- TOC entry 4774 (class 0 OID 0)
-- Dependencies: 6
-- Name: SCHEMA auditoria; Type: COMMENT; Schema: -; Owner: developer
--

COMMENT ON SCHEMA auditoria IS 'Esquema para auditoría y logs del sistema';


--
-- TOC entry 7 (class 2615 OID 17405)
-- Name: comercial; Type: SCHEMA; Schema: -; Owner: developer
--

CREATE SCHEMA comercial;


ALTER SCHEMA comercial OWNER TO developer;

--
-- TOC entry 4775 (class 0 OID 0)
-- Dependencies: 7
-- Name: SCHEMA comercial; Type: COMMENT; Schema: -; Owner: developer
--

COMMENT ON SCHEMA comercial IS 'Esquema principal con entidades del negocio';


--
-- TOC entry 8 (class 2615 OID 17406)
-- Name: reportes; Type: SCHEMA; Schema: -; Owner: developer
--

CREATE SCHEMA reportes;


ALTER SCHEMA reportes OWNER TO developer;

--
-- TOC entry 4776 (class 0 OID 0)
-- Dependencies: 8
-- Name: SCHEMA reportes; Type: COMMENT; Schema: -; Owner: developer
--

COMMENT ON SCHEMA reportes IS 'Esquema para vistas y funciones de reportes';


--
-- TOC entry 9 (class 2615 OID 17407)
-- Name: seguridad; Type: SCHEMA; Schema: -; Owner: developer
--

CREATE SCHEMA seguridad;


ALTER SCHEMA seguridad OWNER TO developer;

--
-- TOC entry 4777 (class 0 OID 0)
-- Dependencies: 9
-- Name: SCHEMA seguridad; Type: COMMENT; Schema: -; Owner: developer
--

COMMENT ON SCHEMA seguridad IS 'Esquema para gestión de usuarios y permisos';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 220 (class 1259 OID 17409)
-- Name: categoria; Type: TABLE; Schema: comercial; Owner: developer
--

CREATE TABLE comercial.categoria (
    id_categoria integer NOT NULL,
    nombre character varying(100) NOT NULL,
    descripcion text,
    slug character varying(100) NOT NULL,
    imagen_url character varying(255),
    activa boolean DEFAULT true,
    fecha_creacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE comercial.categoria OWNER TO developer;

--
-- TOC entry 224 (class 1259 OID 17436)
-- Name: producto; Type: TABLE; Schema: comercial; Owner: developer
--

CREATE TABLE comercial.producto (
    id_producto integer NOT NULL,
    nombre character varying(100) NOT NULL,
    descripcion text,
    precio numeric(10,2) NOT NULL,
    precio_descuento numeric(10,2),
    id_categoria integer NOT NULL,
    id_proveedor integer NOT NULL,
    stock integer DEFAULT 0,
    sku character varying(50),
    imagen_url character varying(255),
    valoracion_promedio numeric(2,1) DEFAULT 0,
    activo boolean DEFAULT true,
    fecha_creacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT producto_precio_check CHECK ((precio > (0)::numeric)),
    CONSTRAINT producto_stock_check CHECK ((stock >= 0)),
    CONSTRAINT producto_valoracion_promedio_check CHECK (((valoracion_promedio >= (0)::numeric) AND (valoracion_promedio <= (5)::numeric)))
);


ALTER TABLE comercial.producto OWNER TO developer;

--
-- TOC entry 222 (class 1259 OID 17422)
-- Name: proveedor; Type: TABLE; Schema: comercial; Owner: developer
--

CREATE TABLE comercial.proveedor (
    id_proveedor integer NOT NULL,
    nombre character varying(100) NOT NULL,
    email character varying(100),
    telefono character varying(20),
    direccion text,
    fecha_registro timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    activo boolean DEFAULT true,
    CONSTRAINT proveedor_email_check CHECK (((email)::text ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'::text))
);


ALTER TABLE comercial.proveedor OWNER TO developer;

--
-- TOC entry 263 (class 1259 OID 25610)
-- Name: busqueda_productos; Type: VIEW; Schema: reportes; Owner: developer
--

CREATE VIEW reportes.busqueda_productos AS
 SELECT p.id_producto,
    p.nombre,
    p.descripcion,
    p.precio,
    p.precio_descuento,
    p.imagen_url,
    c.nombre AS categoria,
    pr.nombre AS proveedor,
    p.valoracion_promedio
   FROM ((comercial.producto p
     JOIN comercial.categoria c ON ((p.id_categoria = c.id_categoria)))
     JOIN comercial.proveedor pr ON ((p.id_proveedor = pr.id_proveedor)))
  WHERE (p.activo = true);


ALTER VIEW reportes.busqueda_productos OWNER TO developer;

--
-- TOC entry 264 (class 1255 OID 25623)
-- Name: buscar_productos(text); Type: FUNCTION; Schema: comercial; Owner: developer
--

CREATE FUNCTION comercial.buscar_productos(termino_busqueda text) RETURNS SETOF reportes.busqueda_productos
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT * FROM reportes.busqueda_productos
    WHERE LOWER(nombre) LIKE LOWER('%' || termino_busqueda || '%')
    OR to_tsvector('spanish', nombre || ' ' || descripcion) @@ to_tsquery('spanish', termino_busqueda)
    ORDER BY nombre;
END;
$$;


ALTER FUNCTION comercial.buscar_productos(termino_busqueda text) OWNER TO developer;

--
-- TOC entry 265 (class 1255 OID 25624)
-- Name: obtener_carrito(integer); Type: FUNCTION; Schema: comercial; Owner: developer
--

CREATE FUNCTION comercial.obtener_carrito(id_usuario_input integer) RETURNS TABLE(id_item integer, id_producto integer, nombre_producto character varying, precio_unitario numeric, cantidad integer, precio_total numeric, imagen_url character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ci.id_item,
        p.id_producto,
        p.nombre AS nombre_producto,
        ci.precio_unitario,
        ci.cantidad,
        (ci.precio_unitario * ci.cantidad) AS precio_total,
        p.imagen_url
    FROM 
        seguridad.usuario u
    JOIN 
        comercial.cliente cl ON u.id_cliente = cl.id_cliente
    JOIN 
        comercial.carrito c ON cl.id_cliente = c.id_cliente
    JOIN 
        comercial.carrito_item ci ON c.id_carrito = ci.id_carrito
    JOIN 
        comercial.producto p ON ci.id_producto = p.id_producto
    WHERE 
        u.id_usuario = id_usuario_input
        AND c.activo = true;
END;
$$;


ALTER FUNCTION comercial.obtener_carrito(id_usuario_input integer) OWNER TO developer;

--
-- TOC entry 266 (class 1255 OID 25625)
-- Name: obtener_detalle_producto(integer); Type: FUNCTION; Schema: comercial; Owner: developer
--

CREATE FUNCTION comercial.obtener_detalle_producto(id_producto_input integer) RETURNS TABLE(id_producto integer, nombre character varying, descripcion text, precio numeric, precio_descuento numeric, imagen_url character varying, categoria character varying, proveedor character varying, valoracion_promedio numeric, stock integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id_producto,
        p.nombre,
        p.descripcion,
        p.precio,
        p.precio_descuento,
        p.imagen_url,
        c.nombre AS categoria,
        pr.nombre AS proveedor,
        p.valoracion_promedio,
        p.stock
    FROM 
        comercial.producto p
    JOIN 
        comercial.categoria c ON p.id_categoria = c.id_categoria
    JOIN 
        comercial.proveedor pr ON p.id_proveedor = pr.id_proveedor
    WHERE 
        p.id_producto = id_producto_input
        AND p.activo = true;
END;
$$;


ALTER FUNCTION comercial.obtener_detalle_producto(id_producto_input integer) OWNER TO developer;

--
-- TOC entry 254 (class 1259 OID 17737)
-- Name: historial_precios; Type: TABLE; Schema: auditoria; Owner: developer
--

CREATE TABLE auditoria.historial_precios (
    id_historial integer NOT NULL,
    id_producto integer NOT NULL,
    precio_anterior numeric(10,2),
    precio_nuevo numeric(10,2) NOT NULL,
    fecha_cambio timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    id_usuario integer,
    motivo text
);


ALTER TABLE auditoria.historial_precios OWNER TO developer;

--
-- TOC entry 253 (class 1259 OID 17736)
-- Name: historial_precios_id_historial_seq; Type: SEQUENCE; Schema: auditoria; Owner: developer
--

CREATE SEQUENCE auditoria.historial_precios_id_historial_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE auditoria.historial_precios_id_historial_seq OWNER TO developer;

--
-- TOC entry 4778 (class 0 OID 0)
-- Dependencies: 253
-- Name: historial_precios_id_historial_seq; Type: SEQUENCE OWNED BY; Schema: auditoria; Owner: developer
--

ALTER SEQUENCE auditoria.historial_precios_id_historial_seq OWNED BY auditoria.historial_precios.id_historial;


--
-- TOC entry 256 (class 1259 OID 17757)
-- Name: log_actividad; Type: TABLE; Schema: auditoria; Owner: developer
--

CREATE TABLE auditoria.log_actividad (
    id_log integer NOT NULL,
    tabla_afectada character varying(100) NOT NULL,
    operacion character varying(10) NOT NULL,
    id_registro integer,
    id_usuario integer,
    datos_anteriores jsonb,
    datos_nuevos jsonb,
    fecha_operacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    ip_usuario inet,
    CONSTRAINT log_actividad_operacion_check CHECK (((operacion)::text = ANY ((ARRAY['INSERT'::character varying, 'UPDATE'::character varying, 'DELETE'::character varying])::text[])))
);


ALTER TABLE auditoria.log_actividad OWNER TO developer;

--
-- TOC entry 255 (class 1259 OID 17756)
-- Name: log_actividad_id_log_seq; Type: SEQUENCE; Schema: auditoria; Owner: developer
--

CREATE SEQUENCE auditoria.log_actividad_id_log_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE auditoria.log_actividad_id_log_seq OWNER TO developer;

--
-- TOC entry 4779 (class 0 OID 0)
-- Dependencies: 255
-- Name: log_actividad_id_log_seq; Type: SEQUENCE OWNED BY; Schema: auditoria; Owner: developer
--

ALTER SEQUENCE auditoria.log_actividad_id_log_seq OWNED BY auditoria.log_actividad.id_log;


--
-- TOC entry 228 (class 1259 OID 17479)
-- Name: carrito; Type: TABLE; Schema: comercial; Owner: developer
--

CREATE TABLE comercial.carrito (
    id_carrito integer NOT NULL,
    id_cliente integer NOT NULL,
    fecha_creacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    activo boolean DEFAULT true
);


ALTER TABLE comercial.carrito OWNER TO developer;

--
-- TOC entry 227 (class 1259 OID 17478)
-- Name: carrito_id_carrito_seq; Type: SEQUENCE; Schema: comercial; Owner: developer
--

CREATE SEQUENCE comercial.carrito_id_carrito_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE comercial.carrito_id_carrito_seq OWNER TO developer;

--
-- TOC entry 4780 (class 0 OID 0)
-- Dependencies: 227
-- Name: carrito_id_carrito_seq; Type: SEQUENCE OWNED BY; Schema: comercial; Owner: developer
--

ALTER SEQUENCE comercial.carrito_id_carrito_seq OWNED BY comercial.carrito.id_carrito;


--
-- TOC entry 230 (class 1259 OID 17494)
-- Name: carrito_item; Type: TABLE; Schema: comercial; Owner: developer
--

CREATE TABLE comercial.carrito_item (
    id_item integer NOT NULL,
    id_carrito integer NOT NULL,
    id_producto integer NOT NULL,
    cantidad integer NOT NULL,
    precio_unitario numeric(10,2) NOT NULL,
    fecha_agregado timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT carrito_item_cantidad_check CHECK ((cantidad > 0)),
    CONSTRAINT carrito_item_precio_unitario_check CHECK ((precio_unitario > (0)::numeric))
);


ALTER TABLE comercial.carrito_item OWNER TO developer;

--
-- TOC entry 229 (class 1259 OID 17493)
-- Name: carrito_item_id_item_seq; Type: SEQUENCE; Schema: comercial; Owner: developer
--

CREATE SEQUENCE comercial.carrito_item_id_item_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE comercial.carrito_item_id_item_seq OWNER TO developer;

--
-- TOC entry 4781 (class 0 OID 0)
-- Dependencies: 229
-- Name: carrito_item_id_item_seq; Type: SEQUENCE OWNED BY; Schema: comercial; Owner: developer
--

ALTER SEQUENCE comercial.carrito_item_id_item_seq OWNED BY comercial.carrito_item.id_item;


--
-- TOC entry 219 (class 1259 OID 17408)
-- Name: categoria_id_categoria_seq; Type: SEQUENCE; Schema: comercial; Owner: developer
--

CREATE SEQUENCE comercial.categoria_id_categoria_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE comercial.categoria_id_categoria_seq OWNER TO developer;

--
-- TOC entry 4782 (class 0 OID 0)
-- Dependencies: 219
-- Name: categoria_id_categoria_seq; Type: SEQUENCE OWNED BY; Schema: comercial; Owner: developer
--

ALTER SEQUENCE comercial.categoria_id_categoria_seq OWNED BY comercial.categoria.id_categoria;


--
-- TOC entry 226 (class 1259 OID 17465)
-- Name: cliente; Type: TABLE; Schema: comercial; Owner: developer
--

CREATE TABLE comercial.cliente (
    id_cliente integer NOT NULL,
    nombre character varying(100) NOT NULL,
    apellido character varying(100) NOT NULL,
    email character varying(100),
    telefono character varying(20),
    direccion text,
    fecha_registro timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    activo boolean DEFAULT true,
    CONSTRAINT cliente_email_check CHECK (((email)::text ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'::text))
);


ALTER TABLE comercial.cliente OWNER TO developer;

--
-- TOC entry 225 (class 1259 OID 17464)
-- Name: cliente_id_cliente_seq; Type: SEQUENCE; Schema: comercial; Owner: developer
--

CREATE SEQUENCE comercial.cliente_id_cliente_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE comercial.cliente_id_cliente_seq OWNER TO developer;

--
-- TOC entry 4783 (class 0 OID 0)
-- Dependencies: 225
-- Name: cliente_id_cliente_seq; Type: SEQUENCE OWNED BY; Schema: comercial; Owner: developer
--

ALTER SEQUENCE comercial.cliente_id_cliente_seq OWNED BY comercial.cliente.id_cliente;


--
-- TOC entry 242 (class 1259 OID 17616)
-- Name: cupon; Type: TABLE; Schema: comercial; Owner: developer
--

CREATE TABLE comercial.cupon (
    id_cupon integer NOT NULL,
    codigo character varying(50) NOT NULL,
    descuento numeric(5,2) NOT NULL,
    tipo character varying(10) NOT NULL,
    fecha_inicio timestamp without time zone NOT NULL,
    fecha_fin timestamp without time zone NOT NULL,
    usos_maximos integer,
    usos_actuales integer DEFAULT 0,
    minimo_compra numeric(10,2),
    activo boolean DEFAULT true,
    CONSTRAINT cupon_descuento_check CHECK (((descuento > (0)::numeric) AND (descuento <= (100)::numeric))),
    CONSTRAINT cupon_tipo_check CHECK (((tipo)::text = ANY ((ARRAY['Porcentaje'::character varying, 'Fijo'::character varying])::text[])))
);


ALTER TABLE comercial.cupon OWNER TO developer;

--
-- TOC entry 241 (class 1259 OID 17615)
-- Name: cupon_id_cupon_seq; Type: SEQUENCE; Schema: comercial; Owner: developer
--

CREATE SEQUENCE comercial.cupon_id_cupon_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE comercial.cupon_id_cupon_seq OWNER TO developer;

--
-- TOC entry 4784 (class 0 OID 0)
-- Dependencies: 241
-- Name: cupon_id_cupon_seq; Type: SEQUENCE OWNED BY; Schema: comercial; Owner: developer
--

ALTER SEQUENCE comercial.cupon_id_cupon_seq OWNED BY comercial.cupon.id_cupon;


--
-- TOC entry 243 (class 1259 OID 17628)
-- Name: cupon_usado; Type: TABLE; Schema: comercial; Owner: developer
--

CREATE TABLE comercial.cupon_usado (
    id_cupon integer NOT NULL,
    id_cliente integer NOT NULL,
    id_pedido integer NOT NULL,
    fecha_uso timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    descuento_aplicado numeric(10,2) NOT NULL
);


ALTER TABLE comercial.cupon_usado OWNER TO developer;

--
-- TOC entry 240 (class 1259 OID 17600)
-- Name: direccion; Type: TABLE; Schema: comercial; Owner: developer
--

CREATE TABLE comercial.direccion (
    id_direccion integer NOT NULL,
    id_cliente integer NOT NULL,
    calle character varying(255) NOT NULL,
    ciudad character varying(100) NOT NULL,
    estado character varying(100) NOT NULL,
    codigo_postal character varying(20) NOT NULL,
    pais character varying(100) NOT NULL,
    telefono character varying(20),
    principal boolean DEFAULT false,
    etiqueta character varying(50) DEFAULT 'Casa'::character varying
);


ALTER TABLE comercial.direccion OWNER TO developer;

--
-- TOC entry 239 (class 1259 OID 17599)
-- Name: direccion_id_direccion_seq; Type: SEQUENCE; Schema: comercial; Owner: developer
--

CREATE SEQUENCE comercial.direccion_id_direccion_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE comercial.direccion_id_direccion_seq OWNER TO developer;

--
-- TOC entry 4785 (class 0 OID 0)
-- Dependencies: 239
-- Name: direccion_id_direccion_seq; Type: SEQUENCE OWNED BY; Schema: comercial; Owner: developer
--

ALTER SEQUENCE comercial.direccion_id_direccion_seq OWNED BY comercial.direccion.id_direccion;


--
-- TOC entry 244 (class 1259 OID 17649)
-- Name: favorito; Type: TABLE; Schema: comercial; Owner: developer
--

CREATE TABLE comercial.favorito (
    id_cliente integer NOT NULL,
    id_producto integer NOT NULL,
    fecha_agregado timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE comercial.favorito OWNER TO developer;

--
-- TOC entry 236 (class 1259 OID 17558)
-- Name: pago; Type: TABLE; Schema: comercial; Owner: developer
--

CREATE TABLE comercial.pago (
    id_pago integer NOT NULL,
    id_pedido integer NOT NULL,
    monto numeric(12,2) NOT NULL,
    metodo character varying(30) NOT NULL,
    estado character varying(20) DEFAULT 'Pendiente'::character varying NOT NULL,
    fecha_pago timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    transaccion_id character varying(100),
    detalles text,
    CONSTRAINT pago_estado_check CHECK (((estado)::text = ANY ((ARRAY['Pendiente'::character varying, 'Completado'::character varying, 'Fallido'::character varying, 'Reembolsado'::character varying])::text[]))),
    CONSTRAINT pago_monto_check CHECK ((monto > (0)::numeric))
);


ALTER TABLE comercial.pago OWNER TO developer;

--
-- TOC entry 235 (class 1259 OID 17557)
-- Name: pago_id_pago_seq; Type: SEQUENCE; Schema: comercial; Owner: developer
--

CREATE SEQUENCE comercial.pago_id_pago_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE comercial.pago_id_pago_seq OWNER TO developer;

--
-- TOC entry 4786 (class 0 OID 0)
-- Dependencies: 235
-- Name: pago_id_pago_seq; Type: SEQUENCE OWNED BY; Schema: comercial; Owner: developer
--

ALTER SEQUENCE comercial.pago_id_pago_seq OWNED BY comercial.pago.id_pago;


--
-- TOC entry 232 (class 1259 OID 17516)
-- Name: pedido; Type: TABLE; Schema: comercial; Owner: developer
--

CREATE TABLE comercial.pedido (
    id_pedido integer NOT NULL,
    id_cliente integer NOT NULL,
    fecha_pedido timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    fecha_entrega_estimada timestamp without time zone,
    estado character varying(20) DEFAULT 'Pendiente'::character varying NOT NULL,
    total numeric(12,2) NOT NULL,
    subtotal numeric(12,2) NOT NULL,
    impuestos numeric(10,2) DEFAULT 0 NOT NULL,
    metodo_pago character varying(30) NOT NULL,
    direccion_envio text NOT NULL,
    notas text,
    CONSTRAINT pedido_estado_check CHECK (((estado)::text = ANY ((ARRAY['Pendiente'::character varying, 'Procesando'::character varying, 'Enviado'::character varying, 'Entregado'::character varying, 'Cancelado'::character varying])::text[]))),
    CONSTRAINT pedido_metodo_pago_check CHECK (((metodo_pago)::text = ANY ((ARRAY['Tarjeta Crédito'::character varying, 'Tarjeta Débito'::character varying, 'PayPal'::character varying, 'Transferencia'::character varying, 'Efectivo'::character varying])::text[]))),
    CONSTRAINT pedido_subtotal_check CHECK ((subtotal > (0)::numeric)),
    CONSTRAINT pedido_total_check CHECK ((total > (0)::numeric))
);


ALTER TABLE comercial.pedido OWNER TO developer;

--
-- TOC entry 231 (class 1259 OID 17515)
-- Name: pedido_id_pedido_seq; Type: SEQUENCE; Schema: comercial; Owner: developer
--

CREATE SEQUENCE comercial.pedido_id_pedido_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE comercial.pedido_id_pedido_seq OWNER TO developer;

--
-- TOC entry 4787 (class 0 OID 0)
-- Dependencies: 231
-- Name: pedido_id_pedido_seq; Type: SEQUENCE OWNED BY; Schema: comercial; Owner: developer
--

ALTER SEQUENCE comercial.pedido_id_pedido_seq OWNED BY comercial.pedido.id_pedido;


--
-- TOC entry 234 (class 1259 OID 17537)
-- Name: pedido_item; Type: TABLE; Schema: comercial; Owner: developer
--

CREATE TABLE comercial.pedido_item (
    id_item integer NOT NULL,
    id_pedido integer NOT NULL,
    id_producto integer NOT NULL,
    cantidad integer NOT NULL,
    precio_unitario numeric(10,2) NOT NULL,
    descuento numeric(5,2) DEFAULT 0,
    CONSTRAINT pedido_item_cantidad_check CHECK ((cantidad > 0)),
    CONSTRAINT pedido_item_descuento_check CHECK (((descuento >= (0)::numeric) AND (descuento <= (100)::numeric))),
    CONSTRAINT pedido_item_precio_unitario_check CHECK ((precio_unitario > (0)::numeric))
);


ALTER TABLE comercial.pedido_item OWNER TO developer;

--
-- TOC entry 233 (class 1259 OID 17536)
-- Name: pedido_item_id_item_seq; Type: SEQUENCE; Schema: comercial; Owner: developer
--

CREATE SEQUENCE comercial.pedido_item_id_item_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE comercial.pedido_item_id_item_seq OWNER TO developer;

--
-- TOC entry 4788 (class 0 OID 0)
-- Dependencies: 233
-- Name: pedido_item_id_item_seq; Type: SEQUENCE OWNED BY; Schema: comercial; Owner: developer
--

ALTER SEQUENCE comercial.pedido_item_id_item_seq OWNED BY comercial.pedido_item.id_item;


--
-- TOC entry 223 (class 1259 OID 17435)
-- Name: producto_id_producto_seq; Type: SEQUENCE; Schema: comercial; Owner: developer
--

CREATE SEQUENCE comercial.producto_id_producto_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE comercial.producto_id_producto_seq OWNER TO developer;

--
-- TOC entry 4789 (class 0 OID 0)
-- Dependencies: 223
-- Name: producto_id_producto_seq; Type: SEQUENCE OWNED BY; Schema: comercial; Owner: developer
--

ALTER SEQUENCE comercial.producto_id_producto_seq OWNED BY comercial.producto.id_producto;


--
-- TOC entry 221 (class 1259 OID 17421)
-- Name: proveedor_id_proveedor_seq; Type: SEQUENCE; Schema: comercial; Owner: developer
--

CREATE SEQUENCE comercial.proveedor_id_proveedor_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE comercial.proveedor_id_proveedor_seq OWNER TO developer;

--
-- TOC entry 4790 (class 0 OID 0)
-- Dependencies: 221
-- Name: proveedor_id_proveedor_seq; Type: SEQUENCE OWNED BY; Schema: comercial; Owner: developer
--

ALTER SEQUENCE comercial.proveedor_id_proveedor_seq OWNED BY comercial.proveedor.id_proveedor;


--
-- TOC entry 238 (class 1259 OID 17576)
-- Name: resena; Type: TABLE; Schema: comercial; Owner: developer
--

CREATE TABLE comercial.resena (
    id_resena integer NOT NULL,
    id_producto integer NOT NULL,
    id_cliente integer NOT NULL,
    valoracion integer NOT NULL,
    comentario text,
    fecha_creacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    aprobada boolean DEFAULT false,
    CONSTRAINT resena_valoracion_check CHECK (((valoracion >= 1) AND (valoracion <= 5)))
);


ALTER TABLE comercial.resena OWNER TO developer;

--
-- TOC entry 237 (class 1259 OID 17575)
-- Name: resena_id_resena_seq; Type: SEQUENCE; Schema: comercial; Owner: developer
--

CREATE SEQUENCE comercial.resena_id_resena_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE comercial.resena_id_resena_seq OWNER TO developer;

--
-- TOC entry 4791 (class 0 OID 0)
-- Dependencies: 237
-- Name: resena_id_resena_seq; Type: SEQUENCE OWNED BY; Schema: comercial; Owner: developer
--

ALTER SEQUENCE comercial.resena_id_resena_seq OWNED BY comercial.resena.id_resena;


--
-- TOC entry 258 (class 1259 OID 17777)
-- Name: clientes_mas_activos; Type: VIEW; Schema: reportes; Owner: developer
--

CREATE VIEW reportes.clientes_mas_activos AS
SELECT
    NULL::integer AS id_cliente,
    NULL::text AS nombre_completo,
    NULL::character varying(100) AS email,
    NULL::bigint AS total_pedidos,
    NULL::numeric AS total_gastado,
    NULL::timestamp without time zone AS ultimo_pedido;


ALTER VIEW reportes.clientes_mas_activos OWNER TO developer;

--
-- TOC entry 260 (class 1259 OID 25595)
-- Name: mejores_ofertas; Type: VIEW; Schema: reportes; Owner: developer
--

CREATE VIEW reportes.mejores_ofertas AS
 SELECT p.id_producto,
    p.nombre,
    p.precio,
    p.precio_descuento,
    p.imagen_url,
    c.nombre AS categoria,
    round((((p.precio - COALESCE(p.precio_descuento, p.precio)) / p.precio) * (100)::numeric)) AS porcentaje_descuento
   FROM (comercial.producto p
     JOIN comercial.categoria c ON ((p.id_categoria = c.id_categoria)))
  WHERE ((p.precio_descuento IS NOT NULL) AND (p.activo = true))
  ORDER BY (round((((p.precio - COALESCE(p.precio_descuento, p.precio)) / p.precio) * (100)::numeric))) DESC
 LIMIT 10;


ALTER VIEW reportes.mejores_ofertas OWNER TO developer;

--
-- TOC entry 257 (class 1259 OID 17772)
-- Name: productos_mas_vendidos; Type: VIEW; Schema: reportes; Owner: developer
--

CREATE VIEW reportes.productos_mas_vendidos AS
SELECT
    NULL::integer AS id_producto,
    NULL::character varying(100) AS nombre,
    NULL::text AS descripcion,
    NULL::bigint AS veces_vendido,
    NULL::bigint AS cantidad_vendida,
    NULL::numeric AS total_vendido;


ALTER VIEW reportes.productos_mas_vendidos OWNER TO developer;

--
-- TOC entry 262 (class 1259 OID 25605)
-- Name: productos_por_categoria; Type: VIEW; Schema: reportes; Owner: developer
--

CREATE VIEW reportes.productos_por_categoria AS
 SELECT c.id_categoria,
    c.nombre AS categoria,
    c.slug,
    p.id_producto,
    p.nombre AS producto,
    p.precio,
    p.precio_descuento,
    p.imagen_url,
    p.valoracion_promedio,
    p.stock
   FROM (comercial.categoria c
     JOIN comercial.producto p ON ((c.id_categoria = p.id_categoria)))
  WHERE ((p.activo = true) AND (c.activa = true))
  ORDER BY c.nombre, p.nombre;


ALTER VIEW reportes.productos_por_categoria OWNER TO developer;

--
-- TOC entry 261 (class 1259 OID 25600)
-- Name: productos_recientes; Type: VIEW; Schema: reportes; Owner: developer
--

CREATE VIEW reportes.productos_recientes AS
 SELECT DISTINCT ON (p.id_producto) p.id_producto,
    p.nombre,
    p.precio,
    p.imagen_url,
    ci.fecha_agregado
   FROM ((comercial.producto p
     JOIN comercial.carrito_item ci ON ((p.id_producto = ci.id_producto)))
     JOIN comercial.carrito c ON ((ci.id_carrito = c.id_carrito)))
  WHERE (c.activo = false)
  ORDER BY p.id_producto, ci.fecha_agregado DESC;


ALTER VIEW reportes.productos_recientes OWNER TO developer;

--
-- TOC entry 259 (class 1259 OID 17782)
-- Name: ventas_por_categoria; Type: VIEW; Schema: reportes; Owner: developer
--

CREATE VIEW reportes.ventas_por_categoria AS
SELECT
    NULL::integer AS id_categoria,
    NULL::character varying(100) AS categoria,
    NULL::bigint AS total_pedidos,
    NULL::bigint AS total_productos,
    NULL::numeric AS total_ventas;


ALTER VIEW reportes.ventas_por_categoria OWNER TO developer;

--
-- TOC entry 248 (class 1259 OID 17678)
-- Name: permiso; Type: TABLE; Schema: seguridad; Owner: developer
--

CREATE TABLE seguridad.permiso (
    id_permiso integer NOT NULL,
    nombre character varying(100) NOT NULL,
    descripcion text,
    modulo character varying(50) NOT NULL
);


ALTER TABLE seguridad.permiso OWNER TO developer;

--
-- TOC entry 247 (class 1259 OID 17677)
-- Name: permiso_id_permiso_seq; Type: SEQUENCE; Schema: seguridad; Owner: developer
--

CREATE SEQUENCE seguridad.permiso_id_permiso_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE seguridad.permiso_id_permiso_seq OWNER TO developer;

--
-- TOC entry 4792 (class 0 OID 0)
-- Dependencies: 247
-- Name: permiso_id_permiso_seq; Type: SEQUENCE OWNED BY; Schema: seguridad; Owner: developer
--

ALTER SEQUENCE seguridad.permiso_id_permiso_seq OWNED BY seguridad.permiso.id_permiso;


--
-- TOC entry 246 (class 1259 OID 17666)
-- Name: rol; Type: TABLE; Schema: seguridad; Owner: developer
--

CREATE TABLE seguridad.rol (
    id_rol integer NOT NULL,
    nombre character varying(50) NOT NULL,
    descripcion text,
    activo boolean DEFAULT true
);


ALTER TABLE seguridad.rol OWNER TO developer;

--
-- TOC entry 245 (class 1259 OID 17665)
-- Name: rol_id_rol_seq; Type: SEQUENCE; Schema: seguridad; Owner: developer
--

CREATE SEQUENCE seguridad.rol_id_rol_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE seguridad.rol_id_rol_seq OWNER TO developer;

--
-- TOC entry 4793 (class 0 OID 0)
-- Dependencies: 245
-- Name: rol_id_rol_seq; Type: SEQUENCE OWNED BY; Schema: seguridad; Owner: developer
--

ALTER SEQUENCE seguridad.rol_id_rol_seq OWNED BY seguridad.rol.id_rol;


--
-- TOC entry 249 (class 1259 OID 17688)
-- Name: rol_permiso; Type: TABLE; Schema: seguridad; Owner: developer
--

CREATE TABLE seguridad.rol_permiso (
    id_rol integer NOT NULL,
    id_permiso integer NOT NULL
);


ALTER TABLE seguridad.rol_permiso OWNER TO developer;

--
-- TOC entry 251 (class 1259 OID 17704)
-- Name: usuario; Type: TABLE; Schema: seguridad; Owner: developer
--

CREATE TABLE seguridad.usuario (
    id_usuario integer NOT NULL,
    email character varying(100) NOT NULL,
    password_hash character varying(255) NOT NULL,
    id_cliente integer,
    fecha_creacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    ultimo_login timestamp without time zone,
    activo boolean DEFAULT true,
    token_reset character varying(100),
    token_expira timestamp without time zone,
    CONSTRAINT usuario_email_check CHECK (((email)::text ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'::text))
);


ALTER TABLE seguridad.usuario OWNER TO developer;

--
-- TOC entry 250 (class 1259 OID 17703)
-- Name: usuario_id_usuario_seq; Type: SEQUENCE; Schema: seguridad; Owner: developer
--

CREATE SEQUENCE seguridad.usuario_id_usuario_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE seguridad.usuario_id_usuario_seq OWNER TO developer;

--
-- TOC entry 4794 (class 0 OID 0)
-- Dependencies: 250
-- Name: usuario_id_usuario_seq; Type: SEQUENCE OWNED BY; Schema: seguridad; Owner: developer
--

ALTER SEQUENCE seguridad.usuario_id_usuario_seq OWNED BY seguridad.usuario.id_usuario;


--
-- TOC entry 252 (class 1259 OID 17720)
-- Name: usuario_rol; Type: TABLE; Schema: seguridad; Owner: developer
--

CREATE TABLE seguridad.usuario_rol (
    id_usuario integer NOT NULL,
    id_rol integer NOT NULL,
    fecha_asignacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE seguridad.usuario_rol OWNER TO developer;

--
-- TOC entry 4471 (class 2604 OID 17740)
-- Name: historial_precios id_historial; Type: DEFAULT; Schema: auditoria; Owner: developer
--

ALTER TABLE ONLY auditoria.historial_precios ALTER COLUMN id_historial SET DEFAULT nextval('auditoria.historial_precios_id_historial_seq'::regclass);


--
-- TOC entry 4473 (class 2604 OID 17760)
-- Name: log_actividad id_log; Type: DEFAULT; Schema: auditoria; Owner: developer
--

ALTER TABLE ONLY auditoria.log_actividad ALTER COLUMN id_log SET DEFAULT nextval('auditoria.log_actividad_id_log_seq'::regclass);


--
-- TOC entry 4438 (class 2604 OID 17482)
-- Name: carrito id_carrito; Type: DEFAULT; Schema: comercial; Owner: developer
--

ALTER TABLE ONLY comercial.carrito ALTER COLUMN id_carrito SET DEFAULT nextval('comercial.carrito_id_carrito_seq'::regclass);


--
-- TOC entry 4442 (class 2604 OID 17497)
-- Name: carrito_item id_item; Type: DEFAULT; Schema: comercial; Owner: developer
--

ALTER TABLE ONLY comercial.carrito_item ALTER COLUMN id_item SET DEFAULT nextval('comercial.carrito_item_id_item_seq'::regclass);


--
-- TOC entry 4423 (class 2604 OID 17412)
-- Name: categoria id_categoria; Type: DEFAULT; Schema: comercial; Owner: developer
--

ALTER TABLE ONLY comercial.categoria ALTER COLUMN id_categoria SET DEFAULT nextval('comercial.categoria_id_categoria_seq'::regclass);


--
-- TOC entry 4435 (class 2604 OID 17468)
-- Name: cliente id_cliente; Type: DEFAULT; Schema: comercial; Owner: developer
--

ALTER TABLE ONLY comercial.cliente ALTER COLUMN id_cliente SET DEFAULT nextval('comercial.cliente_id_cliente_seq'::regclass);


--
-- TOC entry 4459 (class 2604 OID 17619)
-- Name: cupon id_cupon; Type: DEFAULT; Schema: comercial; Owner: developer
--

ALTER TABLE ONLY comercial.cupon ALTER COLUMN id_cupon SET DEFAULT nextval('comercial.cupon_id_cupon_seq'::regclass);


--
-- TOC entry 4456 (class 2604 OID 17603)
-- Name: direccion id_direccion; Type: DEFAULT; Schema: comercial; Owner: developer
--

ALTER TABLE ONLY comercial.direccion ALTER COLUMN id_direccion SET DEFAULT nextval('comercial.direccion_id_direccion_seq'::regclass);


--
-- TOC entry 4450 (class 2604 OID 17561)
-- Name: pago id_pago; Type: DEFAULT; Schema: comercial; Owner: developer
--

ALTER TABLE ONLY comercial.pago ALTER COLUMN id_pago SET DEFAULT nextval('comercial.pago_id_pago_seq'::regclass);


--
-- TOC entry 4444 (class 2604 OID 17519)
-- Name: pedido id_pedido; Type: DEFAULT; Schema: comercial; Owner: developer
--

ALTER TABLE ONLY comercial.pedido ALTER COLUMN id_pedido SET DEFAULT nextval('comercial.pedido_id_pedido_seq'::regclass);


--
-- TOC entry 4448 (class 2604 OID 17540)
-- Name: pedido_item id_item; Type: DEFAULT; Schema: comercial; Owner: developer
--

ALTER TABLE ONLY comercial.pedido_item ALTER COLUMN id_item SET DEFAULT nextval('comercial.pedido_item_id_item_seq'::regclass);


--
-- TOC entry 4429 (class 2604 OID 17439)
-- Name: producto id_producto; Type: DEFAULT; Schema: comercial; Owner: developer
--

ALTER TABLE ONLY comercial.producto ALTER COLUMN id_producto SET DEFAULT nextval('comercial.producto_id_producto_seq'::regclass);


--
-- TOC entry 4426 (class 2604 OID 17425)
-- Name: proveedor id_proveedor; Type: DEFAULT; Schema: comercial; Owner: developer
--

ALTER TABLE ONLY comercial.proveedor ALTER COLUMN id_proveedor SET DEFAULT nextval('comercial.proveedor_id_proveedor_seq'::regclass);


--
-- TOC entry 4453 (class 2604 OID 17579)
-- Name: resena id_resena; Type: DEFAULT; Schema: comercial; Owner: developer
--

ALTER TABLE ONLY comercial.resena ALTER COLUMN id_resena SET DEFAULT nextval('comercial.resena_id_resena_seq'::regclass);


--
-- TOC entry 4466 (class 2604 OID 17681)
-- Name: permiso id_permiso; Type: DEFAULT; Schema: seguridad; Owner: developer
--

ALTER TABLE ONLY seguridad.permiso ALTER COLUMN id_permiso SET DEFAULT nextval('seguridad.permiso_id_permiso_seq'::regclass);


--
-- TOC entry 4464 (class 2604 OID 17669)
-- Name: rol id_rol; Type: DEFAULT; Schema: seguridad; Owner: developer
--

ALTER TABLE ONLY seguridad.rol ALTER COLUMN id_rol SET DEFAULT nextval('seguridad.rol_id_rol_seq'::regclass);


--
-- TOC entry 4467 (class 2604 OID 17707)
-- Name: usuario id_usuario; Type: DEFAULT; Schema: seguridad; Owner: developer
--

ALTER TABLE ONLY seguridad.usuario ALTER COLUMN id_usuario SET DEFAULT nextval('seguridad.usuario_id_usuario_seq'::regclass);


--
-- TOC entry 4586 (class 2606 OID 17745)
-- Name: historial_precios historial_precios_pkey; Type: CONSTRAINT; Schema: auditoria; Owner: developer
--

ALTER TABLE ONLY auditoria.historial_precios
    ADD CONSTRAINT historial_precios_pkey PRIMARY KEY (id_historial);


--
-- TOC entry 4593 (class 2606 OID 17766)
-- Name: log_actividad log_actividad_pkey; Type: CONSTRAINT; Schema: auditoria; Owner: developer
--

ALTER TABLE ONLY auditoria.log_actividad
    ADD CONSTRAINT log_actividad_pkey PRIMARY KEY (id_log);


--
-- TOC entry 4526 (class 2606 OID 17504)
-- Name: carrito_item carrito_item_id_carrito_id_producto_key; Type: CONSTRAINT; Schema: comercial; Owner: developer
--

ALTER TABLE ONLY comercial.carrito_item
    ADD CONSTRAINT carrito_item_id_carrito_id_producto_key UNIQUE (id_carrito, id_producto);


--
-- TOC entry 4528 (class 2606 OID 17502)
-- Name: carrito_item carrito_item_pkey; Type: CONSTRAINT; Schema: comercial; Owner: developer
--

ALTER TABLE ONLY comercial.carrito_item
    ADD CONSTRAINT carrito_item_pkey PRIMARY KEY (id_item);


--
-- TOC entry 4521 (class 2606 OID 17487)
-- Name: carrito carrito_pkey; Type: CONSTRAINT; Schema: comercial; Owner: developer
--

ALTER TABLE ONLY comercial.carrito
    ADD CONSTRAINT carrito_pkey PRIMARY KEY (id_carrito);


--
-- TOC entry 4497 (class 2606 OID 17418)
-- Name: categoria categoria_pkey; Type: CONSTRAINT; Schema: comercial; Owner: developer
--

ALTER TABLE ONLY comercial.categoria
    ADD CONSTRAINT categoria_pkey PRIMARY KEY (id_categoria);


--
-- TOC entry 4499 (class 2606 OID 17420)
-- Name: categoria categoria_slug_key; Type: CONSTRAINT; Schema: comercial; Owner: developer
--

ALTER TABLE ONLY comercial.categoria
    ADD CONSTRAINT categoria_slug_key UNIQUE (slug);


--
-- TOC entry 4517 (class 2606 OID 17477)
-- Name: cliente cliente_email_key; Type: CONSTRAINT; Schema: comercial; Owner: developer
--

ALTER TABLE ONLY comercial.cliente
    ADD CONSTRAINT cliente_email_key UNIQUE (email);


--
-- TOC entry 4519 (class 2606 OID 17475)
-- Name: cliente cliente_pkey; Type: CONSTRAINT; Schema: comercial; Owner: developer
--

ALTER TABLE ONLY comercial.cliente
    ADD CONSTRAINT cliente_pkey PRIMARY KEY (id_cliente);


--
-- TOC entry 4555 (class 2606 OID 17627)
-- Name: cupon cupon_codigo_key; Type: CONSTRAINT; Schema: comercial; Owner: developer
--

ALTER TABLE ONLY comercial.cupon
    ADD CONSTRAINT cupon_codigo_key UNIQUE (codigo);


--
-- TOC entry 4557 (class 2606 OID 17625)
-- Name: cupon cupon_pkey; Type: CONSTRAINT; Schema: comercial; Owner: developer
--

ALTER TABLE ONLY comercial.cupon
    ADD CONSTRAINT cupon_pkey PRIMARY KEY (id_cupon);


--
-- TOC entry 4562 (class 2606 OID 17633)
-- Name: cupon_usado cupon_usado_pkey; Type: CONSTRAINT; Schema: comercial; Owner: developer
--

ALTER TABLE ONLY comercial.cupon_usado
    ADD CONSTRAINT cupon_usado_pkey PRIMARY KEY (id_cupon, id_cliente, id_pedido);


--
-- TOC entry 4551 (class 2606 OID 17609)
-- Name: direccion direccion_pkey; Type: CONSTRAINT; Schema: comercial; Owner: developer
--

ALTER TABLE ONLY comercial.direccion
    ADD CONSTRAINT direccion_pkey PRIMARY KEY (id_direccion);


--
-- TOC entry 4564 (class 2606 OID 17654)
-- Name: favorito favorito_pkey; Type: CONSTRAINT; Schema: comercial; Owner: developer
--

ALTER TABLE ONLY comercial.favorito
    ADD CONSTRAINT favorito_pkey PRIMARY KEY (id_cliente, id_producto);


--
-- TOC entry 4542 (class 2606 OID 17569)
-- Name: pago pago_pkey; Type: CONSTRAINT; Schema: comercial; Owner: developer
--

ALTER TABLE ONLY comercial.pago
    ADD CONSTRAINT pago_pkey PRIMARY KEY (id_pago);


--
-- TOC entry 4540 (class 2606 OID 17546)
-- Name: pedido_item pedido_item_pkey; Type: CONSTRAINT; Schema: comercial; Owner: developer
--

ALTER TABLE ONLY comercial.pedido_item
    ADD CONSTRAINT pedido_item_pkey PRIMARY KEY (id_item);


--
-- TOC entry 4536 (class 2606 OID 17530)
-- Name: pedido pedido_pkey; Type: CONSTRAINT; Schema: comercial; Owner: developer
--

ALTER TABLE ONLY comercial.pedido
    ADD CONSTRAINT pedido_pkey PRIMARY KEY (id_pedido);


--
-- TOC entry 4513 (class 2606 OID 17451)
-- Name: producto producto_pkey; Type: CONSTRAINT; Schema: comercial; Owner: developer
--

ALTER TABLE ONLY comercial.producto
    ADD CONSTRAINT producto_pkey PRIMARY KEY (id_producto);


--
-- TOC entry 4515 (class 2606 OID 17453)
-- Name: producto producto_sku_key; Type: CONSTRAINT; Schema: comercial; Owner: developer
--

ALTER TABLE ONLY comercial.producto
    ADD CONSTRAINT producto_sku_key UNIQUE (sku);


--
-- TOC entry 4501 (class 2606 OID 17434)
-- Name: proveedor proveedor_email_key; Type: CONSTRAINT; Schema: comercial; Owner: developer
--

ALTER TABLE ONLY comercial.proveedor
    ADD CONSTRAINT proveedor_email_key UNIQUE (email);


--
-- TOC entry 4503 (class 2606 OID 17432)
-- Name: proveedor proveedor_pkey; Type: CONSTRAINT; Schema: comercial; Owner: developer
--

ALTER TABLE ONLY comercial.proveedor
    ADD CONSTRAINT proveedor_pkey PRIMARY KEY (id_proveedor);


--
-- TOC entry 4547 (class 2606 OID 17588)
-- Name: resena resena_id_producto_id_cliente_key; Type: CONSTRAINT; Schema: comercial; Owner: developer
--

ALTER TABLE ONLY comercial.resena
    ADD CONSTRAINT resena_id_producto_id_cliente_key UNIQUE (id_producto, id_cliente);


--
-- TOC entry 4549 (class 2606 OID 17586)
-- Name: resena resena_pkey; Type: CONSTRAINT; Schema: comercial; Owner: developer
--

ALTER TABLE ONLY comercial.resena
    ADD CONSTRAINT resena_pkey PRIMARY KEY (id_resena);


--
-- TOC entry 4570 (class 2606 OID 17687)
-- Name: permiso permiso_nombre_key; Type: CONSTRAINT; Schema: seguridad; Owner: developer
--

ALTER TABLE ONLY seguridad.permiso
    ADD CONSTRAINT permiso_nombre_key UNIQUE (nombre);


--
-- TOC entry 4572 (class 2606 OID 17685)
-- Name: permiso permiso_pkey; Type: CONSTRAINT; Schema: seguridad; Owner: developer
--

ALTER TABLE ONLY seguridad.permiso
    ADD CONSTRAINT permiso_pkey PRIMARY KEY (id_permiso);


--
-- TOC entry 4566 (class 2606 OID 17676)
-- Name: rol rol_nombre_key; Type: CONSTRAINT; Schema: seguridad; Owner: developer
--

ALTER TABLE ONLY seguridad.rol
    ADD CONSTRAINT rol_nombre_key UNIQUE (nombre);


--
-- TOC entry 4574 (class 2606 OID 17692)
-- Name: rol_permiso rol_permiso_pkey; Type: CONSTRAINT; Schema: seguridad; Owner: developer
--

ALTER TABLE ONLY seguridad.rol_permiso
    ADD CONSTRAINT rol_permiso_pkey PRIMARY KEY (id_rol, id_permiso);


--
-- TOC entry 4568 (class 2606 OID 17674)
-- Name: rol rol_pkey; Type: CONSTRAINT; Schema: seguridad; Owner: developer
--

ALTER TABLE ONLY seguridad.rol
    ADD CONSTRAINT rol_pkey PRIMARY KEY (id_rol);


--
-- TOC entry 4580 (class 2606 OID 17714)
-- Name: usuario usuario_email_key; Type: CONSTRAINT; Schema: seguridad; Owner: developer
--

ALTER TABLE ONLY seguridad.usuario
    ADD CONSTRAINT usuario_email_key UNIQUE (email);


--
-- TOC entry 4582 (class 2606 OID 17712)
-- Name: usuario usuario_pkey; Type: CONSTRAINT; Schema: seguridad; Owner: developer
--

ALTER TABLE ONLY seguridad.usuario
    ADD CONSTRAINT usuario_pkey PRIMARY KEY (id_usuario);


--
-- TOC entry 4584 (class 2606 OID 17725)
-- Name: usuario_rol usuario_rol_pkey; Type: CONSTRAINT; Schema: seguridad; Owner: developer
--

ALTER TABLE ONLY seguridad.usuario_rol
    ADD CONSTRAINT usuario_rol_pkey PRIMARY KEY (id_usuario, id_rol);


--
-- TOC entry 4587 (class 1259 OID 17811)
-- Name: idx_historial_fecha; Type: INDEX; Schema: auditoria; Owner: developer
--

CREATE INDEX idx_historial_fecha ON auditoria.historial_precios USING btree (fecha_cambio);


--
-- TOC entry 4588 (class 1259 OID 17810)
-- Name: idx_historial_producto; Type: INDEX; Schema: auditoria; Owner: developer
--

CREATE INDEX idx_historial_producto ON auditoria.historial_precios USING btree (id_producto);


--
-- TOC entry 4589 (class 1259 OID 17813)
-- Name: idx_log_fecha; Type: INDEX; Schema: auditoria; Owner: developer
--

CREATE INDEX idx_log_fecha ON auditoria.log_actividad USING btree (fecha_operacion);


--
-- TOC entry 4590 (class 1259 OID 17814)
-- Name: idx_log_tabla; Type: INDEX; Schema: auditoria; Owner: developer
--

CREATE INDEX idx_log_tabla ON auditoria.log_actividad USING btree (tabla_afectada);


--
-- TOC entry 4591 (class 1259 OID 17812)
-- Name: idx_log_usuario; Type: INDEX; Schema: auditoria; Owner: developer
--

CREATE INDEX idx_log_usuario ON auditoria.log_actividad USING btree (id_usuario);


--
-- TOC entry 4522 (class 1259 OID 17792)
-- Name: idx_carrito_activo; Type: INDEX; Schema: comercial; Owner: developer
--

CREATE INDEX idx_carrito_activo ON comercial.carrito USING btree (activo);


--
-- TOC entry 4523 (class 1259 OID 17791)
-- Name: idx_carrito_cliente; Type: INDEX; Schema: comercial; Owner: developer
--

CREATE INDEX idx_carrito_cliente ON comercial.carrito USING btree (id_cliente);


--
-- TOC entry 4524 (class 1259 OID 25619)
-- Name: idx_carrito_cliente_activo; Type: INDEX; Schema: comercial; Owner: developer
--

CREATE INDEX idx_carrito_cliente_activo ON comercial.carrito USING btree (id_cliente, activo);


--
-- TOC entry 4529 (class 1259 OID 17794)
-- Name: idx_carrito_item_carrito; Type: INDEX; Schema: comercial; Owner: developer
--

CREATE INDEX idx_carrito_item_carrito ON comercial.carrito_item USING btree (id_carrito);


--
-- TOC entry 4530 (class 1259 OID 25618)
-- Name: idx_carrito_item_fecha; Type: INDEX; Schema: comercial; Owner: developer
--

CREATE INDEX idx_carrito_item_fecha ON comercial.carrito_item USING btree (fecha_agregado);


--
-- TOC entry 4531 (class 1259 OID 17793)
-- Name: idx_carrito_item_producto; Type: INDEX; Schema: comercial; Owner: developer
--

CREATE INDEX idx_carrito_item_producto ON comercial.carrito_item USING btree (id_producto);


--
-- TOC entry 4558 (class 1259 OID 17806)
-- Name: idx_cupon_activo; Type: INDEX; Schema: comercial; Owner: developer
--

CREATE INDEX idx_cupon_activo ON comercial.cupon USING btree (activo);


--
-- TOC entry 4559 (class 1259 OID 17805)
-- Name: idx_cupon_codigo; Type: INDEX; Schema: comercial; Owner: developer
--

CREATE INDEX idx_cupon_codigo ON comercial.cupon USING btree (codigo);


--
-- TOC entry 4560 (class 1259 OID 17807)
-- Name: idx_cupon_fechas; Type: INDEX; Schema: comercial; Owner: developer
--

CREATE INDEX idx_cupon_fechas ON comercial.cupon USING btree (fecha_inicio, fecha_fin);


--
-- TOC entry 4552 (class 1259 OID 17803)
-- Name: idx_direccion_cliente; Type: INDEX; Schema: comercial; Owner: developer
--

CREATE INDEX idx_direccion_cliente ON comercial.direccion USING btree (id_cliente);


--
-- TOC entry 4553 (class 1259 OID 17804)
-- Name: idx_direccion_principal; Type: INDEX; Schema: comercial; Owner: developer
--

CREATE INDEX idx_direccion_principal ON comercial.direccion USING btree (principal);


--
-- TOC entry 4532 (class 1259 OID 17795)
-- Name: idx_pedido_cliente; Type: INDEX; Schema: comercial; Owner: developer
--

CREATE INDEX idx_pedido_cliente ON comercial.pedido USING btree (id_cliente);


--
-- TOC entry 4533 (class 1259 OID 17797)
-- Name: idx_pedido_estado; Type: INDEX; Schema: comercial; Owner: developer
--

CREATE INDEX idx_pedido_estado ON comercial.pedido USING btree (estado);


--
-- TOC entry 4534 (class 1259 OID 17796)
-- Name: idx_pedido_fecha; Type: INDEX; Schema: comercial; Owner: developer
--

CREATE INDEX idx_pedido_fecha ON comercial.pedido USING btree (fecha_pedido);


--
-- TOC entry 4537 (class 1259 OID 17798)
-- Name: idx_pedido_item_pedido; Type: INDEX; Schema: comercial; Owner: developer
--

CREATE INDEX idx_pedido_item_pedido ON comercial.pedido_item USING btree (id_pedido);


--
-- TOC entry 4538 (class 1259 OID 17799)
-- Name: idx_pedido_item_producto; Type: INDEX; Schema: comercial; Owner: developer
--

CREATE INDEX idx_pedido_item_producto ON comercial.pedido_item USING btree (id_producto);


--
-- TOC entry 4504 (class 1259 OID 17789)
-- Name: idx_producto_activo; Type: INDEX; Schema: comercial; Owner: developer
--

CREATE INDEX idx_producto_activo ON comercial.producto USING btree (activo);


--
-- TOC entry 4505 (class 1259 OID 25617)
-- Name: idx_producto_activo_categoria; Type: INDEX; Schema: comercial; Owner: developer
--

CREATE INDEX idx_producto_activo_categoria ON comercial.producto USING btree (activo, id_categoria);


--
-- TOC entry 4506 (class 1259 OID 25622)
-- Name: idx_producto_busqueda; Type: INDEX; Schema: comercial; Owner: developer
--

CREATE INDEX idx_producto_busqueda ON comercial.producto USING gin (to_tsvector('spanish'::regconfig, (((nombre)::text || ' '::text) || descripcion)));


--
-- TOC entry 4507 (class 1259 OID 17787)
-- Name: idx_producto_categoria; Type: INDEX; Schema: comercial; Owner: developer
--

CREATE INDEX idx_producto_categoria ON comercial.producto USING btree (id_categoria);


--
-- TOC entry 4508 (class 1259 OID 25615)
-- Name: idx_producto_nombre; Type: INDEX; Schema: comercial; Owner: developer
--

CREATE INDEX idx_producto_nombre ON comercial.producto USING btree (lower((nombre)::text));


--
-- TOC entry 4509 (class 1259 OID 17790)
-- Name: idx_producto_precio; Type: INDEX; Schema: comercial; Owner: developer
--

CREATE INDEX idx_producto_precio ON comercial.producto USING btree (precio);


--
-- TOC entry 4510 (class 1259 OID 25616)
-- Name: idx_producto_precio_descuento; Type: INDEX; Schema: comercial; Owner: developer
--

CREATE INDEX idx_producto_precio_descuento ON comercial.producto USING btree (precio_descuento) WHERE (precio_descuento IS NOT NULL);


--
-- TOC entry 4511 (class 1259 OID 17788)
-- Name: idx_producto_proveedor; Type: INDEX; Schema: comercial; Owner: developer
--

CREATE INDEX idx_producto_proveedor ON comercial.producto USING btree (id_proveedor);


--
-- TOC entry 4543 (class 1259 OID 17801)
-- Name: idx_resena_cliente; Type: INDEX; Schema: comercial; Owner: developer
--

CREATE INDEX idx_resena_cliente ON comercial.resena USING btree (id_cliente);


--
-- TOC entry 4544 (class 1259 OID 17800)
-- Name: idx_resena_producto; Type: INDEX; Schema: comercial; Owner: developer
--

CREATE INDEX idx_resena_producto ON comercial.resena USING btree (id_producto);


--
-- TOC entry 4545 (class 1259 OID 17802)
-- Name: idx_resena_valoracion; Type: INDEX; Schema: comercial; Owner: developer
--

CREATE INDEX idx_resena_valoracion ON comercial.resena USING btree (valoracion);


--
-- TOC entry 4575 (class 1259 OID 25620)
-- Name: idx_usuario_activo; Type: INDEX; Schema: seguridad; Owner: developer
--

CREATE INDEX idx_usuario_activo ON seguridad.usuario USING btree (activo);


--
-- TOC entry 4576 (class 1259 OID 17808)
-- Name: idx_usuario_cliente; Type: INDEX; Schema: seguridad; Owner: developer
--

CREATE INDEX idx_usuario_cliente ON seguridad.usuario USING btree (id_cliente);


--
-- TOC entry 4577 (class 1259 OID 17809)
-- Name: idx_usuario_email; Type: INDEX; Schema: seguridad; Owner: developer
--

CREATE INDEX idx_usuario_email ON seguridad.usuario USING btree (email);


--
-- TOC entry 4578 (class 1259 OID 25621)
-- Name: idx_usuario_email_password; Type: INDEX; Schema: seguridad; Owner: developer
--

CREATE INDEX idx_usuario_email_password ON seguridad.usuario USING btree (email, password_hash);


--
-- TOC entry 4762 (class 2618 OID 17775)
-- Name: productos_mas_vendidos _RETURN; Type: RULE; Schema: reportes; Owner: developer
--

CREATE OR REPLACE VIEW reportes.productos_mas_vendidos AS
 SELECT p.id_producto,
    p.nombre,
    p.descripcion,
    count(pi.id_item) AS veces_vendido,
    sum(pi.cantidad) AS cantidad_vendida,
    sum((pi.precio_unitario * (pi.cantidad)::numeric)) AS total_vendido
   FROM ((comercial.producto p
     JOIN comercial.pedido_item pi ON ((p.id_producto = pi.id_producto)))
     JOIN comercial.pedido pd ON ((pi.id_pedido = pd.id_pedido)))
  WHERE ((pd.estado)::text <> 'Cancelado'::text)
  GROUP BY p.id_producto
  ORDER BY (sum(pi.cantidad)) DESC;


--
-- TOC entry 4763 (class 2618 OID 17780)
-- Name: clientes_mas_activos _RETURN; Type: RULE; Schema: reportes; Owner: developer
--

CREATE OR REPLACE VIEW reportes.clientes_mas_activos AS
 SELECT c.id_cliente,
    (((c.nombre)::text || ' '::text) || (c.apellido)::text) AS nombre_completo,
    c.email,
    count(p.id_pedido) AS total_pedidos,
    sum(p.total) AS total_gastado,
    max(p.fecha_pedido) AS ultimo_pedido
   FROM (comercial.cliente c
     LEFT JOIN comercial.pedido p ON ((c.id_cliente = p.id_cliente)))
  WHERE (((p.estado)::text <> 'Cancelado'::text) OR (p.id_pedido IS NULL))
  GROUP BY c.id_cliente
  ORDER BY (sum(p.total)) DESC NULLS LAST;


--
-- TOC entry 4764 (class 2618 OID 17785)
-- Name: ventas_por_categoria _RETURN; Type: RULE; Schema: reportes; Owner: developer
--

CREATE OR REPLACE VIEW reportes.ventas_por_categoria AS
 SELECT cat.id_categoria,
    cat.nombre AS categoria,
    count(DISTINCT p.id_pedido) AS total_pedidos,
    sum(pi.cantidad) AS total_productos,
    sum((pi.precio_unitario * (pi.cantidad)::numeric)) AS total_ventas
   FROM (((comercial.categoria cat
     JOIN comercial.producto pr ON ((cat.id_categoria = pr.id_categoria)))
     JOIN comercial.pedido_item pi ON ((pr.id_producto = pi.id_producto)))
     JOIN comercial.pedido p ON ((pi.id_pedido = p.id_pedido)))
  WHERE ((p.estado)::text <> 'Cancelado'::text)
  GROUP BY cat.id_categoria
  ORDER BY (sum((pi.precio_unitario * (pi.cantidad)::numeric))) DESC;


--
-- TOC entry 4616 (class 2606 OID 17746)
-- Name: historial_precios historial_precios_id_producto_fkey; Type: FK CONSTRAINT; Schema: auditoria; Owner: developer
--

ALTER TABLE ONLY auditoria.historial_precios
    ADD CONSTRAINT historial_precios_id_producto_fkey FOREIGN KEY (id_producto) REFERENCES comercial.producto(id_producto);


--
-- TOC entry 4617 (class 2606 OID 17751)
-- Name: historial_precios historial_precios_id_usuario_fkey; Type: FK CONSTRAINT; Schema: auditoria; Owner: developer
--

ALTER TABLE ONLY auditoria.historial_precios
    ADD CONSTRAINT historial_precios_id_usuario_fkey FOREIGN KEY (id_usuario) REFERENCES seguridad.usuario(id_usuario);


--
-- TOC entry 4618 (class 2606 OID 17767)
-- Name: log_actividad log_actividad_id_usuario_fkey; Type: FK CONSTRAINT; Schema: auditoria; Owner: developer
--

ALTER TABLE ONLY auditoria.log_actividad
    ADD CONSTRAINT log_actividad_id_usuario_fkey FOREIGN KEY (id_usuario) REFERENCES seguridad.usuario(id_usuario);


--
-- TOC entry 4596 (class 2606 OID 17488)
-- Name: carrito carrito_id_cliente_fkey; Type: FK CONSTRAINT; Schema: comercial; Owner: developer
--

ALTER TABLE ONLY comercial.carrito
    ADD CONSTRAINT carrito_id_cliente_fkey FOREIGN KEY (id_cliente) REFERENCES comercial.cliente(id_cliente);


--
-- TOC entry 4597 (class 2606 OID 17505)
-- Name: carrito_item carrito_item_id_carrito_fkey; Type: FK CONSTRAINT; Schema: comercial; Owner: developer
--

ALTER TABLE ONLY comercial.carrito_item
    ADD CONSTRAINT carrito_item_id_carrito_fkey FOREIGN KEY (id_carrito) REFERENCES comercial.carrito(id_carrito) ON DELETE CASCADE;


--
-- TOC entry 4598 (class 2606 OID 17510)
-- Name: carrito_item carrito_item_id_producto_fkey; Type: FK CONSTRAINT; Schema: comercial; Owner: developer
--

ALTER TABLE ONLY comercial.carrito_item
    ADD CONSTRAINT carrito_item_id_producto_fkey FOREIGN KEY (id_producto) REFERENCES comercial.producto(id_producto);


--
-- TOC entry 4606 (class 2606 OID 17639)
-- Name: cupon_usado cupon_usado_id_cliente_fkey; Type: FK CONSTRAINT; Schema: comercial; Owner: developer
--

ALTER TABLE ONLY comercial.cupon_usado
    ADD CONSTRAINT cupon_usado_id_cliente_fkey FOREIGN KEY (id_cliente) REFERENCES comercial.cliente(id_cliente);


--
-- TOC entry 4607 (class 2606 OID 17634)
-- Name: cupon_usado cupon_usado_id_cupon_fkey; Type: FK CONSTRAINT; Schema: comercial; Owner: developer
--

ALTER TABLE ONLY comercial.cupon_usado
    ADD CONSTRAINT cupon_usado_id_cupon_fkey FOREIGN KEY (id_cupon) REFERENCES comercial.cupon(id_cupon);


--
-- TOC entry 4608 (class 2606 OID 17644)
-- Name: cupon_usado cupon_usado_id_pedido_fkey; Type: FK CONSTRAINT; Schema: comercial; Owner: developer
--

ALTER TABLE ONLY comercial.cupon_usado
    ADD CONSTRAINT cupon_usado_id_pedido_fkey FOREIGN KEY (id_pedido) REFERENCES comercial.pedido(id_pedido);


--
-- TOC entry 4605 (class 2606 OID 17610)
-- Name: direccion direccion_id_cliente_fkey; Type: FK CONSTRAINT; Schema: comercial; Owner: developer
--

ALTER TABLE ONLY comercial.direccion
    ADD CONSTRAINT direccion_id_cliente_fkey FOREIGN KEY (id_cliente) REFERENCES comercial.cliente(id_cliente);


--
-- TOC entry 4609 (class 2606 OID 17655)
-- Name: favorito favorito_id_cliente_fkey; Type: FK CONSTRAINT; Schema: comercial; Owner: developer
--

ALTER TABLE ONLY comercial.favorito
    ADD CONSTRAINT favorito_id_cliente_fkey FOREIGN KEY (id_cliente) REFERENCES comercial.cliente(id_cliente);


--
-- TOC entry 4610 (class 2606 OID 17660)
-- Name: favorito favorito_id_producto_fkey; Type: FK CONSTRAINT; Schema: comercial; Owner: developer
--

ALTER TABLE ONLY comercial.favorito
    ADD CONSTRAINT favorito_id_producto_fkey FOREIGN KEY (id_producto) REFERENCES comercial.producto(id_producto);


--
-- TOC entry 4602 (class 2606 OID 17570)
-- Name: pago pago_id_pedido_fkey; Type: FK CONSTRAINT; Schema: comercial; Owner: developer
--

ALTER TABLE ONLY comercial.pago
    ADD CONSTRAINT pago_id_pedido_fkey FOREIGN KEY (id_pedido) REFERENCES comercial.pedido(id_pedido);


--
-- TOC entry 4599 (class 2606 OID 17531)
-- Name: pedido pedido_id_cliente_fkey; Type: FK CONSTRAINT; Schema: comercial; Owner: developer
--

ALTER TABLE ONLY comercial.pedido
    ADD CONSTRAINT pedido_id_cliente_fkey FOREIGN KEY (id_cliente) REFERENCES comercial.cliente(id_cliente);


--
-- TOC entry 4600 (class 2606 OID 17547)
-- Name: pedido_item pedido_item_id_pedido_fkey; Type: FK CONSTRAINT; Schema: comercial; Owner: developer
--

ALTER TABLE ONLY comercial.pedido_item
    ADD CONSTRAINT pedido_item_id_pedido_fkey FOREIGN KEY (id_pedido) REFERENCES comercial.pedido(id_pedido) ON DELETE CASCADE;


--
-- TOC entry 4601 (class 2606 OID 17552)
-- Name: pedido_item pedido_item_id_producto_fkey; Type: FK CONSTRAINT; Schema: comercial; Owner: developer
--

ALTER TABLE ONLY comercial.pedido_item
    ADD CONSTRAINT pedido_item_id_producto_fkey FOREIGN KEY (id_producto) REFERENCES comercial.producto(id_producto);


--
-- TOC entry 4594 (class 2606 OID 17454)
-- Name: producto producto_id_categoria_fkey; Type: FK CONSTRAINT; Schema: comercial; Owner: developer
--

ALTER TABLE ONLY comercial.producto
    ADD CONSTRAINT producto_id_categoria_fkey FOREIGN KEY (id_categoria) REFERENCES comercial.categoria(id_categoria);


--
-- TOC entry 4595 (class 2606 OID 17459)
-- Name: producto producto_id_proveedor_fkey; Type: FK CONSTRAINT; Schema: comercial; Owner: developer
--

ALTER TABLE ONLY comercial.producto
    ADD CONSTRAINT producto_id_proveedor_fkey FOREIGN KEY (id_proveedor) REFERENCES comercial.proveedor(id_proveedor);


--
-- TOC entry 4603 (class 2606 OID 17594)
-- Name: resena resena_id_cliente_fkey; Type: FK CONSTRAINT; Schema: comercial; Owner: developer
--

ALTER TABLE ONLY comercial.resena
    ADD CONSTRAINT resena_id_cliente_fkey FOREIGN KEY (id_cliente) REFERENCES comercial.cliente(id_cliente);


--
-- TOC entry 4604 (class 2606 OID 17589)
-- Name: resena resena_id_producto_fkey; Type: FK CONSTRAINT; Schema: comercial; Owner: developer
--

ALTER TABLE ONLY comercial.resena
    ADD CONSTRAINT resena_id_producto_fkey FOREIGN KEY (id_producto) REFERENCES comercial.producto(id_producto);


--
-- TOC entry 4611 (class 2606 OID 17698)
-- Name: rol_permiso rol_permiso_id_permiso_fkey; Type: FK CONSTRAINT; Schema: seguridad; Owner: developer
--

ALTER TABLE ONLY seguridad.rol_permiso
    ADD CONSTRAINT rol_permiso_id_permiso_fkey FOREIGN KEY (id_permiso) REFERENCES seguridad.permiso(id_permiso);


--
-- TOC entry 4612 (class 2606 OID 17693)
-- Name: rol_permiso rol_permiso_id_rol_fkey; Type: FK CONSTRAINT; Schema: seguridad; Owner: developer
--

ALTER TABLE ONLY seguridad.rol_permiso
    ADD CONSTRAINT rol_permiso_id_rol_fkey FOREIGN KEY (id_rol) REFERENCES seguridad.rol(id_rol);


--
-- TOC entry 4613 (class 2606 OID 17715)
-- Name: usuario usuario_id_cliente_fkey; Type: FK CONSTRAINT; Schema: seguridad; Owner: developer
--

ALTER TABLE ONLY seguridad.usuario
    ADD CONSTRAINT usuario_id_cliente_fkey FOREIGN KEY (id_cliente) REFERENCES comercial.cliente(id_cliente);


--
-- TOC entry 4614 (class 2606 OID 17731)
-- Name: usuario_rol usuario_rol_id_rol_fkey; Type: FK CONSTRAINT; Schema: seguridad; Owner: developer
--

ALTER TABLE ONLY seguridad.usuario_rol
    ADD CONSTRAINT usuario_rol_id_rol_fkey FOREIGN KEY (id_rol) REFERENCES seguridad.rol(id_rol);


--
-- TOC entry 4615 (class 2606 OID 17726)
-- Name: usuario_rol usuario_rol_id_usuario_fkey; Type: FK CONSTRAINT; Schema: seguridad; Owner: developer
--

ALTER TABLE ONLY seguridad.usuario_rol
    ADD CONSTRAINT usuario_rol_id_usuario_fkey FOREIGN KEY (id_usuario) REFERENCES seguridad.usuario(id_usuario);


-- Completed on 2025-06-17 15:35:27 -05

--
-- PostgreSQL database dump complete
--

