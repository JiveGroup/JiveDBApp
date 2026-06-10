# Seed — Redis

Script dữ liệu mẫu cho Redis: **1000 key** đa kiểu. Dữ liệu tổng hợp, chỉ để test.

---

## 1. File

- `seed.redis` — danh sách lệnh `redis-cli` (mỗi dòng một lệnh), bắt đầu bằng `FLUSHDB` nên nạp lại được nhiều lần.

---

## 2. Có những kiểu gì (≈1000 key)

| Kiểu | Mẫu khoá | Số lượng |
|---|---|---|
| hash | `user:*` (300), `cart:*` (100), `order:*` (100) | 500 |
| string (+TTL) | `session:tok*` (150), `rate:ip:*` (50) | 200 |
| counter (string) | `product:*:views` | 150 |
| list | `feed:user:*` | 80 |
| set | `tags:product:*` | 60 |
| sorted set | `leaderboard:wk*` | 10 |

---

## 3. Tự nạp qua Docker

`docker-compose.yml` có service `redis-seed` chạy một lần: chờ Redis sẵn sàng rồi nạp `seed.redis`.

```bash
docker compose up -d
docker compose logs redis-seed     # xem "redis seeded"
```

Nạp lại (Redis không bền vững theo mặc định): chạy lại service seed:

```bash
docker compose run --rm redis-seed
```

---

## 4. Nạp thủ công

```bash
redis-cli -h localhost -p 6379 < seed.redis
```

---

## 5. Kết nối từ JiveDB

| Trường | Giá trị |
|---|---|
| Loại | Redis |
| Host / Port | localhost / 6379 |
| Password | (không) |
| DB index | db0 |

---

## 6. Ghi chú

- File không chứa dòng chú thích vì `redis-cli` xử lý từng dòng là một lệnh.
- Sinh lại: `node db/seeds/generate.mjs`.
