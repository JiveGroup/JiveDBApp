--
-- PostgreSQL database dump
--

\restrict vaNjcwe7n5f5j0zk0vmuMkXwianPJ1ViO0o7LmqersPCh6rfWCnVh0xjWvCszN7

-- Dumped from database version 16.14 (Debian 16.14-1.pgdg13+1)
-- Dumped by pg_dump version 16.14 (Debian 16.14-1.pgdg13+1)

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
-- Name: cart_status; Type: TYPE; Schema: public; Owner: jdb
--

CREATE TYPE public.cart_status AS ENUM (
    'open',
    'converted',
    'abandoned'
);


ALTER TYPE public.cart_status OWNER TO jdb;

--
-- Name: email_addr; Type: DOMAIN; Schema: public; Owner: jdb
--

CREATE DOMAIN public.email_addr AS character varying(255)
	CONSTRAINT email_addr_check CHECK (((VALUE)::text ~ '@'::text));


ALTER DOMAIN public.email_addr OWNER TO jdb;

--
-- Name: geo_point; Type: TYPE; Schema: public; Owner: jdb
--

CREATE TYPE public.geo_point AS (
	lat double precision,
	lng double precision
);


ALTER TYPE public.geo_point OWNER TO jdb;

--
-- Name: order_status; Type: TYPE; Schema: public; Owner: jdb
--

CREATE TYPE public.order_status AS ENUM (
    'pending',
    'paid',
    'shipped',
    'delivered',
    'cancelled'
);


ALTER TYPE public.order_status OWNER TO jdb;

--
-- Name: payment_method; Type: TYPE; Schema: public; Owner: jdb
--

CREATE TYPE public.payment_method AS ENUM (
    'card',
    'paypal',
    'bank',
    'cod'
);


ALTER TYPE public.payment_method OWNER TO jdb;

--
-- Name: payment_status; Type: TYPE; Schema: public; Owner: jdb
--

CREATE TYPE public.payment_status AS ENUM (
    'pending',
    'completed',
    'failed',
    'refunded'
);


ALTER TYPE public.payment_status OWNER TO jdb;

--
-- Name: product_status; Type: TYPE; Schema: public; Owner: jdb
--

CREATE TYPE public.product_status AS ENUM (
    'active',
    'draft',
    'discontinued'
);


ALTER TYPE public.product_status OWNER TO jdb;

--
-- Name: shipment_status; Type: TYPE; Schema: public; Owner: jdb
--

CREATE TYPE public.shipment_status AS ENUM (
    'preparing',
    'shipped',
    'in_transit',
    'delivered',
    'returned'
);


ALTER TYPE public.shipment_status OWNER TO jdb;

--
-- Name: user_status; Type: TYPE; Schema: public; Owner: jdb
--

CREATE TYPE public.user_status AS ENUM (
    'active',
    'pending',
    'blocked'
);


ALTER TYPE public.user_status OWNER TO jdb;

--
-- Name: fn_apply_discount(numeric, numeric); Type: FUNCTION; Schema: public; Owner: jdb
--

CREATE FUNCTION public.fn_apply_discount(price numeric, pct numeric DEFAULT 10) RETURNS numeric
    LANGUAGE sql IMMUTABLE
    AS $$
  SELECT round(price * (1 - pct / 100.0), 2);
$$;


ALTER FUNCTION public.fn_apply_discount(price numeric, pct numeric) OWNER TO jdb;

--
-- Name: fn_concat_tags(text[]); Type: FUNCTION; Schema: public; Owner: jdb
--

CREATE FUNCTION public.fn_concat_tags(VARIADIC tags text[]) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $$
  SELECT array_to_string(tags, ', ');
$$;


ALTER FUNCTION public.fn_concat_tags(VARIADIC tags text[]) OWNER TO jdb;

--
-- Name: fn_full_name(text, text); Type: FUNCTION; Schema: public; Owner: jdb
--

