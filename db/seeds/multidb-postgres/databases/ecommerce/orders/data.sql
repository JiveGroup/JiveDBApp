-- E-commerce › orders data. Full-scale via generate_series (deterministic).
-- customers 80,000 · orders 150,000 · order_items 200,000 · payments 100,000 · shipments 120,000
SET search_path = orders;
BEGIN;

-- customers → 80,000
INSERT INTO customers (id, first_name, last_name, email, phone, country, city, loyalty_tier)
SELECT g,
       (ARRAY['Alice','Bob','Carol','Dave','Eve','Frank','Grace','Hank','Iris','Jack','Kate','Leo','Mia','Nick','Olivia','Paul','Quinn','Rose','Sam','Tina'])[1 + (g % 20)],
       (ARRAY['Smith','Johnson','Williams','Brown','Jones','Garcia','Miller','Davis','Nguyen','Tran','Lee','Walker','Young','King','Scott','Green','Adams','Baker','Nelson','Carter'])[1 + ((g / 20) % 20)],
       'shopper' || g || '@mail.example.com',
       '+1555' || lpad((1000000 + g)::text, 8, '0'),
       (ARRAY['US','UK','VN','JP','FR','DE','AU','CA','IN','SG'])[1 + (g % 10)],
       (ARRAY['New York','London','Hanoi','Tokyo','Paris','Berlin','Sydney','Toronto','Mumbai','Singapore'])[1 + (g % 10)],
       (ARRAY['bronze','bronze','bronze','silver','silver','gold','platinum'])[1 + (g % 7)]
FROM generate_series(1, 80000) AS g;

-- orders → 150,000
INSERT INTO orders (id, customer_id, order_number, status, subtotal, discount, shipping_fee, total, placed_at)
SELECT g,
       ((g - 1) % 80000) + 1,
       'ORD-' || lpad(g::text, 9, '0'),
       (ARRAY['pending','paid','paid','shipped','delivered','delivered','cancelled','refunded'])[1 + (g % 8)],
       round((100 + ((g * 53) % 500000) / 100.0)::numeric, 2),  -- subtotal (>= 100, always > discount)
       round((g % 50)::numeric, 2),                              -- discount
       round((g % 30)::numeric, 2),                              -- shipping_fee
       round((100 + ((g * 53) % 500000) / 100.0 + (g % 30) - (g % 50))::numeric, 2),  -- total
       TIMESTAMPTZ '2025-01-01 08:00:00' + ((g % 350) || ' days')::interval
FROM generate_series(1, 150000) AS g;

-- order_items → 200,000
INSERT INTO order_items (id, order_id, variant_sku, product_name, quantity, unit_price, line_total)
SELECT g,
       ((g - 1) % 150000) + 1,
       'VAR-' || lpad((((g - 1) % 200000) + 1)::text, 9, '0'),
       (ARRAY['Pro Widget','Max Gadget','Ultra Speaker','Lite Charger','Eco Backpack','Smart Lamp','Nano Mouse','Turbo Camera'])[1 + (g % 8)],
       1 + (g % 10),
       round((5 + ((g * 29) % 100000) / 100.0)::numeric, 2),
       round((1 + (g % 10)) * (5 + ((g * 29) % 100000) / 100.0)::numeric, 2)
FROM generate_series(1, 200000) AS g;

-- payments → 100,000
INSERT INTO payments (id, order_id, method, amount, status, paid_at)
SELECT g,
       ((g - 1) % 150000) + 1,
       (ARRAY['card','card','paypal','bank_transfer','cod','wallet'])[1 + (g % 6)],
       round((10 + ((g * 47) % 500000) / 100.0)::numeric, 2),
       (ARRAY['pending','authorized','captured','captured','failed','refunded'])[1 + (g % 6)],
       CASE WHEN g % 4 = 0 THEN NULL ELSE TIMESTAMPTZ '2025-01-01 09:00:00' + ((g % 350) || ' days')::interval END
FROM generate_series(1, 100000) AS g;

-- shipments → 120,000
INSERT INTO shipments (id, order_id, carrier, tracking_no, status, shipped_at, delivered_at)
SELECT g,
       ((g - 1) % 150000) + 1,
       (ARRAY['DHL','FedEx','UPS','USPS','GHN','VNPost','Aramex'])[1 + (g % 7)],
       'TRK-' || lpad(g::text, 12, '0'),
       (ARRAY['label_created','in_transit','out_for_delivery','delivered','delivered','returned'])[1 + (g % 6)],
       TIMESTAMPTZ '2025-01-02 10:00:00' + ((g % 350) || ' days')::interval,
       CASE WHEN g % 3 = 0 THEN NULL ELSE TIMESTAMPTZ '2025-01-05 10:00:00' + ((g % 350) || ' days')::interval END
FROM generate_series(1, 120000) AS g;

COMMIT;

-- Reset sequences for this schema
DO $$
DECLARE r RECORD;
BEGIN
  FOR r IN SELECT table_name FROM information_schema.columns
           WHERE table_schema = 'orders' AND column_name = 'id' AND column_default LIKE 'nextval%'
  LOOP
    EXECUTE format('SELECT setval(pg_get_serial_sequence(''orders.%I'', ''id''), COALESCE((SELECT MAX(id) FROM orders.%I), 1))', r.table_name, r.table_name);
  END LOOP;
END $$;
