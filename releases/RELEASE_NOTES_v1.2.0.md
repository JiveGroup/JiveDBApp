# Release Notes — v1.2.0

Phiên bản: **v1.2.0** · Ngày phát hành: **2026-06-09**

Bản này tập trung **mở rộng & hoàn thiện làm việc với PostgreSQL**: hiển thị đầy đủ mọi loại đối tượng schema, xem định nghĩa nhanh (Quick View), menu thao tác (Create/Alter…), chạy SQL **thông minh** theo con trỏ và chạy nhiều câu, làm mới cây nhất quán, cùng nhiều sửa lỗi quan trọng.

---

## 1. Tổng quan

**Điểm nổi bật:**

- Cây đối tượng PostgreSQL hiển thị **đầy đủ**: Materialized Views, Foreign Tables, Domains, Collations, Aggregates, Operators (+ Classes/Families), Full-Text Search (Parsers/Templates/Dictionaries/Configurations); tách riêng **Functions / Procedures / Trigger Functions**.
- **Quick View**: bấm để xem định nghĩa (DDL) của routine, view, sequence, trigger, domain, aggregate, operator, collation, FTS…
- **Context menu** cho hầu hết đối tượng: **Create / Alter `<type>`**, tạo bảng bằng **modal**, tạo cột/index/khoá/trigger mở thẳng **Edit Structure**.
- **SQL Editor thông minh**: để con trỏ trong câu lệnh rồi chạy → tự chọn đúng câu; hỗ trợ chọn **nhiều câu** để chạy lần lượt.
- **Làm mới cây nhất quán**: thêm/xoá đối tượng luôn nạp lại đúng nhóm chứa nó.

---

## 2. Cây đối tượng PostgreSQL — đầy đủ loại

- Bổ sung nhóm: **Materialized Views**, **Foreign Tables** (mở dữ liệu như bảng), **Domains**, **Collations**, **Aggregates**, **Operators** (nhóm lớn → Operators / Operator Classes / Operator Families), **Full-Text Search** (nhóm lớn → Configurations / Dictionaries / Parsers / Templates).
- Tách rõ **Functions / Procedures / Trigger Functions** (trước gộp chung "Routines"); Object Types gồm enum/composite/range, **Domains** tách riêng.
- Phân loại routine chính xác theo `pg_proc.prokind` (function / procedure / aggregate / window) và nhận diện **trigger function** (trả về `trigger`).
- Cây **chỉ hiển thị nhóm phù hợp**: View không có Foreign Keys; chỉ Materialized View mới có Indexes; Trigger của View chỉ hiện khi là INSTEAD OF.
- Mỗi nhóm chỉ xuất hiện khi schema thực sự có đối tượng tương ứng.

---

## 3. Quick View — xem định nghĩa (DDL)

- Bấm vào đối tượng (hoặc menu chuột phải) để mở popover hiển thị **định nghĩa**:
  - **View / Materialized View**, **Function / Procedure / Trigger Function**, **Sequence**, **Trigger**, **Domain**, **Aggregate**, **Operator**, **Collation**, **FTS** (Configuration/Dictionary/Parser/Template).
- Có nút **Copy** + tô màu cú pháp; routine còn có **Copy as call** (`SELECT …()` / `CALL …()`).

---

## 4. Context menu — tạo & sửa đối tượng

- **Create `<type>` / Alter `<type>`** cho: Functions, Procedures, Trigger Functions, Sequences, Object Types, Domains, Aggregates, Operators (+Classes/Families), Foreign Tables, Collations, FTS — sinh **template SQL** vào SQL Editor của kết nối đang dùng.
- **Tables / Views / Materialized Views**: thêm **Create table / Create view / Create materialized view**.
- **Create table** mở **modal "Create new table"** (chỉ đóng bằng nút Close) — soạn cột/index/khoá/trigger trực quan.
- Nhóm **Columns / Indexes / Foreign Keys / Triggers** của bảng: ngoài Expand còn có **Create `<…>`** → mở tab **Edit Structure** và nhảy đúng phần tương ứng.
- **Trigger** (từng cái): **Cập nhật** (mở định nghĩa hiện tại để sửa) và **Xoá**.
- **View**: Copy name · View data · View definition · New query · Export data · Rename · Drop.
- **Connection**: thêm **Reload**; **Database (PostgreSQL)**: thêm **Refresh** (nạp lại schema + đối tượng).

