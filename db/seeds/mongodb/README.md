# Seed — MongoDB

Dữ liệu mẫu cho MongoDB gồm 3 lớp:

1. **`01-seed.js`** — cùng bộ dữ liệu thương mại điện tử với PostgreSQL/MySQL/SQLite — **17 bảng quan hệ → 16 collection** (bỏ `audit_log`, không áp dụng cho MongoDB), **~47.3k document**. Sinh tự động từ `generate.mjs` — **không sửa tay**.
2. **`02-features.js`** — bổ sung mọi cấu trúc/dữ liệu MongoDB-specific mà `01-seed.js` (vốn chỉ là dữ liệu quan hệ chuyển sang document) không có, để bài test/demo có thể chạm tới **toàn bộ tính năng MongoDB mà JiveDB hỗ trợ**. File này **viết tay**, sửa trực tiếp được.
3. **`03-warmup.js`** — nạp số liệu cho 2 panel vốn TRỐNG TRƠN khi mở lần đầu (**Profiler** và **Index Usage**). Bắt buộc chạy **ngoài** init phase — xem mục 3.

Dữ liệu tổng hợp, chỉ để test.

---

## 1. File

- `01-seed.js` — script `mongosh`: tạo lại từng collection (`drop()` rồi `insertMany()` theo lô 500 document) + `createIndex` unique cho các trường tương ứng ràng buộc UNIQUE bên SQL (`users.email`, `categories.slug`, `warehouses.code`, `products.sku`, `product_variants.sku`, và index kép `inventory.(variant_id, warehouse_id)`).
- `02-features.js` — xem mục 2 bên dưới. Chạy **sau** `01-seed.js` (Docker nạp `*.js` theo thứ tự tên file); không đụng tới 16 collection của `01-seed.js` (chỉ thêm index mới, additive).
- `03-warmup.js` — bật profiler rồi chạy vài truy vấn nặng để `system.profile` có sẵn dữ liệu, và "hâm nóng" các index cần trông **đã dùng**. Do service `mongodb-rs-init` gọi, sau khi instance thật đã sẵn sàng.
- `queries.js` — demo query (`find`/`aggregate`/`$graphLookup`/`$text`/`$geoWithin`/`$indexStats`…) cho cả 3 lớp trên.
- `watch-demo.js` — vòng lặp insert/update/delete để tab **Change Tail** có sự kiện chảy qua (mục 4).
- `import-sample.ndjson` — file mẫu để thử **Import**. (Export chạy được trên mọi collection sẵn có, còn Import thì trước đây phải tự soạn file.)

Các file trên không có cú pháp riêng theo phiên bản nên dùng chung cho MongoDB 7 và 8.

Khác biệt so với các bảng SQL (áp dụng cho `01-seed.js`):
- Cột khoá chính `id` → `_id` kiểu **int** (không phải ObjectId — xem `02-features.js` để có ví dụ tham chiếu bằng ObjectId thật). Các cột khoá ngoại (`user_id`, `product_id`…) giữ nguyên tên, tham chiếu tới `_id` của collection khác — dùng `$lookup` để "join".
- `events.payload` là chuỗi JSON trong SQL nhưng được nhúng thành **object lồng nhau** ở đây — minh hoạ đúng thế mạnh document-model của Mongo.

---

## 2. `02-features.js` — bổ sung theo tính năng JiveDB

