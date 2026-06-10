# Release Notes — v1.3.0

Phiên bản: **v1.3.0** · Ngày phát hành: **2026-06-10**

Bản này tập trung **nâng cấp toàn diện Lưới dữ liệu (DataGrid)** lên ngang một bảng tính chuyên nghiệp, bổ sung **tab Info** xem metadata theo nhóm đối tượng, đưa **Sơ đồ quan hệ (ERD)** về chế độ **chỉ-xem an toàn** kèm panel DDL và đồng bộ theme, cùng nhiều cải thiện backend và sửa lỗi.

---

## 1. Tổng quan

**Điểm nổi bật:**

- **DataGrid mạnh ngang bảng tính**: chọn vùng ô, sao chép đa định dạng, lọc theo toán tử (+ IN/NOT IN), sắp xếp nhiều cột, đóng băng cột, dán nhiều ô, định dạng có điều kiện, tìm & thay thế, thống kê cột, nhập CSV, xuất Excel…
- **Tab Info** mới: xem nhanh metadata **Tables / Views / Indexes / Procedures** của schema (PostgreSQL) hoặc database (MySQL/SQLite).
- **ERD chỉ-xem an toàn**: bỏ mọi thao tác đổi CSDL; double-click mở rộng bảng; panel **DDL** của bảng được chọn; **đồng bộ màu sáng/tối** theo app.
- **Backend**: xuất file nhị phân (.xlsx), truy vấn metadata theo dialect, lọc IN/NOT IN, danh sách rỗng trả `[]` an toàn.

---

## 2. DataGrid — chọn vùng & sao chép

- **Chọn vùng ô** (kéo chuột, Shift+mũi tên) + **thanh tổng hợp**: đếm / tổng / trung bình / nhỏ nhất / lớn nhất.
- Khi kéo chọn ô **không còn bị bôi đen văn bản** mặc định.
- **Sao chép vùng chọn**: TSV, CSV, JSON, INSERT, UPDATE.
- **Sao chép theo cột** (khi chọn nhiều cột): tên cột, giá trị, JSON, INSERT, UPDATE.
- **Sao chép theo dòng/nhiều dòng**: JSON / INSERT / UPDATE (tự đổi sang dạng "N dòng" khi chọn nhiều dòng).
- **Màu vùng chọn ô** nổi bật hơn màu chọn dòng/cột để dễ phân biệt.

---

## 3. DataGrid — lọc, sắp xếp, cột

- **Lọc theo toán tử** cho từng cột: `= ≠ > < ≥ ≤`, **LIKE (chứa)**, **IS NULL / IS NOT NULL**, và **IN / NOT IN** (nhập danh sách phân tách dấu phẩy).
- **Tooltip bảng chú thích** mọi ký hiệu lọc khi rê chuột vào nút Filter.
- **Sắp xếp nhiều cột**: kích hoạt qua **icon order-by ở góc phải mỗi cột** (Shift+click để cộng dồn); click vào tên cột giờ **chọn cột**.
- **Đóng băng (ghim) cột** bên trái khi cuộn ngang.
- **Tự vừa độ rộng cột** (double-click mép cột hoặc menu) — đo theo nội dung.
- **Menu ẩn/hiện cột** có **ô tìm cột** + **Chọn/Bỏ chọn tất cả** (theo danh sách đang lọc).
- **Chọn cột** (click header) + tô sáng cả cột.

---

## 4. DataGrid — chỉnh sửa & nhập/xuất

- **Dán nhiều ô** từ clipboard (TSV), **điền xuống**, **đặt NULL** hàng loạt theo vùng chọn.
- **Nút Hoàn tác trên từng ô đã sửa** — trả ô về giá trị gốc.
- **Độ cao dòng** (Gọn / Vừa / Thoáng).
- **Trình sửa ô lớn** (TEXT/JSON) với định dạng JSON.
- **Tìm & Thay thế** trong lưới (next/prev, phân biệt hoa thường, tô sáng khớp).
- **Định dạng có điều kiện**: quy tắc tô màu theo cột/toán tử/giá trị (lưu theo bảng).
- **Nhập CSV** vào lưới (khớp cột theo tên → dòng staged, xem lại rồi lưu).
- **Xuất Excel (.xlsx)**, CSV, JSON — toàn bộ hoặc chỉ vùng chọn.
- **Tự động làm mới** theo chu kỳ (Tắt / 5s / 10s / 30s / 60s), tạm dừng khi đang có thay đổi chưa lưu, có thông báo mỗi lần làm mới.
- **Thống kê cột** + **phân bố giá trị phổ biến** ngay trong lưới.
- **Điều hướng theo khoá ngoại**: "Đi tới dòng tham chiếu".

