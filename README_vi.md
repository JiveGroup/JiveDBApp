# JiveDB — Công cụ quản lý cơ sở dữ liệu gọn nhẹ, hiện đại

> Một ứng dụng desktop để **kết nối, truy vấn, chỉnh sửa và phân tích** dữ liệu của bạn trên nhiều loại cơ sở dữ liệu — nhanh, an toàn và dễ chịu khi sử dụng hằng ngày.

---

## 1. JiveDB là gì?

JiveDB (JiveDB) là một ứng dụng desktop **native** giúp bạn làm việc với cơ sở dữ liệu mà không cần nhiều công cụ rời rạc. Toàn bộ ứng dụng được đóng gói thành **một file chạy duy nhất**, khởi động nhanh và không yêu cầu cài đặt phức tạp.

Điểm khác biệt của JiveDB nằm ở sự cân bằng: đủ mạnh cho công việc thực tế, nhưng vẫn **nhẹ, sạch và trực quan**. Bạn có thể mở một bảng, lọc dữ liệu, sửa vài dòng, xem sơ đồ quan hệ hay xuất file chỉ trong vài cú nhấp.

---

## 2. Vì sao nên chọn JiveDB?

- **Một công cụ cho nhiều loại cơ sở dữ liệu** — không phải chuyển qua lại giữa nhiều phần mềm.
- **Lưới dữ liệu mạnh ngang bảng tính** — chọn vùng, lọc theo toán tử, sắp xếp nhiều cột, dán nhiều ô, định dạng có điều kiện và hơn thế nữa.
- **Trình soạn SQL thông minh** — chạy đúng câu lệnh tại con trỏ, định dạng, lưu yêu thích, lịch sử truy vấn.
- **Sơ đồ quan hệ (ERD)** trực quan, chỉ-xem an toàn, kèm xem nhanh DDL của từng bảng.
- **Bảo mật ngay từ mặc định** — mật khẩu kết nối được mã hoá khi lưu trên máy.
- **Nhẹ và nhanh** — một file chạy, giao diện gọn, hỗ trợ giao diện sáng/tối.
- **Song ngữ** — hỗ trợ Tiếng Việt và English.

---

## 3. Hỗ trợ cơ sở dữ liệu

JiveDB làm việc với các hệ phổ biến trong cùng một giao diện thống nhất:

| Cơ sở dữ liệu | Ghi chú |
|---|---|
| **PostgreSQL** | Nhiều schema, chuyển schema nhanh, xem định nghĩa đối tượng (DDL). |
| **MySQL** | Quản lý bảng/view/chỉ mục/thủ tục theo từng database. |
| **SQLite** | Mở file cục bộ, gọn nhẹ, không cần máy chủ. |
| **Redis** | Trình duyệt khoá/giá trị cho thao tác nhanh. |

---

## 4. Các tính năng nổi bật

### 4.1. Lưới dữ liệu (DataGrid) — điểm sáng của JiveDB

Đây là nơi bạn dành nhiều thời gian nhất, và JiveDB đầu tư mạnh để nó thật sự tiện:

- **Chọn vùng ô** như Excel, kèm thanh tổng hợp nhanh (đếm, tổng, trung bình, nhỏ nhất, lớn nhất).
- **Sao chép linh hoạt**: ô, dòng, vùng chọn hoặc cả cột dưới nhiều định dạng (TSV, CSV, JSON, INSERT, UPDATE).
- **Lọc theo toán tử** cho từng cột: `= ≠ > < ≥ ≤`, chứa (LIKE), rỗng/khác rỗng, và **IN / NOT IN**, kèm chú thích ký hiệu dễ hiểu.
- **Sắp xếp nhiều cột** theo thứ tự ưu tiên; **đóng băng (ghim) cột** để theo dõi khi cuộn ngang.
- **Chỉnh sửa trực tiếp** an toàn: theo dõi thay đổi, xem trước rồi mới lưu; **hoàn tác từng ô**; dán nhiều ô, điền xuống, đặt NULL hàng loạt.
- **Phân tích nhanh**: thống kê cột và phân bố giá trị phổ biến ngay trong lưới.
- **Tìm & Thay thế**, **định dạng có điều kiện** (tô màu theo quy tắc), **tự vừa độ rộng cột**, **độ cao dòng** linh hoạt.
- **Nhập CSV** và **xuất Excel (.xlsx)**, CSV, JSON — cho cả toàn bộ hoặc chỉ vùng chọn.
- **Điều hướng theo khoá ngoại**: nhảy tới dòng được tham chiếu chỉ với một cú nhấp.

