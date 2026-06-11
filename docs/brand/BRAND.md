# JiveDB — Brand Guidelines

Bộ nhận diện thương hiệu cho **JiveDB** (mã ngắn: **JDB**) — công cụ quản lý CSDL (PostgreSQL, MySQL, SQLite, Redis). Tài liệu và toàn bộ tài nguyên đặt trong `docs/brand/`.

---

## 1. Tổng quan

- **Tên đầy đủ**: JiveDB
- **Mã ngắn / tên kỹ thuật**: JDB
- **Tagline**: "One client for all your databases."
- **Cá tính**: hiện đại, gọn gàng, nhanh nhẹn ("jive" = sống động). Hướng lập trình viên, ưu tiên rõ ràng hơn trang trí.
- **Biểu tượng**: trụ database (data) kết hợp tia sparkle màu hổ phách (năng lượng / "jive").

---

## 2. Logo

Các biến thể (file nguồn SVG + bản PNG xuất kèm):

| Biến thể | File nguồn | Dùng khi |
|---|---|---|
| Logo ngang (nền sáng) | `logo-full.svg` (`png/logo-full.png`) | Header trang sáng, tài liệu |
| Logo ngang (nền tối) | `logo-full-dark.svg` (`png/logo-full-dark.png`) | Header trang tối, footer |
| Mark (chỉ biểu tượng) | `logo-mark.svg` (`png/logo-mark.png`) | Avatar, chỗ hẹp, watermark |
| Wordmark (chỉ chữ) | `wordmark.svg` | Khi đã có mark ở gần |
| App icon (nền gradient) | `icon.svg` | Icon ứng dụng, PWA, mạng xã hội |

Quy tắc:
- **Khoảng trống an toàn**: chừa quanh logo tối thiểu bằng chiều cao chữ "J".
- **Kích thước tối thiểu**: mark ≥ 24px; logo ngang ≥ 120px chiều rộng.
- **Không**: bóp méo tỉ lệ, đổi màu tuỳ tiện, thêm đổ bóng/viền, đặt logo nền sáng lên nền tối (và ngược lại).

---

## 3. Bảng màu

| Vai trò | Tên | HEX |
|---|---|---|
| Chính (gradient từ) | Indigo | `#4F46E5` |
| Chính (gradient đến) | Violet | `#7C3AED` |
| Nhấn (sparkle) | Amber | `#FBBF24` |
| Mực / nền tối | Ink | `#0B1020` |
| Chữ phụ trên nền tối | Mist | `#C7CAD9` |
| Nền sáng | White | `#FFFFFF` |

Biến thể cho nền tối (sáng hơn để tương phản): Indigo `#6366F1`, Violet `#8B5CF6`, "DB" `#A78BFA`.

- **Gradient thương hiệu**: Indigo → Violet theo đường chéo.
- **theme-color (web)**: tách theo chế độ — tối `#0B1020`, sáng `#F6F8FC`.
- **PWA manifest**: `theme_color` `#6366F1`, `background_color` `#0B1020`.

---

## 4. Typography

- **Phông chữ**: **Geist** (đồng bộ với app). Stack dự phòng: `Inter, "Segoe UI", system-ui, sans-serif`.
- **Wordmark**: weight 800, letter-spacing âm nhẹ; "Jive" màu mực/trắng, "DB" màu indigo/violet.
- **Tiêu đề landing**: Geist 700–800. **Thân bài**: Geist 400–500.

---

## 5. Icon & Favicon cho web

Xuất vào `favicons/` (từ `favicon.svg` và `icon.svg`):

| File | Kích thước | Nền tảng |
|---|---|---|
| `favicon.ico` | 16/32/48 | Trình duyệt cũ |
| `favicon.svg` | vector | Trình duyệt hiện đại (tab) |
| `favicon-16x16.png`, `favicon-32x32.png`, `favicon-48x48.png`, `favicon-96x96.png` | px | Web / msapplication tile |
| `apple-touch-icon.png` | 180 | iOS / Safari (home screen) |
| `web-app-manifest-192x192.png` | 192 | Android / PWA |
| `web-app-manifest-512x512.png` | 512 | Android / PWA / maskable |
| `site.webmanifest` | — | PWA manifest |

