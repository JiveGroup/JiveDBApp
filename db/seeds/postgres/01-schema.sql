-- PostgreSQL: object types + 17 bảng + views + triggers
SET client_min_messages = warning;
DROP TYPE IF EXISTS user_status CASCADE;
CREATE TYPE user_status AS ENUM ('active', 'pending', 'blocked');
DROP TYPE IF EXISTS order_status CASCADE;
CREATE TYPE order_status AS ENUM ('pending', 'paid', 'shipped', 'delivered', 'cancelled');
DROP TYPE IF EXISTS payment_method CASCADE;
CREATE TYPE payment_method AS ENUM ('card', 'paypal', 'bank', 'cod');
DROP TYPE IF EXISTS payment_status CASCADE;
CREATE TYPE payment_status AS ENUM ('pending', 'completed', 'failed', 'refunded');
DROP TYPE IF EXISTS cart_status CASCADE;
CREATE TYPE cart_status AS ENUM ('open', 'converted', 'abandoned');
DROP TYPE IF EXISTS shipment_status CASCADE;
CREATE TYPE shipment_status AS ENUM ('preparing', 'shipped', 'in_transit', 'delivered', 'returned');
DROP TYPE IF EXISTS product_status CASCADE;
CREATE TYPE product_status AS ENUM ('active', 'draft', 'discontinued');
DROP DOMAIN IF EXISTS email_addr CASCADE;
CREATE DOMAIN email_addr AS varchar(255) CHECK (VALUE ~ '@');
DROP TYPE IF EXISTS geo_point CASCADE;
CREATE TYPE geo_point AS (lat double precision, lng double precision);

