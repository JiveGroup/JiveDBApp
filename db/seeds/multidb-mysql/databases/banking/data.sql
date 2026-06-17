-- jdb_banking data — full-scale, deterministic (derived from row number `g`).
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

-- accounts_branches → 2000
INSERT INTO accounts_branches (id, code, name, city, country, created_at)
SELECT g,
       CONCAT('BR-', LPAD(g, 6, '0')),
       CONCAT(ELT((g % 8) + 1,'Downtown','Uptown','Harbor','Central','Westside','Airport','Old Town','Riverside'), ' Branch ', g),
       ELT((g % 8) + 1,'New York','London','Hanoi','Tokyo','Paris','Berlin','Sydney','Singapore'),
       ELT((g % 8) + 1,'US','UK','VN','JP','FR','DE','AU','SG'),
       DATE_ADD('2018-01-01 09:00:00', INTERVAL (g % 400) DAY)
FROM seq WHERE g <= 2000;

-- accounts_customers → 80000
INSERT INTO accounts_customers (id, full_name, national_id, email, phone, kyc_status, created_at)
SELECT g,
       CONCAT(ELT((g % 8) + 1,'Alice','Bob','Carol','Dave','Eve','Frank','Grace','Hank'), ' ',
              ELT((FLOOR(g / 8) % 8) + 1,'Smith','Johnson','Nguyen','Tran','Garcia','Lee','Brown','Davis')),
       CONCAT('NID', LPAD(g, 11, '0')),
       CONCAT('cust', g, '@bank.example.com'),
       CONCAT('+1555', LPAD(2000000 + g, 8, '0')),
       ELT((g % 6) + 1,'pending','verified','verified','verified','rejected','review'),
       DATE_ADD('2018-01-01 09:00:00', INTERVAL (g % 2800) DAY)
FROM seq WHERE g <= 80000;

-- accounts_accounts → 120000
INSERT INTO accounts_accounts (id, customer_id, branch_id, account_number, account_type, currency, balance, status, opened_at, created_at)
SELECT g,
       ((g - 1) % 80000) + 1,
       ((g - 1) % 2000) + 1,
       CONCAT('ACC', LPAD(g, 12, '0')),
       ELT((g % 4) + 1,'checking','savings','term_deposit','credit'),
       ELT((g % 5) + 1,'USD','EUR','VND','JPY','GBP'),
       ROUND(((g * 911) % 100000000) / 100, 2),
       ELT((g % 6) + 1,'active','active','active','dormant','frozen','closed'),
       DATE_ADD('2018-01-01', INTERVAL (g % 2800) DAY),
       DATE_ADD('2018-01-01 09:00:00', INTERVAL (g % 2800) DAY)
FROM seq WHERE g <= 120000;

-- accounts_transactions → 200000
INSERT INTO accounts_transactions (id, account_id, txn_type, amount, balance_after, description, txn_at, created_at)
SELECT g,
       ((g - 1) % 120000) + 1,
       ELT((g % 5) + 1,'deposit','withdrawal','transfer','fee','interest'),
       ROUND((100 + (g * 53) % 5000000) / 100, 2),
       ROUND(((g * 911) % 100000000) / 100, 2),
       ELT((g % 6) + 1,'ATM','POS purchase','Online transfer','Salary credit','Service fee','Interest posting'),
       DATE_ADD('2024-01-01 08:00:00', INTERVAL (g % 700) DAY),
       DATE_ADD('2024-01-01 08:00:00', INTERVAL (g % 700) DAY)
FROM seq WHERE g <= 200000;

-- accounts_beneficiaries → 100000
INSERT INTO accounts_beneficiaries (id, account_id, name, bank_name, account_number, created_at)
SELECT g,
       ((g - 1) % 120000) + 1,
       CONCAT('Payee ', g),
       ELT((g % 8) + 1,'Chase','HSBC','Vietcombank','MUFG','BNP Paribas','Deutsche Bank','ANZ','DBS'),
       CONCAT('EXT', LPAD(g, 12, '0')),
       DATE_ADD('2024-01-01 09:00:00', INTERVAL (g % 700) DAY)
FROM seq WHERE g <= 100000;

-- lending_applications → 100000
INSERT INTO lending_applications (id, customer_id, product, amount, status, applied_at, created_at)
SELECT g,
       ((g - 1) % 80000) + 1,
       ELT((g % 5) + 1,'personal','mortgage','auto','business','student'),
       ROUND((100000 + (g * 71) % 50000000) / 100, 2),
       ELT((g % 6) + 1,'submitted','under_review','approved','approved','rejected','withdrawn'),
       DATE_ADD('2023-01-01 08:00:00', INTERVAL (g % 900) DAY),
       DATE_ADD('2023-01-01 08:00:00', INTERVAL (g % 900) DAY)
FROM seq WHERE g <= 100000;

-- lending_loans → 80000
INSERT INTO lending_loans (id, application_id, loan_number, principal, interest_rate, term_months, status, disbursed_at, created_at)
SELECT g,
       ((g - 1) % 100000) + 1,
       CONCAT('LN-', LPAD(g, 10, '0')),
       ROUND((100000 + (g * 67) % 40000000) / 100, 2),
       ROUND(2 + (g % 1800) / 100, 2),
       ELT((g % 8) + 1,12,24,36,48,60,120,240,360),
       ELT((g % 7) + 1,'active','active','active','paid_off','delinquent','defaulted','restructured'),
       DATE_ADD('2023-01-01', INTERVAL (g % 900) DAY),
       DATE_ADD('2023-01-01 09:00:00', INTERVAL (g % 900) DAY)
FROM seq WHERE g <= 80000;

