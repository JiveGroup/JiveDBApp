-- E-commerce › catalog schema: product catalog (5 tables + 1 view).
-- Idempotent: safe to re-run (uses IF NOT EXISTS / OR REPLACE).

CREATE SCHEMA IF NOT EXISTS catalog;
SET search_path = catalog;

-- 1. categories — category tree
CREATE TABLE IF NOT EXISTS categories (
    id         SERIAL PRIMARY KEY,
    name       VARCHAR(100) NOT NULL,
    slug       VARCHAR(120) NOT NULL UNIQUE,
    parent_id  INT REFERENCES categories(id),
    is_active  BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 2. brands — manufacturer / brand master
CREATE TABLE IF NOT EXISTS brands (
    id         SERIAL PRIMARY KEY,
    name       VARCHAR(120) NOT NULL,
    country    VARCHAR(40),
    website    VARCHAR(200),
    rating     NUMERIC(3,2) CHECK (rating BETWEEN 0 AND 5),
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 3. suppliers — vendor master
CREATE TABLE IF NOT EXISTS suppliers (
    id             SERIAL PRIMARY KEY,
    name           VARCHAR(120) NOT NULL,
    country        VARCHAR(40),
    contact_email  VARCHAR(255),
    lead_time_days INT CHECK (lead_time_days >= 0),
    status         VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (status IN ('active','inactive','suspended')),
    created_at     TIMESTAMPTZ DEFAULT now()
);

-- 4. products — sellable product master
CREATE TABLE IF NOT EXISTS products (
    id          SERIAL PRIMARY KEY,
    category_id INT NOT NULL REFERENCES categories(id),
    brand_id    INT REFERENCES brands(id),
    supplier_id INT REFERENCES suppliers(id),
    name        VARCHAR(200) NOT NULL,
    sku         VARCHAR(40) NOT NULL UNIQUE,
    description TEXT,
    price       NUMERIC(12,2) NOT NULL CHECK (price > 0),
    cost        NUMERIC(12,2) NOT NULL CHECK (cost > 0),
    status      VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (status IN ('active','draft','discontinued','archived')),
    created_at  TIMESTAMPTZ DEFAULT now(),
    updated_at  TIMESTAMPTZ DEFAULT now()
);

-- 5. product_variants — per-SKU sellable variants
CREATE TABLE IF NOT EXISTS product_variants (
    id           SERIAL PRIMARY KEY,
    product_id   INT NOT NULL REFERENCES products(id),
    sku          VARCHAR(48) NOT NULL UNIQUE,
    variant_name VARCHAR(120) NOT NULL,
    color        VARCHAR(30),
    size         VARCHAR(20),
    price        NUMERIC(12,2) NOT NULL CHECK (price > 0),
    stock_qty    INT NOT NULL DEFAULT 0 CHECK (stock_qty >= 0),
    weight_g     INT CHECK (weight_g >= 0),
    created_at   TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_cat_products_category ON products(category_id);
CREATE INDEX IF NOT EXISTS idx_cat_products_brand    ON products(brand_id);
CREATE INDEX IF NOT EXISTS idx_cat_products_status   ON products(status);
CREATE INDEX IF NOT EXISTS idx_cat_variants_product  ON product_variants(product_id);

CREATE OR REPLACE VIEW v_catalog_summary AS
SELECT
    c.name                         AS category,
    COUNT(DISTINCT p.id)           AS product_count,
    COUNT(v.id)                    AS variant_count,
    ROUND(AVG(p.price), 2)         AS avg_price,
    COALESCE(SUM(v.stock_qty), 0)  AS total_stock
FROM categories c
LEFT JOIN products p          ON p.category_id = c.id
LEFT JOIN product_variants v  ON v.product_id = p.id
GROUP BY c.id, c.name
ORDER BY product_count DESC;
