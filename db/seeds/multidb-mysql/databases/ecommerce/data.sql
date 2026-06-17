-- jdb_ecommerce data — full-scale, deterministic (derived from row number `g`).
-- Uses a temporary numbers table `seq` (1..200000) built from digit cross-joins.
SET FOREIGN_KEY_CHECKS = 0;
SET UNIQUE_CHECKS = 0;

DROP TEMPORARY TABLE IF EXISTS seq;
CREATE TEMPORARY TABLE seq (g INT UNSIGNED NOT NULL PRIMARY KEY);
INSERT INTO seq (g)
SELECT g FROM (
  SELECT 1 + d0.i + d1.i*10 + d2.i*100 + d3.i*1000 + d4.i*10000 + d5.i*100000 AS g
  FROM       (SELECT 0 i UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) d0
  CROSS JOIN (SELECT 0 i UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) d1
  CROSS JOIN (SELECT 0 i UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) d2
  CROSS JOIN (SELECT 0 i UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) d3
  CROSS JOIN (SELECT 0 i UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) d4
  CROSS JOIN (SELECT 0 i UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) d5
) t WHERE g <= 200000;

-- catalog_categories → 500
INSERT INTO catalog_categories (id, name, slug, parent_id, is_active, created_at)
SELECT g,
       CONCAT(ELT((g % 20) + 1,'Electronics','Fashion','Home','Beauty','Sports','Toys','Grocery','Automotive','Books','Garden','Office','Pets','Health','Music','Jewelry','Shoes','Baby','Tools','Outdoor','Gaming'), ' / Sub ', g),
       CONCAT('cat-', LPAD(g, 5, '0')),
       IF(g <= 20, NULL, (g % 20) + 1),
       (g % 17 <> 0),
       DATE_ADD('2025-01-01 09:00:00', INTERVAL (g % 300) DAY)
FROM seq WHERE g <= 500;

-- catalog_brands → 2000
INSERT INTO catalog_brands (id, name, country, website, rating, created_at)
SELECT g,
       CONCAT(ELT((g % 15) + 1,'Acme','Globex','Initech','Umbra','Cyber','Stark','Wayne','Oscorp','Lex','Nakatomi','Tyrell','Aperture','Nova','Helios','Sombra'), ' ', g),
       ELT((g % 10) + 1,'US','UK','JP','FR','DE','CN','KR','IT','SE','VN'),
       CONCAT('https://brand', g, '.example.com'),
       ROUND((10 + (g % 40)) / 10, 2),
       DATE_ADD('2024-06-01 09:00:00', INTERVAL (g % 300) DAY)
FROM seq WHERE g <= 2000;

-- catalog_suppliers → 5000
INSERT INTO catalog_suppliers (id, name, country, contact_email, lead_time_days, status, created_at)
SELECT g,
       CONCAT('Supplier ', g),
       ELT((g % 10) + 1,'CN','VN','IN','US','DE','MX','TR','TH','ID','BD'),
       CONCAT('supplier', g, '@vendor.example.com'),
       1 + (g % 60),
       ELT((g % 5) + 1,'active','active','active','inactive','suspended'),
       DATE_ADD('2024-01-01 09:00:00', INTERVAL (g % 400) DAY)
FROM seq WHERE g <= 5000;

-- catalog_products → 100000
INSERT INTO catalog_products (id, category_id, brand_id, supplier_id, name, sku, description, price, cost, status, created_at, updated_at)
SELECT g,
       ((g - 1) % 500) + 1,
       ((g - 1) % 2000) + 1,
       ((g - 1) % 5000) + 1,
       CONCAT(ELT((g % 10) + 1,'Pro','Max','Ultra','Lite','Eco','Prime','Smart','Mega','Nano','Turbo'), ' ',
              ELT((FLOOR(g / 10) % 10) + 1,'Widget','Gadget','Speaker','Charger','Backpack','Bottle','Lamp','Keyboard','Mouse','Camera'), ' ', g),
       CONCAT('SKU-', LPAD(g, 8, '0')),
       CONCAT('Auto-generated product description ', g),
       ROUND((500 + (g * 37) % 200000) / 100, 2),
       ROUND((200 + (g * 19) % 100000) / 100, 2),
       ELT((g % 7) + 1,'active','active','active','active','draft','discontinued','archived'),
       DATE_ADD('2024-06-01 09:00:00', INTERVAL (g % 400) DAY),
       '2025-12-01 09:00:00'
FROM seq WHERE g <= 100000;

