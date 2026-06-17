-- Banking › accounts schema: core banking (5 tables + 1 view).
-- Idempotent: safe to re-run (uses IF NOT EXISTS / OR REPLACE).

CREATE SCHEMA IF NOT EXISTS accounts;
SET search_path = accounts;

-- 1. branches — bank branches
CREATE TABLE IF NOT EXISTS branches (
    id         SERIAL PRIMARY KEY,
    code       VARCHAR(12) NOT NULL UNIQUE,
    name       VARCHAR(120) NOT NULL,
    city       VARCHAR(60),
    country    VARCHAR(40),
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 2. customers — account holders
CREATE TABLE IF NOT EXISTS customers (
    id          SERIAL PRIMARY KEY,
    full_name   VARCHAR(120) NOT NULL,
    national_id VARCHAR(20) NOT NULL UNIQUE,
    email       VARCHAR(255),
    phone       VARCHAR(30),
    kyc_status  VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (kyc_status IN ('pending','verified','rejected','review')),
    created_at  TIMESTAMPTZ DEFAULT now()
);

-- 3. accounts — deposit accounts
CREATE TABLE IF NOT EXISTS accounts (
    id             SERIAL PRIMARY KEY,
    customer_id    INT NOT NULL REFERENCES customers(id),
    branch_id      INT NOT NULL REFERENCES branches(id),
    account_number VARCHAR(24) NOT NULL UNIQUE,
    account_type   VARCHAR(20) NOT NULL CHECK (account_type IN ('checking','savings','term_deposit','credit')),
    currency       VARCHAR(3) NOT NULL DEFAULT 'USD',
    balance        NUMERIC(16,2) NOT NULL DEFAULT 0,
    status         VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (status IN ('active','dormant','frozen','closed')),
    opened_at      DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at     TIMESTAMPTZ DEFAULT now()
);

-- 4. transactions — ledger entries
CREATE TABLE IF NOT EXISTS transactions (
    id            SERIAL PRIMARY KEY,
    account_id    INT NOT NULL REFERENCES accounts(id),
    txn_type      VARCHAR(20) NOT NULL CHECK (txn_type IN ('deposit','withdrawal','transfer','fee','interest')),
    amount        NUMERIC(16,2) NOT NULL CHECK (amount > 0),
    balance_after NUMERIC(16,2) NOT NULL,
    description   VARCHAR(200),
    txn_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at    TIMESTAMPTZ DEFAULT now()
);

-- 5. beneficiaries — saved payees
CREATE TABLE IF NOT EXISTS beneficiaries (
    id             SERIAL PRIMARY KEY,
    account_id     INT NOT NULL REFERENCES accounts(id),
    name           VARCHAR(120) NOT NULL,
    bank_name      VARCHAR(120),
    account_number VARCHAR(24) NOT NULL,
    created_at     TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_acc_accounts_customer ON accounts(customer_id);
CREATE INDEX IF NOT EXISTS idx_acc_accounts_branch   ON accounts(branch_id);
CREATE INDEX IF NOT EXISTS idx_acc_txn_account       ON transactions(account_id);
CREATE INDEX IF NOT EXISTS idx_acc_txn_type          ON transactions(txn_type);
CREATE INDEX IF NOT EXISTS idx_acc_benef_account     ON beneficiaries(account_id);

CREATE OR REPLACE VIEW v_branch_balances AS
SELECT
    b.name           AS branch,
    COUNT(DISTINCT a.id)        AS account_count,
    COALESCE(SUM(a.balance), 0) AS total_balance,
    ROUND(AVG(a.balance), 2)    AS avg_balance
FROM branches b
LEFT JOIN accounts a ON a.branch_id = b.id AND a.status = 'active'
GROUP BY b.id, b.name
ORDER BY total_balance DESC;
