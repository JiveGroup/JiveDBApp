# Seed — MariaDB

Dữ liệu mẫu cho MariaDB: **17 bảng** quan hệ + **3 views** + **4 triggers**, **~51k dòng**. Trạng thái dùng cột **ENUM**. Dữ liệu tổng hợp, chỉ để test. Seed files tương thích với MySQL nên được sao chép trực tiếp.

---

## 1. File

- `01-schema.sql` — tạo 17 bảng (`InnoDB`, `AUTO_INCREMENT`, khoá ngoại, cột **ENUM**) → views → triggers (dùng `DELIMITER $$`).
- `02-data.sql` — dữ liệu (INSERT theo lô 500 dòng, transaction; tắt `FOREIGN_KEY_CHECKS` khi nạp).
- `queries.sql` — demo queries.

---

## 2. Tự nạp qua Docker

```bash
docker compose up -d mariadb
docker compose down -v && docker compose up -d mariadb   # nạp lại từ đầu
```

---

## 3. Nạp thủ công

```bash
mariadb -h 127.0.0.1 -P 3309 -u jdb -pjdbtest jdb_dev < 01-schema.sql
mariadb -h 127.0.0.1 -P 3309 -u jdb -pjdbtest jdb_dev < 02-data.sql
```

---

## 4. Kết nối từ JiveDB

| Trường | Giá trị |
|---|---|
| Loại | MariaDB |
| Host / Port | localhost / 3309 |
| Username / Password | jdb / jdbtest |
| Database | jdb_dev |