-- catalog_product_variants → 200000
INSERT INTO catalog_product_variants (id, product_id, sku, variant_name, color, size, price, stock_qty, weight_g, created_at)
SELECT g,
       ((g - 1) % 100000) + 1,
       CONCAT('VAR-', LPAD(g, 9, '0')),
       CONCAT('Variant ', g),
       ELT((g % 8) + 1,'Black','White','Red','Blue','Green','Silver','Gold','Gray'),
       ELT((g % 6) + 1,'XS','S','M','L','XL','One Size'),
       ROUND((500 + (g * 41) % 250000) / 100, 2),
       g % 5000,
       50 + (g % 4000),
       DATE_ADD('2024-06-01 09:00:00', INTERVAL (g % 400) DAY)
FROM seq WHERE g <= 200000;

-- orders_customers → 80000
INSERT INTO orders_customers (id, first_name, last_name, email, phone, country, city, loyalty_tier, created_at)
SELECT g,
       ELT((g % 20) + 1,'Alice','Bob','Carol','Dave','Eve','Frank','Grace','Hank','Iris','Jack','Kate','Leo','Mia','Nick','Olivia','Paul','Quinn','Rose','Sam','Tina'),
       ELT((FLOOR(g / 20) % 20) + 1,'Smith','Johnson','Williams','Brown','Jones','Garcia','Miller','Davis','Nguyen','Tran','Lee','Walker','Young','King','Scott','Green','Adams','Baker','Nelson','Carter'),
       CONCAT('shopper', g, '@mail.example.com'),
       CONCAT('+1555', LPAD(1000000 + g, 8, '0')),
       ELT((g % 10) + 1,'US','UK','VN','JP','FR','DE','AU','CA','IN','SG'),
       ELT((g % 10) + 1,'New York','London','Hanoi','Tokyo','Paris','Berlin','Sydney','Toronto','Mumbai','Singapore'),
       ELT((g % 7) + 1,'bronze','bronze','bronze','silver','silver','gold','platinum'),
       DATE_ADD('2024-01-01 09:00:00', INTERVAL (g % 500) DAY)
FROM seq WHERE g <= 80000;

-- orders_orders → 150000
INSERT INTO orders_orders (id, customer_id, order_number, status, subtotal, discount, shipping_fee, total, placed_at, created_at)
SELECT g,
       ((g - 1) % 80000) + 1,
       CONCAT('ORD-', LPAD(g, 9, '0')),
       ELT((g % 8) + 1,'pending','paid','paid','shipped','delivered','delivered','cancelled','refunded'),
       ROUND((10000 + (g * 53) % 500000) / 100, 2),
       ROUND(g % 50, 2),
       ROUND(g % 30, 2),
       ROUND((10000 + (g * 53) % 500000) / 100 + (g % 30) - (g % 50), 2),
       DATE_ADD('2025-01-01 08:00:00', INTERVAL (g % 350) DAY),
       DATE_ADD('2025-01-01 08:00:00', INTERVAL (g % 350) DAY)
FROM seq WHERE g <= 150000;

-- orders_items → 200000
INSERT INTO orders_items (id, order_id, variant_sku, product_name, quantity, unit_price, line_total, created_at)
SELECT g,
       ((g - 1) % 150000) + 1,
       CONCAT('VAR-', LPAD(((g - 1) % 200000) + 1, 9, '0')),
       ELT((g % 8) + 1,'Pro Widget','Max Gadget','Ultra Speaker','Lite Charger','Eco Backpack','Smart Lamp','Nano Mouse','Turbo Camera'),
       1 + (g % 10),
       ROUND((500 + (g * 29) % 100000) / 100, 2),
       ROUND((1 + (g % 10)) * (500 + (g * 29) % 100000) / 100, 2),
       DATE_ADD('2025-01-01 08:00:00', INTERVAL (g % 350) DAY)
FROM seq WHERE g <= 200000;

-- orders_payments → 100000
INSERT INTO orders_payments (id, order_id, method, amount, status, paid_at, created_at)
SELECT g,
       ((g - 1) % 150000) + 1,
       ELT((g % 6) + 1,'card','card','paypal','bank_transfer','cod','wallet'),
       ROUND((1000 + (g * 47) % 500000) / 100, 2),
       ELT((g % 6) + 1,'pending','authorized','captured','captured','failed','refunded'),
       IF(g % 4 = 0, NULL, DATE_ADD('2025-01-01 09:00:00', INTERVAL (g % 350) DAY)),
       DATE_ADD('2025-01-01 09:00:00', INTERVAL (g % 350) DAY)
