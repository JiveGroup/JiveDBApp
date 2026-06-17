-- E-commerce › marketing data. Full-scale via generate_series (deterministic).
-- campaigns 2,000 · coupons 50,000 · reviews 150,000 · wishlists 120,000 · ad_spend 80,000
SET search_path = marketing;
BEGIN;

-- campaigns → 2,000
INSERT INTO campaigns (id, name, channel, budget, start_date, end_date, status)
SELECT g,
       (ARRAY['Summer Sale','Black Friday','New Arrivals','Flash Deal','Loyalty Boost','Back to School','Holiday Push','Clearance'])[1 + (g % 8)] || ' #' || g,
       (ARRAY['email','social','search','display','affiliate','influencer'])[1 + (g % 6)],
       round((1000 + (g % 50000))::numeric, 2),
       DATE '2025-01-01' + (g % 300),
       DATE '2025-02-01' + (g % 300),
       (ARRAY['planned','active','active','paused','completed'])[1 + (g % 5)]
FROM generate_series(1, 2000) AS g;

-- coupons → 50,000
INSERT INTO coupons (id, code, discount_type, discount_val, max_uses, used_count, expires_at)
SELECT g,
       'SAVE-' || lpad(g::text, 7, '0'),
       (ARRAY['percent','fixed'])[1 + (g % 2)],
       round((1 + (g % 50))::numeric, 2),
       100 + (g % 900),
       g % 100,
       DATE '2025-06-01' + (g % 365)
FROM generate_series(1, 50000) AS g;

-- reviews → 150,000 (product_id 1..100000, customer_id 1..80000)
INSERT INTO reviews (id, product_id, customer_id, rating, title, body, is_verified)
SELECT g,
       ((g - 1) % 100000) + 1,
       ((g - 1) % 80000) + 1,
       1 + (g % 5),
       (ARRAY['Great product','Not bad','Disappointed','Excellent','Average','Would buy again'])[1 + (g % 6)],
       'Auto-generated review body ' || g,
       (g % 3 = 0)
FROM generate_series(1, 150000) AS g;

-- wishlists → 120,000
INSERT INTO wishlists (id, customer_id, variant_sku, added_at)
SELECT g,
       ((g - 1) % 80000) + 1,
       'VAR-' || lpad((((g - 1) % 200000) + 1)::text, 9, '0'),
       TIMESTAMPTZ '2025-01-01 12:00:00' + ((g % 350) || ' days')::interval
FROM generate_series(1, 120000) AS g;

-- ad_spend → 80,000
INSERT INTO ad_spend (id, campaign_id, spend_date, impressions, clicks, conversions, cost)
SELECT g,
       ((g - 1) % 2000) + 1,
       DATE '2025-01-01' + (g % 350),
       1000 + (g % 100000),
       10 + (g % 5000),
       g % 500,
       round((50 + (g % 10000))::numeric, 2)
FROM generate_series(1, 80000) AS g;

COMMIT;

-- Reset sequences for this schema
DO $$
DECLARE r RECORD;
BEGIN
  FOR r IN SELECT table_name FROM information_schema.columns
           WHERE table_schema = 'marketing' AND column_name = 'id' AND column_default LIKE 'nextval%'
  LOOP
    EXECUTE format('SELECT setval(pg_get_serial_sequence(''marketing.%I'', ''id''), COALESCE((SELECT MAX(id) FROM marketing.%I), 1))', r.table_name, r.table_name);
  END LOOP;
END $$;