CREATE FUNCTION public.fn_full_name(first_name text, last_name text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $$
  SELECT trim(coalesce(first_name, '') || ' ' || coalesce(last_name, ''));
$$;


ALTER FUNCTION public.fn_full_name(first_name text, last_name text) OWNER TO jdb;

--
-- Name: fn_label_order_status(public.order_status); Type: FUNCTION; Schema: public; Owner: jdb
--

CREATE FUNCTION public.fn_label_order_status(s public.order_status) RETURNS text
    LANGUAGE plpgsql IMMUTABLE
    AS $$
BEGIN
  RETURN CASE s
    WHEN 'pending' THEN 'Cho xu ly'
    WHEN 'paid' THEN 'Da thanh toan'
    WHEN 'shipped' THEN 'Dang giao'
    WHEN 'delivered' THEN 'Hoan tat'
    WHEN 'cancelled' THEN 'Da huy'
    ELSE 'Khac'
  END;
END; $$;


ALTER FUNCTION public.fn_label_order_status(s public.order_status) OWNER TO jdb;

--
-- Name: fn_order_summary_json(bigint); Type: FUNCTION; Schema: public; Owner: jdb
--

CREATE FUNCTION public.fn_order_summary_json(p_order_id bigint) RETURNS json
    LANGUAGE sql STABLE
    AS $$
  SELECT json_build_object(
    'id', o.id, 'status', o.status, 'total', o.total,
    'items', (SELECT count(*) FROM order_items oi WHERE oi.order_id = o.id)
  ) FROM orders o WHERE o.id = p_order_id;
$$;


ALTER FUNCTION public.fn_order_summary_json(p_order_id bigint) OWNER TO jdb;

--
-- Name: fn_order_total(bigint); Type: FUNCTION; Schema: public; Owner: jdb
--

CREATE FUNCTION public.fn_order_total(p_order_id bigint) RETURNS numeric
    LANGUAGE plpgsql STABLE
    AS $$
DECLARE total numeric;
BEGIN
  SELECT COALESCE(SUM(quantity * unit_price), 0) INTO total FROM order_items WHERE order_id = p_order_id;
  RETURN total;
END; $$;


ALTER FUNCTION public.fn_order_total(p_order_id bigint) OWNER TO jdb;

--
-- Name: fn_recent_orders(integer); Type: FUNCTION; Schema: public; Owner: jdb
--

CREATE FUNCTION public.fn_recent_orders(p_days integer DEFAULT 30) RETURNS TABLE(id bigint, user_id bigint, total numeric, created_at timestamp with time zone)
    LANGUAGE sql STABLE
    AS $$
  SELECT id, user_id, total, created_at FROM orders
  WHERE created_at >= now() - make_interval(days => p_days)
  ORDER BY created_at DESC;
$$;


ALTER FUNCTION public.fn_recent_orders(p_days integer) OWNER TO jdb;

--
-- Name: fn_set_row_timestamp(); Type: FUNCTION; Schema: public; Owner: jdb
--

CREATE FUNCTION public.fn_set_row_timestamp() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END; $$;


ALTER FUNCTION public.fn_set_row_timestamp() OWNER TO jdb;

--
-- Name: fn_user_emails(); Type: FUNCTION; Schema: public; Owner: jdb
--

CREATE FUNCTION public.fn_user_emails() RETURNS SETOF text
    LANGUAGE sql STABLE
    AS $$
  SELECT email FROM users ORDER BY id;
$$;


ALTER FUNCTION public.fn_user_emails() OWNER TO jdb;

--
-- Name: fn_user_order_count(bigint); Type: FUNCTION; Schema: public; Owner: jdb
--

CREATE FUNCTION public.fn_user_order_count(p_user_id bigint) RETURNS integer
    LANGUAGE sql STABLE
    AS $$
  SELECT count(*)::int FROM orders WHERE user_id = p_user_id;
$$;


ALTER FUNCTION public.fn_user_order_count(p_user_id bigint) OWNER TO jdb;

--
-- Name: log_new_order(); Type: FUNCTION; Schema: public; Owner: jdb
--

CREATE FUNCTION public.log_new_order() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN INSERT INTO audit_log(entity, entity_id, action, at) VALUES ('order', NEW.id, 'insert', now()); RETURN NEW; END; $$;


ALTER FUNCTION public.log_new_order() OWNER TO jdb;

--
-- Name: set_updated_at(); Type: FUNCTION; Schema: public; Owner: jdb
--

CREATE FUNCTION public.set_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END; $$;


ALTER FUNCTION public.set_updated_at() OWNER TO jdb;

--
-- Name: sp_touch_order(bigint); Type: PROCEDURE; Schema: public; Owner: jdb
--

CREATE PROCEDURE public.sp_touch_order(IN p_order_id bigint)
    LANGUAGE plpgsql
    AS $$
BEGIN
  UPDATE orders SET updated_at = now() WHERE id = p_order_id;
END; $$;


ALTER PROCEDURE public.sp_touch_order(IN p_order_id bigint) OWNER TO jdb;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: addresses; Type: TABLE; Schema: public; Owner: jdb
--

CREATE TABLE public.addresses (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    line1 character varying(160) NOT NULL,
    city character varying(80) NOT NULL,
    country character varying(2) NOT NULL,
    is_default boolean NOT NULL,
    created_at timestamp with time zone NOT NULL
);


ALTER TABLE public.addresses OWNER TO jdb;

--
-- Name: addresses_id_seq; Type: SEQUENCE; Schema: public; Owner: jdb
--

CREATE SEQUENCE public.addresses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.addresses_id_seq OWNER TO jdb;

--
-- Name: addresses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: jdb
--

ALTER SEQUENCE public.addresses_id_seq OWNED BY public.addresses.id;


--
-- Name: audit_log; Type: TABLE; Schema: public; Owner: jdb
--

CREATE TABLE public.audit_log (
    id bigint NOT NULL,
    entity character varying(24) NOT NULL,
    entity_id integer NOT NULL,
    action character varying(16) NOT NULL,
    at timestamp with time zone NOT NULL
);


ALTER TABLE public.audit_log OWNER TO jdb;

--
-- Name: audit_log_id_seq; Type: SEQUENCE; Schema: public; Owner: jdb
--

CREATE SEQUENCE public.audit_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.audit_log_id_seq OWNER TO jdb;

--
-- Name: audit_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: jdb
--

ALTER SEQUENCE public.audit_log_id_seq OWNED BY public.audit_log.id;


--
-- Name: cart_items; Type: TABLE; Schema: public; Owner: jdb
--

CREATE TABLE public.cart_items (
    id bigint NOT NULL,
    cart_id bigint NOT NULL,
    variant_id bigint NOT NULL,
    quantity integer NOT NULL,
    added_at timestamp with time zone NOT NULL
);


ALTER TABLE public.cart_items OWNER TO jdb;

--
-- Name: cart_items_id_seq; Type: SEQUENCE; Schema: public; Owner: jdb
--

CREATE SEQUENCE public.cart_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.cart_items_id_seq OWNER TO jdb;

--
-- Name: cart_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: jdb
--

ALTER SEQUENCE public.cart_items_id_seq OWNED BY public.cart_items.id;


--
-- Name: carts; Type: TABLE; Schema: public; Owner: jdb
--

CREATE TABLE public.carts (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    status public.cart_status NOT NULL,
    created_at timestamp with time zone NOT NULL
);


ALTER TABLE public.carts OWNER TO jdb;

--
-- Name: carts_id_seq; Type: SEQUENCE; Schema: public; Owner: jdb
--

CREATE SEQUENCE public.carts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.carts_id_seq OWNER TO jdb;

--
-- Name: carts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: jdb
--

ALTER SEQUENCE public.carts_id_seq OWNED BY public.carts.id;


--
-- Name: categories; Type: TABLE; Schema: public; Owner: jdb
--

CREATE TABLE public.categories (
    id bigint NOT NULL,
    name character varying(120) NOT NULL,
    slug character varying(140) NOT NULL,
    parent_id bigint,
    created_at timestamp with time zone NOT NULL
);


ALTER TABLE public.categories OWNER TO jdb;

--
-- Name: categories_id_seq; Type: SEQUENCE; Schema: public; Owner: jdb
--

CREATE SEQUENCE public.categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.categories_id_seq OWNER TO jdb;

--
-- Name: categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: jdb
--

ALTER SEQUENCE public.categories_id_seq OWNED BY public.categories.id;


--
-- Name: events; Type: TABLE; Schema: public; Owner: jdb
--

CREATE TABLE public.events (
    id bigint NOT NULL,
    user_id bigint,
    kind character varying(24) NOT NULL,
    payload character varying(200) NOT NULL,
    created_at timestamp with time zone NOT NULL
);


ALTER TABLE public.events OWNER TO jdb;

--
-- Name: events_id_seq; Type: SEQUENCE; Schema: public; Owner: jdb
--

CREATE SEQUENCE public.events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.events_id_seq OWNER TO jdb;

--
-- Name: events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: jdb
--

ALTER SEQUENCE public.events_id_seq OWNED BY public.events.id;


--
-- Name: inventory; Type: TABLE; Schema: public; Owner: jdb
--

CREATE TABLE public.inventory (
    id bigint NOT NULL,
    variant_id bigint NOT NULL,
    warehouse_id bigint NOT NULL,
    quantity integer NOT NULL,
    updated_at timestamp with time zone NOT NULL
);


ALTER TABLE public.inventory OWNER TO jdb;

--
-- Name: inventory_id_seq; Type: SEQUENCE; Schema: public; Owner: jdb
--

CREATE SEQUENCE public.inventory_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.inventory_id_seq OWNER TO jdb;

--
-- Name: inventory_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: jdb
--

ALTER SEQUENCE public.inventory_id_seq OWNED BY public.inventory.id;


--
-- Name: order_items; Type: TABLE; Schema: public; Owner: jdb
--

CREATE TABLE public.order_items (
    id bigint NOT NULL,
    order_id bigint NOT NULL,
    variant_id bigint NOT NULL,
    quantity integer NOT NULL,
    unit_price numeric(12,2) NOT NULL
);


ALTER TABLE public.order_items OWNER TO jdb;

--
-- Name: order_items_id_seq; Type: SEQUENCE; Schema: public; Owner: jdb
--

CREATE SEQUENCE public.order_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.order_items_id_seq OWNER TO jdb;

--
-- Name: order_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: jdb
--

ALTER SEQUENCE public.order_items_id_seq OWNED BY public.order_items.id;


--
-- Name: orders; Type: TABLE; Schema: public; Owner: jdb
--

CREATE TABLE public.orders (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    address_id bigint NOT NULL,
    status public.order_status NOT NULL,
    total numeric(12,2) NOT NULL,
    payment_method public.payment_method NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL
);


ALTER TABLE public.orders OWNER TO jdb;

--
-- Name: orders_id_seq; Type: SEQUENCE; Schema: public; Owner: jdb
--

CREATE SEQUENCE public.orders_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.orders_id_seq OWNER TO jdb;

--
-- Name: orders_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: jdb
--

ALTER SEQUENCE public.orders_id_seq OWNED BY public.orders.id;


--
-- Name: payments; Type: TABLE; Schema: public; Owner: jdb
--

CREATE TABLE public.payments (
    id bigint NOT NULL,
    order_id bigint NOT NULL,
    method public.payment_method NOT NULL,
    status public.payment_status NOT NULL,
    amount numeric(12,2) NOT NULL,
    paid_at timestamp with time zone
);


ALTER TABLE public.payments OWNER TO jdb;

--
-- Name: payments_id_seq; Type: SEQUENCE; Schema: public; Owner: jdb
--

CREATE SEQUENCE public.payments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.payments_id_seq OWNER TO jdb;

--
-- Name: payments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: jdb
--

ALTER SEQUENCE public.payments_id_seq OWNED BY public.payments.id;


--
-- Name: product_variants; Type: TABLE; Schema: public; Owner: jdb
--

CREATE TABLE public.product_variants (
    id bigint NOT NULL,
    product_id bigint NOT NULL,
    sku character varying(48) NOT NULL,
    color character varying(24) NOT NULL,
    size character varying(8) NOT NULL,
    price numeric(12,2) NOT NULL,
    created_at timestamp with time zone NOT NULL
);


ALTER TABLE public.product_variants OWNER TO jdb;

--
-- Name: product_variants_id_seq; Type: SEQUENCE; Schema: public; Owner: jdb
--

CREATE SEQUENCE public.product_variants_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.product_variants_id_seq OWNER TO jdb;

--
-- Name: product_variants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: jdb
--

ALTER SEQUENCE public.product_variants_id_seq OWNED BY public.product_variants.id;


--
-- Name: products; Type: TABLE; Schema: public; Owner: jdb
--

CREATE TABLE public.products (
    id bigint NOT NULL,
    category_id bigint NOT NULL,
    supplier_id bigint NOT NULL,
    name character varying(200) NOT NULL,
    sku character varying(40) NOT NULL,
    price numeric(12,2) NOT NULL,
    status public.product_status NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL
);


ALTER TABLE public.products OWNER TO jdb;

--
-- Name: products_id_seq; Type: SEQUENCE; Schema: public; Owner: jdb
--

CREATE SEQUENCE public.products_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.products_id_seq OWNER TO jdb;

--
-- Name: products_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: jdb
--

ALTER SEQUENCE public.products_id_seq OWNED BY public.products.id;


--
-- Name: reviews; Type: TABLE; Schema: public; Owner: jdb
--

CREATE TABLE public.reviews (
    id bigint NOT NULL,
    product_id bigint NOT NULL,
    user_id bigint NOT NULL,
    rating integer NOT NULL,
    body character varying(240) NOT NULL,
    created_at timestamp with time zone NOT NULL
);


ALTER TABLE public.reviews OWNER TO jdb;

--
-- Name: reviews_id_seq; Type: SEQUENCE; Schema: public; Owner: jdb
--

CREATE SEQUENCE public.reviews_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.reviews_id_seq OWNER TO jdb;

--
-- Name: reviews_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: jdb
--

ALTER SEQUENCE public.reviews_id_seq OWNED BY public.reviews.id;


--
-- Name: shipments; Type: TABLE; Schema: public; Owner: jdb
--

CREATE TABLE public.shipments (
    id bigint NOT NULL,
    order_id bigint NOT NULL,
    warehouse_id bigint NOT NULL,
    carrier character varying(16) NOT NULL,
    tracking character varying(24) NOT NULL,
    status public.shipment_status NOT NULL,
    shipped_at timestamp with time zone
);


ALTER TABLE public.shipments OWNER TO jdb;

--
-- Name: shipments_id_seq; Type: SEQUENCE; Schema: public; Owner: jdb
--

CREATE SEQUENCE public.shipments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.shipments_id_seq OWNER TO jdb;

--
-- Name: shipments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: jdb
--

ALTER SEQUENCE public.shipments_id_seq OWNED BY public.shipments.id;


--
-- Name: suppliers; Type: TABLE; Schema: public; Owner: jdb
--

CREATE TABLE public.suppliers (
    id bigint NOT NULL,
    name character varying(120) NOT NULL,
    country character varying(2) NOT NULL,
    rating integer NOT NULL,
    created_at timestamp with time zone NOT NULL
);


ALTER TABLE public.suppliers OWNER TO jdb;

--
-- Name: suppliers_id_seq; Type: SEQUENCE; Schema: public; Owner: jdb
--

CREATE SEQUENCE public.suppliers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.suppliers_id_seq OWNER TO jdb;

--
-- Name: suppliers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: jdb
--

ALTER SEQUENCE public.suppliers_id_seq OWNED BY public.suppliers.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: jdb
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    email public.email_addr NOT NULL,
    full_name character varying(120) NOT NULL,
    status public.user_status NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL
);


