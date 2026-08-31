# Makefile tiện ích cho hạ tầng CSDL test (docker-compose) và dữ liệu mẫu.
# Chỉ dùng cho phát triển/test cục bộ — KHÔNG dùng cho production.
#
#   make            # xem danh sách lệnh
#   make up         # dựng PostgreSQL + MySQL + Redis, tự nạp dữ liệu mẫu
#   make reset      # nạp lại từ đầu (xoá volume cũ rồi seed lại)

.DEFAULT_GOAL := help

.PHONY: help up up-multi up-secure up-ssh up-standalone up-all down reset restart logs ps \
        psql psql18 pg-multi pg-multi-ls pg-multi-schemas mysql mysql-multi mysql-multi-ls \
        mariadb redis-cli redis8-cli \
        mongo mongo8 mongo-standalone mongo-warmup mongo-writer mongo-writer-stop \
        secure-gen psql-tls psql-mtls mysql-tls redis-tls-cli ssh-tunnel \
        generate generate-multi generate-multi-small sqlite pg-objects clean \
        reset-mongo reset-one verify verify-mongo smoke

help: ## Liệt kê các lệnh có sẵn
	@echo "Lệnh khả dụng:"
	@grep -E '^[a-zA-Z0-9_.-]+:.*## ' $(MAKEFILE_LIST) \
		| awk 'BEGIN{FS=":.*## "}{printf "  \033[36m%-22s\033[0m %s\n", $$1, $$2}'

## ── Docker stack ────────────────────────────────────────────────────────────

# Service `mongodb` nằm trong nhóm mặc định và mount secure/mongo/keyfile, mà file
# đó bị .gitignore → máy vừa clone chạy `make up` sẽ hỏng (Docker tạo THƯ MỤC rỗng
# thay cho file, mongod không khởi động nổi). Khai keyfile thành prerequisite dạng
# file để make tự sinh khi thiếu, và không làm gì khi đã có.
secure/mongo/keyfile:
	./secure/gen.sh

secure-gen: ## Sinh cert TLS + SSH key + keyfile MongoDB vào secure/
	./secure/gen.sh

up: secure/mongo/keyfile ## Dựng nhóm mặc định (postgres, postgres18, mysql, mariadb, mongodb 7+8, redis 7+8)
	docker compose up -d

up-multi: ## Thêm postgres-multi (5436) + mysql-multi (3308) — profile multi
	docker compose --profile multi up -d

up-secure: ## Thêm các service TLS/mTLS (profile secure)
	docker compose --profile secure up -d

up-ssh: ## Thêm bastion + internal-postgres (profile ssh)
	docker compose --profile ssh up -d

up-standalone: secure/mongo/keyfile ## Thêm mongodb-standalone (27019, không replica set)
	docker compose --profile standalone up -d

up-all: secure/mongo/keyfile ## Dựng TẤT CẢ service (trừ mongodb-writer, xem `make mongo-writer`)
	docker compose --profile all up -d

down: ## Dừng stack, GIỮ dữ liệu trong volume
	docker compose down

clean: ## Dừng stack và xoá TOÀN BỘ volume (mất hết dữ liệu MỌI database)
	docker compose down -v

# `down` KHÔNG xoá volume, mà script seed chỉ chạy khi volume còn rỗng — nên
# `down && up` (bản cũ của target này) không hề seed lại, chỉ bật lại dữ liệu cũ.
reset: clean up ## Xoá volume rồi seed lại từ đầu (MỌI database — cân nhắc reset-mongo)

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

mariadb: ## Mở mariadb client vào MariaDB 11 (port 3309)
	docker exec -it jdbapp-mariadb-1 mariadb -ujdb -pjdbtest jdb_dev

redis-cli: ## Mở redis-cli vào Redis 7 (port 6379)
	docker exec -it jdbapp-redis-1 redis-cli

redis8-cli: ## Mở redis-cli vào Redis 8 (port 6381)
	docker exec -it jdbapp-redis8-1 redis-cli

mongo: ## Mở mongosh vào MongoDB 7 (port 27017, replica set rs0)
	docker exec -it jdbapp-mongodb-1 mongosh -u jdb -p jdbtest --authenticationDatabase admin jdb_dev

mongo8: ## Mở mongosh vào MongoDB 8 (port 27018, replica set rs0)
	docker exec -it jdbapp-mongodb8-1 mongosh -u jdb -p jdbtest --authenticationDatabase admin jdb_dev

mongo-standalone: ## Mở mongosh vào MongoDB standalone (port 27019)
	docker exec -it jdbapp-mongodb-standalone-1 mongosh -u jdb -p jdbtest --authenticationDatabase admin jdb_dev

# $indexStats và mức profiling gắn với tiến trình mongod nên bị reset mỗi lần
# container khởi động lại — khi đó cả bảng index lại hiện "unused". Chạy lại
# target này là đủ, không cần seed lại dữ liệu.
mongo-warmup: ## Nạp lại system.profile + hâm nóng index (sau khi restart container)
	@docker exec -i jdbapp-mongodb-1 mongosh --quiet -u jdb -p jdbtest \
		--authenticationDatabase admin jdb_dev --file /dev/stdin < db/seeds/mongodb/03-warmup.js

mongo-writer: ## Bật vòng lặp ghi để demo Change Tail (nhớ chạy mongo-writer-stop khi xong)
	docker compose --profile mongo-writer up -d mongodb-writer
	@echo "Đang ghi vào jdb_dev.change_tail_demo. Xem: JiveDB → Live Ops → Change Tail"
	@echo "Dừng: make mongo-writer-stop"

