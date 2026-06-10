# Seed — Redis (TẦM TRUNG)

Script dữ liệu mẫu: **5000 key** đa kiểu (tiền tố `m:`). Chỉ để test.

## 1. File
- `seed.redis` — danh sách lệnh `redis-cli` (mỗi dòng một lệnh), bắt đầu bằng `FLUSHDB`.
- `queries.redis` — lệnh demo để duyệt dữ liệu.

## 2. Có những kiểu gì (~5000 key)
| Kiểu | Mẫu khoá |
|---|---|
| string | `m:str:*` |
| hash | `m:user:*` |
| list | `m:list:*` |
| set | `m:set:*` |
| sorted set | `m:rank:*` |

## 3. Nạp (vào DB index riêng để không đụng bộ khác)
```bash
redis-cli -n 1 < db/seeds-medium/redis/seed.redis
```
> `FLUSHDB` sẽ xoá sạch DB đang chọn trước khi nạp.

## 4. Sinh lại
`node db/seeds-medium/generate.mjs`

