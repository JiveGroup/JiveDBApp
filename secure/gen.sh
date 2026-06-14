#!/usr/bin/env bash
# Sinh toàn bộ "file bảo mật" cho hạ tầng test kết nối an toàn (TLS/SSL + SSH).
# CHỈ DÙNG CHO TEST CỤC BỘ — không bao giờ dùng cho production.
#
#   ./secure/gen.sh           # sinh đầy đủ cert TLS + SSH key
#   make secure-gen           # tương đương (qua Makefile)
#
# Kết quả:
#   secure/tls/   ca.crt, ca.key, <db>.crt/.key (server), client.crt/.key (mTLS)
#   secure/ssh/   id_ed25519, id_ed25519.pub   (cặp khoá SSH cho bastion)
#
# Các đường dẫn này chính là thứ khai báo trong tab "TLS/SSL" và "SSH Tunnel"
# của ứng dụng JDB (xem secure/README.md).
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TLS="$HERE/tls"
SSHDIR="$HERE/ssh"
DAYS=3650

mkdir -p "$TLS" "$SSHDIR"

echo "==> Sinh chứng chỉ TLS vào $TLS"

# ── Root CA ─────────────────────────────────────────────────────────────────
# Một CA test tự ký; dùng cho cả 3 engine để bật verify-ca / verify-full.
openssl req -x509 -new -nodes -newkey rsa:4096 -sha256 -days "$DAYS" \
  -keyout "$TLS/ca.key" -out "$TLS/ca.crt" \
  -subj "/O=JDB Test/CN=JDB Test Root CA" 2>/dev/null
echo "    ca.crt / ca.key"

# gen_server <tên file> <danh sách SAN>
# CN luôn = localhost để client cũ (kiểm CN) cũng pass verify-full;
# SAN gồm localhost + 127.0.0.1 + tên service trong docker network.
gen_server() {
  local name="$1" san="$2"
  openssl req -new -nodes -newkey rsa:2048 \
    -keyout "$TLS/$name.key" -out "$TLS/$name.csr" \
    -subj "/O=JDB Test/CN=localhost" 2>/dev/null
  openssl x509 -req -in "$TLS/$name.csr" \
    -CA "$TLS/ca.crt" -CAkey "$TLS/ca.key" -CAcreateserial \
    -out "$TLS/$name.crt" -days "$DAYS" -sha256 \
    -extfile <(printf 'subjectAltName=%s\nextendedKeyUsage=serverAuth\nkeyUsage=digitalSignature,keyEncipherment\n' "$san") \
    2>/dev/null
  rm -f "$TLS/$name.csr"
  echo "    $name.crt / $name.key  (SAN: $san)"
}

gen_server postgres "DNS:localhost,IP:127.0.0.1,DNS:postgres-tls,DNS:internal-postgres"
gen_server mysql    "DNS:localhost,IP:127.0.0.1,DNS:mysql-tls"
gen_server redis    "DNS:localhost,IP:127.0.0.1,DNS:redis-tls"

# ── Client cert cho mTLS ────────────────────────────────────────────────────
# Server (khi bật xác thực client) sẽ kiểm cert này được CA ở trên ký.
openssl req -new -nodes -newkey rsa:2048 \
  -keyout "$TLS/client.key" -out "$TLS/client.csr" \
  -subj "/O=JDB Test/CN=jdb" 2>/dev/null
openssl x509 -req -in "$TLS/client.csr" \
  -CA "$TLS/ca.crt" -CAkey "$TLS/ca.key" -CAcreateserial \
  -out "$TLS/client.crt" -days "$DAYS" -sha256 \
  -extfile <(printf 'extendedKeyUsage=clientAuth\nkeyUsage=digitalSignature,keyEncipherment\n') \
  2>/dev/null
rm -f "$TLS/client.csr"
echo "    client.crt / client.key  (CN=jdb, cho mTLS)"

# Cert/key để mở 0644 cho container (uid khác chủ sở hữu host) đọc được.
# Đây là cert TEST dùng một lần nên quyền mở không gây rủi ro thực tế.
# Riêng PostgreSQL từ chối key có quyền group/world → entrypoint sẽ copy
# và chmod 600 lại bên trong container (secure/postgres-tls-entrypoint.sh).
chmod 644 "$TLS"/*.crt "$TLS"/*.key

# ── SSH keypair cho bastion ─────────────────────────────────────────────────
echo "==> Sinh SSH keypair vào $SSHDIR"
if [ -f "$SSHDIR/id_ed25519" ]; then
  echo "    id_ed25519 đã tồn tại — giữ nguyên"
else
  ssh-keygen -t ed25519 -N "" -C "jdb-tunnel-test" -f "$SSHDIR/id_ed25519" >/dev/null
  echo "    id_ed25519 / id_ed25519.pub"
fi
chmod 600 "$SSHDIR/id_ed25519"
chmod 644 "$SSHDIR/id_ed25519.pub"

echo
echo "Hoàn tất. Xem secure/README.md để biết tham số khai báo trong ứng dụng."
