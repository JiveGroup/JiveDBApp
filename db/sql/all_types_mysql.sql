-- MySQL 8.0+: bảng phủ mọi kiểu dữ liệu + 20 dòng demo (dùng CTE đệ quy).
-- Chạy: mysql <db> < all_types_mysql.sql

DROP TABLE IF EXISTS all_types;

CREATE TABLE all_types (
  id            INT AUTO_INCREMENT PRIMARY KEY,
  c_tinyint     TINYINT,
  c_smallint    SMALLINT,
  c_mediumint   MEDIUMINT,
  c_int         INT,
  c_bigint      BIGINT,
  c_decimal     DECIMAL(12,2),
  c_float       FLOAT,
  c_double      DOUBLE,
  c_bit         BIT(8),
  c_boolean     BOOLEAN,
  c_char        CHAR(4),
  c_varchar     VARCHAR(50),
  c_tinytext    TINYTEXT,
  c_text        TEXT,
  c_mediumtext  MEDIUMTEXT,
  c_longtext    LONGTEXT,
  c_date        DATE,
  c_time        TIME,
  c_datetime    DATETIME,
  c_timestamp   TIMESTAMP NULL,
  c_year        YEAR,
  c_binary      BINARY(4),
  c_varbinary   VARBINARY(16),
  c_tinyblob    TINYBLOB,
  c_blob        BLOB,
  c_mediumblob  MEDIUMBLOB,
  c_json        JSON,
  c_enum        ENUM('red', 'green', 'blue'),
  c_set         SET('x', 'y', 'z')
);

INSERT INTO all_types (
  c_tinyint, c_smallint, c_mediumint, c_int, c_bigint, c_decimal, c_float, c_double, c_bit, c_boolean,
  c_char, c_varchar, c_tinytext, c_text, c_mediumtext, c_longtext,
  c_date, c_time, c_datetime, c_timestamp, c_year,
  c_binary, c_varbinary, c_tinyblob, c_blob, c_mediumblob,
  c_json, c_enum, c_set
)
WITH RECURSIVE seq (g) AS (
  SELECT 1 UNION ALL SELECT g + 1 FROM seq WHERE g < 20
)
SELECT
  g % 128,
  g * 100,
  g * 1000,
  g * 10000,
  g * 1000000,
  g * 1.5,
  g * 0.25,
  g * 3.14159,
  g % 256,
  g % 2,
  LPAD(g, 4, '0'),
  CONCAT('name_', g),
  CONCAT('tiny ', g),
  CONCAT('Text row ', g),
  CONCAT('Medium text row ', g),
  CONCAT('Long text row ', g),
  DATE_ADD('2024-01-01', INTERVAL g DAY),
  SEC_TO_TIME(g * 60),
  DATE_ADD('2024-01-01 08:00:00', INTERVAL g HOUR),
  DATE_ADD('2024-01-01 08:00:00', INTERVAL g HOUR),
  2000 + (g % 50),
  UNHEX(LPAD(HEX(g), 8, '0')),
  CONCAT('bin', g),
  CONCAT('tinyblob', g),
  CONCAT('blob data ', g),
  CONCAT('medium blob ', g),
  JSON_OBJECT('row', g, 'ok', g % 2 = 0, 'tags', JSON_ARRAY('a', 'b', g)),
  ELT((g % 3) + 1, 'red', 'green', 'blue'),
  ELT((g % 3) + 1, 'x', 'x,y', 'x,y,z')
FROM seq;