`icon.svg` đã chừa vùng an toàn nên dùng được cho **maskable** (Android adaptive icon).

---

## 6. App icon (icon ứng dụng đa nền tảng)

Xuất vào `app/` (từ `icon.svg`) — dùng cho bản đóng gói desktop (Wails):

| File | Kích thước | Nền tảng |
|---|---|---|
| `app/mac/appicon.png` | 1024×1024 | macOS (Wails sinh `.icns` từ đây) |
| `app/windows/icon.ico` | 16/32/48/256 | Windows |
| `app/linux/appicon.png` | 512×512 | Linux |

---

## 7. Ảnh mạng xã hội

Xuất vào `social/` (từ `og-image.svg`, tỉ lệ 1200×630) — dùng cho Open Graph / Twitter card khi chia sẻ:

- `social/og-image.jpg` — định dạng chính cho `og:image` / `twitter:image`.
- `social/og-image.png` — bản PNG (nền trong, dự phòng).
- `social/og-image.webp` — bản nhẹ.

---

## 8. Triển khai — copy file vào đâu

Sau khi chạy `./generate.sh`, copy theo bảng sau:

| Nguồn (sau generate) | Đích | Mục đích |
|---|---|---|
| `favicons/*` (gồm `site.webmanifest`) | web root (vd `/`) | favicon + PWA |
| `social/og-image.jpg` | web root → `/og-image.jpg` | OG / Twitter card |
| nội dung `head-snippet.html` | `<head>` của mỗi trang | meta / SEO / social |
| `app/mac/appicon.png` | `build/appicon.png` | icon macOS (Wails) |
| `app/windows/icon.ico` | `build/windows/icon.ico` | icon Windows |
| `app/linux/appicon.png` | `build/linux/appicon.png` | icon Linux |

Ghi chú:
- `head-snippet.html` mặc định trỏ tới web root (`/...`). Nếu đặt khác root, đổi tiền tố đường dẫn (ví dụ landing/tech trong repo dùng `../brand/...`).
- Đổi `https://jivedb.com` trong `head-snippet.html` thành tên miền thật trước khi deploy (ảnh hưởng `canonical`, `og:url`, `og:image`).

---

## 9. Cấu trúc thư mục & tạo lại tài nguyên

```
docs/brand/
├── BRAND.md              # tài liệu này
├── icon.svg              # nguồn: app icon (nền gradient)
├── favicon.svg           # nguồn: favicon (trụ to, dễ đọc 16px)
├── logo-mark.svg         # nguồn: mark nền trong suốt
├── logo-full.svg         # nguồn: logo ngang (nền sáng)
├── logo-full-dark.svg    # nguồn: logo ngang (nền tối)
├── wordmark.svg          # nguồn: chỉ chữ
├── og-image.svg          # nguồn: ảnh social
├── head-snippet.html     # thẻ <head> cho web
├── generate.sh           # script xuất raster
├── favicons/             # (xuất) ico/png 16–96 + apple-touch + manifest png + site.webmanifest
├── png/                  # (xuất) logo PNG (logo-full, logo-full-dark, logo-mark)
├── social/               # (xuất) og-image jpg/png/webp
└── app/                  # (xuất) icon ứng dụng theo nền tảng
    ├── mac/appicon.png       # 1024×1024
    ├── windows/icon.ico      # 16/32/48/256
    └── linux/appicon.png     # 512×512
```

**Tạo lại toàn bộ raster** (sau khi sửa SVG):

```bash
cd docs/brand && ./generate.sh
```

Yêu cầu công cụ: `rsvg-convert` (librsvg), `magick` (ImageMagick), `cwebp` (webp).
Cài nhanh — macOS: `brew install librsvg imagemagick webp`; Ubuntu: `sudo apt install librsvg2-bin imagemagick webp`.

---

## 10. Nguyên tắc sử dụng nhanh

- ✅ Dùng SVG khi có thể; PNG cho nơi không hỗ trợ vector.
- ✅ Giữ gradient và tỉ lệ gốc; chọn biến thể sáng/tối theo nền.
- ❌ Không tự đổi màu, bóp méo, thêm hiệu ứng, hay tái tạo logo các CSDL bên thứ ba trong nhận diện JiveDB.
