# Release Notes — v1.1.0

Phiên bản: **v1.1.0** · Ngày phát hành: **2026-06-09**

Bản phát hành này bổ sung bảng **App Logs** trong ứng dụng, **gia cố mã hoá** thông tin nhạy cảm, nâng cấp trải nghiệm **Sidebar / Data Grid / Redis**, thêm **bộ dữ liệu mẫu nhiều quy mô** và hoàn thiện **quy trình build Linux**.

---

## 1. Tổng quan

- 1 tính năng mới lớn: **App Logs** (nhật ký trong ứng dụng).
- Nâng cấp **bảo mật** dữ liệu lưu cục bộ (mật khẩu kết nối, API key AI).
- Nhiều cải tiến UX cho Sidebar, Data Grid, Redis và thanh Tab.
- Bổ sung công cụ cho nhà phát triển: bộ dữ liệu mẫu, build Linux, tài liệu kế hoạch bảo mật.

**Điểm nổi bật:**

- Hỗ trợ CSDL **tới 500 bảng** vẫn vẽ được **sơ đồ ERD** không lỗi.
- **Cải thiện hệ thống icon** liên quan tới bảng — trực quan, dễ nhận dạng và phân biệt hơn.
- **Hiển thị số dòng (rows)** đang có trong mỗi bảng.
- **Kéo-thả** để thay đổi vị trí các cột trong lưới dữ liệu.
- **Đóng nhiều tab**: đóng các tab bên phải tab đang chọn, đóng toàn bộ tab.
- **Copy dữ liệu dạng câu lệnh SQL**: Copy Row (INSERT), Copy Row (UPDATE).
- **Xem nhanh thông tin bảng** (Table Detail).
- **Form View** — xem một dòng/ô dạng biểu mẫu.

---

## 2. Tính năng mới — App Logs

Bảng nhật ký ngay trong ứng dụng, dành cho việc theo dõi thao tác chạm cơ sở dữ liệu và lỗi.

- **Nút nổi** ở góc dưới-trái (đối xứng với nút Trợ giúp); bấm để mở/đóng bảng logs.
- **Tô màu theo loại** log (SQL, AI, lỗi, cảnh báo, thông tin) kèm nhãn nguồn và thời gian.
- **Nhấn một dòng log để copy** phần nội dung vào clipboard, kèm thông báo thành công.
- **Bật/tắt** trong **Settings → Developer → "Show Log button"** (mặc định tắt); ngoài ra có công tắc tổng ở mức mã nguồn.

Nội dung được ghi (khi bật):

- **SQL chạy từ trình soạn**: câu lệnh + thời gian + số dòng + lỗi.
- **DDL / Import / Data Transfer / lưu Structure**: các câu lệnh + lỗi.
- **Mở/đổi trang bảng dữ liệu**: truy vấn xem dữ liệu + lỗi.
- **Lưu sửa/thêm/xoá dòng**: thao tác cập nhật + lỗi.
- **Redis**: lệnh chạy trực tiếp + các thao tác ghi (SET/DEL/RENAME/EXPIRE/HSET…/LREM).
- **AI**: tóm tắt payload gửi đi (model, số message, trích nội dung) + lỗi.
- **Lỗi**: lỗi backend hiển thị cho người dùng + lỗi giao diện không bắt được.

Ghi chú: một số lời gọi nền (đếm số dòng, tra khoá ngoại, đọc metadata) được **cố ý bỏ qua** để tránh tràn nhật ký. Các bản ghi trùng sát nhau được gộp tự động.

---

## 3. Bảo mật — Gia cố mã hoá dữ liệu nhạy cảm

Áp dụng cho **mật khẩu kết nối CSDL** và **API key AI** lưu cục bộ.