CREATE TABLE users (
  id bigserial PRIMARY KEY,
  email email_addr NOT NULL UNIQUE,
  full_name varchar(120) NOT NULL,
  status user_status NOT NULL,
  created_at timestamptz NOT NULL,
  updated_at timestamptz NOT NULL
);
CREATE TABLE addresses (
  id bigserial PRIMARY KEY,
  user_id bigint NOT NULL,
  line1 varchar(160) NOT NULL,
  city varchar(80) NOT NULL,
  country varchar(2) NOT NULL,
  is_default boolean NOT NULL,
  created_at timestamptz NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id)
);
CREATE TABLE categories (
  id bigserial PRIMARY KEY,
  name varchar(120) NOT NULL,
  slug varchar(140) NOT NULL UNIQUE,
  parent_id bigint,
  created_at timestamptz NOT NULL,
  FOREIGN KEY (parent_id) REFERENCES categories(id)
);
CREATE TABLE suppliers (
  id bigserial PRIMARY KEY,
  name varchar(120) NOT NULL,
  country varchar(2) NOT NULL,
  rating integer NOT NULL,
  created_at timestamptz NOT NULL
);
CREATE TABLE warehouses (
  id bigserial PRIMARY KEY,
  code varchar(12) NOT NULL UNIQUE,
  city varchar(80) NOT NULL,
  country varchar(2) NOT NULL
);
CREATE TABLE products (
  id bigserial PRIMARY KEY,
  category_id bigint NOT NULL,
  supplier_id bigint NOT NULL,
  name varchar(200) NOT NULL,
  sku varchar(40) NOT NULL UNIQUE,
  price numeric(12,2) NOT NULL,
  status product_status NOT NULL,
  created_at timestamptz NOT NULL,
  updated_at timestamptz NOT NULL,
  FOREIGN KEY (category_id) REFERENCES categories(id),
  FOREIGN KEY (supplier_id) REFERENCES suppliers(id)
);
CREATE TABLE product_variants (
  id bigserial PRIMARY KEY,
  product_id bigint NOT NULL,
  sku varchar(48) NOT NULL UNIQUE,
  color varchar(24) NOT NULL,
  size varchar(8) NOT NULL,
  price numeric(12,2) NOT NULL,
  created_at timestamptz NOT NULL,
  FOREIGN KEY (product_id) REFERENCES products(id)
);
CREATE TABLE inventory (
  id bigserial PRIMARY KEY,
  variant_id bigint NOT NULL,
  warehouse_id bigint NOT NULL,
  quantity integer NOT NULL,
  updated_at timestamptz NOT NULL,
  FOREIGN KEY (variant_id) REFERENCES product_variants(id),
  FOREIGN KEY (warehouse_id) REFERENCES warehouses(id),
  UNIQUE (variant_id, warehouse_id)
);
CREATE TABLE carts (
  id bigserial PRIMARY KEY,
  user_id bigint NOT NULL,
  status cart_status NOT NULL,
  created_at timestamptz NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id)
);
CREATE TABLE cart_items (
  id bigserial PRIMARY KEY,
  cart_id bigint NOT NULL,
  variant_id bigint NOT NULL,
  quantity integer NOT NULL,
  added_at timestamptz NOT NULL,
  FOREIGN KEY (cart_id) REFERENCES carts(id),
  FOREIGN KEY (variant_id) REFERENCES product_variants(id)
);
CREATE TABLE orders (
  id bigserial PRIMARY KEY,
  user_id bigint NOT NULL,
  address_id bigint NOT NULL,
  status order_status NOT NULL,
  total numeric(12,2) NOT NULL,
  payment_method payment_method NOT NULL,
  created_at timestamptz NOT NULL,
  updated_at timestamptz NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (address_id) REFERENCES addresses(id)
);
CREATE TABLE order_items (
  id bigserial PRIMARY KEY,
  order_id bigint NOT NULL,
  variant_id bigint NOT NULL,
  quantity integer NOT NULL,
  unit_price numeric(12,2) NOT NULL,
  FOREIGN KEY (order_id) REFERENCES orders(id),
  FOREIGN KEY (variant_id) REFERENCES product_variants(id)
);
CREATE TABLE payments (
  id bigserial PRIMARY KEY,
  order_id bigint NOT NULL,
  method payment_method NOT NULL,
  status payment_status NOT NULL,
  amount numeric(12,2) NOT NULL,
  paid_at timestamptz,
  FOREIGN KEY (order_id) REFERENCES orders(id)
);
CREATE TABLE shipments (
  id bigserial PRIMARY KEY,
  order_id bigint NOT NULL,
  warehouse_id bigint NOT NULL,
  carrier varchar(16) NOT NULL,
  tracking varchar(24) NOT NULL,
  status shipment_status NOT NULL,
  shipped_at timestamptz,
  FOREIGN KEY (order_id) REFERENCES orders(id),
  FOREIGN KEY (warehouse_id) REFERENCES warehouses(id)
);
CREATE TABLE reviews (
  id bigserial PRIMARY KEY,
  product_id bigint NOT NULL,
  user_id bigint NOT NULL,
  rating integer NOT NULL,
  body varchar(240) NOT NULL,
  created_at timestamptz NOT NULL,
  FOREIGN KEY (product_id) REFERENCES products(id),
  FOREIGN KEY (user_id) REFERENCES users(id)
);
CREATE TABLE events (
  id bigserial PRIMARY KEY,
  user_id bigint,
  kind varchar(24) NOT NULL,
  payload varchar(200) NOT NULL,
  created_at timestamptz NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id)
);
CREATE TABLE audit_log (
  id bigserial PRIMARY KEY,
  entity varchar(24) NOT NULL,
  entity_id integer NOT NULL,
  action varchar(16) NOT NULL,
  at timestamptz NOT NULL
);

CREATE VIEW v_order_summary AS
  SELECT o.id, u.email, o.status, o.total, o.created_at
  FROM orders o JOIN users u ON u.id = o.user_id;
CREATE VIEW v_product_stock AS
  SELECT p.id, p.name, COALESCE(SUM(i.quantity), 0) AS stock
  FROM products p
  LEFT JOIN product_variants v ON v.product_id = p.id
  LEFT JOIN inventory i ON i.variant_id = v.id
  GROUP BY p.id, p.name;
CREATE VIEW v_user_orders AS
  SELECT u.id, u.email, COUNT(o.id) AS orders, COALESCE(SUM(o.total), 0) AS spent
  FROM users u LEFT JOIN orders o ON o.user_id = u.id
  GROUP BY u.id, u.email;

