-- SQLite: bảng phủ các kiểu khai báo (theo affinity) + 20 dòng demo.
-- Chạy: sqlite3 demo.db < all_types_sqlite.sql

DROP TABLE IF EXISTS all_types;

CREATE TABLE all_types (
  id          INTEGER PRIMARY KEY,
  c_int       INTEGER,
  c_bigint    BIGINT,
  c_real      REAL,
  c_double    DOUBLE,
  c_numeric   NUMERIC(12,2),
  c_boolean   BOOLEAN,
  c_char      CHAR(4),
  c_varchar   VARCHAR(50),
  c_text      TEXT,
  c_clob      CLOB,
  c_blob      BLOB,
  c_date      DATE,
  c_time      TIME,
  c_datetime  DATETIME,
  c_timestamp TIMESTAMP,
  c_json      JSON
);

INSERT INTO all_types (
  c_int, c_bigint, c_real, c_double, c_numeric, c_boolean,
  c_char, c_varchar, c_text, c_clob, c_blob,
  c_date, c_time, c_datetime, c_timestamp, c_json
)
WITH RECURSIVE seq (g) AS (
  SELECT 1 UNION ALL SELECT g + 1 FROM seq WHERE g < 20
)
SELECT
  g * 10,
  g * 1000000,
  g * 0.25,
  g * 3.14159,
  g * 1.5,
  g % 2,
  printf('%04d', g),
  'name_' || g,
  'Text row ' || g,
  'Clob row ' || g,
  randomblob(4),
  date('2024-01-01', '+' || g || ' day'),
  time('08:00:00', '+' || (g * 5) || ' minute'),
  datetime('2024-01-01 08:00:00', '+' || g || ' hour'),
  datetime('2024-01-01 08:00:00', '+' || g || ' hour'),
  json_object('row', g, 'ok', g % 2, 'tags', json_array('a', 'b', g))
FROM seq;