- Vẫn dùng **AES-256-GCM**, nhưng khoá mã hoá **không còn là khoá thô trên đĩa**. Khoá được **dẫn xuất (HKDF-SHA256)** từ 3 yếu tố:
  1. Khoá ngẫu nhiên lưu cục bộ (mỗi máy một khác).
  2. Một "hạt tiêu" nhúng trong ứng dụng → chỉ có file khoá mà thiếu ứng dụng thì không giải mã được.
  3. Ràng buộc theo **máy + tài khoản hệ điều hành** → sao chép file sang máy/tài khoản khác sẽ không giải mã được.
- **Tương thích ngược**: dữ liệu mã hoá theo định dạng cũ vẫn đọc được và tự nâng cấp sang định dạng mới khi lưu lại — không mất dữ liệu hiện có.
- Kèm tài liệu **kế hoạch bảo mật** mô tả các mức nâng cấp cao hơn (OS keychain, mật khẩu chủ).

Giới hạn: đây là lớp **chống nhòm ngó + chống mang file đi nơi khác**, không thay thế việc mã hoá toàn ổ và không chống được mã độc chạy dưới đúng tài khoản người dùng.

---

## 4. Sidebar & Metadata

- **i18n** cho nhãn nhóm (Tables, Views, Routines, Sequences, Object Types…).
- **Cải thiện hệ thống icon liên quan tới bảng** — trực quan, dễ nhận dạng và phân biệt hơn: mỗi nhóm (Columns / Indexes / Foreign Keys / Triggers) và từng phần tử bên trong có icon riêng; cột là **khoá chính / khoá ngoại / unique** hiển thị **icon khoá** theo màu.
- **Hiển thị số dòng (rows)** cạnh tên mỗi bảng: ước lượng nhanh ban đầu, sau đó **đếm chính xác ở nền** (giới hạn song song) và cập nhật dần.
- Menu bảng: **Xem thông tin bảng (Table Detail)** và **View Structure (DDL)** mở dạng popover cạnh con trỏ, có nút **Copy**.
- Redis: thêm nút **[+]** để mở nhanh một database theo chỉ số.

---

## 5. Data Grid

- **Menu chuột phải trên ô** hiển thị đúng vị trí con trỏ.
- **Copy dữ liệu dạng câu lệnh SQL**: thêm **Copy Row (INSERT)** và **Copy Row (UPDATE)**.
- **Form View**: xem một **dòng / ô** dạng biểu mẫu (popover cạnh con trỏ) — đầy đủ các cột và giá trị tương ứng.
- **Kéo-thả tiêu đề cột** để thay đổi vị trí các cột; thứ tự được ghi nhớ.
- Thông báo **copy thành công** cho các thao tác sao chép.
- Lưới nhận **dialect / schema** để dựng câu lệnh đúng cú pháp từng loại CSDL.

---

## 6. Redis Workspace

- **Group view**: khi xoá một key, tự chọn key liền kề hợp lý; xoá cục bộ mượt (không giật danh sách).
- **Menu ngữ cảnh** cho key/nhóm: xem nhanh (JSON highlight), tải lại, copy (JSON), xoá.
- **Chọn nhiều key** để copy/xoá hàng loạt.
- **Cảnh báo** khi tạo key lệch kiểu so với nhóm cùng mẫu tên; thông báo khi lưu giá trị.
- Trình truy vấn Redis có **thanh công cụ** (Chạy / Yêu thích / AI).

---

## 7. Tab & Giao diện chung

- **Menu thanh Tab**: Đóng tab khác / Đóng các tab bên phải / Đóng tất cả / Mở lại tab vừa đóng.
- **Cờ ngôn ngữ** chuyển từ emoji sang **file SVG** → hiển thị nhất quán trên Windows/macOS/Linux.
- **Phím tắt** hiển thị theo nền tảng (⌘ trên macOS, Ctrl trên Windows/Linux).
- **Lịch sử SQL**: ghi nối tiếp, không ghi đè.
- **Sửa lỗi i18n**: chuẩn hoá chuỗi đa ngôn ngữ (vi/en), loại bỏ khoá không dùng.
