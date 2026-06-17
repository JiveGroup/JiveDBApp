-- Banking › lending data. Full-scale via generate_series (deterministic).
-- applications 100,000 · loans 80,000 · collaterals 60,000 · repayments 200,000 · schedules 200,000
SET search_path = lending;
BEGIN;

-- applications → 100,000 (customer_id references accounts.customers externally, 1..80000)
INSERT INTO applications (id, customer_id, product, amount, status, applied_at)
SELECT g,
       ((g - 1) % 80000) + 1,
       (ARRAY['personal','mortgage','auto','business','student'])[1 + (g % 5)],
       round((1000 + ((g * 71) % 50000000) / 100.0)::numeric, 2),
       (ARRAY['submitted','under_review','approved','approved','rejected','withdrawn'])[1 + (g % 6)],
       TIMESTAMPTZ '2023-01-01 08:00:00' + ((g % 900) || ' days')::interval
FROM generate_series(1, 100000) AS g;

-- loans → 80,000
INSERT INTO loans (id, application_id, loan_number, principal, interest_rate, term_months, status, disbursed_at)
SELECT g,
       ((g - 1) % 100000) + 1,
       'LN-' || lpad(g::text, 10, '0'),
       round((1000 + ((g * 67) % 40000000) / 100.0)::numeric, 2),
       round((2 + (g % 1800) / 100.0)::numeric, 2),
       (ARRAY[12, 24, 36, 48, 60, 120, 240, 360])[1 + (g % 8)],
       (ARRAY['active','active','active','paid_off','delinquent','defaulted','restructured'])[1 + (g % 7)],
       DATE '2023-01-01' + (g % 900)
FROM generate_series(1, 80000) AS g;

-- collaterals → 60,000
INSERT INTO collaterals (id, loan_id, kind, description, value)
SELECT g,
       ((g - 1) % 80000) + 1,
       (ARRAY['property','vehicle','deposit','equipment','securities'])[1 + (g % 5)],
       (ARRAY['Residential property','Passenger vehicle','Fixed deposit','Industrial equipment','Listed securities'])[1 + (g % 5)] || ' #' || g,
       round((5000 + ((g * 89) % 100000000) / 100.0)::numeric, 2)
FROM generate_series(1, 60000) AS g;

-- repayments → 200,000
INSERT INTO repayments (id, loan_id, amount, principal_part, interest_part, paid_at)
SELECT g,
       ((g - 1) % 80000) + 1,
       round((50 + ((g * 41) % 1000000) / 100.0)::numeric, 2),
       round((40 + ((g * 41) % 800000) / 100.0)::numeric, 2),
       round((10 + ((g * 41) % 200000) / 100.0)::numeric, 2),
       TIMESTAMPTZ '2023-06-01 08:00:00' + ((g % 900) || ' days')::interval
FROM generate_series(1, 200000) AS g;

-- schedules → 200,000
INSERT INTO schedules (id, loan_id, due_date, installment, is_paid)
SELECT g,
       ((g - 1) % 80000) + 1,
       DATE '2023-06-01' + (g % 1200),
       round((50 + ((g * 43) % 1000000) / 100.0)::numeric, 2),
       (g % 3 <> 0)
FROM generate_series(1, 200000) AS g;

COMMIT;

-- Reset sequences for this schema
DO $$
DECLARE r RECORD;
BEGIN
  FOR r IN SELECT table_name FROM information_schema.columns
           WHERE table_schema = 'lending' AND column_name = 'id' AND column_default LIKE 'nextval%'
  LOOP
    EXECUTE format('SELECT setval(pg_get_serial_sequence(''lending.%I'', ''id''), COALESCE((SELECT MAX(id) FROM lending.%I), 1))', r.table_name, r.table_name);
  END LOOP;
END $$;
