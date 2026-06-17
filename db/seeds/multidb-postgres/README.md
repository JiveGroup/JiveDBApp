# PostgreSQL Multi-Domain Test Seed

One PostgreSQL instance hosting **3 distinct domain databases** — each with its
own schemas and tables — for testing JiveDB's multi-database / multi-schema
browsing against realistically *different* data shapes. ~14M rows total.

## Cấu trúc

```
postgres-multi (localhost:5436)
├── jdb_ecommerce   (Thương mại điện tử)
│   ├── catalog     categories, brands, suppliers, products, product_variants
│   ├── orders      customers, orders, order_items, payments, shipments
│   └── marketing   campaigns, coupons, reviews, wishlists, ad_spend
├── jdb_healthcare  (Y tế / Bệnh viện)
│   ├── clinical    patients, encounters, diagnoses, vitals, prescriptions
│   ├── pharmacy    suppliers, drugs, drug_inventory, dispenses, stock_moves
│   └── billing     insurers, services, invoices, claims, payments
└── jdb_banking     (Ngân hàng / Fintech)
    ├── accounts    branches, customers, accounts, transactions, beneficiaries
    ├── lending     applications, loans, collaterals, repayments, schedules
    └── cards       merchants, cards, authorizations, settlements, disputes
```

Mỗi database là **một lĩnh vực khác nhau** → schema khác, bảng khác, cột khác.
Tổng cộng 3 database × 3 schema × 5 bảng = **45 bảng** không trùng lặp.

## Thông tin đăng nhập

| Setting | Value |
|---|---|
| Host | `localhost` |
| Port | `5436` |
| User | `jdb` |
| Password | `jdbtest` |
| Databases | `jdb_ecommerce`, `jdb_healthcare`, `jdb_banking` |

## Khởi chạy

```bash
# Cách 1 — mặc định (không cần Node): init.sh chạy data.sql (generate_series)
docker compose up -d
docker compose logs postgres-multi

# Cách 2 — sinh CSV trước rồi load bằng COPY (nhanh hơn cho dữ liệu lớn)
make generate-multi          # sinh data/<domain>/<schema>/*.csv.gz (cần Node)
docker compose down -v && docker compose up -d
```

Test nhanh với ít dữ liệu hơn:
```bash
make generate-multi-small    # 1% rows
docker compose down -v && docker compose up -d
```

## Truy vấn nhanh

```bash
make pg-multi          # mở psql vào jdb_ecommerce
make pg-multi-ls       # liệt kê tất cả database
make pg-multi-schemas  # liệt kê schema trong từng database
```

Hoặc chạy bộ truy vấn demo: `psql ... -f queries.sql`.

## Số lượng dữ liệu (mỗi bảng)

| Database | Schema | Bảng (số dòng) |
|---|---|---|
| jdb_ecommerce | catalog | categories 500 · brands 2K · suppliers 5K · products 100K · product_variants 200K |
| | orders | customers 80K · orders 150K · order_items 200K · payments 100K · shipments 120K |
| | marketing | campaigns 2K · coupons 50K · reviews 150K · wishlists 120K · ad_spend 80K |
| jdb_healthcare | clinical | patients 80K · encounters 200K · diagnoses 200K · vitals 200K · prescriptions 150K |
| | pharmacy | suppliers 3K · drugs 50K · drug_inventory 100K · dispenses 200K · stock_moves 200K |
| | billing | insurers 2K · services 5K · invoices 150K · claims 120K · payments 150K |
| jdb_banking | accounts | branches 2K · customers 80K · accounts 120K · transactions 200K · beneficiaries 100K |
| | lending | applications 100K · loans 80K · collaterals 60K · repayments 200K · schedules 200K |
| | cards | merchants 20K · cards 100K · authorizations 200K · settlements 150K · disputes 50K |

## Cách hoạt động

1. **`databases/<domain>/<schema>/schema.sql`** — DDL cho từng schema (idempotent).
2. **`databases/<domain>/<schema>/data.sql`** — sinh dữ liệu full-scale bằng
   `generate_series` (xác định, FK-safe, tự reset sequence). Đây là đường mặc định
   khi `docker compose up` — không cần Node.
3. **`generate.mjs`** — (tùy chọn) sinh CSV.gz tương đương, để load bằng `COPY`
   (nhanh hơn cho dữ liệu lớn). Ghi ra `data/<domain>/<schema>/`.
4. **`init.sh`** — Docker entrypoint: tạo 3 database, áp DDL, rồi load dữ liệu —
   ưu tiên CSV nếu có (`COPY` với `session_replication_role=replica` để bỏ qua thứ
   tự FK khi nạp), nếu không thì chạy `data.sql`.
5. **`data/`** — sinh ra bởi `generate.mjs`, **không commit** (xem `.gitignore`).

Tham chiếu xuyên schema trong cùng một database (ví dụ `prescriptions.drug_id` →
`pharmacy.drugs`, `reviews.product_id` → `catalog.products`) được lưu dưới dạng id/
sku **không ràng buộc FK** (FK chỉ tồn tại trong cùng schema), đúng với cách các
hệ thống thực tế phân tách theo service/schema.

## Reset

```bash
docker compose down -v && docker compose up -d
```
