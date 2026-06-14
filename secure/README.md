# Hạ tầng test kết nối bảo mật (TLS/SSL + SSH Tunnel)

Thư mục này cung cấp **CSDL bật bảo mật** và **các file bảo mật** để test 2 tính
năng mới của ứng dụng JDB theo `docs/PLAN_secure_connections.md` (repo `jdb`):

- **TLS/SSL** cho PostgreSQL / MySQL / Redis — đủ 4 mode + mTLS.
- **SSH Tunnel** (single-hop) tới một CSDL nội bộ không mở cổng ra ngoài.

> ⚠️ **CHỈ DÙNG CHO TEST CỤC BỘ.** Toàn bộ cert/key/SSH key ở đây là vật phẩm
> test dùng một lần, thông tin đăng nhập là giá trị cố định công khai. Tuyệt đối
> không tái sử dụng cho môi trường thật.

---

## 1. Sinh các file bảo mật

```bash
./secure/gen.sh        # hoặc: make secure-gen
```

Tạo ra:

```
secure/tls/
  ca.crt  ca.key          # Root CA test (ký mọi cert bên dưới)
  postgres.crt  .key       # server cert cho postgres-tls
  mysql.crt     .key       # server cert cho mysql-tls
  redis.crt     .key       # server cert cho redis-tls
  client.crt    .key       # client cert (CN=jdb) cho mTLS
secure/ssh/
  id_ed25519  id_ed25519.pub   # cặp khoá SSH cho bastion
```

Server cert có SAN gồm `localhost`, `127.0.0.1` và tên service → dùng được tới
mode `verify-full`. Chạy lại script là sinh đè (SSH key thì giữ nguyên nếu đã có).

---

## 2. Dựng stack

```bash
make up           # dựng toàn bộ, kể cả các service bảo mật
# hoặc chỉ phần bảo mật:
docker compose up -d postgres-tls mysql-tls redis-tls redis-tls-seed bastion internal-postgres
```

---

## 3. Bảng tham số kết nối

### 3.1. TLS/SSL (tab "TLS/SSL" trong app)

| Engine | Host | Port | User / Pass | DB | Server CA | Client cert / key (mTLS) |
|---|---|---|---|---|---|---|
| PostgreSQL (TLS) | `localhost` | `5434` | `jdb` / `jdbtest` | `jdb_dev` | `secure/tls/ca.crt` | _tuỳ chọn_ `secure/tls/client.crt` + `secure/tls/client.key` |
| PostgreSQL (mTLS) | `localhost` | `5435` | `jdb` / `jdbtest` | `jdb_dev` | `secure/tls/ca.crt` | **bắt buộc** `secure/tls/client.crt` + `secure/tls/client.key` |
| MySQL | `127.0.0.1` | `3307` | `jdb` / `jdbtest` | `jdb_dev` | `secure/tls/ca.crt` | _tuỳ chọn_ `secure/tls/client.crt` + `secure/tls/client.key` |
| Redis | `localhost` | `6380` | — | — | `secure/tls/ca.crt` | _tuỳ chọn_ `secure/tls/client.crt` + `secure/tls/client.key` |

- 4 mode đều test được: `require`, `verify-ca`, `verify-full` (đặt host = `localhost`).
- **mySQL** bật `require_secure_transport=ON` → kết nối **không** TLS tới `3307` sẽ
  bị từ chối (dùng để chứng minh TLS đang thực sự hoạt động).
- **Redis** đang để `tls-auth-clients no` (client cert tuỳ chọn). Muốn bắt buộc
  mTLS, đổi thành `yes` trong `docker-compose.yml` rồi `docker compose up -d redis-tls`.
- **`postgres-tls` (5434) BẮT BUỘC mã hoá:** `pg_hba` dùng `hostssl` + `hostnossl
  reject` → kết nối `sslmode=disable` bị từ chối (`pg_hba.conf rejects ... no
  encryption`). Các mode `require`/`verify-ca`/`verify-full` vẫn chạy.
- **`ca.crt` không phải thứ server kiểm — nó để CLIENT xác minh SERVER.** Vì vậy
  `sslmode=require` (mã hoá nhưng không xác minh) vào được mà **không cần** `ca.crt`;
  chỉ `verify-ca`/`verify-full` mới cần. Server không thể ép client phải dùng `ca.crt`.
- **Client cert (mTLS) chỉ có hiệu lực khi server YÊU CẦU nó.**
  - `postgres-tls` (5434): **không** đòi client cert → có hay không gửi `client.crt/key`
    đều vào được (xác thực bằng mật khẩu, miễn là có TLS). Tốt để test các mode
    `require`/`verify-ca`/`verify-full`.
  - `postgres-mtls` (5435): `pg_hba` đặt `clientcert=verify-full` → **bắt buộc**
    client cert (và CN phải khớp user). Thiếu `client.crt/key` hợp lệ sẽ bị từ chối
    với lỗi `connection requires a valid client certificate`. Đây là nơi thấy rõ
    tác dụng của Client Auth.

Kiểm nhanh từ CLI:

```bash
make psql-tls         # psql sslmode=verify-full qua CA test
make mysql-tls        # mysql --ssl-mode=VERIFY_CA
make redis-tls-cli    # redis-cli --tls
```

### 3.2. SSH Tunnel (tab "SSH Tunnel" trong app)

CSDL đích **`internal-postgres`** không mở cổng ra host — chỉ tới được qua bastion.

**Phần SSH (bastion):**

| Tham số | Giá trị |
|---|---|
| SSH host | `localhost` |
| SSH port | `2222` |
| SSH user | `jdb` |
| Xác thực bằng mật khẩu | `jdbtest` |
| Xác thực bằng key | `secure/ssh/id_ed25519` (không có passphrase) |

**Phần CSDL đích (đi xuyên tunnel):**

| Tham số | Giá trị |
|---|---|
| DB host | `internal-postgres` |
| DB port | `5432` |
| User / Pass | `jdb` / `jdbtest` |
| Database | `jdb_dev` |

> Bastion nằm cùng docker network nên phân giải được tên `internal-postgres`.
> Có thể test cả 2 cách xác thực SSH: mật khẩu **hoặc** private key.

Kiểm nhanh từ CLI (mở tunnel rồi truy vấn ở terminal khác):

```bash
make ssh-tunnel       # localhost:55432 -> internal-postgres:5432
# terminal khác:
psql "host=localhost port=55432 user=jdb dbname=jdb_dev"
```

---

## 4. Cổng tổng hợp

| Service | Cổng host | Bảo mật |
|---|---|---|
| `postgres` / `postgres18` | 5432 / 5433 | plaintext (sẵn có) |
| `mysql` | 3306 | plaintext (sẵn có) |
| `redis` | 6379 | plaintext (sẵn có) |
| `postgres-tls` | 5434 | TLS **bắt buộc** (chặn plaintext), client cert tuỳ chọn |
| `postgres-mtls` | 5435 | TLS + client cert **bắt buộc** (mTLS) |
| `mysql-tls` | 3307 | TLS (bắt buộc) |
| `redis-tls` | 6380 | TLS |
| `bastion` | 2222 | SSH |
| `internal-postgres` | — | chỉ qua tunnel |

Các service bảo mật là **bổ sung**, không thay đổi service plaintext cũ — đúng
tinh thần tương thích ngược của kế hoạch.