mongo-writer-stop: ## Dừng vòng lặp ghi Change Tail
	docker compose stop mongodb-writer
	-docker compose rm -f mongodb-writer

## ── Kết nối bảo mật (TLS/SSL + SSH Tunnel) ───────────────────────────────────

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

## ── Nạp lại theo từng service ───────────────────────────────────────────────

# `make clean`/`make reset` xoá volume của MỌI database. Khi chỉ đang sửa seed của
# một DB thì dùng các target dưới đây để khỏi mất dữ liệu các DB còn lại.
# Bắt buộc dùng `rm -sfv`: cờ -v xoá volume ẩn chứa /data — thiếu nó thì script
# trong docker-entrypoint-initdb.d KHÔNG chạy lại và bạn vẫn thấy dữ liệu cũ.
reset-mongo: secure/mongo/keyfile ## Nạp lại RIÊNG MongoDB 7+8 (giữ nguyên Postgres/MySQL/Redis)
	docker compose rm -sfv mongodb mongodb-rs-init mongodb8 mongodb8-rs-init
	docker compose up -d mongodb mongodb-rs-init mongodb8 mongodb8-rs-init
	@echo "Đang seed + warmup, thường mất 40-60s..."
	@for i in $$(seq 1 120); do \
	  if docker compose logs mongodb-rs-init 2>/dev/null | grep -q '03-warmup.js: done' && \
	     docker compose logs mongodb8-rs-init 2>/dev/null | grep -q '03-warmup.js: done'; then \
	    echo "Xong. Kiểm tra bằng: make verify-mongo"; exit 0; \
	  fi; sleep 2; \
	done; \
	echo "HẾT THỜI GIAN CHỜ — xem log: docker compose logs mongodb-rs-init"; exit 1

reset-one: ## Nạp lại 1 service bất kỳ. Vd: make reset-one SVC=mariadb
	@test -n "$(SVC)" || { echo "Thiếu SVC. Vd: make reset-one SVC=mariadb"; exit 1; }
	docker compose rm -sfv $(SVC)
	docker compose up -d $(SVC)

## ── Kiểm tra ────────────────────────────────────────────────────────────────

# Phần lớn giá trị của bộ seed nằm ở chỗ dữ liệu được canh đúng NGƯỠNG của ứng
# dụng (document phải vượt 2 MiB thì clipping mới chạy, phải có đúng 2 index
# ops=0 thì cờ "unused" mới có nghĩa...). Những thứ đó hỏng rất im lặng: seed vẫn
# nạp xong, không lỗi gì, chỉ là tính năng lặng lẽ không kích hoạt.
verify-mongo: ## Kiểm tra bất biến của seed MongoDB (exit != 0 nếu hỏng)
	@docker exec -i jdbapp-mongodb-1 mongosh --quiet -u jdb -p jdbtest \
		--authenticationDatabase admin jdb_dev --file /dev/stdin < db/seeds/mongodb/verify.js

verify: verify-mongo ## Chạy toàn bộ kiểm tra hiện có

smoke: ## Ping mọi service đang chạy — in bảng OK/FAIL
	@fail=0; \
	chk() { \
	  if ! docker ps --format '{{.Names}}' | grep -qx "$$2"; then \
	    printf "  \033[90m%-26s chưa chạy\033[0m\n" "$$1"; return 0; fi; \
	  if docker exec "$$2" sh -c "$$3" >/dev/null 2>&1; then \
	    printf "  \033[32m%-26s OK\033[0m\n" "$$1"; \
	  else printf "  \033[31m%-26s FAIL\033[0m\n" "$$1"; fail=1; fi; }; \
	chk "PostgreSQL 16 (5432)"  jdbapp-postgres-1           "pg_isready -U jdb -d jdb_dev"; \
	chk "PostgreSQL 18 (5433)"  jdbapp-postgres18-1         "pg_isready -U jdb -d jdb_dev"; \
	chk "PostgreSQL multi(5436)" jdbapp-postgres-multi-1    "pg_isready -U jdb -d jdb_ecommerce"; \
	chk "MySQL 8 (3306)"        jdbapp-mysql-1              "mysqladmin ping -ujdb -pjdbtest"; \
	chk "MySQL multi (3308)"    jdbapp-mysql-multi-1        "mysqladmin ping -ujdb -pjdbtest"; \
	chk "MariaDB 11 (3309)"     jdbapp-mariadb-1            "mariadb-admin ping -ujdb -pjdbtest"; \
	chk "MongoDB 7 (27017)"     jdbapp-mongodb-1            "mongosh --quiet -u jdb -p jdbtest --authenticationDatabase admin --eval 'db.runCommand({ping:1})'"; \
	chk "MongoDB 8 (27018)"     jdbapp-mongodb8-1           "mongosh --quiet -u jdb -p jdbtest --authenticationDatabase admin --eval 'db.runCommand({ping:1})'"; \
	chk "MongoDB stand.(27019)" jdbapp-mongodb-standalone-1 "mongosh --quiet -u jdb -p jdbtest --authenticationDatabase admin --eval 'db.runCommand({ping:1})'"; \
	chk "Redis 7 (6379)"        jdbapp-redis-1              "redis-cli ping"; \
	chk "Redis 8 (6381)"        jdbapp-redis8-1             "redis-cli ping"; \
	exit $$fail
