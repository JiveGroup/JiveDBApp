-- Banking › accounts data. Full-scale via generate_series (deterministic).
-- branches 2,000 · customers 80,000 · accounts 120,000 · transactions 200,000 · beneficiaries 100,000
SET search_path = accounts;
BEGIN;

-- branches → 2,000
INSERT INTO branches (id, code, name, city, country)
SELECT g,
       'BR-' || lpad(g::text, 6, '0'),
       (ARRAY['Downtown','Uptown','Harbor','Central','Westside','Airport','Old Town','Riverside'])[1 + (g % 8)] || ' Branch ' || g,
       (ARRAY['New York','London','Hanoi','Tokyo','Paris','Berlin','Sydney','Singapore'])[1 + (g % 8)],
       (ARRAY['US','UK','VN','JP','FR','DE','AU','SG'])[1 + (g % 8)]
FROM generate_series(1, 2000) AS g;

-- customers → 80,000
INSERT INTO customers (id, full_name, national_id, email, phone, kyc_status)
SELECT g,
       (ARRAY['Alice','Bob','Carol','Dave','Eve','Frank','Grace','Hank'])[1 + (g % 8)] || ' ' ||
       (ARRAY['Smith','Johnson','Nguyen','Tran','Garcia','Lee','Brown','Davis'])[1 + ((g / 8) % 8)],
       'NID' || lpad(g::text, 11, '0'),
       'cust' || g || '@bank.example.com',
       '+1555' || lpad((2000000 + g)::text, 8, '0'),
       (ARRAY['pending','verified','verified','verified','rejected','review'])[1 + (g % 6)]
FROM generate_series(1, 80000) AS g;

-- accounts → 120,000
INSERT INTO accounts (id, customer_id, branch_id, account_number, account_type, currency, balance, status, opened_at)
SELECT g,
       ((g - 1) % 80000) + 1,
       ((g - 1) % 2000) + 1,
       'ACC' || lpad(g::text, 12, '0'),
       (ARRAY['checking','savings','term_deposit','credit'])[1 + (g % 4)],
       (ARRAY['USD','EUR','VND','JPY','GBP'])[1 + (g % 5)],
       round((((g * 911) % 100000000) / 100.0)::numeric, 2),
       (ARRAY['active','active','active','dormant','frozen','closed'])[1 + (g % 6)],
       DATE '2018-01-01' + (g % 2800)
FROM generate_series(1, 120000) AS g;

-- transactions → 200,000 (amount must be > 0)
INSERT INTO transactions (id, account_id, txn_type, amount, balance_after, description, txn_at)
SELECT g,
       ((g - 1) % 120000) + 1,
       (ARRAY['deposit','withdrawal','transfer','fee','interest'])[1 + (g % 5)],
       round((1 + ((g * 53) % 5000000) / 100.0)::numeric, 2),
       round((((g * 911) % 100000000) / 100.0)::numeric, 2),
       (ARRAY['ATM','POS purchase','Online transfer','Salary credit','Service fee','Interest posting'])[1 + (g % 6)],
       TIMESTAMPTZ '2024-01-01 08:00:00' + ((g % 700) || ' days')::interval
FROM generate_series(1, 200000) AS g;

-- beneficiaries → 100,000
INSERT INTO beneficiaries (id, account_id, name, bank_name, account_number)
SELECT g,
       ((g - 1) % 120000) + 1,
       'Payee ' || g,
       (ARRAY['Chase','HSBC','Vietcombank','MUFG','BNP Paribas','Deutsche Bank','ANZ','DBS'])[1 + (g % 8)],
       'EXT' || lpad(g::text, 12, '0')
FROM generate_series(1, 100000) AS g;

COMMIT;

-- Reset sequences for this schema
DO $$
DECLARE r RECORD;
BEGIN
  FOR r IN SELECT table_name FROM information_schema.columns
           WHERE table_schema = 'accounts' AND column_name = 'id' AND column_default LIKE 'nextval%'
  LOOP
    EXECUTE format('SELECT setval(pg_get_serial_sequence(''accounts.%I'', ''id''), COALESCE((SELECT MAX(id) FROM accounts.%I), 1))', r.table_name, r.table_name);
  END LOOP;
END $$;
