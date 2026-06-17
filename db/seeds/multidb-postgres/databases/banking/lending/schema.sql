-- Banking › lending schema: loans (5 tables + 1 view).
-- Idempotent: safe to re-run (uses IF NOT EXISTS / OR REPLACE).

CREATE SCHEMA IF NOT EXISTS lending;
SET search_path = lending;

-- 1. applications — loan applications (customer lives in accounts schema; referenced by id)
CREATE TABLE IF NOT EXISTS applications (
    id           SERIAL PRIMARY KEY,
    customer_id  INT NOT NULL,
    product      VARCHAR(20) NOT NULL CHECK (product IN ('personal','mortgage','auto','business','student')),
    amount       NUMERIC(16,2) NOT NULL CHECK (amount > 0),
    status       VARCHAR(20) NOT NULL DEFAULT 'submitted' CHECK (status IN ('submitted','under_review','approved','rejected','withdrawn')),
    applied_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at   TIMESTAMPTZ DEFAULT now()
);

-- 2. loans — disbursed loans
CREATE TABLE IF NOT EXISTS loans (
    id             SERIAL PRIMARY KEY,
    application_id INT NOT NULL REFERENCES applications(id),
    loan_number    VARCHAR(24) NOT NULL UNIQUE,
    principal      NUMERIC(16,2) NOT NULL CHECK (principal > 0),
    interest_rate  NUMERIC(5,2) NOT NULL CHECK (interest_rate >= 0),
    term_months    INT NOT NULL CHECK (term_months > 0),
    status         VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (status IN ('active','paid_off','delinquent','defaulted','restructured')),
    disbursed_at   DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at     TIMESTAMPTZ DEFAULT now()
);

-- 3. collaterals — assets securing loans
CREATE TABLE IF NOT EXISTS collaterals (
    id           SERIAL PRIMARY KEY,
    loan_id      INT NOT NULL REFERENCES loans(id),
    kind         VARCHAR(20) NOT NULL CHECK (kind IN ('property','vehicle','deposit','equipment','securities')),
    description  VARCHAR(200),
    value        NUMERIC(16,2) NOT NULL CHECK (value > 0),
    created_at   TIMESTAMPTZ DEFAULT now()
);

-- 4. repayments — actual repayments
CREATE TABLE IF NOT EXISTS repayments (
    id             SERIAL PRIMARY KEY,
    loan_id        INT NOT NULL REFERENCES loans(id),
    amount         NUMERIC(14,2) NOT NULL CHECK (amount > 0),
    principal_part NUMERIC(14,2) NOT NULL DEFAULT 0,
    interest_part  NUMERIC(14,2) NOT NULL DEFAULT 0,
    paid_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at     TIMESTAMPTZ DEFAULT now()
);

-- 5. schedules — amortization schedule
CREATE TABLE IF NOT EXISTS schedules (
    id          SERIAL PRIMARY KEY,
    loan_id     INT NOT NULL REFERENCES loans(id),
    due_date    DATE NOT NULL,
    installment NUMERIC(14,2) NOT NULL CHECK (installment > 0),
    is_paid     BOOLEAN NOT NULL DEFAULT false,
    created_at  TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_len_loans_app      ON loans(application_id);
CREATE INDEX IF NOT EXISTS idx_len_loans_status   ON loans(status);
CREATE INDEX IF NOT EXISTS idx_len_collat_loan    ON collaterals(loan_id);
CREATE INDEX IF NOT EXISTS idx_len_repay_loan     ON repayments(loan_id);
CREATE INDEX IF NOT EXISTS idx_len_sched_loan     ON schedules(loan_id);

CREATE OR REPLACE VIEW v_loan_portfolio AS
SELECT
    l.status,
    COUNT(*)                       AS loan_count,
    COALESCE(SUM(l.principal), 0)  AS total_principal,
    ROUND(AVG(l.interest_rate), 2) AS avg_rate
FROM loans l
GROUP BY l.status
ORDER BY total_principal DESC;