| Tính năng JiveDB | Collection/cấu trúc | Ghi chú |
|---|---|---|
| Index: text | `reviews` (+ index `body`) | `$text` search demo (xem `queries.js`) |
| Index: compound (mixed direction) | `products` (+ index `category_id,price`) | |
| Index: partial | `orders` (+ index `total`, filter `status:"cancelled"`) | |
| Index: wildcard | `events` (+ index `payload.$**`) | `payload` vốn đã là object tự do |
| Index: 2dsphere (geospatial) | `stores` | GeoJSON Point, `$geoWithin`/`$near` |
| Index: unused (cờ "unused" trong Indexes panel) | `stores` (index `tags`, cố ý không dùng ở đâu) | |
| Index: unique + sparse | `authors` | `email` unique, `deceasedAt` sparse (chỉ 2/15 doc có field) |
| Index: TTL + hashed | `user_sessions` | `expiresAt` TTL (một số phiên đã hết hạn sẵn), `userId` hashed |
| Collection kind: view | `v_order_summary`, `v_category_tree` | `db.createView` — JiveDB không có UI tạo view nên phải seed sẵn |
| Collection kind: capped | `activity_ring_buffer` | chèn 400 doc vào cap 300 → minh hoạ ghi đè vòng |
| Collection kind: time-series | `sensor_readings` | 3 ngày × mỗi 10 phút × mỗi kho hàng; có **schema drift cố ý** (field `unit` chỉ có ở 20% gần nhất, ~1% giá trị bị lưu nhầm kiểu string) — demo Shape Lens |
| Validator (`$jsonSchema`) | `subscriptions` | Áp validator SAU khi đã insert — ~10% document cũ cố ý vi phạm (thiếu field/sai kiểu) để test "N valid / M invalid" mà không bị chặn insert |
| Reference Map: ObjectId, tên field không gợi ý | `articles.writer → authors` | ~100% confidence → "Verified" |
| Reference Map: tham chiếu gãy một phần | `comments.articleId → articles` | ~50% trỏ tới id không tồn tại → confidence < 60%, KHÔNG "Verified" — tương phản với cạnh trên |
| Reference Map: mảng ObjectId (one-to-many) | `articles.relatedArticleIds` | tự tham chiếu |
| `$graphLookup` (cây tự tham chiếu) | `categories` (đã có sẵn ở `01-seed.js`, `parent_id`) | không cần seed thêm, xem `queries.js` |
| `_id` kiểu string (không phải int/ObjectId) | `feature_flags` | test nhánh `idFilter` nhận `_id` vô hướng bất kỳ kiểu |
| `_id` kiểu **compound** (embedded document) | `inventory_ledger` (`_id:{sku,warehouse}`) | `PLAN_mongodb.md` nêu đây là câu hỏi mở cần xác nhận sớm; buộc `idFilter` và ô `_id` bị khoá trong DocEditorDialog xử lý `_id` KHÔNG vô hướng |
| Reference Map: tham chiếu bằng **chuỗi** | `user_sessions.feature_flag_id → feature_flags` | `mongorefs.go` chỉ xét id int/string khi tên field có hậu tố FK; trước đây mọi cạnh trong seed đều là ObjectId hoặc int nên nhánh `refValue.kind=='s'` chưa từng chạy |
| **Shape Lens** — showcase 4 shape | `order_snapshots` | ~70/20/7/3%: shape trội · `+ added` (coupon/discount) · `~ retyped` (`total` decimal→double) · legacy dưới 10% ⇒ vòng amber. Xem ghi chú bên dưới |
| Field **polymorphic** rõ rệt | `metric_samples` (`value`) | xoay vòng 6 kiểu BSON đều nhau (string/int/bool/object/array/null) — `sensor_readings` chỉ lệch ~1% nên rất khó thấy |
| Collection **rỗng** | `archived_orders` | 0 document nhưng CÓ index + validator → test trạng thái rỗng của Find / Shape Lens (`sampled==0`) / Overview |
| Validator **strict + error** | `payment_methods` | thái cực còn lại của `subscriptions` (moderate/warn): validator gắn ngay lúc tạo, insert sai bị server TỪ CHỐI thật |
| Index: **hidden** | `articles` (index `views`, `hidden:true`) | chip "hidden" (amber) là cờ duy nhất trước đây chưa có ví dụ seed sẵn |
| GridFS | bucket `attachments` + `avatars` | 59 file ở `attachments` (**>50** → lộ phân trang, `PAGE_SIZE=50`), gồm 1 file CSV ~1.4 MB **nhiều chunk**; bucket thứ 2 để dropdown chọn bucket có cái mà chọn, có file PNG nhị phân |
| BSON "kitchen sink" | `bson_type_gallery` | mỗi document 1 nhóm kiểu BSON (xem bên dưới) |
| **Clipping** tài liệu lớn | `bson_type_gallery` (2 doc `clipping pass 1/2`) | xem ghi chú "NGƯỠNG CLIPPING" bên dưới |

**Kiểu BSON được seed trong `bson_type_gallery`**: double, int32, long, decimal128, NaN/Infinity, string, objectId, date, BSON timestamp, bool, null (so với field vắng mặt), binary (subtype 00 + UUID subtype 04), regex, **code (javascript)**, **code kèm scope (javascriptWithScope)**, array (thường + mảng ObjectId), object lồng 3 cấp, minKey, maxKey, DBRef.

**KHÔNG seed**: Symbol, DBPointer, Undefined. `Undefined` bị `mongosh` ghi thành `null` (kiểm chứng bằng `$type`), còn Symbol/DBPointer đã deprecated và không có cách dựng hợp lệ bằng shell — đây là giới hạn của shell, **không phải** JiveDB thiếu hỗ trợ hiển thị.

> Trước đây mục này liệt kê cả `JavaScriptWithScope` là "không tạo được". Điều đó **sai**: `Code(code, scope)` (2 tham số) tạo ra đúng BSON `javascriptWithScope` (0x0F), khác với `Code(code)` là `javascript` (0x0D) — đã kiểm chứng bằng `$type` và nay đã seed cả hai.

