# Seed — MySQL

Dữ liệu mẫu cho MySQL: **17 bảng** quan hệ + **3 views** + **4 triggers**, **~51k dòng**. Trạng thái dùng cột **ENUM** (MySQL không có object type riêng). Dữ liệu tổng hợp, chỉ để test.

---

## 1. File

- `01-schema.sql` — tạo 17 bảng (`InnoDB`, `AUTO_INCREMENT`, khoá ngoại, cột **ENUM**) → views → triggers (dùng `DELIMITER $$`).
- `02-data.sql` — dữ liệu (INSERT theo lô 500 dòng, transaction; tắt `FOREIGN_KEY_CHECKS` khi nạp).

> File **không** chứa `CREATE DATABASE`/`USE` — Docker chạy chúng sẵn trên `jdb_dev`. Nạp tay thì chỉ định DB ở lệnh `mysql` (xem mục 3).

---

## 2. Tự nạp qua Docker

`docker-compose.yml` đã mount thư mục này vào MySQL. Khi tạo container lần đầu, hai file `*.sql` chạy tự động.

```bash
docker compose up -d
docker compose down -v && docker compose up -d   # nạp lại từ đầu
```

> MySQL khởi tạo lần đầu hơi lâu; chờ container "healthy" trước khi kết nối.

---

## 3. Nạp thủ công

```bash
mysql -h 127.0.0.1 -P 3306 -u jdb -pjdbtest jdb_dev < 01-schema.sql
mysql -h 127.0.0.1 -P 3306 -u jdb -pjdbtest jdb_dev < 02-data.sql
```

---

## 4. Kết nối từ JiveDB

| Trường | Giá trị |
|---|---|
| Loại | MySQL |
| Host / Port | localhost / 3306 |
| Username / Password | jdb / jdbtest |
| Database | jdb_dev |

---

## 5. Ghi chú

- MySQL coi **database = schema**; trong JiveDB, mở node database `jdb_dev` để thấy bảng.
- Có **4 functions** mẫu (`fn_full_name`, `fn_apply_discount`, `fn_order_total`, `fn_user_order_count`). Khi nạp cần quyền tạo function lúc bật binlog → schema có `SET GLOBAL log_bin_trust_function_creators = 1;` (docker chạy init bằng root nên OK; nạp tay cần quyền tương ứng).
- Sinh lại: `node db/seeds/generate.mjs`.
