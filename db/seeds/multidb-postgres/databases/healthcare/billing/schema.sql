-- Healthcare › billing schema: revenue cycle (5 tables + 1 view).
-- Idempotent: safe to re-run (uses IF NOT EXISTS / OR REPLACE).

CREATE SCHEMA IF NOT EXISTS billing;
SET search_path = billing;

-- 1. insurers — insurance providers
CREATE TABLE IF NOT EXISTS insurers (
    id            SERIAL PRIMARY KEY,
    name          VARCHAR(120) NOT NULL,
    country       VARCHAR(40),
    plan_type     VARCHAR(20) NOT NULL CHECK (plan_type IN ('public','private','employer','supplemental')),
    contact_email VARCHAR(255),
    created_at    TIMESTAMPTZ DEFAULT now()
);

-- 2. services — billable service catalog
CREATE TABLE IF NOT EXISTS services (
    id          SERIAL PRIMARY KEY,
    code        VARCHAR(20) NOT NULL UNIQUE,
    name        VARCHAR(150) NOT NULL,
    category    VARCHAR(60) NOT NULL,
    unit_price  NUMERIC(12,2) NOT NULL CHECK (unit_price > 0),
    created_at  TIMESTAMPTZ DEFAULT now()
);

-- 3. invoices — patient invoices (patient lives in clinical schema; referenced by id)
CREATE TABLE IF NOT EXISTS invoices (
    id             SERIAL PRIMARY KEY,
    patient_id     INT NOT NULL,
    insurer_id     INT REFERENCES insurers(id),
    invoice_number VARCHAR(30) NOT NULL UNIQUE,
    amount         NUMERIC(14,2) NOT NULL CHECK (amount >= 0),
    status         VARCHAR(20) NOT NULL DEFAULT 'open' CHECK (status IN ('open','sent','paid','partially_paid','overdue','written_off')),
    issued_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    due_date       DATE NOT NULL,
    created_at     TIMESTAMPTZ DEFAULT now()
);

-- 4. claims — insurance claims against invoices
CREATE TABLE IF NOT EXISTS claims (
    id            SERIAL PRIMARY KEY,
    invoice_id    INT NOT NULL REFERENCES invoices(id),
    insurer_id    INT NOT NULL REFERENCES insurers(id),
    claim_number  VARCHAR(30) NOT NULL UNIQUE,
    amount        NUMERIC(14,2) NOT NULL CHECK (amount >= 0),
    status        VARCHAR(20) NOT NULL DEFAULT 'submitted' CHECK (status IN ('submitted','in_review','approved','partially_approved','denied','paid')),
    submitted_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    resolved_at   TIMESTAMPTZ,
    created_at    TIMESTAMPTZ DEFAULT now()
);

-- 5. payments — payments against invoices
CREATE TABLE IF NOT EXISTS payments (
    id          SERIAL PRIMARY KEY,
    invoice_id  INT NOT NULL REFERENCES invoices(id),
    method      VARCHAR(20) NOT NULL CHECK (method IN ('cash','card','insurance','bank_transfer')),
    amount      NUMERIC(14,2) NOT NULL CHECK (amount >= 0),
    paid_at     TIMESTAMPTZ,
    created_at  TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_bil_inv_insurer  ON invoices(insurer_id);
CREATE INDEX IF NOT EXISTS idx_bil_inv_status   ON invoices(status);
CREATE INDEX IF NOT EXISTS idx_bil_claims_inv   ON claims(invoice_id);
CREATE INDEX IF NOT EXISTS idx_bil_pay_inv      ON payments(invoice_id);

CREATE OR REPLACE VIEW v_claims_by_insurer AS
SELECT
    i.name           AS insurer,
    i.plan_type,
    COUNT(c.id)      AS claim_count,
    COALESCE(SUM(c.amount), 0) AS total_claimed,
    COUNT(c.id) FILTER (WHERE c.status IN ('approved','paid')) AS approved_count
FROM insurers i
LEFT JOIN claims c ON c.insurer_id = i.id
GROUP BY i.id, i.name, i.plan_type
ORDER BY total_claimed DESC;
