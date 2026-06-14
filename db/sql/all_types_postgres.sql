-- PostgreSQL: bảng phủ mọi kiểu dữ liệu + 20 dòng demo.
-- Chạy: psql -d <db> -f all_types_postgres.sql   (cần PostgreSQL 13+ cho gen_random_uuid)

DROP TABLE IF EXISTS all_types;
DROP TYPE IF EXISTS mood;
CREATE TYPE mood AS ENUM ('happy', 'sad', 'neutral');

CREATE TABLE all_types (
  id            serial PRIMARY KEY,
  c_smallint    smallint,
  c_integer     integer,
  c_bigint      bigint,
  c_numeric     numeric(12,2),
  c_real        real,
  c_double      double precision,
  c_money       money,
  c_boolean     boolean,
  c_char        char(4),
  c_varchar     varchar(50),
  c_text        text,
  c_uuid        uuid,
  c_date        date,
  c_time        time,
  c_timestamp   timestamp,
  c_timestamptz timestamptz,
  c_interval    interval,
  c_json        json,
  c_jsonb       jsonb,
  c_bytea       bytea,
  c_inet        inet,
  c_cidr        cidr,
  c_macaddr     macaddr,
  c_bit         bit(8),
  c_varbit      varbit(8),
  c_point       point,
  c_line        line,
  c_lseg        lseg,
  c_box         box,
  c_path        path,
  c_polygon     polygon,
  c_circle      circle,
  c_int_arr     integer[],
  c_text_arr    text[],
  c_enum        mood,
  c_tsvector    tsvector,
  c_xml         xml
);

INSERT INTO all_types (
  c_smallint, c_integer, c_bigint, c_numeric, c_real, c_double, c_money, c_boolean,
  c_char, c_varchar, c_text, c_uuid, c_date, c_time, c_timestamp, c_timestamptz, c_interval,
  c_json, c_jsonb, c_bytea, c_inet, c_cidr, c_macaddr, c_bit, c_varbit,
  c_point, c_line, c_lseg, c_box, c_path, c_polygon, c_circle,
  c_int_arr, c_text_arr, c_enum, c_tsvector, c_xml
)
SELECT
  (g % 100)::smallint,
  g * 10,
  g * 1000000::bigint,
  (g * 1.5)::numeric(12,2),
  (g * 0.25)::real,
  g * 3.14159,
  (g * 9.99)::numeric::money,
  (g % 2 = 0),
  lpad(g::text, 4, '0'),
  'name_' || g,
  'Long description text for row ' || g,
  gen_random_uuid(),
  DATE '2024-01-01' + g,
  TIME '08:00:00' + (g || ' minutes')::interval,
  TIMESTAMP '2024-01-01 08:00:00' + (g || ' hours')::interval,
  TIMESTAMPTZ '2024-01-01 08:00:00+00' + (g || ' hours')::interval,
  (g || ' days')::interval,
  json_build_object('row', g, 'ok', g % 2 = 0),
  jsonb_build_object('row', g, 'tags', jsonb_build_array('a', 'b', g)),
  decode(lpad(to_hex(g), 2, '0'), 'hex'),
  ('192.168.1.' || (g % 255))::inet,
  ('10.' || (g % 255) || '.0.0/16')::cidr,
  ('08:00:2b:01:02:' || lpad(to_hex(g % 255), 2, '0'))::macaddr,
  g::bit(8),
  g::bit(8)::varbit,
  point(g, g * 2),
  ('{1,-1,' || (-g) || '}')::line,
  lseg(point(0, 0), point(g, g)),
  box(point(0, 0), point(g, g)),
  ('[(0,0),(' || g || ',' || g || ')]')::path,
  ('((0,0),(' || g || ',0),(' || g || ',' || g || '))')::polygon,
  circle(point(g, g), g),
  ARRAY[g, g * 2, g * 3],
  ARRAY['tag' || g, 'x', 'y'],
  (ARRAY['happy', 'sad', 'neutral'])[(g % 3) + 1]::mood,
  to_tsvector('english', 'row ' || g || ' demo text'),
  ('<row id="' || g || '"/>')::xml
FROM generate_series(1, 20) AS g;

