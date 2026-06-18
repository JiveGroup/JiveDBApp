# Makefile tiện ích cho hạ tầng CSDL test (docker-compose) và dữ liệu mẫu.
# Chỉ dùng cho phát triển/test cục bộ — KHÔNG dùng cho production.
#
#   make            # xem danh sách lệnh
#   make up         # dựng PostgreSQL + MySQL + Redis, tự nạp dữ liệu mẫu
#   make reset      # nạp lại từ đầu (xoá volume cũ rồi seed lại)

.DEFAULT_GOAL := help

.PHONY: help up up-single up-secure up-ssh up-all down reset restart logs ps \
        psql psql18 pg-multi pg-multi-ls pg-multi-schemas mysql mysql-multi mysql-multi-ls redis-cli \
        secure-gen psql-tls psql-mtls mysql-tls redis-tls-cli ssh-tunnel \
        generate sqlite pg-objects clean

help: ## Liệt kê các lệnh có sẵn
	@echo "Lệnh khả dụng:"
	@grep -E '^[a-zA-Z0-9_-]+:.*## ' $(MAKEFILE_LIST) \
		| awk 'BEGIN{FS=":.*## "}{printf "  \033[36m%-14s\033[0m %s\n", $$1, $$2}'

## ── Docker stack ────────────────────────────────────────────────────────────

up: ## Dựng nhóm chính (postgres-multi, mysql-multi, redis, redis-seed)
	docker compose up -d

up-single: ## Thêm postgres, postgres18, mysql (profile single)
	docker compose --profile single up -d

up-secure: ## Thêm các service TLS/mTLS (profile secure)
	docker compose --profile secure up -d

up-ssh: ## Thêm bastion + internal-postgres (profile ssh)
	docker compose --profile ssh up -d

up-all: ## Dựng TẤT CẢ service (mọi profile)
	docker compose --profile all up -d

down: ## Dừng stack, GIỮ dữ liệu trong volume
	docker compose down

clean: ## Dừng stack và xoá toàn bộ volume (mất hết dữ liệu)
	docker compose down -v

reset: down up ## Xoá volume rồi seed lại từ đầu

restart: ## Khởi động lại các service (không xoá dữ liệu)
	docker compose restart

logs: ## Theo dõi log tất cả service (Ctrl+C để thoát)
	docker compose logs -f

ps: ## Xem trạng thái các container
	docker compose ps

## ── Mở shell vào DB ─────────────────────────────────────────────────────────

psql: ## Mở psql vào PostgreSQL 16 (port 5432)
	docker exec -it jdbapp-postgres-1 psql -U jdb -d jdb_dev

psql18: ## Mở psql vào PostgreSQL 18 (port 5433)
	docker exec -it jdbapp-postgres18-1 psql -U jdb -d jdb_dev

pg-multi: ## Mở psql vào PostgreSQL multi-db (port 5436, jdb_ecommerce)
	docker exec -it jdbapp-postgres-multi-1 psql -U jdb -d jdb_ecommerce

pg-multi-ls: ## Liệt kê tất cả database trong instance multi-db
	docker exec -it jdbapp-postgres-multi-1 psql -U jdb -d jdb_ecommerce -c "\l"

pg-multi-schemas: ## Liệt kê schema trong mỗi database multi-db
	@for db in jdb_ecommerce jdb_healthcare jdb_banking; do \
	  echo "=== $$db ==="; \
	  docker exec -it jdbapp-postgres-multi-1 psql -U jdb -d $$db -c "\dn"; \
	done

mysql: ## Mở mysql client vào MySQL 8 (port 3306)
	docker exec -it jdbapp-mysql-1 mysql -ujdb -pjdbtest jdb_dev

mysql-multi: ## Mở mysql client vào MySQL multi-db (port 3308, jdb_ecommerce)
	docker exec -it jdbapp-mysql-multi-1 mysql -ujdb -pjdbtest jdb_ecommerce

mysql-multi-ls: ## Liệt kê database mà tài khoản jdb thấy trong instance multi-db
	docker exec -it jdbapp-mysql-multi-1 mysql -ujdb -pjdbtest -e "SHOW DATABASES;"

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

generate: ## Sinh lại file SQL/Redis cho bộ seed (cần Node)
	node db/seeds/generate.mjs

generate-multi: ## Sinh dữ liệu multi-DB seed (~500MB compressed, cần Node)
	node db/seeds/multidb-postgres/generate.mjs

generate-multi-small: ## Sinh dữ liệu multi-DB seed 1% rows (~5MB, test nhanh)
	node db/seeds/multidb-postgres/generate.mjs --scale 0.01

sqlite: ## Dựng lại file SQLite mẫu
	db/seeds/sqlite/build.sh

pg-objects: ## Nạp đầy đủ schema objects mẫu vào PostgreSQL (schema demo_objects)
	docker exec -i jdbapp-postgres-1 psql -U jdb -d jdb_dev < db/sql/schema_object_postgres.sql