-- Functions (đa dạng kiểu)
-- 1. Scalar SQL, IMMUTABLE
CREATE OR REPLACE FUNCTION fn_full_name(first_name text, last_name text)
RETURNS text LANGUAGE sql IMMUTABLE AS $$
  SELECT trim(coalesce(first_name, '') || ' ' || coalesce(last_name, ''));
$$;

-- 2. Tham số mặc định
CREATE OR REPLACE FUNCTION fn_apply_discount(price numeric, pct numeric DEFAULT 10)
RETURNS numeric LANGUAGE sql IMMUTABLE AS $$
  SELECT round(price * (1 - pct / 100.0), 2);
$$;

-- 3. Tham số VARIADIC
CREATE OR REPLACE FUNCTION fn_concat_tags(VARIADIC tags text[])
RETURNS text LANGUAGE sql IMMUTABLE AS $$
  SELECT array_to_string(tags, ', ');
$$;

-- 4. plpgsql, đọc dữ liệu (STABLE)
CREATE OR REPLACE FUNCTION fn_order_total(p_order_id bigint)
RETURNS numeric LANGUAGE plpgsql STABLE AS $$
DECLARE total numeric;
BEGIN
  SELECT COALESCE(SUM(quantity * unit_price), 0) INTO total FROM order_items WHERE order_id = p_order_id;
  RETURN total;
END; $$;

-- 5. Scalar SQL đọc bảng
CREATE OR REPLACE FUNCTION fn_user_order_count(p_user_id bigint)
RETURNS integer LANGUAGE sql STABLE AS $$
  SELECT count(*)::int FROM orders WHERE user_id = p_user_id;
$$;

-- 6. RETURNS TABLE + tham số mặc định
CREATE OR REPLACE FUNCTION fn_recent_orders(p_days integer DEFAULT 30)
RETURNS TABLE(id bigint, user_id bigint, total numeric, created_at timestamptz)
LANGUAGE sql STABLE AS $$
  SELECT id, user_id, total, created_at FROM orders
  WHERE created_at >= now() - make_interval(days => p_days)
  ORDER BY created_at DESC;
$$;

-- 7. RETURNS SETOF
CREATE OR REPLACE FUNCTION fn_user_emails()
RETURNS SETOF text LANGUAGE sql STABLE AS $$
  SELECT email FROM users ORDER BY id;
$$;

-- 8. Trả về JSON
CREATE OR REPLACE FUNCTION fn_order_summary_json(p_order_id bigint)
RETURNS json LANGUAGE sql STABLE AS $$
  SELECT json_build_object(
    'id', o.id, 'status', o.status, 'total', o.total,
    'items', (SELECT count(*) FROM order_items oi WHERE oi.order_id = o.id)
  ) FROM orders o WHERE o.id = p_order_id;
$$;

-- 9. Tham số kiểu ENUM + CASE (plpgsql)
CREATE OR REPLACE FUNCTION fn_label_order_status(s order_status)
RETURNS text LANGUAGE plpgsql IMMUTABLE AS $$
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

-- 10. Trigger function (RETURNS trigger)
CREATE OR REPLACE FUNCTION fn_set_row_timestamp()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END; $$;

-- Bonus: PROCEDURE (không trả về)
CREATE OR REPLACE PROCEDURE sp_touch_order(p_order_id bigint)
LANGUAGE plpgsql AS $$
BEGIN
  UPDATE orders SET updated_at = now() WHERE id = p_order_id;
END; $$;


CREATE OR REPLACE FUNCTION set_updated_at() RETURNS trigger AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END; $$ LANGUAGE plpgsql;
CREATE TRIGGER trg_users_updated BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_products_updated BEFORE UPDATE ON products FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_orders_updated BEFORE UPDATE ON orders FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE OR REPLACE FUNCTION log_new_order() RETURNS trigger AS $$
BEGIN INSERT INTO audit_log(entity, entity_id, action, at) VALUES ('order', NEW.id, 'insert', now()); RETURN NEW; END; $$ LANGUAGE plpgsql;
CREATE TRIGGER trg_orders_audit AFTER INSERT ON orders FOR EACH ROW EXECUTE FUNCTION log_new_order();
