# MySQL Multi-Domain Test Seed

One MySQL instance + one `jdb` account that can see **3 distinct domain databases**
— mirroring the PostgreSQL `multidb` setup. ~14M rows total.

MySQL không có khái niệm *schema bên trong database* như PostgreSQL (ở MySQL,
"schema" = "database"). Vì vậy mỗi lĩnh vực là **một database riêng**, và 3 mảng
con của lĩnh vực đó được giữ bằng **tiền tố tên bảng** (`catalog_`, `orders_`, …)
để vẫn nhóm trực quan khi duyệt.

## Cấu trúc

```
mysql-multi (localhost:3308)   ·   account: jdb / jdbtest
├── jdb_ecommerce   (Thương mại điện tử)
│   ├── catalog_*     categories, brands, suppliers, products, product_variants
│   ├── orders_*      customers, orders, items, payments, shipments
│   └── marketing_*   campaigns, coupons, reviews, wishlists, ad_spend
├── jdb_healthcare  (Y tế / Bệnh viện)
│   ├── clinical_*    patients, encounters, diagnoses, vitals, prescriptions
│   ├── pharmacy_*    suppliers, drugs, drug_inventory, dispenses, stock_moves
│   └── billing_*     insurers, services, invoices, claims, payments
└── jdb_banking     (Ngân hàng / Fintech)
    ├── accounts_*    branches, customers, accounts, transactions, beneficiaries
    ├── lending_*     applications, loans, collaterals, repayments, schedules
    └── cards_*       merchants, cards, authorizations, settlements, disputes
```

3 database × 15 bảng = **45 bảng** không trùng lặp. Khi tài khoản `jdb` kết nối
vào instance, `SHOW DATABASES` hiển thị cả 3 database.

## Thông tin đăng nhập

| Setting | Value |
|---|---|
| Host | `localhost` |
| Port | `3308` |
| User | `jdb` |
| Password | `jdbtest` |
| Databases | `jdb_ecommerce`, `jdb_healthcare`, `jdb_banking` |

## Khởi chạy

```bash
docker compose up -d mysql-multi
docker compose logs mysql-multi          # xem tiến trình init
```

## Truy vấn nhanh

```bash
make mysql-multi      # mở mysql client vào jdb_ecommerce
make mysql-multi-ls   # SHOW DATABASES (thấy cả 3 database)
```

Hoặc chạy bộ truy vấn demo: `mysql -h127.0.0.1 -P3308 -ujdb -pjdbtest < queries.sql`.

## Số lượng dữ liệu (mỗi bảng)

| Database | Nhóm | Bảng (số dòng) |
|---|---|---|
| jdb_ecommerce | catalog_ | categories 500 · brands 2K · suppliers 5K · products 100K · product_variants 200K |
| | orders_ | customers 80K · orders 150K · items 200K · payments 100K · shipments 120K |
| | marketing_ | campaigns 2K · coupons 50K · reviews 150K · wishlists 120K · ad_spend 80K |
| jdb_healthcare | clinical_ | patients 80K · encounters 200K · diagnoses 200K · vitals 200K · prescriptions 150K |
| | pharmacy_ | suppliers 3K · drugs 50K · drug_inventory 100K · dispenses 200K · stock_moves 200K |
| | billing_ | insurers 2K · services 5K · invoices 150K · claims 120K · payments 150K |
| jdb_banking | accounts_ | branches 2K · customers 80K · accounts 120K · transactions 200K · beneficiaries 100K |
| | lending_ | applications 100K · loans 80K · collaterals 60K · repayments 200K · schedules 200K |
| | cards_ | merchants 20K · cards 100K · authorizations 200K · settlements 150K · disputes 50K |

## Cách hoạt động

1. **`databases/<domain>/schema.sql`** — DDL cho 15 bảng của domain (InnoDB,
   utf8mb4, ENUM cho cột trạng thái, FK trong cùng database).
2. **`databases/<domain>/data.sql`** — sinh dữ liệu full-scale: tạo bảng tạm
   `seq` (1..200000) bằng cross-join các chữ số, rồi `INSERT … SELECT` với mọi
   giá trị suy ra xác định từ số dòng `g` (FK/UNIQUE/CHECK đều hợp lệ). Nạp với
   `FOREIGN_KEY_CHECKS=0` để không phụ thuộc thứ tự bảng.
3. **`init.sh`** — MySQL Docker entrypoint: tạo 3 database, `GRANT` cho tài khoản
   `jdb` trên cả 3, rồi áp `schema.sql` + `data.sql` cho từng database.

Khác với PostgreSQL (FK chỉ trong cùng schema), ở MySQL cả 3 mảng của một domain
nằm chung một database nên các tham chiếu liên mảng (vd `clinical_prescriptions.
drug_id` → `pharmacy_drugs`, `marketing_reviews.product_id` → `catalog_products`)
là **FOREIGN KEY thực sự**.

## Reset

```bash
docker compose rm -sfv mysql-multi && docker compose up -d mysql-multi
```
(init.sh chỉ chạy khi volume được tạo mới.)
