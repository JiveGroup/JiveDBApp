#!/usr/bin/env bash
# Dựng file SQLite mẫu từ schema + data. Yêu cầu: sqlite3.
#   ./build.sh            -> tạo jdb_sample.sqlite
set -euo pipefail
cd "$(dirname "$0")"
OUT="${1:-jdb_sample.sqlite}"
rm -f "$OUT"
sqlite3 "$OUT" < schema.sql
sqlite3 "$OUT" < data.sql
echo "✓ Đã tạo $OUT"
sqlite3 "$OUT" "SELECT 'tables', count(*) FROM sqlite_master WHERE type='table';"
