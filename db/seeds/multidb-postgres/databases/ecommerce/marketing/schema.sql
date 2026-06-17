-- E-commerce › marketing schema: growth & engagement (5 tables + 1 view).
-- Idempotent: safe to re-run (uses IF NOT EXISTS / OR REPLACE).

CREATE SCHEMA IF NOT EXISTS marketing;
SET search_path = marketing;

-- 1. campaigns — marketing campaigns
CREATE TABLE IF NOT EXISTS campaigns (
    id            SERIAL PRIMARY KEY,
    name          VARCHAR(150) NOT NULL,
    channel       VARCHAR(20) NOT NULL CHECK (channel IN ('email','social','search','display','affiliate','influencer')),
    budget        NUMERIC(12,2) CHECK (budget >= 0),
    start_date    DATE NOT NULL DEFAULT CURRENT_DATE,
    end_date      DATE,
    status        VARCHAR(20) NOT NULL DEFAULT 'planned' CHECK (status IN ('planned','active','paused','completed')),
    created_at    TIMESTAMPTZ DEFAULT now()
);

-- 2. coupons — discount codes
CREATE TABLE IF NOT EXISTS coupons (
    id            SERIAL PRIMARY KEY,
    code          VARCHAR(30) NOT NULL UNIQUE,
    discount_type VARCHAR(10) NOT NULL CHECK (discount_type IN ('percent','fixed')),
    discount_val  NUMERIC(10,2) NOT NULL CHECK (discount_val > 0),
    max_uses      INT CHECK (max_uses >= 0),
    used_count    INT NOT NULL DEFAULT 0 CHECK (used_count >= 0),
    expires_at    DATE,
    created_at    TIMESTAMPTZ DEFAULT now()
);

-- 3. reviews — product reviews (product_id / customer_id are external references, no FK)
CREATE TABLE IF NOT EXISTS reviews (
    id           SERIAL PRIMARY KEY,
    product_id   INT NOT NULL,
    customer_id  INT NOT NULL,
    rating       INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    title        VARCHAR(150),
    body         TEXT,
    is_verified  BOOLEAN DEFAULT false,
    created_at   TIMESTAMPTZ DEFAULT now()
);

-- 4. wishlists — saved items (customer_id / variant_sku are external references)
CREATE TABLE IF NOT EXISTS wishlists (
    id           SERIAL PRIMARY KEY,
    customer_id  INT NOT NULL,
    variant_sku  VARCHAR(48) NOT NULL,
    added_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at   TIMESTAMPTZ DEFAULT now()
);

-- 5. ad_spend — daily campaign spend & performance
CREATE TABLE IF NOT EXISTS ad_spend (
    id            SERIAL PRIMARY KEY,
    campaign_id   INT NOT NULL REFERENCES campaigns(id),
    spend_date    DATE NOT NULL DEFAULT CURRENT_DATE,
    impressions   INT NOT NULL DEFAULT 0 CHECK (impressions >= 0),
    clicks        INT NOT NULL DEFAULT 0 CHECK (clicks >= 0),
    conversions   INT NOT NULL DEFAULT 0 CHECK (conversions >= 0),
    cost          NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (cost >= 0),
    created_at    TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_mkt_reviews_product   ON reviews(product_id);
CREATE INDEX IF NOT EXISTS idx_mkt_wishlists_customer ON wishlists(customer_id);
CREATE INDEX IF NOT EXISTS idx_mkt_adspend_campaign  ON ad_spend(campaign_id);

CREATE OR REPLACE VIEW v_campaign_performance AS
SELECT
    c.name        AS campaign,
    c.channel,
    COALESCE(SUM(a.impressions), 0) AS impressions,
    COALESCE(SUM(a.clicks), 0)      AS clicks,
    COALESCE(SUM(a.conversions), 0) AS conversions,
    COALESCE(SUM(a.cost), 0)        AS spend,
    CASE WHEN SUM(a.clicks) > 0
         THEN ROUND(100.0 * SUM(a.conversions) / SUM(a.clicks), 2)
         ELSE 0 END                 AS conversion_rate
FROM campaigns c
LEFT JOIN ad_spend a ON a.campaign_id = c.id
GROUP BY c.id, c.name, c.channel
ORDER BY spend DESC;
