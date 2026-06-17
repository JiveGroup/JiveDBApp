-- Healthcare › pharmacy schema: drug supply (5 tables + 1 view).
-- Idempotent: safe to re-run (uses IF NOT EXISTS / OR REPLACE).

CREATE SCHEMA IF NOT EXISTS pharmacy;
SET search_path = pharmacy;

-- 1. suppliers — drug vendors
CREATE TABLE IF NOT EXISTS suppliers (
    id            SERIAL PRIMARY KEY,
    name          VARCHAR(120) NOT NULL,
    country       VARCHAR(40),
    contact_email VARCHAR(255),
    status        VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (status IN ('active','inactive','suspended')),
    created_at    TIMESTAMPTZ DEFAULT now()
);

-- 2. drugs — drug catalog
CREATE TABLE IF NOT EXISTS drugs (
    id           SERIAL PRIMARY KEY,
    name         VARCHAR(150) NOT NULL,
    generic_name VARCHAR(150),
    atc_code     VARCHAR(10) NOT NULL,
    form         VARCHAR(20) NOT NULL CHECK (form IN ('tablet','capsule','syrup','injection','inhaler','cream')),
    strength     VARCHAR(40),
    unit_price   NUMERIC(10,2) NOT NULL CHECK (unit_price > 0),
    is_controlled BOOLEAN DEFAULT false,
    created_at   TIMESTAMPTZ DEFAULT now()
);

-- 3. drug_inventory — stock batches
CREATE TABLE IF NOT EXISTS drug_inventory (
    id           SERIAL PRIMARY KEY,
    drug_id      INT NOT NULL REFERENCES drugs(id),
    batch_no     VARCHAR(40) NOT NULL UNIQUE,
    quantity     INT NOT NULL DEFAULT 0 CHECK (quantity >= 0),
    expiry_date  DATE,
    received_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at   TIMESTAMPTZ DEFAULT now()
);

-- 4. dispenses — medication handed out (prescription lives in clinical schema)
CREATE TABLE IF NOT EXISTS dispenses (
    id             SERIAL PRIMARY KEY,
    drug_id        INT NOT NULL REFERENCES drugs(id),
    prescription_id INT NOT NULL,
    quantity       INT NOT NULL CHECK (quantity > 0),
    pharmacist     VARCHAR(120) NOT NULL,
    dispensed_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at     TIMESTAMPTZ DEFAULT now()
);

-- 5. stock_moves — inventory movement log
CREATE TABLE IF NOT EXISTS stock_moves (
    id           SERIAL PRIMARY KEY,
    drug_id      INT NOT NULL REFERENCES drugs(id),
    move_type    VARCHAR(20) NOT NULL CHECK (move_type IN ('receipt','dispense','adjustment','return','expiry_writeoff')),
    quantity     INT NOT NULL CHECK (quantity <> 0),
    reason       VARCHAR(120),
    moved_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at   TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_phr_inv_drug    ON drug_inventory(drug_id);
CREATE INDEX IF NOT EXISTS idx_phr_disp_drug   ON dispenses(drug_id);
CREATE INDEX IF NOT EXISTS idx_phr_moves_drug  ON stock_moves(drug_id);
CREATE INDEX IF NOT EXISTS idx_phr_moves_type  ON stock_moves(move_type);

CREATE OR REPLACE VIEW v_drug_stock AS
SELECT
    d.name           AS drug,
    d.form,
    d.is_controlled,
    COALESCE(SUM(i.quantity), 0) AS on_hand,
    COUNT(i.id)                  AS batch_count
FROM drugs d
LEFT JOIN drug_inventory i ON i.drug_id = d.id
GROUP BY d.id, d.name, d.form, d.is_controlled
ORDER BY on_hand DESC;
