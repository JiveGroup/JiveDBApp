# Seed — PostgreSQL (TẦM TRUNG)

Dữ liệu sinh tự động: **100 bảng** quan hệ (FK inline), ~9.029 dòng. Chỉ để test.

## 1. File
- `01-schema.sql` — 100 bảng (`bigserial` PK, FK inline). Tiền tố số để chạy đúng thứ tự trong `/docker-entrypoint-initdb.d`.
- `02-data.sql` — dữ liệu (INSERT theo lô 200 dòng, trong transaction).
- `queries.sql` — câu truy vấn demo.

## 2. Nạp qua Docker (đặt bộ này làm seed mặc định)
```bash
JDB_SEED=seeds-medium docker compose down -v && JDB_SEED=seeds-medium docker compose up -d
```

## 3. Nạp thủ công (DB riêng)
```bash
createdb jdb_medium
psql jdb_medium -f 01-schema.sql -f 02-data.sql
```

## 4. Sinh lại
`node db/seeds-medium/generate.mjs`

