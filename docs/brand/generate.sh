#!/usr/bin/env bash
# ============================================================================
# JiveDB — sinh bộ branding (favicon / icon / web manifest / ảnh social)
# từ các file SVG nguồn. Chạy lại mỗi khi đổi logo/màu thương hiệu.
#
# CẦN CHUẨN BỊ
#   1) Công cụ (cài sẵn trong PATH):
#        - rsvg-convert        (librsvg)      : SVG -> PNG
#        - magick               (ImageMagick) : gộp .ico, xuất .jpg
#        - cwebp                (webp)        : xuất .webp
#      macOS:  brew install librsvg imagemagick webp
#      Ubuntu: sudo apt install librsvg2-bin imagemagick webp
#   2) File SVG nguồn (đặt cùng thư mục với script này):
#        - favicon.svg          : icon vuông nhỏ (dùng cho favicon)
#        - icon.svg             : icon ứng dụng (apple-touch, PWA manifest)
#        - logo-full.svg        : logo ngang (nền sáng)
#        - logo-full-dark.svg   : logo ngang (nền tối)
#        - logo-mark.svg        : chỉ phần biểu tượng
#        - og-image.svg         : ảnh chia sẻ mạng xã hội (tỉ lệ 1200×630)
#
# SẼ NHẬN ĐƯỢC
#   favicons/  favicon.ico, favicon.svg, favicon-16/32/48/96.png,
#              apple-touch-icon.png, web-app-manifest-192/512.png,
#              icon.svg, site.webmanifest
#   png/       logo-full.png, logo-full-dark.png, logo-mark.png (nền trong suốt)
#   social/    og-image.png, og-image.jpg, og-image.webp (1200×630)
#   app/       mac/appicon.png (1024), windows/icon.ico (16–256),
#              linux/appicon.png (512)   ← icon ứng dụng cho từng nền tảng
#
# DÙNG
#   ./generate.sh
#
# DEPLOY
#   - Web: copy favicons/* (gồm site.webmanifest) và social/og-image.jpg lên web
#          root, rồi dán docs/brand/head-snippet.html vào <head>.
#   - App (Wails): copy app/mac/appicon.png  -> build/appicon.png
#                       app/windows/icon.ico -> build/windows/icon.ico
#                       app/linux/appicon.png -> build/linux/appicon.png
# ============================================================================
set -euo pipefail
cd "$(dirname "$0")"

mkdir -p favicons social png app/mac app/windows app/linux

png() { rsvg-convert -w "$2" -h "$2" "$1" -o "$3"; }

echo "→ Favicons (từ favicon.svg)"
png favicon.svg 16 favicons/favicon-16x16.png
png favicon.svg 32 favicons/favicon-32x32.png
png favicon.svg 48 favicons/favicon-48x48.png
png favicon.svg 96 favicons/favicon-96x96.png
magick favicons/favicon-16x16.png favicons/favicon-32x32.png favicons/favicon-48x48.png favicons/favicon.ico
cp favicon.svg favicons/favicon.svg

echo "→ Icons nền tảng (từ icon.svg)"
png icon.svg 180 favicons/apple-touch-icon.png
png icon.svg 192 favicons/web-app-manifest-192x192.png
png icon.svg 512 favicons/web-app-manifest-512x512.png
cp icon.svg favicons/icon.svg

echo "→ Web app manifest"
cat > favicons/site.webmanifest <<'JSON'
{
  "name": "JiveDB",
  "short_name": "JiveDB",
  "description": "One client for all your databases — PostgreSQL, MySQL, SQLite & Redis.",
  "icons": [
    { "src": "/web-app-manifest-192x192.png", "sizes": "192x192", "type": "image/png", "purpose": "any maskable" },
    { "src": "/web-app-manifest-512x512.png", "sizes": "512x512", "type": "image/png", "purpose": "any maskable" }
  ],
  "theme_color": "#6366F1",
  "background_color": "#0B1020",
  "display": "standalone",
  "start_url": "/"
}
JSON

echo "→ Logo PNG (nền trong suốt; chỉ định -h, rộng tự suy theo tỉ lệ)"
rsvg-convert -h 200 logo-full.svg -o png/logo-full.png
rsvg-convert -h 200 logo-full-dark.svg -o png/logo-full-dark.png
rsvg-convert -w 512 -h 512 logo-mark.svg -o png/logo-mark.png

echo "→ App icons (từ icon.svg)"
png icon.svg 1024 app/mac/appicon.png      # macOS (Wails build/appicon.png)
png icon.svg 512 app/linux/appicon.png     # Linux
png icon.svg 256 app/windows/icon-256.png  # Windows .ico (đa kích thước)
png icon.svg 48 app/windows/icon-48.png
png icon.svg 32 app/windows/icon-32.png
png icon.svg 16 app/windows/icon-16.png
magick app/windows/icon-16.png app/windows/icon-32.png app/windows/icon-48.png app/windows/icon-256.png app/windows/icon.ico
rm -f app/windows/icon-16.png app/windows/icon-32.png app/windows/icon-48.png app/windows/icon-256.png

echo "→ Social (OG image 1200×630)"
rsvg-convert -w 1200 -h 630 og-image.svg -o social/og-image.png
magick social/og-image.png -quality 90 social/og-image.jpg
cwebp -quiet -q 90 social/og-image.png -o social/og-image.webp

echo "✓ Xong. Xem thư mục favicons/, png/, social/, app/."
echo "  Web : copy favicons/* (gồm site.webmanifest) và social/og-image.jpg lên web root,"
echo "        rồi dán docs/brand/head-snippet.html vào <head>."
echo "  App : copy app/mac/appicon.png -> build/appicon.png."
echo "        copy app/linux/appicon.png -> build/linux/appicon.png."
echo "        copy app/windows/icon.ico -> build/windows/icon.ico."