ALTER TABLE public.users OWNER TO jdb;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: jdb
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.users_id_seq OWNER TO jdb;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: jdb
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: v_order_summary; Type: VIEW; Schema: public; Owner: jdb
--

CREATE VIEW public.v_order_summary AS
 SELECT o.id,
    u.email,
    o.status,
    o.total,
    o.created_at
   FROM (public.orders o
     JOIN public.users u ON ((u.id = o.user_id)));


ALTER VIEW public.v_order_summary OWNER TO jdb;

--
-- Name: v_product_stock; Type: VIEW; Schema: public; Owner: jdb
--

CREATE VIEW public.v_product_stock AS
 SELECT p.id,
    p.name,
    COALESCE(sum(i.quantity), (0)::bigint) AS stock
   FROM ((public.products p
     LEFT JOIN public.product_variants v ON ((v.product_id = p.id)))
     LEFT JOIN public.inventory i ON ((i.variant_id = v.id)))
  GROUP BY p.id, p.name;


ALTER VIEW public.v_product_stock OWNER TO jdb;

--
-- Name: v_user_orders; Type: VIEW; Schema: public; Owner: jdb
--

CREATE VIEW public.v_user_orders AS
 SELECT u.id,
    u.email,
    count(o.id) AS orders,
    COALESCE(sum(o.total), (0)::numeric) AS spent
   FROM (public.users u
     LEFT JOIN public.orders o ON ((o.user_id = u.id)))
  GROUP BY u.id, u.email;