### 4.2. Trình soạn thảo SQL

- **Chạy thông minh**: chỉ cần đặt con trỏ trong một câu lệnh và chạy — JiveDB tự nhận đúng câu cần thực thi.
- Hỗ trợ **nhiều câu lệnh**, **định dạng (format)**, tô màu cú pháp, gợi ý.
- **Lịch sử truy vấn** và **câu lệnh yêu thích** để dùng lại nhanh.
- Với PostgreSQL: **chọn schema** ngay trên thanh công cụ và truy vấn theo schema đang chọn.

### 4.3. Sơ đồ quan hệ (ERD)

- Tự dựng sơ đồ **chỉ gồm các bảng** và quan hệ khoá ngoại giữa chúng.
- **Chỉ-xem an toàn**: không có thao tác làm thay đổi cơ sở dữ liệu.
- **Double-click** một bảng để mở rộng vừa đủ, hiển thị đầy đủ tên cột dài.
- Bật **panel Info** để xem nhanh **DDL** của bảng được chọn và sao chép chỉ với một nút.
- Màu sắc **đồng bộ với giao diện sáng/tối** của ứng dụng.

### 4.4. Khám phá cấu trúc & thông tin

- Cây đối tượng đầy đủ: bảng, view, chỉ mục, hàm/thủ tục, sequence, kiểu dữ liệu…
- **Xem định nghĩa (DDL)** của đối tượng dưới dạng chỉ-đọc, có tô màu cú pháp.
- Tab **Info** tổng hợp metadata theo nhóm (Tables, Views, Indexes, Procedures) để nắm nhanh toàn cảnh.

---

## 5. Bảo mật và quyền riêng tư

- **Mã hoá khi lưu**: thông tin nhạy cảm của kết nối được mã hoá trước khi ghi xuống máy của bạn.
- **Dữ liệu nằm trên máy bạn**: JiveDB là ứng dụng desktop, không bắt buộc gửi dữ liệu lên dịch vụ bên ngoài để hoạt động.
- **An toàn theo mặc định**: các thao tác có thể gây mất dữ liệu đều được xác nhận rõ ràng; nhiều màn hình ưu tiên chế độ **chỉ-xem** khi không cần chỉnh sửa.

---

## 6. Đa nền tảng và hiệu năng

- Đóng gói thành **một file chạy duy nhất**, khởi động nhanh.
- Giao diện **gọn, hiện đại**, hỗ trợ **giao diện sáng/tối** và tông màu nhấn.
- Lưới dữ liệu được **ảo hoá** để xử lý mượt mà với lượng dòng lớn.

---

## 7. Phù hợp với ai?

- **Lập trình viên** cần một công cụ nhanh để truy vấn và sửa dữ liệu khi phát triển.
- **Người làm dữ liệu / phân tích** muốn lọc, tổng hợp và xuất dữ liệu mà không phải viết nhiều SQL.
- **Quản trị viên cơ sở dữ liệu** cần xem cấu trúc, quan hệ và định nghĩa đối tượng một cách trực quan.
- Bất kỳ ai muốn **một công cụ duy nhất, nhẹ nhàng** thay cho nhiều phần mềm rời rạc.

---

## 8. Bắt đầu nhanh

1. Mở JiveDB và **tạo một kết nối** tới PostgreSQL, MySQL, SQLite hoặc Redis.
2. Duyệt cây đối tượng ở thanh bên, **mở một bảng** để xem dữ liệu.
3. Dùng **lưới dữ liệu** để lọc, sắp xếp, chỉnh sửa hoặc xuất file.
4. Mở **SQL Editor** để chạy truy vấn, hoặc xem **ERD** để hiểu quan hệ giữa các bảng.

---

## 9. Tải về và cài đặt

Lấy bản dựng mới nhất cho nền tảng của bạn từ trang **[Releases](../../releases/latest)**.

| Nền tảng | File |
|---|---|
| macOS (Intel & Apple Silicon) | `JiveDB.dmg` |
| Windows x64 | `JiveDB-windows-amd64.exe` |
| Windows ARM64 | `JiveDB-windows-arm64.exe` |
| Linux x64 | `JiveDB-linux-amd64.tar.gz` |
| Linux ARM64 | `JiveDB-linux-arm64.tar.gz` |

**macOS** — mở `JiveDB.dmg`, kéo **JiveDB** vào thư mục **Applications** rồi khởi chạy. (Đã ký Developer ID + notarized.)

