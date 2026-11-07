# Quickstart: Chi tiết món

**Tính năng**: `004-food-details` | **Spec**: [spec.md](spec.md)

## Chuẩn bị

1. Chạy Firestore Emulator (project `demo-ordering`) với rules mới, rồi nạp thực đơn. Seed không tạo đánh giá; đánh giá phải được gửi từ luồng Customer sau khi đơn hoàn thành:

   ```powershell
   cd tools/seed_menu
   node build_seed.cjs menu_seed.json
   $env:FIRESTORE_EMULATOR_HOST = '127.0.0.1:8080'; $env:GCLOUD_PROJECT = 'demo-ordering'; node seed.js
   ```

2. Chạy ứng dụng:

   ```powershell
   flutter run -d chrome --web-port 5555 --dart-define=USE_FIRESTORE_EMULATOR=true
   ```

## Kịch bản kiểm chứng

| # | Story | Bước | Kỳ vọng |
|---|---|---|---|
| Q1 | US1 | Mở "Trà sữa trân châu đường đen" từ Trang chủ | Ảnh thay thế, tên, mô tả, khoảng giá, "Chưa có đánh giá", không có nhãn hết hàng |
| Q2 | US1 | Mở một món chưa có đánh giá | "Chưa có đánh giá" ở dòng tóm tắt và ở phần đánh giá |
| Q3 | US1 | Mở "Cá viên chiên" | Nhãn "Hết hàng"; tùy chọn, ghi chú và số lượng bị vô hiệu; nút "Hết hàng" xám |
| Q4 | US1 | Đang xem một món, dùng Emulator UI đổi giá rồi đặt `isPublished = false` | Giá cập nhật; sau đó màn hình "Món này không còn được bán" |
| Q5 | US1 | Mở món từ kết quả tìm kiếm rồi quay lại | Về đúng kết quả tìm kiếm với từ khóa và vị trí cuộn cũ |
| Q6 | US2 | Mở "Trà đào", chọn size L | Giá tạm tính 25.000 ₫ |
| Q7 | US2 | Mở một món trà sữa, chọn size L + "Trân châu đen" + "Kem cheese" | Giá tạm tính = giá L + 5.000 + 8.000 |
| Q8 | US2 | Mở món không có size và topping | Không có phần tùy chọn |
| Q9 | US2 | Chọn tùy chọn, quay lại, mở lại cùng món | Về mặc định: size rẻ nhất, không topping, số lượng 1, ghi chú trống |
| Q10 | US2 | Đang chọn một topping, dùng Emulator UI xóa topping đó khỏi món | SnackBar báo tùy chọn đã thay đổi; giá tính lại |
| Q11 | US3 | Hoàn thành đơn, Customer gửi đánh giá, rồi mở chi tiết món đã mua | Đánh giá Firestore thật xuất hiện mới nhất trước với số sao, nội dung và ngày |
| Q12 | US3 | Khi món có hơn 5 đánh giá thật, chạm "Xem thêm đánh giá" | Thêm tối đa 10 đánh giá; hết thì nút biến mất |
| Q13 | US3 | Với đánh giá thật có ảnh, chạm ảnh thu nhỏ, vuốt, đóng | Xem lớn, vuốt qua ảnh khác, đóng về đúng vị trí |
| Q14 | US3 | Tắt mạng (DevTools → Offline) sau khi đã xem đánh giá, mở lại món | Nhãn ngoại tuyến; đánh giá đã lưu vẫn hiện; "Xem thêm đánh giá" báo cần kết nối mạng |
| Q15 | US4 | "Trà đào" size L, số lượng 3, ghi chú "ít đá" | Nút ghi "Thêm vào giỏ · 75.000 ₫" |
| Q16 | US4 | Chạm "Thêm vào giỏ" | SnackBar "Tính năng đang được phát triển"; lựa chọn giữ nguyên |
| Q17 | US4 | Bấm trừ ở số lượng 1; nhập ghi chú 250 ký tự | Không xuống dưới 1; ghi chú dừng ở 200 ký tự, bộ đếm "200/200" |
| Q18 | Bảo mật | Không đăng nhập, đọc `reviews/{id}` gốc bằng Emulator Requests hoặc rules test | Bị từ chối (R15) |
| Q19 | Thiết kế | Thu cửa sổ còn 320 px, phóng chữ 1,3× | Không tràn, kể cả thanh dưới |

## Kiểm tra tự động

```powershell
dart format lib test
flutter analyze
flutter test
cd tests/firestore_rules; npm test   # R1–R17
```
