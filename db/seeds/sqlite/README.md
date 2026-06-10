# Seed — SQLite

Dữ liệu mẫu cho SQLite: **17 bảng** quan hệ + **3 views** + **4 triggers**, **~51k dòng**. Trạng thái dùng ràng buộc **CHECK** (SQLite không có ENUM/object type). Dữ liệu tổng hợp, chỉ để test.

---

## 1. File

- `schema.sql` — tạo 17 bảng (`INTEGER PRIMARY KEY`, khoá ngoại inline, `CHECK` cho cột trạng thái) → views → triggers.
- `data.sql` — dữ liệu (INSERT theo lô 500 dòng, transaction).
- `build.sh` — dựng file `.sqlite` từ hai file trên.
- `jdb_sample.sqlite` — **file dựng sẵn** (dùng được ngay).

---

## 2. Dùng ngay

SQLite không cần server — mở thẳng file trong JiveDB:

| Trường | Giá trị |
|---|---|
| Loại | SQLite |
| Đường dẫn file | `db/seeds/sqlite/jdb_sample.sqlite` |

> Docker không phục vụ SQLite (nó là file). Dùng trực tiếp file, không qua `docker compose`.

---

## 3. Dựng lại file

```bash
cd db/seeds/sqlite && ./build.sh           # → jdb_sample.sqlite
# hoặc tên khác:    ./build.sh my.sqlite
```

Hoặc thủ công:

```bash
sqlite3 jdb_sample.sqlite < schema.sql
sqlite3 jdb_sample.sqlite < data.sql
```

---

## 4. Kiểm tra nhanh

```bash
sqlite3 jdb_sample.sqlite "SELECT count(*) FROM orders;"
sqlite3 -header -column jdb_sample.sqlite \
  "SELECT u.full_name, count(o.id) AS orders
   FROM users u JOIN orders o ON o.user_id=u.id
   GROUP BY u.id ORDER BY orders DESC LIMIT 5;"
```

---

## 5. Ghi chú

- Sinh lại SQL: `node db/seeds/generate.mjs`, rồi `./build.sh` để dựng lại file.
