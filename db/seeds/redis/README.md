# Seed — Redis

Script dữ liệu mẫu cho Redis: **1000 key** đa kiểu. Dữ liệu tổng hợp, chỉ để test.

---

## 1. File

| File | Dùng cho | JSON format |
|---|---|---|
| `seed7.redis` | Redis 6/7 (plain, không module) | `SET key '{"...":"..."}'` — JSON lưu dạng string |
| `seed8.redis` | Redis 8 (built-in JSON) | `JSON.SET key $ '{"...":"..."}'` — JSON native |
| `queries.redis` | Demo queries cho cả hai phiên bản | |

---

## 2. Có những kiểu gì (≈1050 key)

| Kiểu | Mẫu khoá | Số lượng |
|---|---|---|
| hash | `user:*` (300), `cart:*` (100), `order:*` (100) | 500 |
| string (+TTL) | `session:tok*` (150), `rate:ip:*` (50) | 200 |
| counter (string) | `product:*:views` | 150 |
| list | `feed:user:*` | 80 |
| set | `tags:product:*` | 60 |
| sorted set | `leaderboard:wk*` | 10 |
| **stream** | `events:user:*` (3), `notifications:orders` (1), `audit:login` (1) | 5 |
| **json** | `product:*:meta` (20) — `SET` string (Redis 7) hoặc `JSON.SET` (Redis 8) | 20 |

---

## 3. Tự nạp qua Docker

`docker-compose.yml` tự chọn file đúng cho từng service:
- `redis-seed` → `seed7.redis` (Redis 7 trên port 6379)
- `redis8-seed` → `seed8.redis` (Redis 8 trên port 6381)

```bash
docker compose up -d
docker compose logs redis-seed redis8-seed
```

Nạp lại: `docker compose run --rm redis-seed` hoặc `docker compose run --rm redis8-seed`.

---

## 4. Nạp thủ công

```bash
redis-cli -h localhost -p 6379 < seed7.redis     # Redis 7
redis-cli -h localhost -p 6381 < seed8.redis     # Redis 8
```

---

## 5. Kết nối từ JiveDB

| Phiên bản | Host / Port |
|---|---|
| Redis 7 | localhost / 6379 |
| Redis 8 | localhost / 6381 |

Password: (không) · DB index: db0

---

## 6. Ghi chú

- File không chứa dòng chú thích vì `redis-cli` xử lý từng dòng là một lệnh.
