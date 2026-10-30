# Contract: Giao diện màn hình Tìm kiếm và lọc

**Chủ sở hữu**: Member 2 (màn hình "Search and Filter" trong bảng phân công gốc).
**Mẫu tham chiếu**: khung Search và Filter của Pixel True – Food Ninja (chế độ sáng), thay bằng dữ liệu một nhà hàng.

## Điểm vào (FR-002)

| Từ | Thao tác | Kết quả |
|---|---|---|
| Trang chủ, ô tìm kiếm (`home-search`) | Chạm | Mở `MenuSearchView(openFilters: false)`, ô nhập tự focus, bàn phím hiện |
| Trang chủ, nút lọc (`home-filter`) | Chạm | Mở `MenuSearchView(openFilters: true)`, bảng lọc mở sẵn, không focus ô nhập |

Màn hình được đẩy lên navigator gốc, phủ toàn màn hình (không có thanh tab dưới). Nút quay lại đưa về Trang chủ, trạng thái tìm kiếm bị bỏ (FR-015). Chuông thông báo vẫn hiện SnackBar "Tính năng đang được phát triển".

## Bố cục từ trên xuống

1. **Thanh trên**: nút quay lại tròn (`search-back`), ô nhập (`search-input`) cùng kiểu ô tìm kiếm Trang chủ (nền `warningSurface`, bo `AppRadii.input`, kính lúp `foodAccentDark`, gợi ý "Bạn muốn ăn gì?"; phím "Tìm" trên bàn phím áp dụng từ khóa ngay), nút "x" xóa từ khóa (`search-clear`, chỉ khi có chữ), nút lọc (`search-filter`) có chấm `primaryEnd` khi bộ lọc khác mặc định.
2. **Nhãn bộ lọc** (chỉ khi `!filters.isDefault`): hàng cuộn ngang gồm nhãn danh mục (`search-chip-category`), "Chỉ món còn hàng" (`search-chip-available`), nhãn cách sắp xếp khi khác "Phù hợp nhất" (`search-chip-sort`). Mỗi nhãn có nút bỏ, có hiệu lực ngay. Cuối hàng có nút chữ "Xóa bộ lọc" (`search-clear-filters`).
3. Nhãn ngoại tuyến (dùng lại `OfflineBanner`) khi `isOffline`.
4. **Kết quả**: dòng "N món" (`labelLarge`, `textMuted`), sau đó danh sách dọc các `FoodCard` (FR-011). Không có tiêu đề nhóm danh mục.

## Bảng lọc (`showModalBottomSheet`, FR-016)

- Tay nắm, tiêu đề "Bộ lọc" (`titleLarge`).
- **Danh mục**: `Wrap` các chip chọn một (`filter-category-all`, `filter-category-<id>`), chip đầu "Tất cả".
- **Tình trạng**: công tắc "Chỉ món còn hàng" (`filter-available`).
- **Sắp xếp**: 4 chip chọn một (`filter-sort-<relevance|priceAsc|priceDesc|ratingDesc>`) với nhãn ở data-model.
- Hàng nút cuối: "Đặt lại" (`filter-reset`, nút viền) và "Áp dụng" (`filter-apply`, nút gradient `AppGradients.primary`).
- Nội dung cuộn được; cao tối đa 85% màn hình; dùng `SafeArea`.
- Đóng bằng vuốt, chạm ngoài hoặc nút quay lại: không đổi bộ lọc.

## Trạng thái

| Trạng thái | Hiển thị | Hành động |
|---|---|---|
| Đang tải | `AppLoadingView` dạng skeleton dưới thanh trên | — |
| Có kết quả | Dòng "N món" và danh sách | Chạm thẻ → chi tiết |
| Không có kết quả | `AppEmptyView` "Không tìm thấy món phù hợp", dòng phụ "Thử từ khóa khác hoặc bỏ bộ lọc" | Nút "Xóa từ khóa" (khi có từ khóa) và "Xóa bộ lọc" (khi có bộ lọc) |
| Lỗi | `AppErrorView` | "Thử lại"; từ khóa và bộ lọc giữ nguyên |
| Ngoại tuyến | `OfflineBanner` trên kết quả từ cache | — |
| Danh mục đang lọc bị gỡ | SnackBar "Danh mục này không còn được bán" (cùng câu với Trang chủ) | Bộ lọc danh mục tự về "Tất cả" |

## Điều hướng (FR-013)

- Chạm thẻ → `MenuItemDetailView(menuItemId)` bằng `Navigator.push`.
- Quay lại → giữ nguyên từ khóa trong ô nhập, bộ lọc, cách sắp xếp và vị trí cuộn.

## Truy cập và thiết kế

- Ô nhập có nhãn ngữ nghĩa "Tìm kiếm món"; nút lọc "Bộ lọc"; các nút bỏ nhãn "Bỏ bộ lọc <tên>".
- Vùng chạm ≥ 48 dp. Chỉ dùng token trong `lib/core/theme/`; padding ngang 24 (16 khi < 360 dp).
- Không tràn bố cục ở 320 dp và cỡ chữ 1,3×, cả màn hình lẫn bảng lọc (SC-006).