ALTER VIEW public.v_user_orders OWNER TO jdb;

--
-- Name: warehouses; Type: TABLE; Schema: public; Owner: jdb
--

CREATE TABLE public.warehouses (
    id bigint NOT NULL,
    code character varying(12) NOT NULL,
    city character varying(80) NOT NULL,
    country character varying(2) NOT NULL
);


ALTER TABLE public.warehouses OWNER TO jdb;

--
-- Name: warehouses_id_seq; Type: SEQUENCE; Schema: public; Owner: jdb
--

CREATE SEQUENCE public.warehouses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.warehouses_id_seq OWNER TO jdb;

--
-- Name: warehouses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: jdb
--

ALTER SEQUENCE public.warehouses_id_seq OWNED BY public.warehouses.id;


--
-- Name: addresses id; Type: DEFAULT; Schema: public; Owner: jdb
--

ALTER TABLE ONLY public.addresses ALTER COLUMN id SET DEFAULT nextval('public.addresses_id_seq'::regclass);


--
-- Name: audit_log id; Type: DEFAULT; Schema: public; Owner: jdb
--

ALTER TABLE ONLY public.audit_log ALTER COLUMN id SET DEFAULT nextval('public.audit_log_id_seq'::regclass);


--
-- Name: cart_items id; Type: DEFAULT; Schema: public; Owner: jdb
--