---

## 5. SQL Editor — chạy thông minh & nhiều câu

- **Smart run**: chỉ cần để con trỏ trong một câu lệnh rồi bấm Run / ⌘R → tự **chọn đúng câu chứa con trỏ** và chạy (áp dụng cho **cả nút Run lẫn ⌘R**). Chạy tất cả: **⌘A** rồi Run.
- **Chạy nhiều câu**: bôi đen nhiều câu → chạy **lần lượt** (autocommit từng câu), **dừng khi gặp lỗi** và **giữ kết quả các câu đã chạy**; nhiều SELECT → hiện **nhiều tab kết quả**.
- Bộ tách câu hiểu **dollar-quote `$$…$$`** của PostgreSQL → chạy được `CREATE FUNCTION/PROCEDURE` (có `;` trong thân) như một câu.

---

## 6. Icon & màu sắc

- Mỗi loại đối tượng một **hệ màu riêng**; **nhóm (đậm) khác item bên trong (nhạt)** để dễ phân biệt.
- Icon riêng cho từng loại/leaf (cột PK/FK/unique hiện **icon khoá** theo màu).
- Đổi icon **schema PostgreSQL** sang `Layers`.

---

## 7. Làm mới cây nhất quán

- **Quy tắc**: thêm/xoá/sửa đối tượng → luôn nạp lại **đúng nhóm chứa** đối tượng đó.
- DDL qua SQL Editor (mọi loại đối tượng) → tự refresh cây + ERD.
- Sửa cấu trúc bảng (thêm/bớt **cột/index/khoá/trigger**) qua **Edit Structure** hoặc SQL Editor → nạp lại đúng 4 nhóm con của bảng.
- `CREATE VIEW` / tạo các đối tượng khác giờ **tự hiện** ngay sau khi chạy.

---

## 8. App Logs — hoàn thiện

- Bật/tắt qua **Settings → Developer → "Show Log button"** (mặc định ẩn).
- **Nhấn một dòng log để copy** (kèm thông báo); bảng rộng hơn, đặt cân đối góc dưới-trái.
- Ghi đầy đủ hơn: SQL/DDL đã chạy, **mở/đổi trang bảng**, **lưu sửa/thêm/xoá dòng**, lệnh & thao tác ghi **Redis**, **payload + lỗi AI**, lỗi Go/React. Gộp bản ghi trùng sát nhau.

---

## 9. Sửa lỗi

- Sửa lỗi load schema PostgreSQL khi `routine_type` là NULL (`converting NULL to string`).
- Hiển thị **đúng lỗi PostgreSQL** trong SQL Editor (trước bị che thành "Lỗi không xác định").
- `CREATE VIEW`/đối tượng mới không tự hiện trong sidebar → đã tự làm mới.
- DDL nặng (CREATE MATERIALIZED VIEW, CREATE INDEX…) được cấp **thời gian chờ rộng hơn** (không bị cắt ở 30s).
- Bỏ chức năng **Compact | Comfortable** ở phần sửa cấu trúc (đồng nhất giao diện).

---

## 10. Tài liệu

- Thêm `docs/POSTGRES_SCHEMA_OBJECTS.md`: tổng quan từng loại đối tượng schema PostgreSQL (lý thuyết, lý do, cách tạo/sửa/dùng, ví dụ).
- Thêm `docs/postgres_schema_objects_demo.sql`: script demo tạo **đầy đủ** mọi loại đối tượng trong schema riêng `demo_objects` (an toàn, chạy lại được).

---

## 11. Ghi chú nâng cấp

- Thay đổi phía backend (Go) → cần **build lại ứng dụng** để có hiệu lực.
- Các đối tượng nâng cao (Operators/Collations/FTS/Foreign Tables…) chỉ áp dụng **PostgreSQL**.
- Quick View của một số đối tượng là **bản tóm tắt** dựng từ catalog, không phải DDL gốc tuyệt đối.
