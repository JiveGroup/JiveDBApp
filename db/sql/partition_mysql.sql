-- ============================================================================
-- JDB demo · MySQL partitioned tables
-- ----------------------------------------------------------------------------
-- Purpose : sample objects to exercise the partition tree in JDB
--           (parent table -> partitions -> sub-partitions).
-- Data    : synthetic / test-only. No real or sensitive data.
-- Run     : mysql -h <host> -u <user> -p <database> < partition_mysql.sql
-- Note    : MySQL partitions are NOT separate tables. JDB reads one partition
--           with  SELECT ... FROM <table> PARTITION (<partition_name>).
--           Every column used in a partition/sub-partition expression must be
--           part of every unique key (including the primary key).
-- ============================================================================

-- ── 1. RANGE + HASH sub-partitions (multi-level) ─────────────────────────────
-- Partitioned by YEAR(sale_date); each partition is sub-partitioned by HASH.
DROP TABLE IF EXISTS sales;
CREATE TABLE sales (
    id         INT           NOT NULL AUTO_INCREMENT,
    sale_date  DATE          NOT NULL,
    region     VARCHAR(20)   NOT NULL,
    amount     DECIMAL(12,2) NOT NULL,
    PRIMARY KEY (id, sale_date)
)
PARTITION BY RANGE (YEAR(sale_date))
SUBPARTITION BY HASH (TO_DAYS(sale_date))
SUBPARTITIONS 2 (
    PARTITION p2023 VALUES LESS THAN (2024),
    PARTITION p2024 VALUES LESS THAN (2025),
    PARTITION pmax  VALUES LESS THAN MAXVALUE
);

INSERT INTO sales (sale_date, region, amount) VALUES
    ('2023-03-15', 'north', 120.00),
    ('2023-07-01', 'south',  80.50),
    ('2024-02-20', 'north', 200.00),
    ('2024-09-09', 'east',   99.99),
    ('2025-01-05', 'west',   10.00);   -- lands in pmax

-- ── 2. LIST COLUMNS partition ─────────────────────────────────────────────────
-- MySQL LIST has no DEFAULT partition → only insert values that are covered.
DROP TABLE IF EXISTS customers;
CREATE TABLE customers (
    id      INT         NOT NULL AUTO_INCREMENT,
    region  VARCHAR(8)  NOT NULL,
    name    VARCHAR(50) NOT NULL,
    PRIMARY KEY (id, region)
)
PARTITION BY LIST COLUMNS (region) (
    PARTITION p_apac VALUES IN ('vn', 'jp', 'sg'),
    PARTITION p_emea VALUES IN ('de', 'fr', 'uk')
);

INSERT INTO customers (region, name) VALUES
    ('vn', 'Alpha'), ('jp', 'Bravo'), ('de', 'Charlie');

-- ── 3. HASH partition ────────────────────────────────────────────────────────
DROP TABLE IF EXISTS events;
CREATE TABLE events (
    id       INT NOT NULL AUTO_INCREMENT,
    payload  VARCHAR(100),
    PRIMARY KEY (id)
)
PARTITION BY HASH (id) PARTITIONS 4;

INSERT INTO events (payload) VALUES
    ('evt-1'), ('evt-2'), ('evt-3'), ('evt-4'), ('evt-5'),
    ('evt-6'), ('evt-7'), ('evt-8'), ('evt-9'), ('evt-10');

-- Quick check: list partitions / sub-partitions and their descriptions.
-- SELECT PARTITION_NAME, SUBPARTITION_NAME, PARTITION_METHOD,
--        SUBPARTITION_METHOD, PARTITION_DESCRIPTION, TABLE_ROWS
-- FROM information_schema.PARTITIONS
-- WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'sales'
-- ORDER BY PARTITION_ORDINAL_POSITION, SUBPARTITION_ORDINAL_POSITION;
