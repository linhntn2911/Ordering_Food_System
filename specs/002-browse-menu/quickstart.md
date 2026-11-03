# Quickstart: Duyệt thực đơn

## Chuẩn bị

```powershell
flutter pub get
cd tests/firestore_rules; npm install; cd ../..
tests/firestore_rules/node_modules/.bin/firebase emulators:start --only firestore --project demo-ordering
```

Ở một cửa sổ khác, nạp dữ liệu mẫu vào Emulator:

```powershell
cd tools/seed_menu
npm install
$env:FIRESTORE_EMULATOR_HOST = "127.0.0.1:8080"; $env:GCLOUD_PROJECT = "demo-ordering"; node seed.js
```

Dữ liệu mẫu là thực đơn Ngô Chicken: 6 danh mục (Gà rán, Cơm, Mỳ, Đồ ăn vặt, Combo, Đồ uống), 28 món, tối đa 6 món mỗi danh mục. Đồ uống có size M/L nên hiện khoảng giá; 7 món có điểm đánh giá trình diễn để mục "Phổ biến" có dữ liệu; "Cá viên chiên" và "Sinh tố bơ" được đánh dấu hết hàng. Các trường hợp danh mục trống, danh mục chưa đăng bán, món chưa đăng bán được tạo bằng cách sửa dữ liệu trên Emulator UI (http://localhost:4000) như bảng bên dưới; chúng cũng đã có trong unit test và kiểm thử rules.

Chạy app trỏ vào Emulator (Chrome dùng project demo, Android dùng cấu hình trong `firebase_options.dart`):

```powershell
flutter run -d chrome --dart-define=USE_FIRESTORE_EMULATOR=true
```

## Kiểm tra theo kịch bản

**Điều kiện đo**: thiết bị Android tầm trung (RAM ≥ 4 GB), Wi-Fi hoặc 4G, khởi động lạnh (đã tắt hẳn app).

| Bước | Kỳ vọng | Đối chiếu |
|---|---|---|
| Đo thời gian từ khi chạm biểu tượng app tới khi thẻ món đầu tiên hiện ra | ≤ 3 giây (trung bình 3 lần) | SC-001 |
| Từ Trang chủ chọn danh mục cuối cùng trên thanh danh mục | Tối đa 2 lần chạm, chưa tính cuộn ngang | SC-002 |
| Mở app, chưa đăng nhập | Thấy tiêu đề + chuông, ô tìm kiếm + nút lọc, banner Ngô Chicken, thẻ danh mục, "Phổ biến" (tối đa 5 món), thực đơn gom nhóm, thanh điều hướng dưới | US1-1, US1-7, US1-9, FR-015 |
| Chạm "Mua ngay" trên banner | Cuộn tới hàng thẻ danh mục | US1-10, FR-017 |
| Chạm ô tìm kiếm, nút lọc, chuông, hoặc mục Giỏ hàng/Đơn hàng/Tài khoản | Báo "Tính năng đang được phát triển"; quay lại Trang chủ vẫn giữ trạng thái | US1-11, FR-018, FR-019 |
| Trên Emulator UI đặt `isPublished = false` cho một danh mục và `isCategoryPublished = false` cho các món của nó | Danh mục và các món đó biến mất | US1-3, FR-011 |
| Món hết hàng | Có nhãn "Hết hàng", vẫn mở được | FR-004 |
| Món nhiều size (ví dụ Trà đào) | Hiện "20.000 – 25.000 ₫" | FR-005 |
| Đặt `isPublished = false` cho mọi món của một danh mục, rồi chọn danh mục đó | Trạng thái danh mục trống, có nút quay về | US2-2 |
| Trên Emulator UI đổi giá một món | Giá đổi trong ≤ 5 giây | US3-1, SC-004 |
| Gỡ đăng bán danh mục đang chọn (cập nhật cả `isCategoryPublished` của món) | Quay về "Tất cả" kèm thông báo | US2-4 |
| Chạm một món, rồi quay lại | Giữ thẻ danh mục đang chọn và vị trí cuộn | US4-2 |
| Tắt Emulator, mở lại app | Thực đơn cũ kèm nhãn ngoại tuyến | FR-014, SC-008 |
| Gỡ cài đặt, mở app khi không có mạng | Trạng thái lỗi kèm "Thử lại" | FR-014 |

## Kiểm tra tự động

```powershell
dart format lib test
flutter analyze
flutter test
cd tests/firestore_rules; npm install; npm test
```

`npm test` dùng `firebase emulators:exec` để chạy các ca R1–R9 trong `contracts/firestore_menu_access.md`.