**NGƯỠNG CLIPPING** (`internal/driver/ejson.go`) — `documentToEJSON` kiểm tra kích thước EJSON của **toàn document trước**:

```go
if len(full) <= maxDocEJSONBytes { return full, false, nil }   // 2 MiB
```

Chỉ khi vượt **2 MiB** nó mới cắt từng field vượt **256 KiB** thành marker `$jdbClipped`. Nghĩa là một document ~300 KiB (dù có field lớn hơn 256 KiB) **không bao giờ** bị cắt. Vì vậy cần 2 document riêng để phủ cả hai pass:

| Document | Cách vượt ngưỡng | Nhánh chạm tới |
|---|---|---|
| `clipping pass 1 — single huge field` | 1 field ~2.4 MiB (vượt cả 2 ngưỡng) | pass 1 — thay ngay field to bằng marker |
| `clipping pass 2 — many mid-sized fields` | 12 field × ~200 KiB (mỗi field **dưới** 256 KiB, tổng ~2.4 MiB) | pass 2 — cắt dần field lớn nhất cho tới khi vừa |

**Đổi cấu trúc Docker Compose kèm theo** (xem `docker-compose.yml` + `secure/README.md`): `mongodb`/`mongodb8` chạy **single-node replica set** (`--replSet rs0`, cần thêm `--keyFile`) thay vì standalone — bắt buộc để 2 tính năng Live Ops **Change Tail** (change streams) và **Topology** (replica set) hoạt động được; một mongod standalone không bao giờ hỗ trợ 2 tính năng này dù dữ liệu đầy đủ đến đâu.

Nhưng chuyển **cả hai** sang replica set lại làm mất khả năng demo nhánh NGƯỢC LẠI — `probeCapabilities` báo `topology:"single"`, `changeStreams:false`, khiến Change Tail hiện màn giải thích "cần replica set" còn Topology hiện "This deployment is a standalone". Đó là các nhánh code có thật (và `docs/MONGO_E2E.md` có kiểm tra), nên có thêm service **`mongodb-standalone`** ở cổng **27019** để bấm qua lại giữa hai chế độ:

```bash
docker compose --profile standalone up -d mongodb-standalone
```

---

## 3. Tự nạp qua Docker

Image `mongo` tự chạy các file `.js` trong `/docker-entrypoint-initdb.d/` khi container khởi tạo **lần đầu** (giống cách Postgres/MySQL chạy `*.sql`). Hai việc KHÔNG chạy được qua cơ chế đó, nên tách sang service `mongodb-rs-init`/`mongodb8-rs-init` (chạy đúng 1 lần sau khi container chính sẵn sàng):

1. **`rs.initiate()`** — mongod tạm thời của init phase không bật `--replSet` dù command của service khai báo gì, nên gọi ở đó luôn báo "not started with replication enabled".
2. **`03-warmup.js`** — bộ đếm `$indexStats` và mức profiling gắn với **tiến trình mongod đang chạy**, không phải dữ liệu trên đĩa. Init phase chạy trên mongod tạm rồi entrypoint tắt nó đi và khởi động lại instance thật ⇒ nếu hâm nóng ở `02-features.js` thì bộ đếm bị **reset sạch** và mức profiling trở về 0. Đặt ở đây thì số liệu mới còn.

```bash
./secure/gen.sh                          # sinh secure/mongo/keyfile (bắt buộc, xem mục 6)
docker compose up -d mongodb mongodb-rs-init      # MongoDB 7, cổng 27017
docker compose up -d mongodb8 mongodb8-rs-init    # MongoDB 8, cổng 27018
docker compose --profile standalone up -d mongodb-standalone   # standalone, cổng 27019
docker compose down -v && docker compose up -d    # nạp lại từ đầu
```

> `mongodb-standalone` cố ý **không** chạy `03-warmup.js` — nó tồn tại để so sánh capability (không change stream, topology "single"), nên Profiler/Index Usage ở đó trống là đúng ý đồ.

---

## 4. Change Tail — cần có ghi trong lúc xem

Change stream **chỉ** hiện sự kiện xảy ra trong lúc stream đang mở, nên không seed tĩnh nào làm tab này "có sẵn dữ liệu" được. `watch-demo.js` sinh ghi liên tục để feed có cái mà chảy:

```bash
docker compose --profile mongo-writer up -d mongodb-writer   # chạy nền
docker compose stop mongodb-writer                           # dừng

# hoặc chạy tay:
mongosh "mongodb://jdb:jdbtest@localhost:27017/jdb_dev?authSource=admin&replicaSet=rs0" db/seeds/mongodb/watch-demo.js
```

