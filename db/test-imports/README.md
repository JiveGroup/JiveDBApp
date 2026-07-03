# Test Import Data — JiveDB

Bộ file test cho tính năng **Import Data** của JiveDB, dùng để kiểm thử khả năng import `.sql`
và `.csv` vào PostgreSQL, MySQL, MariaDB, và SQLite.

Xem tài liệu chi tiết về khả năng import: `docs/IMPORT_COMPATIBILITY.md` trong repo JiveDB.

---

## 1. File test

Tất cả file được export từ database mẫu e-commerce (17 bảng, ~47k dòng) chạy trên Docker
tại `docker-compose.yml` (thư mục gốc).

| File | Kích thước | Test gì |
|---|---|---|
| `test_pg_inserts.sql` | 4.9 MB | PostgreSQL INSERT thuần (`pg_dump --inserts`) |
| `test_pg_copy.sql` | 2.5 MB | PostgreSQL COPY → INSERT (`pg_dump` mặc định) |
| `test_pg_functions.sql` | 34 KB | PostgreSQL dollar-quote `$$` (function/procedure) |
| `test_mysql_default.sql` | 2.7 MB | MySQL INSERT mở rộng (`mysqldump` mặc định) |
| `test_mysql_routines.sql` | 2.7 MB | MySQL DELIMITER + trigger/procedure |
| `test_mariadb_default.sql` | 2.8 MB | MariaDB cơ bản (`mariadb-dump`) |
| `test_mariadb_routines.sql` | 2.8 MB | MariaDB + trigger/procedure |
| `test_sqlite_dump.sql` | 4.3 MB | SQLite `.dump` (StripTxControl) |
| `test_users.csv` | 134 KB | CSV 1500 dòng — test Import CSV ở cấp Table |

---

## 2. Sinh lại file test

Yêu cầu: Docker, `sqlite3`.

```bash
cd /Users/vinh/Working/JiveDB/jdbapp
mkdir -p db/test-imports

# PostgreSQL
docker compose exec -T postgres pg_dump -U jdb jdb_dev --inserts > db/test-imports/test_pg_inserts.sql
docker compose exec -T postgres pg_dump -U jdb jdb_dev > db/test-imports/test_pg_copy.sql
docker compose exec -T postgres pg_dump -U jdb jdb_dev --schema-only > db/test-imports/test_pg_functions.sql

# MySQL (dùng root để export được trigger/procedure)
docker compose exec -T mysql mysqldump -u jdb -pjdbtest jdb_dev 2>/dev/null > db/test-imports/test_mysql_default.sql
docker compose exec -T mysql mysqldump -u root -pjdbtest --routines --triggers jdb_dev 2>/dev/null > db/test-imports/test_mysql_routines.sql

# MariaDB
docker compose exec -T mariadb mariadb-dump -u jdb -pjdbtest jdb_dev 2>/dev/null > db/test-imports/test_mariadb_default.sql
docker compose exec -T mariadb mariadb-dump -u jdb -pjdbtest --routines --triggers jdb_dev 2>/dev/null > db/test-imports/test_mariadb_routines.sql

# SQLite (cần rebuild file .sqlite trước nếu bị 0 byte)
cd db/seeds/sqlite && bash build.sh && cd -
sqlite3 db/seeds/sqlite/jdb_sample.sqlite .dump > db/test-imports/test_sqlite_dump.sql

# CSV
docker compose exec -T postgres psql -U jdb -d jdb_dev -c "\copy users TO '/tmp/users.csv' CSV HEADER" 2>/dev/null
docker compose exec -T postgres cat /tmp/users.csv > db/test-imports/test_users.csv
```

---

## 3. Chuẩn bị database đích (rỗng)

### 3.1 Tạo database rỗng

```bash
cd /Users/vinh/Working/JiveDB/jdbapp

# PostgreSQL
docker compose exec -T postgres psql -U jdb -d jdb_dev -c "CREATE DATABASE jdb_import_test;"

# MySQL
docker compose exec -T mysql mysql -u root -pjdbtest -e "CREATE DATABASE IF NOT EXISTS jdb_import_test;"

# MariaDB
docker compose exec -T mariadb mariadb -u root -pjdbtest -e "CREATE DATABASE IF NOT EXISTS jdb_import_test;"

# SQLite — tự tạo file mới khi connect trong JiveDB, hoặc:
sqlite3 db/test-imports/test_import.sqlite "SELECT 1;"
```

