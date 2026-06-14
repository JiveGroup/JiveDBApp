#!/usr/bin/env bash
# Entrypoint bọc cho service postgres-tls.
# PostgreSQL từ chối khởi động nếu file private key cho phép group/world đọc,
# và yêu cầu key thuộc sở hữu của user postgres (hoặc root). File mount từ host
# thường có uid/quyền không thoả mãn → ta copy ra thư mục riêng, chmod 600 và
# chown postgres TRƯỚC khi gọi entrypoint gốc.
#
# Container chạy với user: root; entrypoint gốc của postgres khi thấy uid=0 sẽ
# tự gosu xuống user postgres, nên ta vẫn tận dụng được toàn bộ logic init/seed.
set -e

SRC=/certs
DST=/var/lib/postgresql/tls
mkdir -p "$DST"
cp "$SRC/ca.crt" "$SRC/postgres.crt" "$SRC/postgres.key" "$DST/"
cp /etc/postgres-tls/pg_hba.conf "$DST/pg_hba.conf" # ép TLS, chặn plaintext
chown -R postgres:postgres "$DST"
chmod 600 "$DST/postgres.key"
chmod 644 "$DST/postgres.crt" "$DST/ca.crt" "$DST/pg_hba.conf"

exec docker-entrypoint.sh postgres \
  -c ssl=on \
  -c ssl_cert_file="$DST/postgres.crt" \
  -c ssl_key_file="$DST/postgres.key" \
  -c ssl_ca_file="$DST/ca.crt" \
  -c hba_file="$DST/pg_hba.conf"