**Windows** — chạy `JiveDB-windows-amd64.exe` (hoặc bản `-arm64`). Nếu hiện cảnh báo SmartScreen, bấm **More info → Run anyway** (bản dựng hiện chưa code‑signed).

> **Yêu cầu WebView2 Runtime.** JiveDB dùng **Microsoft Edge WebView2** để hiển thị giao diện. Windows 11 (và đa số Windows 10 đã cập nhật) có sẵn runtime này. Nếu ứng dụng không mở được hoặc hiện màn hình trắng, hãy tải và cài **Evergreen WebView2 Runtime** (miễn phí) từ Microsoft:
>
> - Trang tải: https://developer.microsoft.com/en-us/microsoft-edge/webview2
> - Chọn **Evergreen Bootstrapper** → tải về và chạy `MicrosoftEdgeWebview2Setup.exe`, làm theo hướng dẫn.
> - Cài xong, khởi chạy lại JiveDB.

**Linux** — giải nén archive rồi chạy `install.sh` (thêm launcher kèm icon vào menu ứng dụng, không cần sudo):

```bash
tar -xzf JiveDB-linux-amd64.tar.gz
cd JiveDB-amd64 && ./install.sh
# Cài runtime WebKitGTK nếu cần (Debian/Ubuntu):
# sudo apt install libwebkit2gtk-4.1-0 libgtk-3-0
```

Sau đó mở **JiveDB** từ menu ứng dụng. (Gỡ cài đặt: `./uninstall.sh`.)

---

## 10. Tạo dữ liệu test với Docker

Repo kèm sẵn `docker-compose.yml` và bộ dữ liệu mẫu trong `db/` để bạn dựng nhanh PostgreSQL, MySQL và Redis có dữ liệu — dùng để thử nghiệm JiveDB mà không cần tự cài máy chủ. Dữ liệu là **tổng hợp** (sinh tất định), không phải dữ liệu thật, và **chỉ dùng cho test cục bộ**.

> Yêu cầu: đã cài **Docker** và **Docker Compose** (lệnh `docker compose`).

### 10.1. Khởi chạy

Từ thư mục gốc của repo:

```bash
docker compose up -d
```

Dữ liệu mẫu **tự nạp khi container khởi tạo lần đầu**:

- **PostgreSQL / MySQL**: chạy các file `*.sql` trong `db/<bộ>/<db>/` qua `/docker-entrypoint-initdb.d`.
- **Redis**: service `redis-seed` nạp `db/<bộ>/redis/seed.redis` ngay sau khi Redis sẵn sàng rồi tự thoát.

### 10.2. Thông tin đăng nhập (chỉ để test)

Dùng các thông số dưới đây để **tạo kết nối trong JiveDB** tới dữ liệu mẫu vừa dựng. Đây là thông tin test cục bộ, **không dùng cho production**.

| CSDL | Host | Port | User | Password | Database |
|---|---|---|---|---|---|
| PostgreSQL 16 | `localhost` | `5432` | `jdb` | `jdbtest` | `jdb_dev` |
| PostgreSQL 18 | `localhost` | `5433` | `jdb` | `jdbtest` | `jdb_dev` |
| MySQL 8 | `localhost` | `3306` | `jdb` | `jdbtest` | `jdb_dev` |
| Redis 7 | `localhost` | `6379` | — | — | `db0` (không mật khẩu) |
| SQLite | — | — | — | — | mở trực tiếp file `.sqlite` (xem dưới) |

Ghi chú theo từng CSDL:

- **PostgreSQL** — có hai phiên bản chạy song song: **16** ở cổng `5432` và **18** ở cổng `5433`, cùng tài khoản `jdb` / `jdbtest`, database `jdb_dev`.
- **MySQL** — ngoài tài khoản `jdb` / `jdbtest`, còn có tài khoản quản trị **`root`** với mật khẩu `jdbtest` nếu cần.
- **Redis** — không bật xác thực; dữ liệu mẫu nằm ở DB index `0`.
- **SQLite** — không cần Docker, mở thẳng file bằng JiveDB:
  - Bộ nhỏ: `db/seeds/sqlite/jdb.sqlite`
  - Bộ tầm trung: `db/seeds-medium/sqlite/jdb_medium.sqlite`

> Mẹo: với `make` (xem `Makefile`), bạn có thể mở nhanh shell vào DB — `make psql`, `make mysql`, `make redis-cli`.

