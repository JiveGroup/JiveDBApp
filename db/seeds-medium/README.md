# Dữ liệu mẫu — bộ TẦM TRUNG

Bộ dữ liệu tổng hợp **lớn**, **tách biệt hoàn toàn** với `db/seeds/` (bộ nhỏ mặc định). Dùng để thử nghiệm hiệu năng UI / duyệt nhiều bảng và nhiều dòng. Dùng qua Docker bằng biến môi trường `JDB_SEED=seeds-medium` (xem `docker-compose.yml`).

- **100 bảng** có quan hệ (FK) cho mỗi CSDL quan hệ, mỗi loại **2 file**: schema + data.
- **~199k dòng/dialect** (≈ 800–3000 dòng mỗi bảng) → file SQLite ~14 MB, lớn hơn hẳn bộ nhỏ (~51k dòng).
- **Redis ~5000 key** đa kiểu (string / hash / list / set / zset).
- Sinh tất định (RNG có seed) → chạy lại cho kết quả giống nhau.

---

## 1. Cấu trúc

```
postgres/01-schema.sql  postgres/02-data.sql
mysql/01-schema.sql     mysql/02-data.sql
sqlite/schema.sql       sqlite/data.sql
redis/seed.redis
generate.mjs
```

---

## 2. Sinh lại

```bash
node db/seeds-medium/generate.mjs
```

Chỉnh quy mô trong `generate.mjs`: `TABLE_COUNT`, `ROWS_MIN/MAX`, `REDIS_KEYS`.

---

## 3. Nạp dữ liệu (vào DB/instance RIÊNG, không trùng bộ cũ)

PostgreSQL:

```bash
createdb jdb_medium
psql jdb_medium -f db/seeds-medium/postgres/01-schema.sql
psql jdb_medium -f db/seeds-medium/postgres/02-data.sql
```

MySQL:

```bash
mysql -e "CREATE DATABASE jdb_medium"
mysql jdb_medium < db/seeds-medium/mysql/01-schema.sql
mysql jdb_medium < db/seeds-medium/mysql/02-data.sql
```

SQLite:

```bash
sqlite3 jdb_medium.sqlite < db/seeds-medium/sqlite/schema.sql
sqlite3 jdb_medium.sqlite < db/seeds-medium/sqlite/data.sql
```

Redis (nạp vào DB index khác, ví dụ `1`, để giữ nguyên DB 0):

```bash
redis-cli -n 1 < db/seeds-medium/redis/seed.redis
```

> Lưu ý: `redis/seed.redis` bắt đầu bằng `FLUSHDB` — sẽ **xoá sạch DB đang chọn** trước khi nạp. Hãy chọn đúng DB index trống.
