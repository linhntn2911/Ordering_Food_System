# Quickstart: Tìm kiếm và lọc thực đơn

**Tính năng**: `003-menu-search` | **Spec**: [spec.md](spec.md)

## Chuẩn bị

Giống [quickstart của tính năng 002](../002-browse-menu/quickstart.md):

1. Chạy Firestore Emulator (project `demo-ordering`) và nạp dữ liệu mẫu Ngô Chicken (6 danh mục, 28 món; "Cá viên chiên" và "Sinh tố bơ" đang hết hàng):

   ```powershell
   cd tools/seed_menu
   $env:FIRESTORE_EMULATOR_HOST = '127.0.0.1:8080'; $env:GCLOUD_PROJECT = 'demo-ordering'; node seed.js
   ```

2. Chạy ứng dụng:

   ```powershell
   flutter run -d chrome --web-port 5555 --dart-define=USE_FIRESTORE_EMULATOR=true
   ```

## Kịch bản kiểm chứng

| # | Story | Bước | Kỳ vọng |
|---|---|---|---|
| Q1 | US1 | Ở Trang chủ chạm ô tìm kiếm | Màn hình tìm kiếm mở, ô nhập có con trỏ, không có thanh tab dưới, hiện đủ 28 món theo thứ tự thực đơn |
| Q2 | US1 | Gõ `tra sua` | Sau khoảng 300 ms chỉ còn các món "Trà sữa …" |
| Q3 | US1 | Gõ `ga` | Món có tên bắt đầu bằng "Gà" đứng trước, sau đó các món khác có "gà" (ví dụ "Cơm gà chiên mắm tỏi", "Bánh gà") |
| Q4 | US1 | Gõ `pizza` | "Không tìm thấy món phù hợp" và nút "Xóa từ khóa" |
| Q5 | US1 | Gõ `mỳ ý + gà` | Hiện combo "Mỳ ý + Gà rán" |
| Q6 | US1 | Chạm một kết quả rồi quay lại | Từ khóa, bộ lọc và vị trí cuộn giữ nguyên |
| Q7 | US1 | Chọn "Gà rán" ở Trang chủ, rồi chạm ô tìm kiếm | Bộ lọc danh mục là "Tất cả", không có nhãn bộ lọc |
| Q8 | US2 | Ở Trang chủ chạm nút lọc | Màn hình tìm kiếm mở với bảng lọc mở sẵn |
| Q9 | US2 | Chọn "Đồ ăn vặt", bật "Chỉ món còn hàng", bấm "Áp dụng" | Chỉ món đồ ăn vặt còn hàng, không có "Cá viên chiên"; hiện 2 nhãn bộ lọc và "Xóa bộ lọc" |
| Q10 | US2 | Mở bảng lọc, đổi sang "Đồ uống", vuốt đóng | Kết quả và nhãn không đổi |
| Q11 | US2 | Mở bảng lọc, bấm "Đặt lại" rồi vuốt đóng | Bộ lọc không đổi; mở lại bảng thấy lựa chọn đang áp dụng |
| Q12 | US2 | Bỏ nhãn "Chỉ món còn hàng" | "Cá viên chiên" xuất hiện lại kèm nhãn "Hết hàng" |
| Q13 | US2 | Gõ `sinh to`, lọc "Đồ uống", bật "Chỉ món còn hàng" | "Không tìm thấy món phù hợp" (Sinh tố bơ hết hàng) |
| Q14 | US3 | Gõ `tra`, chọn "Giá thấp đến cao", "Áp dụng" | Món có giá thấp nhất đứng đầu; có nhãn sắp xếp |
| Q15 | US3 | Chọn "Đánh giá cao", "Áp dụng" | Món có đánh giá đứng trước theo điểm giảm dần; món chưa có đánh giá ở cuối |
| Q16 | US3 | Bấm "Xóa bộ lọc" | Mọi nhãn biến mất, thứ tự về "Phù hợp nhất", từ khóa vẫn giữ |
| Q17 | Biên | Trong lúc đang lọc "Đồ uống", dùng Emulator UI đặt `isPublished = false` cho danh mục `do-uong` (và đồng bộ `isCategoryPublished` trên món) | SnackBar "Danh mục này không còn được bán", bộ lọc về "Tất cả" |
| Q18 | Biên | Dùng Emulator UI đổi giá hoặc `isAvailable` một món đang hiện | Kết quả cập nhật trong vài giây, không cần làm mới |
| Q19 | Biên | Quay về Trang chủ rồi mở tìm kiếm lại | Từ khóa trống, không có bộ lọc |
| Q20 | Thiết kế | Thu cửa sổ còn 320 px, phóng chữ 1,3× | Màn hình và bảng lọc không tràn |

## Kiểm tra tự động

```powershell
dart format lib test
flutter analyze
flutter test
cd tests/firestore_rules; npm test   # gồm R11
```
