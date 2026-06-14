# Makefile tiện ích cho hạ tầng CSDL test (docker-compose) và dữ liệu mẫu.
# Chỉ dùng cho phát triển/test cục bộ — KHÔNG dùng cho production.
#
#   make            # xem danh sách lệnh
#   make up         # dựng PostgreSQL + MySQL + Redis, tự nạp dữ liệu mẫu
#   make reset      # nạp lại từ đầu (xoá volume cũ rồi seed lại)
#   make up SEED=seeds-medium   # dùng bộ dữ liệu tầm trung
#
# Bộ dữ liệu mặc định = seeds (nhỏ). Đổi qua biến SEED.

SEED ?= seeds
COMPOSE := JDB_SEED=$(SEED) docker compose

.DEFAULT_GOAL := help

.PHONY: help up down reset restart logs ps \
        psql psql18 mysql redis-cli \
        secure-gen psql-tls psql-mtls mysql-tls redis-tls-cli ssh-tunnel \
        seed-small seed-medium generate sqlite pg-objects clean

help: ## Liệt kê các lệnh có sẵn
	@echo "Lệnh khả dụng (bộ seed hiện tại: SEED=$(SEED)):"
	@grep -E '^[a-zA-Z0-9_-]+:.*## ' $(MAKEFILE_LIST) \
		| awk 'BEGIN{FS=":.*## "}{printf "  \033[36m%-14s\033[0m %s\n", $$1, $$2}'

## ── Docker stack ────────────────────────────────────────────────────────────

up: ## Dựng stack ở chế độ nền, tự nạp dữ liệu mẫu (lần đầu)
	$(COMPOSE) up -d

down: ## Dừng stack, GIỮ dữ liệu trong volume
	$(COMPOSE) down

reset: ## Xoá volume rồi seed lại từ đầu
	$(COMPOSE) down -v && $(COMPOSE) up -d

restart: ## Khởi động lại các service (không xoá dữ liệu)
	$(COMPOSE) restart

logs: ## Theo dõi log tất cả service (Ctrl+C để thoát)
	$(COMPOSE) logs -f

ps: ## Xem trạng thái các container
	$(COMPOSE) ps

## ── Mở shell vào DB ─────────────────────────────────────────────────────────

psql: ## Mở psql vào PostgreSQL 16 (port 5432)
	docker exec -it jdbapp-postgres-1 psql -U jdb -d jdb_dev

psql18: ## Mở psql vào PostgreSQL 18 (port 5433)
	docker exec -it jdbapp-postgres18-1 psql -U jdb -d jdb_dev

mysql: ## Mở mysql client vào MySQL 8 (port 3306)
	docker exec -it jdbapp-mysql-1 mysql -ujdb -pjdbtest jdb_dev

redis-cli: ## Mở redis-cli vào Redis 7 (port 6379)
	docker exec -it jdbapp-redis-1 redis-cli

## ── Kết nối bảo mật (TLS/SSL + SSH Tunnel) ───────────────────────────────────

secure-gen: ## Sinh cert TLS + SSH key vào secure/ (chạy trước khi up)
	./secure/gen.sh

psql-tls: ## psql tới PostgreSQL TLS (host localhost:5434, verify-full qua CA test)
	psql "host=localhost port=5434 user=jdb dbname=jdb_dev sslmode=verify-full sslrootcert=secure/tls/ca.crt"

psql-mtls: ## psql tới PostgreSQL mTLS (host localhost:5435, BẮT BUỘC client cert)
	psql "host=localhost port=5435 user=jdb dbname=jdb_dev sslmode=verify-full sslrootcert=secure/tls/ca.crt sslcert=secure/tls/client.crt sslkey=secure/tls/client.key"

mysql-tls: ## mysql client tới MySQL TLS (host 127.0.0.1:3307, bắt buộc TLS)
	mysql --protocol=TCP -h127.0.0.1 -P3307 -ujdb -pjdbtest \
		--ssl-mode=VERIFY_CA --ssl-ca=secure/tls/ca.crt jdb_dev

redis-tls-cli: ## redis-cli tới Redis TLS (host localhost:6380)
	redis-cli --tls -h localhost -p 6380 --cacert secure/tls/ca.crt

ssh-tunnel: ## Mở SSH tunnel localhost:55432 -> internal-postgres:5432 (qua bastion)
	@echo "Tunnel: localhost:55432 -> internal-postgres:5432. Ctrl+C để đóng."
	ssh -i secure/ssh/id_ed25519 -p 2222 -N \
		-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
		-L 55432:internal-postgres:5432 jdb@localhost

## ── Dữ liệu mẫu ─────────────────────────────────────────────────────────────

seed-small: ## Seed lại với bộ NHỎ (seeds)
	$(MAKE) reset SEED=seeds

seed-medium: ## Seed lại với bộ TẦM TRUNG (seeds-medium)
	$(MAKE) reset SEED=seeds-medium

generate: ## Sinh lại file SQL/Redis cho bộ seed đang chọn (cần Node)
	node db/$(SEED)/generate.mjs

sqlite: ## Dựng lại file SQLite mẫu cho bộ seed đang chọn
	db/$(SEED)/sqlite/build.sh

pg-objects: ## Nạp đầy đủ schema objects mẫu vào PostgreSQL (schema demo_objects)
	docker exec -i jdbapp-postgres-1 psql -U jdb -d jdb_dev < db/postgres_schema_objects_sample.sql

clean: ## Dừng stack và xoá toàn bộ volume (mất hết dữ liệu)
	$(COMPOSE) down -v

# Tạo database mới (thay đổi tên nếu cần)
pg-new-db:
	docker exec -it jdbapp-postgres-1 psql -U jdb -d jdb_dev -c "CREATE DATABASE ten_db_moi OWNER jdb;"
	docker exec -i jdbapp-postgres-1 pg_restore -U jdb -d ten_db_moi < file.dump

# Tạo database mới cho MySQL (thay đổi tên nếu cần)
mysql-new-db:
	docker exec -it jdbapp-mysql-1 mysql -uroot -pjdbtest -e \
	    "CREATE DATABASE ten_db_moi CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci; \
     GRANT ALL PRIVILEGES ON ten_db_moi.* TO 'jdb'@'%'; FLUSH PRIVILEGES;"
    docker exec -i jdbapp-mysql-1 mysql -ujdb -pjdbtest ten_db_moi  <  dump.sql
