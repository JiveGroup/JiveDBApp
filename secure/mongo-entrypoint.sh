#!/usr/bin/env bash
# Entrypoint bọc cho service mongodb/mongodb8.
# MongoDB từ chối khởi động (--replSet + --auth cùng lúc) nếu keyfile cho phép
# group/world đọc, và yêu cầu keyfile thuộc sở hữu user mongodb (hoặc root). File
# mount từ host thường có uid/quyền không thoả mãn → ta copy ra thư mục riêng,
# chmod 400 và chown mongodb TRƯỚC khi gọi entrypoint gốc — cùng kỹ thuật với
# secure/postgres-tls-entrypoint.sh.
#
# Container chạy với user: root; entrypoint gốc của mongo khi thấy uid=0 sẽ tự
# gosu xuống user mongodb, nên ta vẫn tận dụng được toàn bộ logic init/seed
# (docker-entrypoint-initdb.d, MONGO_INITDB_ROOT_USERNAME/PASSWORD...).
set -e

SRC=/keyfile-src/keyfile
DST=/etc/mongo-keyfile
cp "$SRC" "$DST"
chown mongodb:mongodb "$DST"
chmod 400 "$DST"

exec docker-entrypoint.sh mongod --replSet rs0 --keyFile "$DST"