---

## 5. DataGrid — thao tác dòng & menu

- Khi **chọn nhiều dòng** rồi chuột phải lên một dòng đã chọn: **Copy N dòng**, **Xoá N dòng**, **Bỏ chọn N dòng**.
- Sau khi xoá dòng → tự **bỏ chọn**; **đổi trang** cũng bỏ chọn dòng/cột.
- **Mọi mục context menu đều có icon** (Cell / Selection / Column / Row), nhất quán toàn app.
- Cột số dòng (`#`) dùng **nền đồng màu header**; bỏ "Form view" khỏi menu cột `#`.
- **Tự discard** thay đổi chưa lưu khi **Filter** hoặc **Find** (vì chỉ số dòng đổi sau khi truy vấn lại); nút **Filter** reset các bộ lọc cột.

---

## 6. Tab Info — metadata theo nhóm

- Action **Info** trong menu **schema** (PostgreSQL) hoặc **database** (MySQL/SQLite) → mở tab mới.
- Sub-tab: **Tables / Views / Indexes / Procedures**, hiển thị dạng bảng metadata theo dialect (MySQL có Engine/Auto-increment/Data length/Partitioned…; PostgreSQL có size/rows/comment…; SQLite tối giản).
- Tên tab dạng `Info: <DB> > <Schema>` (PostgreSQL) hoặc `Info: <DB>` (MySQL/SQLite).

---

## 7. ERD — chỉ-xem, mở rộng & DDL

- **Chỉ-xem an toàn**: bỏ xoá bảng, bỏ double-click sửa cấu trúc, bỏ tạo bảng — ERD không còn thao tác làm đổi CSDL.
- **Double-click** một bảng → mở rộng vừa đủ để hiển thị đầy đủ tên/cột; double-click lần nữa → thu gọn.
- **Toggle Info** (kế nút SVG) → panel góc phải-trên hiển thị **DDL** của bảng được click, có nút **Sao chép** (cùng cách hiển thị với "View Structure (DDL)").
- **Chỉ hiển thị Tables** (bỏ view) trong sơ đồ.
- **Đồng bộ màu sáng/tối** theo theme app (dùng token giao diện chung, không còn nền tối lệch).

---

## 8. Backend & hạ tầng

- `App.SaveFileBytes` (base64) để **xuất file nhị phân** an toàn (.xlsx).
- `App.SchemaInfo` + truy vấn catalog theo từng dialect cho tab Info.
- `sqlutil.BuildWhere`: hỗ trợ **IN / NOT IN**.
- `ListTables` trả **`[]` thay vì `nil`** → tránh lỗi khi schema/database rỗng; thêm null-guard ở tầng nạp cây.
- Thêm thư viện **`xlsx` (SheetJS)**; sinh lại binding Wails.

---

## 9. Sửa lỗi

- Sửa lỗi `null is not an object` khi mở Tables/Views của SQLite rỗng (danh sách `null`).
- Kéo chọn nhiều ô không còn bôi đen văn bản gây rối mắt.

---

## 10. Tài liệu

- Thêm `INTRO.md` — giới thiệu JiveDB và các tính năng nổi bật.
- Thêm `docs/DATAGRID_UPGRADE_PLAN.md` — kế hoạch nâng cấp DataGrid (tham chiếu nhiều công cụ phổ biến).

---

## 11. Ghi chú nâng cấp

- Thay đổi phía backend (Go) → cần **build lại / khởi động lại** ứng dụng để có hiệu lực.
- Một số cột trong tab Info phụ thuộc khả năng của từng hệ CSDL (vd Engine/Auto-increment chỉ có ở MySQL).
- Xuất `.xlsx` cần thư viện mới `xlsx` (đã thêm vào dependencies).
