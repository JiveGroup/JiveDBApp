-- E-commerce › catalog data. Full-scale via generate_series (deterministic).
-- categories 500 · brands 2,000 · suppliers 5,000 · products 100,000 · product_variants 200,000
SET search_path = catalog;
BEGIN;

-- categories → 500 (first 20 are top-level roots, rest nested)
INSERT INTO categories (id, name, slug, parent_id, is_active)
SELECT g,
       (ARRAY['Electronics','Fashion','Home','Beauty','Sports','Toys','Grocery','Automotive','Books','Garden',
              'Office','Pets','Health','Music','Jewelry','Shoes','Baby','Tools','Outdoor','Gaming'])[1 + (g % 20)] || ' / Sub ' || g,
       'cat-' || lpad(g::text, 5, '0'),
       CASE WHEN g <= 20 THEN NULL ELSE (g % 20) + 1 END,
       (g % 17 <> 0)
FROM generate_series(1, 500) AS g;

-- brands → 2,000
INSERT INTO brands (id, name, country, website, rating)
SELECT g,
       (ARRAY['Acme','Globex','Initech','Umbra','Cyber','Stark','Wayne','Oscorp','Lex','Nakatomi','Tyrell','Aperture','Nova','Helios','Sombra'])[1 + (g % 15)] || ' ' || g,
       (ARRAY['US','UK','JP','FR','DE','CN','KR','IT','SE','VN'])[1 + (g % 10)],
       'https://brand' || g || '.example.com',
       round((1 + (g % 40) / 10.0)::numeric, 2)
FROM generate_series(1, 2000) AS g;

-- suppliers → 5,000
INSERT INTO suppliers (id, name, country, contact_email, lead_time_days, status)
SELECT g,
       'Supplier ' || g,
       (ARRAY['CN','VN','IN','US','DE','MX','TR','TH','ID','BD'])[1 + (g % 10)],
       'supplier' || g || '@vendor.example.com',
       1 + (g % 60),
       (ARRAY['active','active','active','inactive','suspended'])[1 + (g % 5)]
FROM generate_series(1, 5000) AS g;

-- products → 100,000
INSERT INTO products (id, category_id, brand_id, supplier_id, name, sku, description, price, cost, status, updated_at)
SELECT g,
       ((g - 1) % 500) + 1,
       ((g - 1) % 2000) + 1,
       ((g - 1) % 5000) + 1,
       (ARRAY['Pro','Max','Ultra','Lite','Eco','Prime','Smart','Mega','Nano','Turbo'])[1 + (g % 10)] || ' ' ||
       (ARRAY['Widget','Gadget','Speaker','Charger','Backpack','Bottle','Lamp','Keyboard','Mouse','Camera'])[1 + ((g / 10) % 10)] || ' ' || g,
       'SKU-' || lpad(g::text, 8, '0'),
       'Auto-generated product description ' || g,
       round((5 + ((g * 37) % 200000) / 100.0)::numeric, 2),
       round((2 + ((g * 19) % 100000) / 100.0)::numeric, 2),
       (ARRAY['active','active','active','active','draft','discontinued','archived'])[1 + (g % 7)],
       '2025-12-01 09:00:00'
FROM generate_series(1, 100000) AS g;

-- product_variants → 200,000
INSERT INTO product_variants (id, product_id, sku, variant_name, color, size, price, stock_qty, weight_g)
SELECT g,
       ((g - 1) % 100000) + 1,
       'VAR-' || lpad(g::text, 9, '0'),
       'Variant ' || g,
       (ARRAY['Black','White','Red','Blue','Green','Silver','Gold','Gray'])[1 + (g % 8)],
       (ARRAY['XS','S','M','L','XL','One Size'])[1 + (g % 6)],
       round((5 + ((g * 41) % 250000) / 100.0)::numeric, 2),
       g % 5000,
       50 + (g % 4000)
FROM generate_series(1, 200000) AS g;

COMMIT;

-- Reset sequences for this schema
DO $$
DECLARE r RECORD;
BEGIN
  FOR r IN SELECT table_name FROM information_schema.columns
           WHERE table_schema = 'catalog' AND column_name = 'id' AND column_default LIKE 'nextval%'
  LOOP
    EXECUTE format('SELECT setval(pg_get_serial_sequence(''catalog.%I'', ''id''), COALESCE((SELECT MAX(id) FROM catalog.%I), 1))', r.table_name, r.table_name);
  END LOOP;
END $$;
