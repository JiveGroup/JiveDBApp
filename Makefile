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
