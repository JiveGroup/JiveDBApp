-- ============================================================================
-- PostgreSQL Schema Objects — DEMO (chạy tuần tự từng câu)
-- Dựa trên docs/POSTGRES_SCHEMA_OBJECTS.md. Tạo đầy đủ mỗi loại đối tượng để
-- hiển thị trong cây sidebar: Tables, Views, Materialized Views, Foreign Tables,
-- Sequences, Types, Domains, Collations, Functions, Procedures, Trigger Functions,
-- Aggregates, Operators, FTS (Parser/Template/Dictionary/Configuration).
--
-- AN TOÀN: mọi đối tượng nằm trong schema riêng "demo_objects" và dùng tên đầy đủ
-- (demo_objects.*). KHÔNG đụng tới bảng/đối tượng có sẵn của bạn. Dọn sạch chỉ bằng
-- DROP SCHEMA demo_objects CASCADE (đã có ở đầu file → chạy lại nhiều lần được).
--
-- Lưu ý khi chạy:
--   * PostgreSQL (khuyến nghị 14+; cần ICU + postgres_fdw — đều có sẵn ở bản chuẩn).
--   * Các khối FUNCTION/PROCEDURE dùng dollar-quote ($$ ... $$): chạy CẢ KHỐI như
--     MỘT câu lệnh (đừng cắt theo dấu ';' bên trong khối).
--   * Foreign table chỉ tạo METADATA (không cần remote thật để hiển thị trong tree).
-- ============================================================================


-- ── 0. Dọn dẹp + tạo schema demo ────────────────────────────────────────────
DROP SCHEMA IF EXISTS demo_objects CASCADE;
DROP SERVER IF EXISTS demo_remote CASCADE;   -- server FDW là toàn-cục, không thuộc schema
CREATE SCHEMA demo_objects;


