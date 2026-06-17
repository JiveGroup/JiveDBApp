-- Demo queries for the MySQL multi-domain seed (3 databases, 15 tables each).
-- Run with: mysql -h127.0.0.1 -P3308 -ujdb -pjdbtest < queries.sql
-- `USE` switches database; tables are area-prefixed (catalog_/orders_/...).

-- Databases visible to this account
SHOW DATABASES LIKE 'jdb\_%';

-- ══════════════════════════════════════════════════════════════════════════
-- jdb_ecommerce
-- ══════════════════════════════════════════════════════════════════════════
USE jdb_ecommerce;
SELECT DATABASE();

-- products & variants per category
SELECT c.name AS category, COUNT(DISTINCT p.id) AS products,
       COUNT(v.id) AS variants, ROUND(AVG(p.price), 2) AS avg_price
FROM catalog_categories c
LEFT JOIN catalog_products p         ON p.category_id = c.id
LEFT JOIN catalog_product_variants v ON v.product_id = p.id
GROUP BY c.id, c.name
ORDER BY products DESC
LIMIT 15;

-- revenue by loyalty tier
SELECT c.loyalty_tier, COUNT(DISTINCT o.id) AS orders,
       ROUND(SUM(o.total), 2) AS revenue
FROM orders_customers c
LEFT JOIN orders_orders o ON o.customer_id = c.id AND o.status IN ('paid','shipped','delivered')
GROUP BY c.loyalty_tier
ORDER BY revenue DESC;

-- top campaigns by conversions
SELECT ca.name, ca.channel, SUM(a.clicks) AS clicks, SUM(a.conversions) AS conversions
FROM marketing_campaigns ca
JOIN marketing_ad_spend a ON a.campaign_id = ca.id
GROUP BY ca.id, ca.name, ca.channel
ORDER BY conversions DESC
LIMIT 15;

-- ══════════════════════════════════════════════════════════════════════════
-- jdb_healthcare
-- ══════════════════════════════════════════════════════════════════════════
USE jdb_healthcare;
SELECT DATABASE();

-- encounter load by department / type
SELECT department, encounter_type, COUNT(*) AS encounters,
       SUM(status = 'open') AS open_now
FROM clinical_encounters
GROUP BY department, encounter_type
ORDER BY encounters DESC
LIMIT 15;

-- drugs with most stock on hand
SELECT d.name, d.form, SUM(i.quantity) AS on_hand, COUNT(i.id) AS batches
FROM pharmacy_drugs d
JOIN pharmacy_drug_inventory i ON i.drug_id = d.id
GROUP BY d.id, d.name, d.form
ORDER BY on_hand DESC
LIMIT 15;

-- claims by insurer
SELECT ins.name AS insurer, ins.plan_type, COUNT(c.id) AS claims,
       ROUND(SUM(c.amount), 2) AS total_claimed
FROM billing_insurers ins
JOIN billing_claims c ON c.insurer_id = ins.id
GROUP BY ins.id, ins.name, ins.plan_type
ORDER BY total_claimed DESC
LIMIT 15;

-- ══════════════════════════════════════════════════════════════════════════
-- jdb_banking
-- ══════════════════════════════════════════════════════════════════════════
USE jdb_banking;
SELECT DATABASE();

-- balances by branch
SELECT b.name AS branch, COUNT(a.id) AS accounts, ROUND(SUM(a.balance), 2) AS total_balance
FROM accounts_branches b
LEFT JOIN accounts_accounts a ON a.branch_id = b.id AND a.status = 'active'
GROUP BY b.id, b.name
ORDER BY total_balance DESC
LIMIT 15;

-- loan portfolio by status
SELECT status, COUNT(*) AS loans, ROUND(SUM(principal), 2) AS total_principal,
       ROUND(AVG(interest_rate), 2) AS avg_rate
FROM lending_loans
GROUP BY status
ORDER BY total_principal DESC;

-- top merchants by approved card volume
SELECT m.name AS merchant, m.category, COUNT(a.id) AS auths,
       ROUND(SUM(IF(a.status = 'approved', a.amount, 0)), 2) AS approved_volume
FROM cards_merchants m
JOIN cards_authorizations a ON a.merchant_id = m.id
GROUP BY m.id, m.name, m.category
ORDER BY approved_volume DESC
LIMIT 15;