-- lending_collaterals → 60000
INSERT INTO lending_collaterals (id, loan_id, kind, description, value, created_at)
SELECT g,
       ((g - 1) % 80000) + 1,
       ELT((g % 5) + 1,'property','vehicle','deposit','equipment','securities'),
       CONCAT(ELT((g % 5) + 1,'Residential property','Passenger vehicle','Fixed deposit','Industrial equipment','Listed securities'), ' #', g),
       ROUND((500000 + (g * 89) % 100000000) / 100, 2),
       DATE_ADD('2023-01-01 09:00:00', INTERVAL (g % 900) DAY)
FROM seq WHERE g <= 60000;

-- lending_repayments → 200000
INSERT INTO lending_repayments (id, loan_id, amount, principal_part, interest_part, paid_at, created_at)
SELECT g,
       ((g - 1) % 80000) + 1,
       ROUND((5000 + (g * 41) % 1000000) / 100, 2),
       ROUND((4000 + (g * 41) % 800000) / 100, 2),
       ROUND((1000 + (g * 41) % 200000) / 100, 2),
       DATE_ADD('2023-06-01 08:00:00', INTERVAL (g % 900) DAY),
       DATE_ADD('2023-06-01 08:00:00', INTERVAL (g % 900) DAY)
FROM seq WHERE g <= 200000;

-- lending_schedules → 200000
INSERT INTO lending_schedules (id, loan_id, due_date, installment, is_paid, created_at)
SELECT g,
       ((g - 1) % 80000) + 1,
       DATE_ADD('2023-06-01', INTERVAL (g % 1200) DAY),
       ROUND((5000 + (g * 43) % 1000000) / 100, 2),
       (g % 3 <> 0),
       DATE_ADD('2023-06-01 09:00:00', INTERVAL (g % 1200) DAY)
FROM seq WHERE g <= 200000;

-- cards_merchants → 20000
INSERT INTO cards_merchants (id, name, category, mcc, country, created_at)
SELECT g,
       CONCAT(ELT((g % 8) + 1,'Amazon','Walmart','Starbucks','Shell','Netflix','Apple','Grab','Shopee'), ' #', g),
       ELT((g % 8) + 1,'Retail','Grocery','Dining','Fuel','Streaming','Electronics','Transport','Marketplace'),
       ELT((g % 8) + 1,'5411','5812','5541','5732','4899','5732','4121','5999'),
       ELT((g % 8) + 1,'US','UK','VN','JP','FR','DE','SG','AU'),
       DATE_ADD('2024-01-01 09:00:00', INTERVAL (g % 400) DAY)
FROM seq WHERE g <= 20000;

-- cards_cards → 100000
INSERT INTO cards_cards (id, account_id, card_masked, brand, status, expires_on, created_at)
SELECT g,
       ((g - 1) % 120000) + 1,
       CONCAT('4XXX-XXXX-', LPAD(FLOOR(g / 10000) % 10000, 4, '0'), '-', LPAD(g % 10000, 4, '0')),
       ELT((g % 5) + 1,'visa','mastercard','amex','jcb','unionpay'),
       ELT((g % 7) + 1,'active','active','active','blocked','expired','lost','stolen'),
       DATE_ADD('2026-01-01', INTERVAL (g % 1500) DAY),
       DATE_ADD('2024-06-01 09:00:00', INTERVAL (g % 350) DAY)
FROM seq WHERE g <= 100000;

-- cards_authorizations → 200000
INSERT INTO cards_authorizations (id, card_id, merchant_id, amount, currency, status, authorized_at, created_at)
SELECT g,
       ((g - 1) % 100000) + 1,
       ((g - 1) % 20000) + 1,
       ROUND((100 + (g * 53) % 2000000) / 100, 2),
       ELT((g % 5) + 1,'USD','EUR','VND','JPY','GBP'),
       ELT((g % 6) + 1,'approved','approved','approved','declined','reversed','expired'),
       DATE_ADD('2025-01-01 08:00:00', INTERVAL (g % 350) DAY),
       DATE_ADD('2025-01-01 08:00:00', INTERVAL (g % 350) DAY)
FROM seq WHERE g <= 200000;

-- cards_settlements → 150000
INSERT INTO cards_settlements (id, authorization_id, amount, status, settled_at, created_at)
SELECT g,
       ((g - 1) % 200000) + 1,
       ROUND((100 + (g * 53) % 2000000) / 100, 2),
       ELT((g % 5) + 1,'settled','settled','settled','pending','failed'),
       IF(g % 5 = 0, NULL, DATE_ADD('2025-01-03 08:00:00', INTERVAL (g % 350) DAY)),
       DATE_ADD('2025-01-03 08:00:00', INTERVAL (g % 350) DAY)
FROM seq WHERE g <= 150000;

-- cards_disputes → 50000
INSERT INTO cards_disputes (id, authorization_id, reason, amount, status, opened_at, resolved_at, created_at)
SELECT g,
       ((g - 1) % 200000) + 1,
       ELT((g % 5) + 1,'Unauthorized charge','Item not received','Duplicate charge','Wrong amount','Cancelled service'),
       ROUND((100 + (g * 47) % 1500000) / 100, 2),
       ELT((g % 5) + 1,'open','under_review','won','lost','withdrawn'),
       DATE_ADD('2025-02-01 08:00:00', INTERVAL (g % 300) DAY),
       IF(g % 2 = 0, NULL, DATE_ADD('2025-02-20 08:00:00', INTERVAL (g % 300) DAY)),
       DATE_ADD('2025-02-01 08:00:00', INTERVAL (g % 300) DAY)
FROM seq WHERE g <= 50000;

DROP TEMPORARY TABLE IF EXISTS seq;
SET UNIQUE_CHECKS = 1;
SET FOREIGN_KEY_CHECKS = 1;