### 10.3. Chọn bộ dữ liệu

Mặc định nạp bộ **nhỏ** (`seeds`). Đổi bộ qua biến môi trường `JDB_SEED`:

```bash
JDB_SEED=seeds        docker compose up -d   # bộ nhỏ (mặc định)
JDB_SEED=seeds-medium docker compose up -d   # bộ tầm trung (nhiều bảng hơn)
```

### 10.4. Nạp lại từ đầu

Script init **chỉ chạy khi volume còn trống**. Muốn xoá dữ liệu cũ và seed lại:

```bash
docker compose down -v && docker compose up -d
```

### 10.5. Dừng và dọn dẹp

```bash
docker compose down       # dừng, giữ lại dữ liệu trong volume
docker compose down -v    # dừng và xoá luôn dữ liệu (volume)
```

### 10.6. Tạo đầy đủ Schema Objects cho PostgreSQL

File `db/postgres_schema_objects_sample.sql` tạo **đầy đủ mỗi loại đối tượng schema** của PostgreSQL để bạn xem chúng hiển thị trong cây sidebar của JiveDB: **Tables, Views, Materialized Views, Foreign Tables, Sequences, Types** (enum/composite/range), **Domains, Collations, Functions, Procedures, Trigger Functions, Aggregates, Operators** và **Full-Text Search** (Parser → Template → Dictionary → Configuration).

- **An toàn**: mọi thứ nằm trong schema riêng **`demo_objects`**, không đụng dữ liệu sẵn có. Đầu file đã `DROP SCHEMA ... CASCADE` nên **chạy lại nhiều lần được**.
- **Yêu cầu**: PostgreSQL **14+**, cần **ICU** và **postgres_fdw** — các image `postgres:16`/`postgres:18` trong `docker-compose.yml` đã có sẵn, và tài khoản `jdb` là superuser nên tạo được EXTENSION / SERVER / FTS.

Nạp file vào PostgreSQL đang chạy (Postgres 16, cổng 5432):

```bash
docker exec -i jdbapp-postgres-1 psql -U jdb -d jdb_dev < db/postgres_schema_objects_sample.sql
# hoặc nhanh hơn:
make pg-objects
```

Hoặc mở file, **copy toàn bộ nội dung vào SQL Editor** của JiveDB rồi chạy (lưu ý: các khối hàm/thủ tục dùng dollar-quote `$$ ... $$` phải chạy cả khối, đừng cắt theo dấu `;` bên trong).

Sau đó **Refresh sidebar** rồi mở schema `demo_objects` để xem toàn bộ đối tượng. Dọn sạch khi xong:

```sql
DROP SCHEMA demo_objects CASCADE;
DROP SERVER  demo_remote  CASCADE;   -- server FDW là toàn cục, không thuộc schema
```

> Chi tiết về lược đồ, số lượng bảng/dòng và câu truy vấn DEMO có sẵn trong `db/seeds/README.md` và các README ở từng thư mục con.

### 10.7. Test kết nối bảo mật (TLS/SSL + SSH Tunnel)

Stack còn kèm các CSDL **bật bảo mật** để thử tab **TLS/SSL** và **SSH Tunnel**:

```bash
make secure-gen   # sinh CA/cert/key TLS + SSH key vào secure/ (chạy một lần)
make up           # dựng thêm postgres-tls / mysql-tls / redis-tls / bastion
```

| Mục đích | Host | Cổng | Ghi chú |
|---|---|---|---|
| PostgreSQL TLS | `localhost` | `5434` | bắt buộc mã hoá (chặn plaintext), client cert tuỳ chọn, CA = `secure/tls/ca.crt` |
| PostgreSQL mTLS | `localhost` | `5435` | **bắt buộc** client cert (`client.crt`+`client.key`) |
| MySQL TLS | `127.0.0.1` | `3307` | bắt buộc TLS (chặn kết nối không mã hoá) |
| Redis TLS | `localhost` | `6380` | — |
| Bastion SSH | `localhost` | `2222` | user `jdb`, mật khẩu `jdbtest` hoặc key `secure/ssh/id_ed25519` |
| CSDL nội bộ qua tunnel | `internal-postgres` | `5432` | chỉ tới được sau khi SSH vào bastion |

> Bảng tham số đầy đủ để khai báo trong ứng dụng: xem **`secure/README.md`**.

---

> **JiveDB** — đủ mạnh cho công việc thực tế, đủ nhẹ để dùng mỗi ngày.