ALTER TABLE ONLY public.cart_items ALTER COLUMN id SET DEFAULT nextval('public.cart_items_id_seq'::regclass);


--
-- Name: carts id; Type: DEFAULT; Schema: public; Owner: jdb
--

ALTER TABLE ONLY public.carts ALTER COLUMN id SET DEFAULT nextval('public.carts_id_seq'::regclass);


--
-- Name: categories id; Type: DEFAULT; Schema: public; Owner: jdb
--

ALTER TABLE ONLY public.categories ALTER COLUMN id SET DEFAULT nextval('public.categories_id_seq'::regclass);


--
-- Name: events id; Type: DEFAULT; Schema: public; Owner: jdb
--

ALTER TABLE ONLY public.events ALTER COLUMN id SET DEFAULT nextval('public.events_id_seq'::regclass);


--
-- Name: inventory id; Type: DEFAULT; Schema: public; Owner: jdb
--

ALTER TABLE ONLY public.inventory ALTER COLUMN id SET DEFAULT nextval('public.inventory_id_seq'::regclass);


--
-- Name: order_items id; Type: DEFAULT; Schema: public; Owner: jdb
--

ALTER TABLE ONLY public.order_items ALTER COLUMN id SET DEFAULT nextval('public.order_items_id_seq'::regclass);


