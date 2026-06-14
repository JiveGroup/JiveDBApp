-- ============================================================================
-- JDB demo · PostgreSQL partitioned tables
-- ----------------------------------------------------------------------------
-- Purpose : sample objects to exercise the partition tree in JDB
--           (parent table -> partitions -> sub-partitions).
-- Data    : synthetic / test-only. No real or sensitive data.
-- Run     : psql -h <host> -U <user> -d <database> -f partition_postgres.sql
-- Cleanup : DROP SCHEMA partition_demo CASCADE;
-- ============================================================================

-- Keep demo objects isolated in their own schema.
CREATE SCHEMA IF NOT EXISTS partition_demo;
SET search_path TO partition_demo;

-- ── 1. RANGE partition, with one child that is itself partitioned ────────────
-- `sales` is partitioned by sale_date. The 2024 child is sub-partitioned by
-- HASH(region) → this is the multi-level (sub-partition) case.
-- Note: every partition-key column must be part of the primary key, at each
--       level → PK includes sale_date (level 1) and region (level 2).
DROP TABLE IF EXISTS sales CASCADE;
CREATE TABLE sales (
    id         bigint        GENERATED ALWAYS AS IDENTITY,
    sale_date  date          NOT NULL,
    region     text          NOT NULL,
    amount     numeric(12,2) NOT NULL,
    PRIMARY KEY (id, sale_date, region)
) PARTITION BY RANGE (sale_date);

-- plain RANGE child (a leaf partition)
CREATE TABLE sales_2023 PARTITION OF sales
    FOR VALUES FROM ('2023-01-01') TO ('2024-01-01');

-- this child is partitioned again → its own sub-partitions (level 2)
CREATE TABLE sales_2024 PARTITION OF sales
    FOR VALUES FROM ('2024-01-01') TO ('2025-01-01')
    PARTITION BY HASH (region);
CREATE TABLE sales_2024_h0 PARTITION OF sales_2024
    FOR VALUES WITH (MODULUS 2, REMAINDER 0);
CREATE TABLE sales_2024_h1 PARTITION OF sales_2024
    FOR VALUES WITH (MODULUS 2, REMAINDER 1);

-- catch-all for rows outside every defined range
CREATE TABLE sales_default PARTITION OF sales DEFAULT;

INSERT INTO sales (sale_date, region, amount) VALUES
    ('2023-03-15', 'north', 120.00),
    ('2023-07-01', 'south',  80.50),
    ('2024-02-20', 'north', 200.00),
    ('2024-02-21', 'south',  50.00),
    ('2024-09-09', 'east',   99.99),
    ('2025-01-05', 'west',   10.00);   -- no 2025 range → lands in sales_default

-- ── 2. LIST partition ────────────────────────────────────────────────────────
DROP TABLE IF EXISTS customers CASCADE;
CREATE TABLE customers (
    id      bigint GENERATED ALWAYS AS IDENTITY,
    region  text   NOT NULL,
    name    text   NOT NULL,
    PRIMARY KEY (id, region)
) PARTITION BY LIST (region);

CREATE TABLE customers_apac  PARTITION OF customers FOR VALUES IN ('vn', 'jp', 'sg');
CREATE TABLE customers_emea  PARTITION OF customers FOR VALUES IN ('de', 'fr', 'uk');
CREATE TABLE customers_other PARTITION OF customers DEFAULT;

INSERT INTO customers (region, name) VALUES
    ('vn', 'Alpha'), ('jp', 'Bravo'), ('de', 'Charlie'), ('us', 'Delta');

-- ── 3. HASH partition ────────────────────────────────────────────────────────
DROP TABLE IF EXISTS events CASCADE;
CREATE TABLE events (
    id       bigint GENERATED ALWAYS AS IDENTITY,
    payload  text,
    PRIMARY KEY (id)
) PARTITION BY HASH (id);

CREATE TABLE events_p0 PARTITION OF events FOR VALUES WITH (MODULUS 3, REMAINDER 0);
CREATE TABLE events_p1 PARTITION OF events FOR VALUES WITH (MODULUS 3, REMAINDER 1);
CREATE TABLE events_p2 PARTITION OF events FOR VALUES WITH (MODULUS 3, REMAINDER 2);

INSERT INTO events (payload)
SELECT 'evt-' || g FROM generate_series(1, 30) AS g;

-- Quick check: list partitions and their bounds.
-- SELECT inhrelid::regclass AS partition,
--        pg_get_expr(c.relpartbound, c.oid) AS bound
-- FROM pg_inherits i JOIN pg_class c ON c.oid = i.inhrelid
-- WHERE i.inhparent = 'partition_demo.sales'::regclass;