-- Mô tả cột (hiển thị ở tooltip header trong JiveDB).
COMMENT ON COLUMN all_types.id            IS 'Khóa chính tự tăng (serial).';
COMMENT ON COLUMN all_types.c_smallint    IS 'Số nguyên nhỏ (2 byte).';
COMMENT ON COLUMN all_types.c_integer     IS 'Số nguyên 4 byte.';
COMMENT ON COLUMN all_types.c_bigint      IS 'Số nguyên lớn 8 byte.';
COMMENT ON COLUMN all_types.c_numeric     IS 'Số thập phân chính xác (12,2).';
COMMENT ON COLUMN all_types.c_real        IS 'Số thực dấu phẩy động 4 byte.';
COMMENT ON COLUMN all_types.c_double      IS 'Số thực dấu phẩy động 8 byte.';
COMMENT ON COLUMN all_types.c_money       IS 'Giá trị tiền tệ.';
COMMENT ON COLUMN all_types.c_boolean     IS 'Giá trị luận lý true/false.';
COMMENT ON COLUMN all_types.c_char        IS 'Chuỗi cố định 4 ký tự.';
COMMENT ON COLUMN all_types.c_varchar     IS 'Chuỗi tối đa 50 ký tự.';
COMMENT ON COLUMN all_types.c_text        IS 'Văn bản dài không giới hạn.';
COMMENT ON COLUMN all_types.c_uuid        IS 'Định danh duy nhất UUID.';
COMMENT ON COLUMN all_types.c_date        IS 'Ngày (không có giờ).';
COMMENT ON COLUMN all_types.c_time        IS 'Giờ trong ngày.';
COMMENT ON COLUMN all_types.c_timestamp   IS 'Mốc thời gian (không timezone).';
COMMENT ON COLUMN all_types.c_timestamptz IS 'Mốc thời gian kèm timezone.';
COMMENT ON COLUMN all_types.c_interval    IS 'Khoảng thời gian.';
COMMENT ON COLUMN all_types.c_json        IS 'Dữ liệu JSON (văn bản).';
COMMENT ON COLUMN all_types.c_jsonb       IS 'Dữ liệu JSON nhị phân (jsonb).';
COMMENT ON COLUMN all_types.c_bytea       IS 'Dữ liệu nhị phân thô.';
COMMENT ON COLUMN all_types.c_inet        IS 'Địa chỉ IP (host).';
COMMENT ON COLUMN all_types.c_cidr        IS 'Dải mạng IP (CIDR).';
COMMENT ON COLUMN all_types.c_macaddr     IS 'Địa chỉ MAC.';
COMMENT ON COLUMN all_types.c_bit         IS 'Chuỗi bit cố định 8 bit.';
COMMENT ON COLUMN all_types.c_varbit      IS 'Chuỗi bit thay đổi tối đa 8 bit.';
COMMENT ON COLUMN all_types.c_point       IS 'Điểm hình học (x, y).';
COMMENT ON COLUMN all_types.c_line        IS 'Đường thẳng {A, B, C}.';
COMMENT ON COLUMN all_types.c_lseg        IS 'Đoạn thẳng [(x1,y1),(x2,y2)].';
COMMENT ON COLUMN all_types.c_box         IS 'Hình chữ nhật (2 góc đối).';
COMMENT ON COLUMN all_types.c_path        IS 'Đường gấp khúc (mở/đóng).';
COMMENT ON COLUMN all_types.c_polygon     IS 'Đa giác (chuỗi điểm).';
COMMENT ON COLUMN all_types.c_circle      IS 'Hình tròn <(x,y), r>.';
COMMENT ON COLUMN all_types.c_int_arr     IS 'Mảng số nguyên.';
COMMENT ON COLUMN all_types.c_text_arr    IS 'Mảng chuỗi.';
COMMENT ON COLUMN all_types.c_enum        IS 'Kiểu liệt kê: happy/sad/neutral.';
COMMENT ON COLUMN all_types.c_tsvector    IS 'Vector tìm kiếm toàn văn.';
COMMENT ON COLUMN all_types.c_xml         IS 'Dữ liệu XML.';
