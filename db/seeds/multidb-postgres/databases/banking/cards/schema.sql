-- Banking › cards schema: card payments (5 tables + 1 view).
-- Idempotent: safe to re-run (uses IF NOT EXISTS / OR REPLACE).

CREATE SCHEMA IF NOT EXISTS cards;
SET search_path = cards;

-- 1. merchants — card-accepting merchants
CREATE TABLE IF NOT EXISTS merchants (
    id          SERIAL PRIMARY KEY,
    name        VARCHAR(120) NOT NULL,
    category    VARCHAR(60) NOT NULL,
    mcc         VARCHAR(4) NOT NULL,
    country     VARCHAR(40),
    created_at  TIMESTAMPTZ DEFAULT now()
);

-- 2. cards — issued cards (account lives in accounts schema; referenced by id)
CREATE TABLE IF NOT EXISTS cards (
    id            SERIAL PRIMARY KEY,
    account_id    INT NOT NULL,
    card_masked   VARCHAR(19) NOT NULL UNIQUE,
    brand         VARCHAR(20) NOT NULL CHECK (brand IN ('visa','mastercard','amex','jcb','unionpay')),
    status        VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (status IN ('active','blocked','expired','lost','stolen')),
    expires_on    DATE NOT NULL,
    created_at    TIMESTAMPTZ DEFAULT now()
);

-- 3. authorizations — card authorization requests
CREATE TABLE IF NOT EXISTS authorizations (
    id            SERIAL PRIMARY KEY,
    card_id       INT NOT NULL REFERENCES cards(id),
    merchant_id   INT NOT NULL REFERENCES merchants(id),
    amount        NUMERIC(14,2) NOT NULL CHECK (amount > 0),
    currency      VARCHAR(3) NOT NULL DEFAULT 'USD',
    status        VARCHAR(20) NOT NULL DEFAULT 'approved' CHECK (status IN ('approved','declined','reversed','expired')),
    authorized_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at    TIMESTAMPTZ DEFAULT now()
);

-- 4. settlements — cleared authorizations
CREATE TABLE IF NOT EXISTS settlements (
    id               SERIAL PRIMARY KEY,
    authorization_id INT NOT NULL REFERENCES authorizations(id),
    amount           NUMERIC(14,2) NOT NULL CHECK (amount >= 0),
    status           VARCHAR(20) NOT NULL DEFAULT 'settled' CHECK (status IN ('settled','pending','failed')),
    settled_at       TIMESTAMPTZ,
    created_at       TIMESTAMPTZ DEFAULT now()
);

-- 5. disputes — chargebacks / disputes
CREATE TABLE IF NOT EXISTS disputes (
    id               SERIAL PRIMARY KEY,
    authorization_id INT NOT NULL REFERENCES authorizations(id),
    reason           VARCHAR(120) NOT NULL,
    amount           NUMERIC(14,2) NOT NULL CHECK (amount >= 0),
    status           VARCHAR(20) NOT NULL DEFAULT 'open' CHECK (status IN ('open','under_review','won','lost','withdrawn')),
    opened_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    resolved_at      TIMESTAMPTZ,
    created_at       TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_crd_auth_card      ON authorizations(card_id);
CREATE INDEX IF NOT EXISTS idx_crd_auth_merchant  ON authorizations(merchant_id);
CREATE INDEX IF NOT EXISTS idx_crd_settle_auth    ON settlements(authorization_id);
CREATE INDEX IF NOT EXISTS idx_crd_disputes_auth  ON disputes(authorization_id);

CREATE OR REPLACE VIEW v_merchant_volume AS
SELECT
    m.name           AS merchant,
    m.category,
    COUNT(a.id)      AS auth_count,
    COALESCE(SUM(a.amount) FILTER (WHERE a.status = 'approved'), 0) AS approved_volume
FROM merchants m
LEFT JOIN authorizations a ON a.merchant_id = m.id
GROUP BY m.id, m.name, m.category
ORDER BY approved_volume DESC;
