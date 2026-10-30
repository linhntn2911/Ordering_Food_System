# Nghiên cứu (Research): Duyệt thực đơn

**Tính năng**: `002-browse-menu` | **Ngày**: 2026-10-20 | **Spec**: [spec.md](spec.md)

Mỗi mục ghi theo dạng: Quyết định, Lý do, Phương án đã cân nhắc.

## R1. Chặn món thuộc danh mục chưa đăng bán ở tầng rules (FR-003, FR-011)

- **Quyết định**: Thêm hai trường phi chuẩn hóa vào `menu_items`: `isCategoryPublished` (bool) và `categorySortOrder` (int). Rules chỉ cho Guest/Customer đọc món khi `isPublished == true && isCategoryPublished == true`. Mọi truy vấn duyệt phải có cả hai bộ lọc đó để Firestore chứng minh được truy vấn hợp lệ.
- **Lý do**: Rules của Firestore không thể `get()` danh mục cho từng tài liệu trong một truy vấn `list`, nên không thể kiểm tra trạng thái danh mục lúc đọc danh sách. Trường phi chuẩn hóa giúp rules tự chặn, đúng yêu cầu FR-011 "không truy xuất được, không chỉ ẩn trên giao diện".
- **Ràng buộc kéo theo**: Khi Admin đổi `isPublished` hoặc `sortOrder` của danh mục, mọi món thuộc danh mục đó phải được cập nhật trong cùng một batch (thuộc tính năng quản lý danh mục, User Story 7 của đặc tả gốc). Ghi chú ràng buộc này vào `docs/database_schema.md`.
- **Phương án đã cân nhắc**:
  - Lọc ở client theo danh sách danh mục đã đăng bán: bị loại vì món vẫn đọc được qua truy vấn trực tiếp, vi phạm FR-011.
  - Cloud Function tự đồng bộ trường phi chuẩn hóa: hợp lệ nhưng thêm hạ tầng backend chưa có; có thể chuyển sang sau mà không đổi schema.

## R2. Hiển thị món hết hàng (FR-004)

- **Quyết định**: Bỏ điều kiện `isAvailable == true` khỏi rules đọc công khai và khỏi truy vấn danh sách chính. `isAvailable` chỉ dùng để hiển thị nhãn "Hết hàng" và để lọc mục "Phổ biến".
- **Lý do**: Khớp với Clarification Q1 và User Story 1 kịch bản 3 của đặc tả gốc. Sửa luôn câu tương ứng trong `docs/database_schema.md`.
- **Phương án đã cân nhắc**: Giữ rules cũ và đọc món hết hàng qua đường riêng: bị loại vì phức tạp và không có lợi ích bảo mật (món hết hàng không phải dữ liệu nhạy cảm).

## R3. Danh sách "Tất cả" gom theo danh mục và tải dần (FR-003, FR-009)

- **Quyết định**: Một truy vấn duy nhất trên `menu_items`, sắp xếp theo `categorySortOrder`, `categoryId`, `sortOrder`, `name`. Client gom các món liên tiếp cùng `categoryId` thành nhóm có tiêu đề. Tải dần bằng cách tăng `limit` theo bước 20 (20 → 40 → 60 …) trên cùng một luồng realtime.
- **Lý do**: Thứ tự trả về đã đúng thứ tự nhóm, nên món tải thêm luôn nối vào đúng nhóm và thứ tự nhóm không đổi (FR-009). Tăng `limit` giữ được cập nhật realtime (FR-008) mà không phải quản lý con trỏ trang; phần trùng lặp được phục vụ từ cache cục bộ.
- **Phương án đã cân nhắc**:
  - Mỗi danh mục một luồng riêng, mở khi cuộn tới: nhiều listener, khó giữ vị trí cuộn và khó kiểm thử.
  - Phân trang bằng `startAfterDocument`: các trang cũ không nhận cập nhật realtime.

## R4. Mục "Phổ biến" (FR-013)

- **Quyết định**: Truy vấn `isPublished == true`, `isCategoryPublished == true`, `isAvailable == true`, sắp xếp `ratingAverage` giảm dần, `reviewCount` giảm dần, `name` tăng dần, `limit(5)`; client bỏ món có `reviewCount == 0`.
- **Lý do**: Món đã có đánh giá luôn có `ratingAverage >= 1`, nên luôn đứng trước món chưa có đánh giá (`ratingAverage == 0`). Vì vậy lọc ở client sau `limit(5)` không làm mất món hợp lệ nào. Tránh được bộ lọc bất đẳng thức trên `reviewCount`.
- **Phương án đã cân nhắc**: Bộ lọc `reviewCount > 0` ở truy vấn: buộc `orderBy` theo `reviewCount` trước, sai thứ tự yêu cầu.

## R5. Ngoại tuyến (FR-014, SC-008)

