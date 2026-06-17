-- Healthcare › billing data. Full-scale via generate_series (deterministic).
-- insurers 2,000 · services 5,000 · invoices 150,000 · claims 120,000 · payments 150,000
SET search_path = billing;
BEGIN;

-- insurers → 2,000
INSERT INTO insurers (id, name, country, plan_type, contact_email)
SELECT g,
       (ARRAY['BlueCross','Aetna','Cigna','Humana','Bao Viet','PVI','UnitedHealth','Allianz'])[1 + (g % 8)] || ' ' || g,
       (ARRAY['US','US','VN','DE','GB','FR','JP','SG'])[1 + (g % 8)],
       (ARRAY['public','private','employer','supplemental'])[1 + (g % 4)],
       'claims' || g || '@insurer.example.com'
FROM generate_series(1, 2000) AS g;

-- services → 5,000
INSERT INTO services (id, code, name, category, unit_price)
SELECT g,
       'SVC-' || lpad(g::text, 6, '0'),
       (ARRAY['Consultation','X-Ray','MRI Scan','Blood Test','Surgery','Physiotherapy','Vaccination','ECG'])[1 + (g % 8)] || ' ' || g,
       (ARRAY['Consultation','Imaging','Laboratory','Surgical','Therapy','Preventive'])[1 + (g % 6)],
       round((10 + ((g * 31) % 500000) / 100.0)::numeric, 2)
FROM generate_series(1, 5000) AS g;

-- invoices → 150,000 (patient_id references clinical.patients externally, 1..80000)
INSERT INTO invoices (id, patient_id, insurer_id, invoice_number, amount, status, issued_at, due_date)
SELECT g,
       ((g - 1) % 80000) + 1,
       CASE WHEN g % 5 = 0 THEN NULL ELSE ((g - 1) % 2000) + 1 END,
       'INV-' || lpad(g::text, 9, '0'),
       round((20 + ((g * 43) % 2000000) / 100.0)::numeric, 2),
       (ARRAY['open','sent','paid','partially_paid','overdue','written_off'])[1 + (g % 6)],
       TIMESTAMPTZ '2024-06-01 08:00:00' + ((g % 700) || ' days')::interval,
       DATE '2024-07-01' + (g % 700)
FROM generate_series(1, 150000) AS g;

-- claims → 120,000
INSERT INTO claims (id, invoice_id, insurer_id, claim_number, amount, status, submitted_at, resolved_at)
SELECT g,
       ((g - 1) % 150000) + 1,
       ((g - 1) % 2000) + 1,
       'CLM-' || lpad(g::text, 9, '0'),
       round((20 + ((g * 37) % 1500000) / 100.0)::numeric, 2),
       (ARRAY['submitted','in_review','approved','partially_approved','denied','paid'])[1 + (g % 6)],
       TIMESTAMPTZ '2024-06-05 08:00:00' + ((g % 700) || ' days')::interval,
       CASE WHEN g % 3 = 0 THEN NULL ELSE TIMESTAMPTZ '2024-06-20 08:00:00' + ((g % 700) || ' days')::interval END
FROM generate_series(1, 120000) AS g;

-- payments → 150,000
INSERT INTO payments (id, invoice_id, method, amount, paid_at)
SELECT g,
       ((g - 1) % 150000) + 1,
       (ARRAY['cash','card','insurance','bank_transfer'])[1 + (g % 4)],
       round((10 + ((g * 29) % 1000000) / 100.0)::numeric, 2),
       CASE WHEN g % 6 = 0 THEN NULL ELSE TIMESTAMPTZ '2024-06-10 08:00:00' + ((g % 700) || ' days')::interval END
FROM generate_series(1, 150000) AS g;

COMMIT;

-- Reset sequences for this schema
DO $$
DECLARE r RECORD;
BEGIN
  FOR r IN SELECT table_name FROM information_schema.columns
           WHERE table_schema = 'billing' AND column_name = 'id' AND column_default LIKE 'nextval%'
  LOOP
    EXECUTE format('SELECT setval(pg_get_serial_sequence(''billing.%I'', ''id''), COALESCE((SELECT MAX(id) FROM billing.%I), 1))', r.table_name, r.table_name);
  END LOOP;
END $$;
