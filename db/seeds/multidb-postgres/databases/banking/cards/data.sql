-- Banking › cards data. Full-scale via generate_series (deterministic).
-- merchants 20,000 · cards 100,000 · authorizations 200,000 · settlements 150,000 · disputes 50,000
SET search_path = cards;
BEGIN;

-- merchants → 20,000
INSERT INTO merchants (id, name, category, mcc, country)
SELECT g,
       (ARRAY['Amazon','Walmart','Starbucks','Shell','Netflix','Apple','Grab','Shopee'])[1 + (g % 8)] || ' #' || g,
       (ARRAY['Retail','Grocery','Dining','Fuel','Streaming','Electronics','Transport','Marketplace'])[1 + (g % 8)],
       (ARRAY['5411','5812','5541','5732','4899','5732','4121','5999'])[1 + (g % 8)],
       (ARRAY['US','UK','VN','JP','FR','DE','SG','AU'])[1 + (g % 8)]
FROM generate_series(1, 20000) AS g;

-- cards → 100,000 (account_id references accounts.accounts externally, 1..120000)
INSERT INTO cards (id, account_id, card_masked, brand, status, expires_on)
SELECT g,
       ((g - 1) % 120000) + 1,
       '4XXX-XXXX-' || lpad(((g / 10000) % 10000)::text, 4, '0') || '-' || lpad((g % 10000)::text, 4, '0'),
       (ARRAY['visa','mastercard','amex','jcb','unionpay'])[1 + (g % 5)],
       (ARRAY['active','active','active','blocked','expired','lost','stolen'])[1 + (g % 7)],
       DATE '2026-01-01' + (g % 1500)
FROM generate_series(1, 100000) AS g;

-- authorizations → 200,000 (amount must be > 0)
INSERT INTO authorizations (id, card_id, merchant_id, amount, currency, status, authorized_at)
SELECT g,
       ((g - 1) % 100000) + 1,
       ((g - 1) % 20000) + 1,
       round((1 + ((g * 53) % 2000000) / 100.0)::numeric, 2),
       (ARRAY['USD','EUR','VND','JPY','GBP'])[1 + (g % 5)],
       (ARRAY['approved','approved','approved','declined','reversed','expired'])[1 + (g % 6)],
       TIMESTAMPTZ '2025-01-01 08:00:00' + ((g % 350) || ' days')::interval
FROM generate_series(1, 200000) AS g;

-- settlements → 150,000
INSERT INTO settlements (id, authorization_id, amount, status, settled_at)
SELECT g,
       ((g - 1) % 200000) + 1,
       round((1 + ((g * 53) % 2000000) / 100.0)::numeric, 2),
       (ARRAY['settled','settled','settled','pending','failed'])[1 + (g % 5)],
       CASE WHEN g % 5 = 0 THEN NULL ELSE TIMESTAMPTZ '2025-01-03 08:00:00' + ((g % 350) || ' days')::interval END
FROM generate_series(1, 150000) AS g;

-- disputes → 50,000
INSERT INTO disputes (id, authorization_id, reason, amount, status, opened_at, resolved_at)
SELECT g,
       ((g - 1) % 200000) + 1,
       (ARRAY['Unauthorized charge','Item not received','Duplicate charge','Wrong amount','Cancelled service'])[1 + (g % 5)],
       round((1 + ((g * 47) % 1500000) / 100.0)::numeric, 2),
       (ARRAY['open','under_review','won','lost','withdrawn'])[1 + (g % 5)],
       TIMESTAMPTZ '2025-02-01 08:00:00' + ((g % 300) || ' days')::interval,
       CASE WHEN g % 2 = 0 THEN NULL ELSE TIMESTAMPTZ '2025-02-20 08:00:00' + ((g % 300) || ' days')::interval END
FROM generate_series(1, 50000) AS g;

COMMIT;

-- Reset sequences for this schema
DO $$
DECLARE r RECORD;
BEGIN
  FOR r IN SELECT table_name FROM information_schema.columns
           WHERE table_schema = 'cards' AND column_name = 'id' AND column_default LIKE 'nextval%'
  LOOP
    EXECUTE format('SELECT setval(pg_get_serial_sequence(''cards.%I'', ''id''), COALESCE((SELECT MAX(id) FROM cards.%I), 1))', r.table_name, r.table_name);
  END LOOP;
END $$;
