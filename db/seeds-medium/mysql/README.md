# Seed — MySQL (TẦM TRUNG)

Dữ liệu sinh tự động: **100 bảng** quan hệ (FK inline), ~9.029 dòng. Chỉ để test.

## 1. File
- `01-schema.sql` — 100 bảng (`bigint AUTO_INCREMENT` PK, FK inline; `FOREIGN_KEY_CHECKS=0` khi tạo).
- `02-data.sql` — dữ liệu (INSERT theo lô 200 dòng).
- `queries.sql` — câu truy vấn demo.

## 2. Nạp qua Docker (đặt bộ này làm seed mặc định)
```bash
JDB_SEED=seeds-medium docker compose down -v && JDB_SEED=seeds-medium docker compose up -d
```

## 3. Nạp thủ công (DB riêng)
```bash
mysql -e "CREATE DATABASE jdb_medium"
mysql jdb_medium < 01-schema.sql
mysql jdb_medium < 02-data.sql
```

## 4. Sinh lại
`node db/seeds-medium/generate.mjs`