### 3.2 Kết nối JiveDB tới database đích

Mở JiveDB, thêm 4 kết nối mới:

| CSDL | Host | Port | User | Password | Database |
|---|---|---|---|---|---|
| PostgreSQL | localhost | 5432 | `jdb` | `jdbtest` | `jdb_import_test` |
| MySQL | localhost | 3306 | `root` | `jdbtest` | `jdb_import_test` |
| MariaDB | localhost | 3309 | `root` | `jdbtest` | `jdb_import_test` |
| SQLite | — | — | — | — | file `db/test-imports/test_import.sqlite` |

---

## 4. Thực hiện import

### 4.1 Import .sql (cấp Database/Schema)

Với mỗi kết nối, **chuột phải vào tên database** → **Import Data** → chọn file `.sql`:

| Kết nối | File | Test gì |
|---|---|---|
| PostgreSQL `jdb_import_test` | `test_pg_inserts.sql` | INSERT thuần |
| PostgreSQL `jdb_import_test` | `test_pg_copy.sql` | ExpandPgCopy (COPY → INSERT) |
| PostgreSQL `jdb_import_test` | `test_pg_functions.sql` | Dollar-quote `$$` |
| MySQL `jdb_import_test` | `test_mysql_default.sql` | INSERT mở rộng |
| MySQL `jdb_import_test` | `test_mysql_routines.sql` | DELIMITER + trigger/procedure |
| MariaDB `jdb_import_test` | `test_mariadb_default.sql` | MariaDB cơ bản |
| MariaDB `jdb_import_test` | `test_mariadb_routines.sql` | MariaDB routines |
| SQLite `test_import.sqlite` | `test_sqlite_dump.sql` | StripTxControl (bỏ BEGIN/COMMIT) |

### 4.2 Import CSV (cấp Table)

1. Kết nối tới **PostgreSQL** `jdb_import_test` (sau khi đã import schema — dùng `test_pg_inserts.sql`)
2. Chuột phải vào bảng `users` → **Import CSV/TSV**
3. Chọn file `test_users.csv`
4. Kiểm tra: mở bảng `users` → tab Data → phải có 1500 dòng

---

## 5. Kiểm tra kết quả

Sau mỗi lần import:

- Mở rộng cây Database/Schema → kiểm tra bảng đã được tạo (17 bảng cho file đầy đủ)
- Mở bảng `users` → tab Data → kiểm tra số dòng
- Với file functions: vào Schema Objects → Functions → kiểm tra function đã được tạo
- Với file routines: vào Schema Objects → Triggers → kiểm tra trigger

---

## 6. Reset database test

Xoá và tạo lại database rỗng để import lại từ đầu:

```bash
cd /Users/vinh/Working/JiveDB/jdbapp

# PostgreSQL
docker compose exec -T postgres psql -U jdb -d jdb_dev -c "DROP DATABASE IF EXISTS jdb_import_test;" && docker compose exec -T postgres psql -U jdb -d jdb_dev -c "CREATE DATABASE jdb_import_test;"

# MySQL
docker compose exec -T mysql mysql -u root -pjdbtest -e "DROP DATABASE IF EXISTS jdb_import_test; CREATE DATABASE jdb_import_test;"

# MariaDB
docker compose exec -T mariadb mariadb -u root -pjdbtest -e "DROP DATABASE IF EXISTS jdb_import_test; CREATE DATABASE jdb_import_test;"

# SQLite
rm -f db/test-imports/test_import.sqlite && sqlite3 db/test-imports/test_import.sqlite "SELECT 1;"
```

Sau đó disconnect rồi reconnect trong JiveDB để thấy database rỗng.

---

## 7. Ghi chú

- **MySQL**: Dùng `root` thay vì `jdb` khi export có trigger/procedure vì user `jdb` không có quyền `PROCESS` để đọc `mysql.proc`.
- **SQLite**: File `jdb_sample.sqlite` có thể bị 0 byte nếu chưa chạy `build.sh`. Luôn rebuild trước khi export.
- **CSV**: Chỉ import được ở cấp **Table** (không phải Database/Schema). Cần có bảng đích đã tồn tại.
- **Transaction**: PostgreSQL import hoàn toàn nguyên tử (1 transaction). MySQL/MariaDB có thể tự commit khi gặp DDL.
