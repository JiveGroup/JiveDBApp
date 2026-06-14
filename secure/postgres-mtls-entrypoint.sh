#!/usr/bin/env bash
# Entrypoint cho service postgres-mtls. Như postgres-tls (copy cert + chmod 600
# để Postgres chấp nhận key), nhưng thêm: nạp pg_hba.conf yêu cầu client cert.
set -e

SRC=/certs
DST=/var/lib/postgresql/tls
mkdir -p "$DST"
cp "$SRC/ca.crt" "$SRC/postgres.crt" "$SRC/postgres.key" "$DST/"
cp /etc/postgres-mtls/pg_hba.conf "$DST/pg_hba.conf"
chown -R postgres:postgres "$DST"
chmod 600 "$DST/postgres.key"
chmod 644 "$DST/postgres.crt" "$DST/ca.crt" "$DST/pg_hba.conf"

exec docker-entrypoint.sh postgres \
  -c ssl=on \
  -c ssl_cert_file="$DST/postgres.crt" \
  -c ssl_key_file="$DST/postgres.key" \
  -c ssl_ca_file="$DST/ca.crt" \
  -c hba_file="$DST/pg_hba.conf"
