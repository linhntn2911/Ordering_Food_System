# Contract: Giao diện Chi tiết món

**Chủ sở hữu**: Member 2 (màn hình "Food Details", mức High).
**Mẫu tham chiếu**: khung Product Detail của Pixel True – Food Ninja (chế độ sáng). Bỏ nút yêu thích (FR-010 gốc chưa thuộc phạm vi) và nhãn "Popular" quảng cáo.

## Điểm vào

`MenuItemDetailView(menuItemId: id)` được `Navigator.push` từ Trang chủ (`HomeView._openItem`) và kết quả tìm kiếm (`MenuSearchView._openItem`). Giữ nguyên tên lớp và tham số để hai nơi gọi không phải sửa.

## Bố cục từ trên xuống

1. **Ảnh món**: rộng toàn màn hình, tỉ lệ 4:3 (cao tối đa 45% màn hình); ảnh lỗi hoặc trống dùng `FoodImagePlaceholder`. Nút quay lại tròn trắng có bóng nổi ở góc trên trái (`detail-back`, nhãn "Quay lại").
2. **Khối nội dung** nền trắng, bo góc trên `AppRadii.dialog`, đè lên ảnh 24 dp, padding ngang 24 (16 khi < 360 dp):
   - Nhãn "Hết hàng" (`SoldOutLabel`) khi hết hàng.
   - Tên món (`headlineMedium`, không cắt).
   - Dòng đánh giá: `RatingStars` + "4,9 (210 đánh giá)" hoặc "Chưa có đánh giá" (`detail-rating`).
   - Giá cơ bản hoặc khoảng giá (`AppTextStyles.price`).
   - Mô tả (`bodyLarge`), tối đa 6 dòng kèm "Xem thêm"/"Thu gọn" (`detail-description-toggle`); ẩn khi trống.
   - Nhãn ngoại tuyến (`OfflineBanner`) khi `isOffline`.
3. **Tùy chọn** (ẩn khi món không có size và topping):
   - "Chọn size" (`titleMedium`): danh sách chọn một (`detail-size-<id>`), mỗi dòng gồm tên và "+5.000 ₫" (bỏ phần cộng thêm khi bằng 0).
   - "Topping" (`titleMedium`): danh sách chọn nhiều (`detail-topping-<id>`), mỗi dòng gồm tên và "+x ₫".
   - Khi hết hàng: các dòng hiển thị mờ, không chọn được, có nhãn ngữ nghĩa "không khả dụng".
4. **Ghi chú**: ô nhập nhiều dòng (`detail-note`), gợi ý "Ví dụ: ít đá, không hành", bộ đếm "x/200"; vô hiệu khi hết hàng.
5. **Đánh giá**: tiêu đề "Đánh giá" (`titleLarge`) kèm số lượt; mỗi thẻ đánh giá (`review-<id>`) gồm "Khách hàng" hoặc "Khách hàng ẩn danh", `RatingStars` cỡ nhỏ, ngày `dd/MM/yyyy`, nhãn "Đã chỉnh sửa", nội dung tối đa 4 dòng kèm "Xem thêm", hàng ảnh thu nhỏ 64 dp (`review-<id>-image-<i>`). Cuối danh sách là nút "Xem thêm đánh giá" (`detail-more-reviews`) khi `hasMore`, hoặc chỉ báo tải khi `isLoadingMore`.
6. **Thanh dưới cố định** (nền trắng, bóng `AppShadows.card`, `SafeArea`):
   - Bộ chọn số lượng (`detail-quantity-minus`, `detail-quantity`, `detail-quantity-plus`); nút trừ vô hiệu ở 1, nút cộng vô hiệu ở 99.
   - Nút gradient `AppGradients.primary` "Thêm vào giỏ" kèm giá tạm tính (`detail-add-to-cart`), cao ≥ 48 dp.
   - Hết hàng: ẩn bộ chọn số lượng, nút xám ghi "Hết hàng" và vô hiệu.

## Trạng thái

| Trạng thái | Hiển thị | Hành động |
|---|---|---|
| Đang tải | Khung xương: ô ảnh và 3 dòng chữ | — |
| Món không còn được bán | `AppEmptyView` "Món này không còn được bán" | "Quay lại" |
| Lỗi | `AppErrorView` | "Thử lại" |
| Ngoại tuyến | `OfflineBanner` dưới dòng giá | — |
| Đánh giá đang tải | 2 khung xương thẻ đánh giá | — |
| Không có đánh giá | "Chưa có đánh giá cho món này" | — |
| Lỗi đánh giá | Thông điệp ngắn trong phần đánh giá | "Thử lại" (`detail-reviews-retry`) |
| Tùy chọn bị xóa | SnackBar "Một số tùy chọn đã thay đổi, vui lòng chọn lại" | — |
| Xem thêm khi ngoại tuyến | SnackBar "Cần kết nối mạng để tải thêm đánh giá" | — |
| Thêm vào giỏ | SnackBar "Tính năng đang được phát triển" | Lựa chọn giữ nguyên |

## Xem ảnh đánh giá

Chạm ảnh thu nhỏ mở hộp thoại toàn màn hình nền `AppColors.scrim` gần đen: `PageView` các ảnh của đánh giá đó, bắt đầu từ ảnh đã chạm, `InteractiveViewer` để phóng to, nút đóng (`review-image-close`) và chỉ số "1/3". Ảnh lỗi hiện `FoodImagePlaceholder`.

## Truy cập và thiết kế

- `RatingStars` có nhãn ngữ nghĩa "Đánh giá 4,9 trên 5".
- Vùng chạm ≥ 48 dp; lựa chọn đang chọn phân biệt bằng biểu tượng (radio/checkbox) chứ không chỉ màu.
- Chỉ dùng token trong `lib/core/theme/`; không tràn ở 320 dp và cỡ chữ 1,3× (SC-006), kể cả thanh dưới.
