# Seed — PostgreSQL

Dữ liệu mẫu cho PostgreSQL: **17 bảng** quan hệ + **3 views** + **4 triggers** + **object types** (7 ENUM, 1 DOMAIN, 1 composite), **~51k dòng**. Dữ liệu tổng hợp, chỉ để test.

---

## 1. File

- `01-schema.sql` — object types (`CREATE TYPE … AS ENUM`, `CREATE DOMAIN email_addr`, composite `geo_point`) → 17 bảng (`BIGSERIAL` PK, khoá ngoại inline) → views → functions + triggers.
- `02-data.sql` — dữ liệu (INSERT theo lô 500 dòng, trong transaction) + `setval` đồng bộ sequence ở cuối.

Tên file có tiền tố số để chạy đúng thứ tự trong `/docker-entrypoint-initdb.d`.

---

## 2. Tự nạp qua Docker

`docker-compose.yml` đã mount thư mục này vào PostgreSQL. Khi tạo container lần đầu, hai file `*.sql` chạy tự động trên database `jdb_dev`.

```bash
docker compose up -d           # nạp lần đầu
docker compose down -v && docker compose up -d   # nạp lại từ đầu
```

---

## 3. Nạp thủ công

```bash
psql "postgres://jdb:jdbtest@localhost:5432/jdb_dev" -f 01-schema.sql
psql "postgres://jdb:jdbtest@localhost:5432/jdb_dev" -f 02-data.sql
```

---

## 4. Kết nối từ JiveDB

| Trường | Giá trị |
|---|---|
| Loại | PostgreSQL |
| Host / Port | localhost / 5432 |
| Username / Password | jdb / jdbtest |
| Database | jdb_dev |

---

## 5. Ghi chú

- Khoá chính dùng `BIGSERIAL`; seed chèn id tường minh nhưng `02-data.sql` đã tự **`setval`** từng sequence ở cuối → chèn thêm bằng tay/qua app không bị trùng id.
- **Object types** hiện trong cây JiveDB ở nhóm *Object Types*; **Sequences** (do `BIGSERIAL`) ở nhóm *Sequences*; **Routines** gồm **10 functions** đa dạng (scalar SQL/plpgsql, tham số mặc định/VARIADIC, `RETURNS TABLE`/`SETOF`/`json`, tham số ENUM, trigger function) + **1 procedure** (`sp_touch_order`) + 2 trigger function (`set_updated_at`, `log_new_order`). Dùng được cho dropdown **Function** ở Add Trigger.
- `audit_log` rỗng lúc seed → được trigger `trg_orders_audit` điền (~4k dòng) khi nạp `orders`.
- Sinh lại: `node db/seeds/generate.mjs`.
