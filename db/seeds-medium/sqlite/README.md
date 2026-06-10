# Seed — SQLite (TẦM TRUNG)

Dữ liệu sinh tự động: **100 bảng** quan hệ (FK inline), ~9.029 dòng. Chỉ để test.

## 1. File
- `schema.sql` — 100 bảng (`INTEGER PRIMARY KEY AUTOINCREMENT`, FK inline).
- `data.sql` — dữ liệu (INSERT theo lô 200 dòng, transaction).
- `build.sh` — dựng file `.sqlite` từ hai file trên.
- `jdb_medium.sqlite` — **file dựng sẵn** (mở được ngay trong JiveDB).
- `queries.sql` — câu truy vấn demo.

## 2. Dùng ngay
SQLite không cần server — mở thẳng file: `db/seeds-medium/sqlite/jdb_medium.sqlite`.

## 3. Dựng lại file
```bash
cd db/seeds-medium/sqlite && ./build.sh   # → jdb_medium.sqlite
```

## 4. Sinh lại SQL
`node db/seeds-medium/generate.mjs` rồi `./build.sh`.