-- ── 2. Tables (Bảng) ────────────────────────────────────────────────────────
CREATE TABLE demo_objects.users (
  id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  email       text NOT NULL UNIQUE,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE demo_objects.products (
  id    bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name  text NOT NULL
);

CREATE TABLE demo_objects.orders (
  id            bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  customer_id   bigint,
  product_name  text,
  amount        numeric NOT NULL DEFAULT 0,
  created_at    timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE demo_objects.order_items (
  id        bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  order_id  bigint NOT NULL,
  price     numeric NOT NULL,
  qty       int NOT NULL DEFAULT 1
);

-- Dữ liệu mẫu (cho view / matview / aggregate / function dùng sau).
INSERT INTO demo_objects.users (email) VALUES ('a@example.com'), ('b@example.com');
INSERT INTO demo_objects.products (name) VALUES ('Cà phê'), ('Ăn sáng'), ('Bánh mì'), ('Trà');
INSERT INTO demo_objects.orders (customer_id, product_name, amount) VALUES
  (1, 'Keyboard', 120), (1, 'Mouse', 45), (2, 'Monitor', 300);
INSERT INTO demo_objects.order_items (order_id, price, qty) VALUES (1, 60, 2), (1, 45, 1), (2, 300, 1);


-- ── 6. Sequences (Dãy số tuần tự) ───────────────────────────────────────────
CREATE SEQUENCE demo_objects.order_no_seq START 1000 INCREMENT 1;
CREATE TABLE demo_objects.invoices (
  no    bigint PRIMARY KEY DEFAULT nextval('demo_objects.order_no_seq'),
  note  text
);
INSERT INTO demo_objects.invoices (note) VALUES ('demo invoice');   -- no = 1001


-- ── 7. Types (enum / composite / range) ─────────────────────────────────────
CREATE TYPE demo_objects.order_status AS ENUM ('pending', 'paid', 'shipped');
CREATE TYPE demo_objects.address AS (street text, city text, zip text);  -- composite
CREATE TYPE demo_objects.int_range AS RANGE (subtype = int4);            -- range
ALTER TABLE demo_objects.orders
  ADD COLUMN status demo_objects.order_status NOT NULL DEFAULT 'pending';


-- ── 8. Domains (Miền giá trị) ───────────────────────────────────────────────
CREATE DOMAIN demo_objects.email_address AS text
  CHECK (VALUE ~ '^[^@\s]+@[^@\s]+\.[^@\s]+$');
CREATE TABLE demo_objects.contacts (
  id    bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  email demo_objects.email_address NOT NULL
);
INSERT INTO demo_objects.contacts (email) VALUES ('valid@example.com');   -- hợp lệ
-- INSERT INTO demo_objects.contacts (email) VALUES ('invalid');          -- (bỏ comment → lỗi CHECK)


-- ── 9. Collations (Quy tắc so sánh/sắp xếp) ─────────────────────────────────
CREATE COLLATION demo_objects.vi_coll (provider = icu, locale = 'vi-VN');

-- ── 3. Views (Khung nhìn) ───────────────────────────────────────────────────
CREATE VIEW demo_objects.active_users AS
SELECT id, email FROM demo_objects.users WHERE created_at > now() - interval '30 days';

-- ── 4. Materialized Views ───────────────────────────────────────────────────
CREATE MATERIALIZED VIEW demo_objects.daily_sales AS
SELECT date_trunc('day', created_at) AS day, sum(amount) AS total
FROM demo_objects.orders GROUP BY 1;
CREATE UNIQUE INDEX daily_sales_day_uidx ON demo_objects.daily_sales (day);
REFRESH MATERIALIZED VIEW demo_objects.daily_sales;

-- ── 10. Functions (Hàm) ─────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION demo_objects.order_total(p_order_id bigint)
RETURNS numeric LANGUAGE sql AS $$
  SELECT coalesce(sum(price * qty), 0) FROM demo_objects.order_items WHERE order_id = p_order_id;
$$;

-- ── 11. Procedures (Thủ tục) ────────────────────────────────────────────────
-- (Tài liệu có thể đặt COMMIT bên trong để kiểm soát transaction; demo bỏ COMMIT
--  cho an toàn ở mọi chế độ. Gọi bằng CALL.)
CREATE OR REPLACE PROCEDURE demo_objects.archive_old_orders(p_days int)
LANGUAGE plpgsql AS $$
BEGIN
  DELETE FROM demo_objects.orders WHERE created_at < now() - make_interval(days => p_days);
END;
$$;
CALL demo_objects.archive_old_orders(3650);   -- xoá orders cũ hơn ~10 năm (demo: thường không xoá gì)


-- ── 12. Trigger Functions (Hàm trigger) + Trigger ──────────────────────────
CREATE OR REPLACE FUNCTION demo_objects.set_updated_at()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;
CREATE TRIGGER trg_users_updated
  BEFORE UPDATE ON demo_objects.users
  FOR EACH ROW EXECUTE FUNCTION demo_objects.set_updated_at();
UPDATE demo_objects.users SET email = 'a2@example.com' WHERE email = 'a@example.com';

-- ── 13. Aggregates (Hàm tổng hợp) ───────────────────────────────────────────
CREATE FUNCTION demo_objects.concat_sfunc(state text, value text)
RETURNS text LANGUAGE sql IMMUTABLE AS $$ SELECT coalesce(state || ',', '') || value $$;
CREATE AGGREGATE demo_objects.comma_join(text) (
  SFUNC = demo_objects.concat_sfunc,
  STYPE = text
);



-- ── 14. Operators (Toán tử) ─────────────────────────────────────────────────
CREATE FUNCTION demo_objects.demo_point_eq(p1 point, p2 point) RETURNS boolean
LANGUAGE sql IMMUTABLE AS $$ SELECT p1[0] = p2[0] AND p1[1] = p2[1] $$;
CREATE OPERATOR demo_objects.#=# (LEFTARG = point, RIGHTARG = point, FUNCTION = demo_objects.demo_point_eq);

-- ── 5. Foreign Tables (Bảng ngoại) — chỉ tạo metadata ───────────────────────
CREATE EXTENSION IF NOT EXISTS postgres_fdw;
CREATE SERVER demo_remote FOREIGN DATA WRAPPER postgres_fdw
  OPTIONS (host 'localhost', dbname 'postgres', port '5432');
CREATE USER MAPPING FOR CURRENT_USER SERVER demo_remote
  OPTIONS (user 'postgres', password 'postgres');
CREATE FOREIGN TABLE demo_objects.demo_foreign_orders (id bigint, amount numeric)
  SERVER demo_remote OPTIONS (schema_name 'public', table_name 'orders');
-- SELECT * FROM demo_objects.demo_foreign_orders;  -- cần remote thật mới chạy


-- ── 15–18. FTS: Parser → Template → Dictionary → Configuration ──────────────
CREATE TEXT SEARCH PARSER demo_objects.demo_parser (
  START = prsd_start, GETTOKEN = prsd_nexttoken, END = prsd_end, LEXTYPES = prsd_lextype
);
CREATE TEXT SEARCH TEMPLATE demo_objects.demo_template (
  INIT = dsimple_init, LEXIZE = dsimple_lexize
);
CREATE TEXT SEARCH DICTIONARY demo_objects.demo_dict (TEMPLATE = demo_objects.demo_template);
CREATE TEXT SEARCH DICTIONARY demo_objects.en_stem (TEMPLATE = snowball, Language = english);
CREATE TEXT SEARCH CONFIGURATION demo_objects.demo_english (PARSER = demo_objects.demo_parser);
ALTER TEXT SEARCH CONFIGURATION demo_objects.demo_english
  ALTER MAPPING FOR asciiword, word WITH demo_objects.en_stem;

CREATE TABLE demo_objects.docs (
  id   bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  body text
);
INSERT INTO demo_objects.docs (body) VALUES ('running runs ran'), ('postgres full text search');
CREATE INDEX idx_docs_fts ON demo_objects.docs USING gin (to_tsvector('demo_objects.demo_english', body));

-- ============================================================================
-- HẾT. Refresh sidebar → mở schema "demo_objects" để thấy toàn bộ đối tượng.
-- Xoá sạch: DROP SCHEMA demo_objects CASCADE;  (+ DROP SERVER demo_remote CASCADE;)
-- ============================================================================

SELECT * FROM demo_objects.users;
SELECT nextval('demo_objects.order_no_seq');         -- 1000
SELECT name FROM demo_objects.products ORDER BY name COLLATE demo_objects.vi_coll;
SELECT count(*) FROM demo_objects.active_users;
SELECT * FROM demo_objects.daily_sales;
SELECT demo_objects.order_total(1);    -- 165
SELECT email, updated_at FROM demo_objects.users;
SELECT customer_id, demo_objects.comma_join(product_name)
FROM demo_objects.orders GROUP BY customer_id;
SELECT point(1, 2) OPERATOR(demo_objects.#=#) point(1, 2);    -- true
SELECT to_tsvector('demo_objects.demo_english', 'running runs ran PostgreSQL');
SELECT id, body FROM demo_objects.docs
WHERE to_tsvector('demo_objects.demo_english', body) @@ to_tsquery('demo_objects.demo_english', 'run');