--
-- Name: orders id; Type: DEFAULT; Schema: public; Owner: jdb
--

ALTER TABLE ONLY public.orders ALTER COLUMN id SET DEFAULT nextval('public.orders_id_seq'::regclass);


--
-- Name: payments id; Type: DEFAULT; Schema: public; Owner: jdb
--

ALTER TABLE ONLY public.payments ALTER COLUMN id SET DEFAULT nextval('public.payments_id_seq'::regclass);


--
-- Name: product_variants id; Type: DEFAULT; Schema: public; Owner: jdb
--

ALTER TABLE ONLY public.product_variants ALTER COLUMN id SET DEFAULT nextval('public.product_variants_id_seq'::regclass);


--
-- Name: products id; Type: DEFAULT; Schema: public; Owner: jdb
--

ALTER TABLE ONLY public.products ALTER COLUMN id SET DEFAULT nextval('public.products_id_seq'::regclass);


--
-- Name: reviews id; Type: DEFAULT; Schema: public; Owner: jdb
--

ALTER TABLE ONLY public.reviews ALTER COLUMN id SET DEFAULT nextval('public.reviews_id_seq'::regclass);


--
-- Name: shipments id; Type: DEFAULT; Schema: public; Owner: jdb
--

ALTER TABLE ONLY public.shipments ALTER COLUMN id SET DEFAULT nextval('public.shipments_id_seq'::regclass);


--
-- Name: suppliers id; Type: DEFAULT; Schema: public; Owner: jdb
--