Vòng lặp phát đủ 3 loại thao tác để thấy hết 3 màu của feed, và bước update dùng **đồng thời** `$set` lẫn `$unset` nên hiện được cả `~field` (updatedFields, amber) lẫn `−field` (removedFields, rose).

> Script ghi vào collection riêng `change_tail_demo`, **không** dùng `activity_ring_buffer`: đó là capped collection mà MongoDB **cấm xoá document** khỏi capped collection, nên nhánh delete sẽ lỗi.

---

## 5. Nạp thủ công

```bash
mongosh "mongodb://jdb:jdbtest@localhost:27017/jdb_dev?authSource=admin&replicaSet=rs0" db/seeds/mongodb/01-seed.js
mongosh "mongodb://jdb:jdbtest@localhost:27017/jdb_dev?authSource=admin&replicaSet=rs0" db/seeds/mongodb/02-features.js
mongosh "mongodb://jdb:jdbtest@localhost:27017/jdb_dev?authSource=admin&replicaSet=rs0" db/seeds/mongodb/03-warmup.js
```

(Thay `27017` bằng `27018` cho MongoDB 8.) Nếu server chưa có replica set nào được khởi tạo, chạy thêm một lần: `mongosh "mongodb://jdb:jdbtest@localhost:27017/admin?authSource=admin" --eval 'rs.initiate({_id:"rs0",members:[{_id:0,host:"localhost:27017"}]})'`.

`03-warmup.js` chạy lại lúc nào cũng được (chỉ đọc + bật profiler) — hữu ích sau khi restart container, vì `$indexStats` reset thì cả bảng index lại hiện "unused".

---

## 6. Keyfile (bắt buộc khi dùng replica set + auth)

MongoDB yêu cầu `--keyFile` khi bật cả `--replSet` lẫn `--auth` cùng lúc, kể cả replica set 1 node (xác thực nội bộ giữa các thành viên). Sinh keyfile bằng:

```bash
./secure/gen.sh          # hoặc: make secure-gen — xem secure/README.md
```

`docker-compose.yml` tự mount `secure/mongo/keyfile` và chỉnh quyền bên trong container qua `secure/mongo-entrypoint.sh`. Không cần làm gì thêm nếu chỉ dùng `docker compose up`.

---

## 7. Kết nối từ JiveDB

| Trường | Giá trị |
|---|---|
| Loại | MongoDB |
| Host / Port | localhost / **27017** (MongoDB 7, rs0) · **27018** (MongoDB 8, rs0) · **27019** (standalone) |
| Username / Password | jdb / jdbtest |
| Auth database | admin |
| Database | jdb_dev |
| Replica set | `rs0` cho 27017/27018 (không bắt buộc, driver tự khám phá qua handshake, nhưng khai rõ giúp kết nối nhanh hơn). **Bỏ trống** cho 27019 — instance đó là standalone. |

Với MongoDB Compass hoặc `mongosh`:

```
mongodb://jdb:jdbtest@localhost:27017/jdb_dev?authSource=admin&replicaSet=rs0
mongodb://jdb:jdbtest@localhost:27019/jdb_dev?authSource=admin              # standalone
```

Bắt buộc đặt **Authentication Database = `admin`**: `jdb` được tạo qua `MONGO_INITDB_ROOT_USERNAME` nên là **root user** nằm ở database `admin`, không phải `jdb_dev`.

---

## 8. Giới hạn đã biết (không phải thiếu sót của seed)

| Chỗ | Vì sao | Cách demo |
|---|---|---|
| **Topology** hiện đúng 1 thành viên, cột lag luôn trống | `rs0` là replica set **1 node**: chỉ có `self`, `lagSeconds` luôn 0 nên sparkline lag không bao giờ có dữ liệu. Muốn khác phải dựng replica set 2–3 node thật — nặng hơn nhiều so với giá trị demo thu được. | Chấp nhận; tab vẫn render đúng và trung thực. |
| **Current Op** gần như luôn rỗng | Tab poll mỗi 2s nên chỉ bắt được thao tác chạy **lâu hơn ~2 giây**; không seed tĩnh nào tạo ra được. | Mở tab rồi ở cửa sổ khác chạy một aggregate nặng, ví dụ `$lookup` giữa `orders` và `order_items` kèm `allowDiskUse`. |
| **Change Tail** trống khi không ai ghi | Bản chất của change stream. | Bật `mongodb-writer` — xem mục 4. |
| Atlas Search / Performance Advisor / sharded cluster | Chỉ có trên Atlas hoặc cụm sharded; app đã ẩn/khoá sẵn các phần này. | Không thể tái tạo bằng Docker cục bộ. |
