# Contract: Giao diện Trang chủ (Home)

**Chủ sở hữu**: Member 2 (bảng phân công màn hình trong đặc tả gốc).
**Mẫu tham chiếu**: khung Home của Pixel True – Food Ninja (chế độ sáng). Các phần của mẫu không thuộc phạm vi đã được thay thế theo Clarifications của `spec.md`.

## Khung ứng dụng

`MainShell` bọc Trang chủ và có thanh điều hướng dưới gồm 4 mục: **Trang chủ**, **Giỏ hàng**, **Đơn hàng**, **Tài khoản**. Thanh nền trắng, bo góc `AppRadii.large`, bóng `AppShadows.card`; mục đang chọn có nền `primarySoft`, biểu tượng và chữ `primaryEnd`; mục khác chỉ có biểu tượng `textMuted`. Các mục khác Trang chủ hiện màn chờ "Tính năng đang được phát triển". Trang chủ được giữ trong `IndexedStack` để không mất trạng thái khi chuyển mục.

## Bố cục Trang chủ từ trên xuống

1. **Tiêu đề**: "Tìm món / bạn yêu thích" (`headlineLarge`, hai dòng) và nút chuông tròn nền trắng có bóng nhẹ ở góc phải.
2. **Ô tìm kiếm** (chỉ đọc, mở màn hình tìm kiếm của `specs/003-menu-search`; nền `warningSurface`, bo góc `AppRadii.input`, biểu tượng kính lúp `foodAccentDark`, gợi ý "Bạn muốn ăn gì?") và **nút lọc** vuông cùng nền.
3. Nhãn ngoại tuyến "Đang ngoại tuyến – dữ liệu có thể chưa cập nhật" (chỉ khi `isOffline`).
4. **Banner nhà hàng**: nền `AppGradients.primary`, bo góc `AppRadii.large`; tiêu đề "Ngõ Chicken", dòng phụ "Gà rán, cơm, mỳ & đồ uống – giao hàng tận nơi", nút trắng "Mua ngay"; minh họa bằng biểu tượng.
5. **Danh mục**: tiêu đề "Danh mục"; hàng thẻ cuộn ngang, thẻ đầu "Tất cả", mỗi thẻ có biểu tượng và tên (tối đa 2 dòng); thẻ đang chọn có nền `primarySoft` và viền `primaryEnd`.
6. **Phổ biến**: tiêu đề "Phổ biến"; danh sách dọc tối đa 5 thẻ món; chỉ hiện khi đang chọn "Tất cả"; ẩn khi rỗng.
7. **Thực đơn**: "Tất cả" thì có tiêu đề nhóm theo danh mục; một danh mục thì không có tiêu đề nhóm.
8. Chỉ báo tải thêm ở cuối danh sách khi `isLoadingMore`.

## Thẻ món (widget dùng chung `FoodCard`)

Theo hàng "Popular Menu" của mẫu: ảnh vuông bo góc bên trái → cột giữa gồm tên (tối đa 2 dòng), dòng đánh giá ("4,6 (23)" hoặc "Chưa có đánh giá"), nhãn "Hết hàng" khi `isAvailable == false` → giá hoặc khoảng giá ở bên phải, căn phải, được xuống dòng nhưng không được cắt mất số. Toàn bộ thẻ là một vùng chạm ≥ 48 dp có nhãn ngữ nghĩa gồm tên, giá, đánh giá và tình trạng.

## Trạng thái

| Trạng thái | Hiển thị | Hành động |
|---|---|---|
| Đang tải | Khung xương (skeleton) dưới phần tìm kiếm | — |
| Trống | "Thực đơn chưa sẵn sàng" | — |
| Danh mục trống | "Danh mục này chưa có món" | Nút "Xem tất cả món" |
| Lỗi | Thông điệp lỗi dễ hiểu | Nút "Thử lại" |
| Thông báo danh mục bị gỡ | SnackBar "Danh mục này không còn được bán" | Tự quay về "Tất cả" |
| Chạm chuông | SnackBar "Tính năng đang được phát triển" | Ở lại Trang chủ |
| Chạm ô tìm kiếm / nút lọc | Mở màn hình tìm kiếm của `specs/003-menu-search` (nút lọc mở sẵn bảng lọc) | Quay lại về Trang chủ |

## Điều hướng

- Chạm thẻ món → màn hình chi tiết món với `menuItemId`.
- Quay lại → giữ nguyên thẻ danh mục đang chọn và vị trí cuộn.
- "Mua ngay" → cuộn tới hàng thẻ danh mục.

## Thiết kế

Chỉ dùng token trong `lib/core/theme/`; padding ngang 24 (16 khi màn hình < 360 dp); không tràn bố cục ở 320 dp và cỡ chữ 1,3×.
