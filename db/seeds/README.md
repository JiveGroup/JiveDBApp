# Dữ liệu mẫu (Seeds)

Bộ dữ liệu mẫu để kiểm thử JiveDB với 6 loại CSDL: PostgreSQL, MySQL, MariaDB, SQLite, Redis và MongoDB. Dữ liệu là **tổng hợp** (sinh tất định), không phải dữ liệu thật.

---

## 1. Có gì bên trong

- **PostgreSQL / MySQL / MariaDB / SQLite**: cùng một lược đồ thương mại điện tử gồm **17 bảng có quan hệ** (`users`, `products`, `orders`…), **3 views**, **4 triggers**. Tổng **~47.3k dòng seed** + ~4k dòng `audit_log` do trigger tự điền (≈ **51k dòng**). MariaDB dùng lại nguyên file schema/data của MySQL (tương thích, không cần generator riêng).
- **Object types (chỉ PostgreSQL)**: 7 **ENUM** (`order_status`, `payment_method`…), 1 **DOMAIN** (`email_addr`), 1 **composite** (`geo_point`). MySQL/MariaDB dùng cột **ENUM**; SQLite dùng ràng buộc **CHECK** (không có object type riêng).
- **Functions/Routines**: PostgreSQL có **10 functions** đa dạng (scalar SQL/plpgsql, tham số mặc định/VARIADIC, `RETURNS TABLE`/`SETOF`/`json`, tham số ENUM, trigger function) + **1 procedure**; MySQL/MariaDB có **4 functions**. SQLite không có stored function.
- **Redis**: script **1000 key** đa kiểu — hash (`user:`, `cart:`, `order:`), string + TTL (`session:`, `rate:`), counter (`product:*:views`), list (`feed:`), set (`tags:`), sorted set (`leaderboard:`).
- **MongoDB**: cùng dữ liệu thương mại điện tử với PostgreSQL/MySQL/SQLite — **17 bảng → 16 collection** (bỏ `audit_log`, không áp dụng cho document DB), `id` → `_id`, `events.payload` nhúng thành object lồng nhau thay vì chuỗi JSON, có `createIndex` unique tương ứng ràng buộc UNIQUE bên SQL. Bổ sung thêm **`02-features.js`** (viết tay, không phải generator) phủ mọi tính năng MongoDB-specific mà JiveDB hỗ trợ — index text/2dsphere/TTL/partial/wildcard/hashed/hidden, view, capped, time-series, validator cả `moderate/warn` lẫn `strict/error`, GridFS 2 bucket (có file đa chunk, >50 file để lộ phân trang), reference map bằng ObjectId **và bằng chuỗi**, `_id` đủ 4 kiểu (int/string/ObjectId/compound), collection rỗng, showcase **Shape Lens** 4 shape với tỉ lệ biết trước, field polymorphic 6 kiểu BSON, và collection "kitchen sink" đủ mọi kiểu BSON kèm 2 document canh đúng ngưỡng clipping (2 MiB / 256 KiB). Thêm **`03-warmup.js`** nạp sẵn `system.profile` và "hâm nóng" index để 2 panel Profiler/Index Usage không trống khi mở lần đầu. Chạy trên **single-node replica set** để Change Tail/Topology dùng được, kèm một instance **standalone** ở cổng 27019 để demo nhánh capability ngược lại. Chi tiết: `mongodb/README.md`.

```
db/seeds/
├── generate.mjs        # generator (Node, không phụ thuộc) — sinh lại toàn bộ
├── postgres/           # 01-schema.sql · 02-data.sql · README
├── mysql/              # 01-schema.sql · 02-data.sql · README
├── mariadb/            # 01-schema.sql · 02-data.sql · README (sao chép từ mysql/)
├── sqlite/             # schema.sql · data.sql · build.sh · jdb_sample.sqlite · README
├── redis/              # seed.redis · README
└── mongodb/            # 01-seed.js (generator) · 02-features.js + 03-warmup.js (viết tay)
                        #   · watch-demo.js · import-sample.ndjson · queries.js · README
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

- PostgreSQL & MySQL & MariaDB & MongoDB: chạy `*.sql` (hoặc `*.js` với MongoDB) trong thư mục tương ứng qua `/docker-entrypoint-initdb.d`.
- Redis: service `redis-seed` nạp `redis/seed.redis` sau khi Redis sẵn sàng.
- MongoDB: cần chạy `./secure/gen.sh` trước ít nhất 1 lần (sinh `secure/mongo/keyfile` — bắt buộc cho replica set + auth), và thêm service `mongodb-rs-init`/`mongodb8-rs-init`. Service này làm 2 việc mà init phase không làm được: khởi tạo replica set, rồi chạy `03-warmup.js` (bộ đếm `$indexStats` và mức profiling gắn với tiến trình mongod nên bị reset khi container restart sau init — xem `mongodb/README.md`).

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
| MariaDB | localhost | 3309 | `jdb` | `jdbtest` | `jdb_dev` |
| Redis | localhost | 6379 | — | — | `db0` |
| MongoDB | localhost | 27017 | `jdb` | `jdbtest` | `jdb_dev` (auth database `admin`, replica set `rs0`) |
| MongoDB standalone | localhost | 27019 | `jdb` | `jdbtest` | `jdb_dev` (auth database `admin`, KHÔNG replica set) |
| SQLite | — | — | — | — | file `db/seeds/sqlite/jdb_sample.sqlite` |

---

## 5. Sinh lại dữ liệu

Toàn bộ file `*-data.sql`, `data.sql`, `seed.redis`, `mongodb/01-seed.js` được sinh từ một generator:

```bash
node db/seeds/generate.mjs        # sinh lại schema + data + redis + mongodb (01-seed.js)
db/seeds/sqlite/build.sh          # dựng lại file SQLite mẫu
```

Generator dùng RNG có seed nên kết quả lặp lại giống nhau. Xem README trong từng thư mục con để biết chi tiết loại DB.

Riêng `mongodb/02-features.js` là **viết tay**, generator không đụng vào — sửa trực tiếp file này nếu cần thêm/bớt tính năng.

---

## Câu truy vấn DEMO

Mỗi thư mục có sẵn file truy vấn mẫu để copy vào SQL/Redis Editor và chạy thử trên dữ liệu mẫu:

- `postgres/queries.sql` · `mysql/queries.sql` · `mariadb/queries.sql` · `sqlite/queries.sql`
- `redis/queries.redis`
- `mongodb/queries.js`

Hầu hết là câu **chỉ đọc** (an toàn); các ví dụ ghi/sửa được để dạng ghi chú, bỏ `--`/`#` để chạy.
