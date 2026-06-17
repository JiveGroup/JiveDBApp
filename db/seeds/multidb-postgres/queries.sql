-- Demo queries for the multi-domain seed (3 databases, 3 schemas each, 5 tables/schema).
-- Paste into JiveDB's SQL Editor, or pipe into psql (\c switches database).

-- ══════════════════════════════════════════════════════════════════════════
-- jdb_ecommerce  (catalog · orders · marketing)
-- ══════════════════════════════════════════════════════════════════════════
\c jdb_ecommerce
SELECT current_database();

-- catalog: products & variants per category
SELECT * FROM catalog.v_catalog_summary LIMIT 20;

-- orders: revenue by loyalty tier
SELECT * FROM orders.v_revenue_by_tier;

-- orders: biggest recent orders with customer
SELECT o.order_number, c.first_name || ' ' || c.last_name AS customer,
       o.status, o.total, o.placed_at
FROM orders.orders o
JOIN orders.customers c ON c.id = o.customer_id
ORDER BY o.total DESC
LIMIT 20;

-- marketing: campaign performance (spend, clicks, conversion rate)
SELECT * FROM marketing.v_campaign_performance LIMIT 20;

-- marketing: rating distribution
SELECT rating, COUNT(*) AS reviews
FROM marketing.reviews
GROUP BY rating ORDER BY rating;

-- ══════════════════════════════════════════════════════════════════════════
-- jdb_healthcare  (clinical · pharmacy · billing)
-- ══════════════════════════════════════════════════════════════════════════
\c jdb_healthcare
SELECT current_database();

-- clinical: encounter load by department / type
SELECT * FROM clinical.v_encounter_load LIMIT 20;

-- clinical: most common diagnoses
SELECT description, severity, COUNT(*) AS n
FROM clinical.diagnoses
GROUP BY description, severity
ORDER BY n DESC LIMIT 15;

-- pharmacy: drugs with the most stock on hand
SELECT * FROM pharmacy.v_drug_stock LIMIT 20;

-- billing: claims by insurer
SELECT * FROM billing.v_claims_by_insurer ORDER BY total_claimed DESC LIMIT 20;

-- billing: invoice status mix
SELECT status, COUNT(*) AS invoices, ROUND(SUM(amount), 2) AS total_amount
FROM billing.invoices
GROUP BY status ORDER BY total_amount DESC;

-- ══════════════════════════════════════════════════════════════════════════
-- jdb_banking  (accounts · lending · cards)
-- ══════════════════════════════════════════════════════════════════════════
\c jdb_banking
SELECT current_database();

-- accounts: balances by branch
SELECT * FROM accounts.v_branch_balances LIMIT 20;

-- accounts: transaction volume by type
SELECT txn_type, COUNT(*) AS n, ROUND(SUM(amount), 2) AS total
FROM accounts.transactions
GROUP BY txn_type ORDER BY total DESC;

-- lending: loan portfolio by status
SELECT * FROM lending.v_loan_portfolio;

-- lending: largest active loans with collateral value
SELECT l.loan_number, l.principal, l.interest_rate, l.status,
       COALESCE(SUM(co.value), 0) AS collateral_value
FROM lending.loans l
LEFT JOIN lending.collaterals co ON co.loan_id = l.id
WHERE l.status = 'active'
GROUP BY l.id, l.loan_number, l.principal, l.interest_rate, l.status
ORDER BY l.principal DESC LIMIT 20;

-- cards: top merchants by approved volume
SELECT * FROM cards.v_merchant_volume ORDER BY approved_volume DESC LIMIT 20;

-- cards: dispute outcomes
SELECT status, COUNT(*) AS disputes, ROUND(SUM(amount), 2) AS total_amount
FROM cards.disputes
GROUP BY status ORDER BY disputes DESC;
