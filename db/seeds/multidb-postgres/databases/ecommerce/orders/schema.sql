-- E-commerce › orders schema: order management (5 tables + 1 view).
-- Idempotent: safe to re-run (uses IF NOT EXISTS / OR REPLACE).

CREATE SCHEMA IF NOT EXISTS orders;
SET search_path = orders;

-- 1. customers — shoppers
CREATE TABLE IF NOT EXISTS customers (
    id           SERIAL PRIMARY KEY,
    first_name   VARCHAR(60) NOT NULL,
    last_name    VARCHAR(60) NOT NULL,
    email        VARCHAR(255) NOT NULL UNIQUE,
    phone        VARCHAR(30),
    country      VARCHAR(40),
    city         VARCHAR(60),
    loyalty_tier VARCHAR(20) NOT NULL DEFAULT 'bronze' CHECK (loyalty_tier IN ('bronze','silver','gold','platinum')),
    created_at   TIMESTAMPTZ DEFAULT now()
);

-- 2. orders — customer orders
CREATE TABLE IF NOT EXISTS orders (
    id            SERIAL PRIMARY KEY,
    customer_id   INT NOT NULL REFERENCES customers(id),
    order_number  VARCHAR(30) NOT NULL UNIQUE,
    status        VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','paid','shipped','delivered','cancelled','refunded')),
    subtotal      NUMERIC(14,2) NOT NULL CHECK (subtotal >= 0),
    discount      NUMERIC(12,2) NOT NULL DEFAULT 0,
    shipping_fee  NUMERIC(10,2) NOT NULL DEFAULT 0,
    total         NUMERIC(14,2) NOT NULL CHECK (total >= 0),
    placed_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at    TIMESTAMPTZ DEFAULT now()
);

-- 3. order_items — line items (variant referenced by SKU; catalog lives in another schema)
CREATE TABLE IF NOT EXISTS order_items (
    id           SERIAL PRIMARY KEY,
    order_id     INT NOT NULL REFERENCES orders(id),
    variant_sku  VARCHAR(48) NOT NULL,
    product_name VARCHAR(200) NOT NULL,
    quantity     INT NOT NULL CHECK (quantity > 0),
    unit_price   NUMERIC(12,2) NOT NULL CHECK (unit_price > 0),
    line_total   NUMERIC(14,2) NOT NULL,
    created_at   TIMESTAMPTZ DEFAULT now()
);

-- 4. payments — payment attempts per order
CREATE TABLE IF NOT EXISTS payments (
    id          SERIAL PRIMARY KEY,
    order_id    INT NOT NULL REFERENCES orders(id),
    method      VARCHAR(20) NOT NULL CHECK (method IN ('card','paypal','bank_transfer','cod','wallet')),
    amount      NUMERIC(14,2) NOT NULL CHECK (amount >= 0),
    status      VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','authorized','captured','failed','refunded')),
    paid_at     TIMESTAMPTZ,
    created_at  TIMESTAMPTZ DEFAULT now()
);

-- 5. shipments — order fulfilment
CREATE TABLE IF NOT EXISTS shipments (
    id             SERIAL PRIMARY KEY,
    order_id       INT NOT NULL REFERENCES orders(id),
    carrier        VARCHAR(40) NOT NULL,
    tracking_no    VARCHAR(40) NOT NULL UNIQUE,
    status         VARCHAR(20) NOT NULL DEFAULT 'label_created' CHECK (status IN ('label_created','in_transit','out_for_delivery','delivered','returned')),
    shipped_at     TIMESTAMPTZ,
    delivered_at   TIMESTAMPTZ,
    created_at     TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_ord_orders_customer ON orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_ord_orders_status   ON orders(status);
CREATE INDEX IF NOT EXISTS idx_ord_items_order     ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_ord_payments_order  ON payments(order_id);
CREATE INDEX IF NOT EXISTS idx_ord_shipments_order ON shipments(order_id);

CREATE OR REPLACE VIEW v_revenue_by_tier AS
SELECT
    c.loyalty_tier,
    COUNT(DISTINCT o.id)        AS order_count,
    COALESCE(SUM(o.total), 0)   AS total_revenue,
    ROUND(AVG(o.total), 2)      AS avg_order_value
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.id AND o.status IN ('paid','shipped','delivered')
GROUP BY c.loyalty_tier
ORDER BY total_revenue DESC;