ALTER TABLE ONLY public.suppliers ALTER COLUMN id SET DEFAULT nextval('public.suppliers_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: jdb
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: warehouses id; Type: DEFAULT; Schema: public; Owner: jdb
--

ALTER TABLE ONLY public.warehouses ALTER COLUMN id SET DEFAULT nextval('public.warehouses_id_seq'::regclass);


--
-- Name: addresses addresses_pkey; Type: CONSTRAINT; Schema: public; Owner: jdb
--

ALTER TABLE ONLY public.addresses
    ADD CONSTRAINT addresses_pkey PRIMARY KEY (id);


--
-- Name: audit_log audit_log_pkey; Type: CONSTRAINT; Schema: public; Owner: jdb
--

ALTER TABLE ONLY public.audit_log
    ADD CONSTRAINT audit_log_pkey PRIMARY KEY (id);


--
-- Name: cart_items cart_items_pkey; Type: CONSTRAINT; Schema: public; Owner: jdb
--

ALTER TABLE ONLY public.cart_items
    ADD CONSTRAINT cart_items_pkey PRIMARY KEY (id);


--
-- Name: carts carts_pkey; Type: CONSTRAINT; Schema: public; Owner: jdb
--

ALTER TABLE ONLY public.carts
    ADD CONSTRAINT carts_pkey PRIMARY KEY (id);


--
-- Name: categories categories_pkey; Type: CONSTRAINT; Schema: public; Owner: jdb
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_pkey PRIMARY KEY (id);


--
-- Name: categories categories_slug_key; Type: CONSTRAINT; Schema: public; Owner: jdb
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_slug_key UNIQUE (slug);


--
-- Name: events events_pkey; Type: CONSTRAINT; Schema: public; Owner: jdb
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_pkey PRIMARY KEY (id);


--
-- Name: inventory inventory_pkey; Type: CONSTRAINT; Schema: public; Owner: jdb
--

ALTER TABLE ONLY public.inventory
    ADD CONSTRAINT inventory_pkey PRIMARY KEY (id);


--
-- Name: inventory inventory_variant_id_warehouse_id_key; Type: CONSTRAINT; Schema: public; Owner: jdb
--

ALTER TABLE ONLY public.inventory
    ADD CONSTRAINT inventory_variant_id_warehouse_id_key UNIQUE (variant_id, warehouse_id);


--
-- Name: order_items order_items_pkey; Type: CONSTRAINT; Schema: public; Owner: jdb
--

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT order_items_pkey PRIMARY KEY (id);


--
-- Name: orders orders_pkey; Type: CONSTRAINT; Schema: public; Owner: jdb
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_pkey PRIMARY KEY (id);


--
-- Name: payments payments_pkey; Type: CONSTRAINT; Schema: public; Owner: jdb
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_pkey PRIMARY KEY (id);


--
-- Name: product_variants product_variants_pkey; Type: CONSTRAINT; Schema: public; Owner: jdb
--

ALTER TABLE ONLY public.product_variants
    ADD CONSTRAINT product_variants_pkey PRIMARY KEY (id);


--
-- Name: product_variants product_variants_sku_key; Type: CONSTRAINT; Schema: public; Owner: jdb
--

ALTER TABLE ONLY public.product_variants
    ADD CONSTRAINT product_variants_sku_key UNIQUE (sku);


--
-- Name: products products_pkey; Type: CONSTRAINT; Schema: public; Owner: jdb
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_pkey PRIMARY KEY (id);


--
-- Name: products products_sku_key; Type: CONSTRAINT; Schema: public; Owner: jdb
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_sku_key UNIQUE (sku);


--
-- Name: reviews reviews_pkey; Type: CONSTRAINT; Schema: public; Owner: jdb
--

ALTER TABLE ONLY public.reviews
    ADD CONSTRAINT reviews_pkey PRIMARY KEY (id);


--
-- Name: shipments shipments_pkey; Type: CONSTRAINT; Schema: public; Owner: jdb
--

ALTER TABLE ONLY public.shipments
    ADD CONSTRAINT shipments_pkey PRIMARY KEY (id);


--
-- Name: suppliers suppliers_pkey; Type: CONSTRAINT; Schema: public; Owner: jdb
--

ALTER TABLE ONLY public.suppliers
    ADD CONSTRAINT suppliers_pkey PRIMARY KEY (id);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: jdb
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: jdb
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: warehouses warehouses_code_key; Type: CONSTRAINT; Schema: public; Owner: jdb
--

ALTER TABLE ONLY public.warehouses
    ADD CONSTRAINT warehouses_code_key UNIQUE (code);


--
-- Name: warehouses warehouses_pkey; Type: CONSTRAINT; Schema: public; Owner: jdb
--

ALTER TABLE ONLY public.warehouses
    ADD CONSTRAINT warehouses_pkey PRIMARY KEY (id);


--
-- Name: orders trg_orders_audit; Type: TRIGGER; Schema: public; Owner: jdb
--

CREATE TRIGGER trg_orders_audit AFTER INSERT ON public.orders FOR EACH ROW EXECUTE FUNCTION public.log_new_order();


--
-- Name: orders trg_orders_updated; Type: TRIGGER; Schema: public; Owner: jdb
--

CREATE TRIGGER trg_orders_updated BEFORE UPDATE ON public.orders FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: products trg_products_updated; Type: TRIGGER; Schema: public; Owner: jdb
--

CREATE TRIGGER trg_products_updated BEFORE UPDATE ON public.products FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: users trg_users_updated; Type: TRIGGER; Schema: public; Owner: jdb
--

CREATE TRIGGER trg_users_updated BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: addresses addresses_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: jdb
--

ALTER TABLE ONLY public.addresses
    ADD CONSTRAINT addresses_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: cart_items cart_items_cart_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: jdb
--

ALTER TABLE ONLY public.cart_items
    ADD CONSTRAINT cart_items_cart_id_fkey FOREIGN KEY (cart_id) REFERENCES public.carts(id);


--
-- Name: cart_items cart_items_variant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: jdb
--

ALTER TABLE ONLY public.cart_items
    ADD CONSTRAINT cart_items_variant_id_fkey FOREIGN KEY (variant_id) REFERENCES public.product_variants(id);


--
-- Name: carts carts_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: jdb
--

ALTER TABLE ONLY public.carts
    ADD CONSTRAINT carts_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: categories categories_parent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: jdb
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.categories(id);


--
-- Name: events events_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: jdb
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: inventory inventory_variant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: jdb
--

ALTER TABLE ONLY public.inventory
    ADD CONSTRAINT inventory_variant_id_fkey FOREIGN KEY (variant_id) REFERENCES public.product_variants(id);


--
-- Name: inventory inventory_warehouse_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: jdb
--

ALTER TABLE ONLY public.inventory
    ADD CONSTRAINT inventory_warehouse_id_fkey FOREIGN KEY (warehouse_id) REFERENCES public.warehouses(id);


--
-- Name: order_items order_items_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: jdb
--

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT order_items_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.orders(id);


--
-- Name: order_items order_items_variant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: jdb
--

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT order_items_variant_id_fkey FOREIGN KEY (variant_id) REFERENCES public.product_variants(id);


--
-- Name: orders orders_address_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: jdb
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_address_id_fkey FOREIGN KEY (address_id) REFERENCES public.addresses(id);


--
-- Name: orders orders_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: jdb
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: payments payments_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: jdb
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.orders(id);


--
-- Name: product_variants product_variants_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: jdb
--

ALTER TABLE ONLY public.product_variants
    ADD CONSTRAINT product_variants_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id);


--
-- Name: products products_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: jdb
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.categories(id);


--
-- Name: products products_supplier_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: jdb
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_supplier_id_fkey FOREIGN KEY (supplier_id) REFERENCES public.suppliers(id);


--
-- Name: reviews reviews_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: jdb
--

ALTER TABLE ONLY public.reviews
    ADD CONSTRAINT reviews_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id);


--
-- Name: reviews reviews_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: jdb
--

ALTER TABLE ONLY public.reviews
    ADD CONSTRAINT reviews_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: shipments shipments_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: jdb
--

ALTER TABLE ONLY public.shipments
    ADD CONSTRAINT shipments_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.orders(id);


--
-- Name: shipments shipments_warehouse_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: jdb
--

ALTER TABLE ONLY public.shipments
    ADD CONSTRAINT shipments_warehouse_id_fkey FOREIGN KEY (warehouse_id) REFERENCES public.warehouses(id);


--
-- PostgreSQL database dump complete
--

\unrestrict vaNjcwe7n5f5j0zk0vmuMkXwianPJ1ViO0o7LmqersPCh6rfWCnVh0xjWvCszN7

