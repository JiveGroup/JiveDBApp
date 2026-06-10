# Dữ liệu mẫu (Seeds)

Bộ dữ liệu mẫu để kiểm thử JiveDB với 4 loại CSDL: PostgreSQL, MySQL, SQLite và Redis. Dữ liệu là **tổng hợp** (sinh tất định), không phải dữ liệu thật.

---

## 1. Có gì bên trong

- **PostgreSQL / MySQL / SQLite**: cùng một lược đồ thương mại điện tử gồm **17 bảng có quan hệ** (`users`, `products`, `orders`…), **3 views**, **4 triggers**. Tổng **~47.3k dòng seed** + ~4k dòng `audit_log` do trigger tự điền (≈ **51k dòng**).
- **Object types (chỉ PostgreSQL)**: 7 **ENUM** (`order_status`, `payment_method`…), 1 **DOMAIN** (`email_addr`), 1 **composite** (`geo_point`). MySQL dùng cột **ENUM**; SQLite dùng ràng buộc **CHECK** (không có object type riêng).
- **Functions/Routines**: PostgreSQL có **10 functions** đa dạng (scalar SQL/plpgsql, tham số mặc định/VARIADIC, `RETURNS TABLE`/`SETOF`/`json`, tham số ENUM, trigger function) + **1 procedure**; MySQL có **4 functions**. SQLite không có stored function.
- **Redis**: script **1000 key** đa kiểu — hash (`user:`, `cart:`, `order:`), string + TTL (`session:`, `rate:`), counter (`product:*:views`), list (`feed:`), set (`tags:`), sorted set (`leaderboard:`).

```
db/seeds/
├── generate.mjs        # generator (Node, không phụ thuộc) — sinh lại toàn bộ
├── postgres/           # 01-schema.sql · 02-data.sql · README
├── mysql/              # 01-schema.sql · 02-data.sql · README
├── sqlite/             # schema.sql · data.sql · build.sh · jdb_sample.sqlite · README
└── redis/              # seed.redis · README
```

---

## 2. Lược đồ 17 bảng (quan hệ)

```
users ─< addresses          products ─< product_variants ─< inventory >─ warehouses
users ─< carts ─< cart_items >─ product_variants
users ─< orders ─< order_items >─ product_variants
orders ─< payments           orders ─< shipments >─ warehouses
categories ─< products >─ suppliers
products ─< reviews >─ users          categories ─< categories (parent_id)
users ─< events                       audit_log  (trigger trên orders điền)
```

(`A ─< B` nghĩa là một A có nhiều B; `B >─ C` nghĩa là B tham chiếu C.)

**Views**: `v_order_summary`, `v_product_stock`, `v_user_orders`.
**Triggers**: `trg_{users,products,orders}_updated` (cập nhật `updated_at`), `trg_orders_audit` (INSERT order → ghi `audit_log`).

---

## 3. Tự nạp qua Docker

`docker-compose.yml` (ở thư mục gốc) tự nạp dữ liệu khi container khởi tạo **lần đầu**:

```bash
docker compose up -d
```

- PostgreSQL & MySQL: chạy `*.sql` trong thư mục tương ứng qua `/docker-entrypoint-initdb.d`.
- Redis: service `redis-seed` nạp `redis/seed.redis` sau khi Redis sẵn sàng.

**Nạp lại từ đầu** (xoá dữ liệu cũ rồi seed lại):

```bash
docker compose down -v && docker compose up -d
```

> Lưu ý: script init chỉ chạy khi volume còn trống. Muốn seed lại bắt buộc dùng `down -v`.

---

## 4. Thông tin kết nối (chỉ để test)

| DB | Host | Port | User | Password | Database |
|---|---|---|---|---|---|
| PostgreSQL | localhost | 5432 | `jdb` | `jdbtest` | `jdb_dev` |
| MySQL | localhost | 3306 | `jdb` | `jdbtest` | `jdb_dev` |
| Redis | localhost | 6379 | — | — | `db0` |
| SQLite | — | — | — | — | file `db/seeds/sqlite/jdb_sample.sqlite` |

---

## 5. Sinh lại dữ liệu

Toàn bộ file `*-data.sql`, `data.sql`, `seed.redis` được sinh từ một generator:

```bash
node db/seeds/generate.mjs        # sinh lại schema + data + redis
db/seeds/sqlite/build.sh          # dựng lại file SQLite mẫu
```

Generator dùng RNG có seed nên kết quả lặp lại giống nhau. Xem README trong từng thư mục con để biết chi tiết loại DB.

---

## Câu truy vấn DEMO

Mỗi thư mục có sẵn file truy vấn mẫu để copy vào SQL/Redis Editor và chạy thử trên dữ liệu mẫu:

- `postgres/queries.sql` · `mysql/queries.sql` · `sqlite/queries.sql`
- `redis/queries.redis`

Hầu hết là câu **chỉ đọc** (an toàn); các ví dụ ghi/sửa được để dạng ghi chú, bỏ `--`/`#` để chạy.