- **Quyết định**: Dùng cache bền vững có sẵn của Cloud Firestore trên Android/iOS (bật mặc định). Repository nghe `snapshots(includeMetadataChanges: true)` và trả kèm cờ `isFromCache`. ViewModel hiện nhãn ngoại tuyến khi `isFromCache == true`. Nếu dữ liệu từ cache rỗng và chưa từng có snapshot từ máy chủ, hiện trạng thái lỗi kèm nút thử lại thay vì trạng thái trống. Có một khoảng chờ 2 giây: chỉ coi là ngoại tuyến khi `isFromCache == true` kéo dài liên tục quá 2 giây, vì snapshot đầu tiên lúc khởi động có thể đến từ cache dù đang có mạng.
- **Lý do**: Đáp ứng "hiện dữ liệu đã tải từ lần mở app trước" mà không thêm cơ chế lưu trữ thứ hai. Cờ `isFromCache` tự chuyển về `false` khi đồng bộ lại với máy chủ, nên nhãn tự tắt (SC-008: trong 5 giây).
- **Phương án đã cân nhắc**:
  - Lưu thực đơn vào SharedPreferences: trái với FR-043 của đặc tả gốc (không lưu dữ liệu nghiệp vụ ở đó) và trùng với cache Firestore.
  - Thêm `connectivity_plus`: không cần thiết; trạng thái cache đã phản ánh việc có đồng bộ được với máy chủ hay không. Không thêm phụ thuộc mới.

## R6. Khoảng giá theo size (FR-005)

- **Quyết định**: `sizes` là danh sách `{ id, name, priceDelta }`, `priceDelta` là số nguyên VND ≥ 0 cộng vào `basePrice`. Khoảng giá hiển thị = `basePrice + min(priceDelta)` đến `basePrice + max(priceDelta)`. Không có size hoặc mọi `priceDelta` bằng nhau thì hiện một giá. Topping (`{ id, name, priceDelta }`) không tính vào.
- **Lý do**: Cùng một cấu trúc cho size và topping, khớp với cách giỏ hàng sẽ tính giá dòng sau này. Phép tính thuần, đặt ở domain và có unit test.
- **Phương án đã cân nhắc**: Size lưu giá tuyệt đối: khó dùng chung với topping và dễ lệch với `basePrice`.

## R7. Định dạng tiền VND

- **Quyết định**: Viết một hàm định dạng nhỏ trong `lib/core/utils/vnd_format.dart` (nhóm hàng nghìn bằng dấu chấm, hậu tố " ₫"), có unit test.
- **Lý do**: Chỉ cần một định dạng cố định; tránh thêm `intl` cho một hàm. Nếu sau này cần đa ngôn ngữ (FR-042 của đặc tả gốc) thì thay bằng `intl`.

## R8. Sắp xếp theo tên khi trùng thứ tự hiển thị

- **Quyết định**: Dùng `orderBy('name')` của Firestore (so sánh theo mã ký tự).
- **Lý do**: Trùng `sortOrder` là hiếm và spec chỉ yêu cầu thứ tự ổn định. Tên tiếng Việt có dấu có thể không theo thứ tự từ điển; chấp nhận được ở bản này.

## R9. Điều hướng vào chi tiết món (FR-010)

- **Quyết định**: Dùng `Navigator.push` từ Home sang một route chi tiết món. Màn hình chi tiết đầy đủ thuộc feature khác (FR-009 của đặc tả gốc); feature này tạo một màn hình chi tiết tối thiểu (tên, ảnh, giá, nhãn "Hết hàng") để có đích điều hướng. Home giữ trạng thái vì không bị gỡ khỏi cây widget, và ViewModel của Home không `autoDispose` khi đang trong stack.
- **Lý do**: Chưa có thư viện router; thêm `go_router` chỉ vì một route là quá sớm. Quyết định router chung để lại cho feature điều hướng/app shell.

## R10. Kiểm thử rules (FR-011, SC-003)

- **Quyết định**: Thêm thư mục `tests/firestore_rules/` dùng Node với `@firebase/rules-unit-testing` và trình chạy `node --test` có sẵn, chạy trên Firebase Emulator.
- **Lý do**: Constitution yêu cầu kiểm chứng phân quyền bằng rules hoặc emulator. Đây là phụ thuộc chỉ dùng khi phát triển, không vào app. Đồng thời hoàn thành phần việc T019 còn mở của feature 001 cho phạm vi menu.
- **Phương án đã cân nhắc**: Chỉ kiểm thử thủ công trên Emulator UI: không lặp lại được, không đủ bằng chứng.

## R11. Nền tảng giao diện chưa có

- **Phát hiện**: `lib/core/theme/` chưa tồn tại, chưa có font Poppins trong `assets/fonts/`, `main.dart` vẫn là ứng dụng đếm số mẫu.
- **Quyết định**: Feature này dựng phần nền tối thiểu cần cho Trang chủ: các tệp token trong `lib/core/theme/`, `AppTheme.light`, khai báo Poppins (tệp font tải từ Google Fonts, giấy phép OFL), `lib/app/app.dart` với `themeMode: ThemeMode.light`, và các widget dùng chung cho trạng thái đang tải/trống/lỗi, thẻ món, nhãn "Hết hàng", nhãn ngoại tuyến.
- **Lý do**: Constitution VI và `docs/design_system.md` cấm token cục bộ trong màn hình, nên phải có token chung trước khi dựng Home.

## R12. Dữ liệu mẫu

- **Quyết định**: Thêm `tools/seed_menu/` (Node, `firebase-admin`) mặc định ghi vào Emulator, đọc `menu_seed.json` gồm danh mục đã/chưa đăng bán, món còn/hết hàng, món có/không có size, món có/không có đánh giá.
- **Lý do**: Phục vụ kiểm thử độc lập từng user story và demo khi màn hình quản trị menu chưa có. Script không chứa thông tin xác thực; chạy với dự án thật thì dùng credentials cục bộ không commit.
