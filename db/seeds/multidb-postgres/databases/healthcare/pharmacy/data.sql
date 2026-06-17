-- Healthcare › pharmacy data. Full-scale via generate_series (deterministic).
-- suppliers 3,000 · drugs 50,000 · drug_inventory 100,000 · dispenses 200,000 · stock_moves 200,000
SET search_path = pharmacy;
BEGIN;

-- suppliers → 3,000
INSERT INTO suppliers (id, name, country, contact_email, status)
SELECT g,
       'Pharma Supplier ' || g,
       (ARRAY['IN','CN','DE','CH','US','VN','FR','GB','JP','KR'])[1 + (g % 10)],
       'supplier' || g || '@pharma.example.com',
       (ARRAY['active','active','active','inactive','suspended'])[1 + (g % 5)]
FROM generate_series(1, 3000) AS g;

-- drugs → 50,000
INSERT INTO drugs (id, name, generic_name, atc_code, form, strength, unit_price, is_controlled)
SELECT g,
       (ARRAY['Amoxil','Glucophage','Lipitor','Losec','Norvasc','Ventolin','Brufen','Panadol','Augmentin','Zithromax'])[1 + (g % 10)] || ' ' || g,
       (ARRAY['Amoxicillin','Metformin','Atorvastatin','Omeprazole','Amlodipine','Salbutamol','Ibuprofen','Paracetamol','Co-amoxiclav','Azithromycin'])[1 + (g % 10)],
       (ARRAY['J01','A10','C10','A02','C08','R03','M01','N02'])[1 + (g % 8)] || lpad((g % 100)::text, 2, '0'),
       (ARRAY['tablet','capsule','syrup','injection','inhaler','cream'])[1 + (g % 6)],
       (ARRAY['250mg','500mg','5mg','10mg','20mg','100ml'])[1 + (g % 6)],
       round((0.5 + ((g * 23) % 50000) / 100.0)::numeric, 2),
       (g % 11 = 0)
FROM generate_series(1, 50000) AS g;

-- drug_inventory → 100,000
INSERT INTO drug_inventory (id, drug_id, batch_no, quantity, expiry_date, received_at)
SELECT g,
       ((g - 1) % 50000) + 1,
       'BATCH-' || lpad(g::text, 9, '0'),
       g % 10000,
       DATE '2026-01-01' + (g % 1000),
       TIMESTAMPTZ '2024-06-01 08:00:00' + ((g % 600) || ' days')::interval
FROM generate_series(1, 100000) AS g;

-- dispenses → 200,000 (prescription_id references clinical.prescriptions externally, 1..150000)
INSERT INTO dispenses (id, drug_id, prescription_id, quantity, pharmacist, dispensed_at)
SELECT g,
       ((g - 1) % 50000) + 1,
       ((g - 1) % 150000) + 1,
       1 + (g % 60),
       'Pharmacist ' || (g % 200),
       TIMESTAMPTZ '2024-06-02 09:00:00' + ((g % 600) || ' days')::interval
FROM generate_series(1, 200000) AS g;

-- stock_moves → 200,000 (quantity must be <> 0)
INSERT INTO stock_moves (id, drug_id, move_type, quantity, reason, moved_at)
SELECT g,
       ((g - 1) % 50000) + 1,
       (ARRAY['receipt','dispense','adjustment','return','expiry_writeoff'])[1 + (g % 5)],
       CASE WHEN g % 2 = 0 THEN 1 + (g % 500) ELSE -(1 + (g % 500)) END,
       (ARRAY['Routine receipt','Patient dispense','Cycle count','Customer return','Expired stock'])[1 + (g % 5)],
       TIMESTAMPTZ '2024-06-01 12:00:00' + ((g % 600) || ' days')::interval
FROM generate_series(1, 200000) AS g;

COMMIT;

-- Reset sequences for this schema
DO $$
DECLARE r RECORD;
BEGIN
  FOR r IN SELECT table_name FROM information_schema.columns
           WHERE table_schema = 'pharmacy' AND column_name = 'id' AND column_default LIKE 'nextval%'
  LOOP
    EXECUTE format('SELECT setval(pg_get_serial_sequence(''pharmacy.%I'', ''id''), COALESCE((SELECT MAX(id) FROM pharmacy.%I), 1))', r.table_name, r.table_name);
  END LOOP;
END $$;