FROM seq WHERE g <= 100000;

-- orders_shipments → 120000
INSERT INTO orders_shipments (id, order_id, carrier, tracking_no, status, shipped_at, delivered_at, created_at)
SELECT g,
       ((g - 1) % 150000) + 1,
       ELT((g % 7) + 1,'DHL','FedEx','UPS','USPS','GHN','VNPost','Aramex'),
       CONCAT('TRK-', LPAD(g, 12, '0')),
       ELT((g % 6) + 1,'label_created','in_transit','out_for_delivery','delivered','delivered','returned'),
       DATE_ADD('2025-01-02 10:00:00', INTERVAL (g % 350) DAY),
       IF(g % 3 = 0, NULL, DATE_ADD('2025-01-05 10:00:00', INTERVAL (g % 350) DAY)),
       DATE_ADD('2025-01-02 10:00:00', INTERVAL (g % 350) DAY)
FROM seq WHERE g <= 120000;

-- marketing_campaigns → 2000
INSERT INTO marketing_campaigns (id, name, channel, budget, start_date, end_date, status, created_at)
SELECT g,
       CONCAT(ELT((g % 8) + 1,'Summer Sale','Black Friday','New Arrivals','Flash Deal','Loyalty Boost','Back to School','Holiday Push','Clearance'), ' #', g),
       ELT((g % 6) + 1,'email','social','search','display','affiliate','influencer'),
       ROUND(1000 + (g % 50000), 2),
       DATE_ADD('2025-01-01', INTERVAL (g % 300) DAY),
       DATE_ADD('2025-02-01', INTERVAL (g % 300) DAY),
       ELT((g % 5) + 1,'planned','active','active','paused','completed'),
       DATE_ADD('2025-01-01 09:00:00', INTERVAL (g % 300) DAY)
FROM seq WHERE g <= 2000;

-- marketing_coupons → 50000
INSERT INTO marketing_coupons (id, code, discount_type, discount_val, max_uses, used_count, expires_at, created_at)
SELECT g,
       CONCAT('SAVE-', LPAD(g, 7, '0')),
       ELT((g % 2) + 1,'percent','fixed'),
       ROUND(1 + (g % 50), 2),
       100 + (g % 900),
       g % 100,
       DATE_ADD('2025-06-01', INTERVAL (g % 365) DAY),
       DATE_ADD('2025-01-01 09:00:00', INTERVAL (g % 300) DAY)
FROM seq WHERE g <= 50000;

-- marketing_reviews → 150000
INSERT INTO marketing_reviews (id, product_id, customer_id, rating, title, body, is_verified, created_at)
SELECT g,
       ((g - 1) % 100000) + 1,
       ((g - 1) % 80000) + 1,
       1 + (g % 5),
       ELT((g % 6) + 1,'Great product','Not bad','Disappointed','Excellent','Average','Would buy again'),
       CONCAT('Auto-generated review body ', g),
       (g % 3 = 0),
       DATE_ADD('2025-01-01 09:00:00', INTERVAL (g % 350) DAY)
FROM seq WHERE g <= 150000;

-- marketing_wishlists → 120000
INSERT INTO marketing_wishlists (id, customer_id, variant_sku, added_at, created_at)
SELECT g,
       ((g - 1) % 80000) + 1,
       CONCAT('VAR-', LPAD(((g - 1) % 200000) + 1, 9, '0')),
       DATE_ADD('2025-01-01 12:00:00', INTERVAL (g % 350) DAY),
       DATE_ADD('2025-01-01 12:00:00', INTERVAL (g % 350) DAY)
FROM seq WHERE g <= 120000;

-- marketing_ad_spend → 80000
INSERT INTO marketing_ad_spend (id, campaign_id, spend_date, impressions, clicks, conversions, cost, created_at)
SELECT g,
       ((g - 1) % 2000) + 1,
       DATE_ADD('2025-01-01', INTERVAL (g % 350) DAY),
       1000 + (g % 100000),
       10 + (g % 5000),
       g % 500,
       ROUND(50 + (g % 10000), 2),
       DATE_ADD('2025-01-01 09:00:00', INTERVAL (g % 350) DAY)
FROM seq WHERE g <= 80000;

DROP TEMPORARY TABLE IF EXISTS seq;
SET UNIQUE_CHECKS = 1;
SET FOREIGN_KEY_CHECKS = 1;
