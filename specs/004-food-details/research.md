# Nghiên cứu (Research): Chi tiết món

**Tính năng**: `004-food-details` | **Ngày**: 2026-10-20 | **Spec**: [spec.md](spec.md)

Mỗi mục ghi theo dạng: Quyết định, Lý do, Phương án đã cân nhắc.

## R1. Đọc đánh giá công khai mà không lộ dữ liệu cá nhân (FR-007, FR-008, SC-003)

- **Quyết định**:
  - Thêm subcollection công khai `menu_items/{menuItemId}/reviews/{reviewId}`. Mỗi tài liệu chỉ gồm trường hiển thị: `rating`, `comment`, `imageUrls`, `isAnonymous`, `isEdited`, `createdAt`, `updatedAt`. `reviewId` trùng id của tài liệu `reviews/{reviewId}` gốc.
  - Rules cho phép đọc subcollection khi món cha đọc được công khai (`get()` món cha: `isPublished && isCategoryPublished`) hoặc người đọc là Admin. Không ai được ghi từ client.
  - Thu hẹp rules của collection gốc `reviews`: chỉ chủ đánh giá (`customerId == auth.uid`) hoặc Admin được đọc.
  - Hệ thống tin cậy (tính năng viết đánh giá của Member 4) ghi tài liệu gốc và bản công khai trong cùng một batch, xóa cả hai khi xóa đánh giá.
- **Lý do**:
  - Rules Firestore không ẩn được từng trường. Nếu để `reviews` đọc công khai như hiện tại thì `customerId` và `orderId` của mọi khách lộ cho bất kỳ ai, trái FR-008 và nguyên tắc III của constitution.
  - Đường dẫn con chứa sẵn `menuItemId`, nên rules dùng `get()` món cha được cả cho truy vấn `list`. Nhờ vậy đánh giá của món chưa đăng bán không đọc được (Giả định của spec).
  - Sắp xếp `createdAt` giảm dần trong một subcollection chỉ cần chỉ mục đơn trường tự động, không thêm chỉ mục tổng hợp.
- **Phương án đã cân nhắc**:
  - Giữ `reviews` đọc công khai và chỉ ẩn trên giao diện: bị loại vì dữ liệu vẫn truy xuất được.
  - Cloud Function trả danh sách đánh giá đã lọc trường: thêm hạ tầng backend chưa có.
  - Collection gốc riêng `public_reviews` có trường `menuItemId`: rules không `get()` món cha được khi `list` theo trường, nên không chặn được đánh giá của món chưa đăng bán.

## R2. Luồng dữ liệu món có cờ ngoại tuyến (FR-009, FR-010)

- **Quyết định**: Đổi `MenuRepository.watchItem(menuItemId)` sang trả `Stream<MenuItemFeed>`: lớp `MenuItemFeed(item: MenuItem?, isFromCache: bool)`, nghe `snapshots(includeMetadataChanges: true)`. `item == null` khi món không tồn tại, không còn đọc được (`permission-denied`) hoặc sai định dạng.
- **Lý do**: Màn hình cần nhãn ngoại tuyến giống Trang chủ. Phiên bản hiện tại không có metadata. Chỉ màn hình chi tiết dùng `watchItem`, nên đổi chữ ký không ảnh hưởng chỗ khác.
- **Phương án đã cân nhắc**: Dùng `MenuFeed<MenuItem>` với 0 hoặc 1 phần tử: tiết kiệm một lớp nhưng ý nghĩa `hasMore` và danh sách gây hiểu nhầm.

## R3. Topping trên thực thể món (FR-003)

- **Quyết định**: Thêm `toppings` (`List<MenuOption>`) vào `MenuItem`. `MenuItemModel` đã đọc trường này nhưng chưa chuyển sang thực thể.
- **Lý do**: Dữ liệu và model đã có, chỉ thiếu ở thực thể domain.

## R4. Lựa chọn tạm và giá tạm tính (FR-003 – FR-005, FR-011, FR-012, FR-016, SC-002)

- **Quyết định**: Lớp bất biến `ItemSelection` ở domain (`lib/features/menu/domain/entities/item_selection.dart`):
  - Trường: `sizeId`, `toppingIds` (tập không trùng), `quantity` (1–99), `note` (≤ 200 ký tự).
  - `ItemSelection.initial(item)`: size có `priceDelta` nhỏ nhất (cùng giá thì size đứng trước), không topping, số lượng 1, ghi chú trống.
  - `unitPrice(item)` = `basePrice` + delta của size + tổng delta topping. `total(item)` = `unitPrice × quantity`.
  - `reconcile(item)`: bỏ size/topping không còn trên món và trả cờ `removedOptions` để báo người dùng.
  - Ghi chú chỉ gồm khoảng trắng được coi là trống.
- **Lý do**: Quy tắc giá là logic nghiệp vụ, đặt ở domain thì kiểm thử được mọi tổ hợp (SC-002) và tính năng Giỏ hàng dùng lại được.

## R5. ViewModel và vòng đời (FR-016, FR-014)

- **Quyết định**: `MenuItemDetailViewModel` là `Notifier` với `NotifierProvider.autoDispose.family<…, String>` theo `menuItemId`. ViewModel nghe luồng món và luồng đánh giá, giữ `ItemSelection`, và phát `MenuItemDetailState` bất biến. Provider bị hủy khi màn hình đóng, nên mỗi lần mở đều về mặc định.
- **Lý do**: Đúng FR-016 mà không cần dọn tay. Cùng khuôn mẫu với `HomeMenuViewModel` và `MenuSearchViewModel`.

## R6. Danh sách đánh giá và tải thêm (FR-006, User Story 3)

- **Quyết định**:
  - `ReviewRepository.watchMenuItemReviews(menuItemId, {required int limit})` trả `Stream<MenuFeed<Review>>` từ `menu_items/{id}/reviews`, sắp xếp `createdAt` giảm dần, nghe `includeMetadataChanges`.
  - Trang đầu `limit = 5`. "Xem thêm đánh giá" tăng `limit` thêm 10 trên cùng luồng (giống cách Trang chủ tải dần).
  - Tài liệu sai định dạng (sao ngoài 1–5, thiếu `createdAt`) bị bỏ qua.
  - Thuộc feature mới `lib/features/reviews/` (domain + data), để Member 4 thêm phần ghi sau này.
- **Lý do**: Luồng realtime cho phép đánh giá mới hiện ra mà không cần mở lại (trường hợp biên của spec), nhất quán với các màn hình khác. Phần trùng lặp được phục vụ từ cache.
- **Phương án đã cân nhắc**: `get()` từng trang bằng con trỏ: không có realtime, phải tự gộp trang.

## R7. Ngoại tuyến của phần đánh giá (Clarification Q3)

- **Quyết định**: Phần đánh giá dùng `isFromCache` của luồng đánh giá:
  - Có dữ liệu từ cache: hiện danh sách dưới nhãn ngoại tuyến chung của màn hình.
  - "Xem thêm đánh giá" khi đang ngoại tuyến (luồng món hoặc đánh giá đang `isFromCache` quá khoảng chờ `menuOfflineGraceProvider`): không tăng `limit`, phát thông báo `reviewsNeedConnection`.
  - Cache rỗng và chưa từng có dữ liệu máy chủ: sau khoảng chờ thì phần đánh giá chuyển sang lỗi kèm "Thử lại".
- **Lý do**: Cùng cơ chế khoảng chờ 2 giây đã dùng ở Trang chủ, tránh báo ngoại tuyến nhầm lúc khởi động.

## R8. Hiển thị (FR-002, FR-007, FR-015)

- **Quyết định**:
  - Bố cục theo khung Product Detail của Food Ninja: ảnh lớn đầu trang có nút quay lại nổi, phần nội dung nền trắng bo góc trên đè lên ảnh, thanh dưới cố định gồm bộ chọn số lượng và nút gradient "Thêm vào giỏ · giá tạm tính" (chi tiết ở `contracts/food_details_ui.md`).
  - Widget dùng chung mới `RatingStars` (`lib/core/widgets/rating_stars.dart`): 5 sao, hỗ trợ nửa sao cho điểm trung bình, có nhãn ngữ nghĩa "Đánh giá x trên 5".
  - Ngày đánh giá định dạng `dd/MM/yyyy` theo giờ thiết bị bằng hàm thuần `formatReviewDate` (`lib/core/utils/date_format.dart`), không thêm gói `intl`.
  - Xem ảnh đánh giá: hộp thoại toàn màn hình với `PageView` vuốt qua các ảnh của cùng đánh giá và `InteractiveViewer` để phóng to; đóng quay lại đúng vị trí.
  - Tên người đánh giá: "Khách hàng ẩn danh" khi `isAnonymous`, ngược lại "Khách hàng" (Clarification Q1).
  - "Thêm vào giỏ" khi món còn hàng: SnackBar `ComingSoonView.message`.
- **Lý do**: Dùng lại token, `FoodImagePlaceholder`, `SoldOutLabel`, `formatVnd`; không thêm phụ thuộc.

## R9. Dữ liệu mẫu

- **Quyết định**: Mở rộng `tools/seed_menu/build_seed.cjs` và `seed.js`:
  - Thêm mô tả ngắn cho món.
  - Thêm topping cho các món trà sữa (Trân châu đen +5.000 ₫, Thạch dừa +5.000 ₫, Kem cheese +8.000 ₫) và mỳ cay (Thêm trứng +5.000 ₫, Thêm xúc xích +7.000 ₫).
  - Thêm đánh giá công khai mẫu vào `menu_items/{id}/reviews`: 12 đánh giá cho "Gà sốt cay ngọt Hàn Quốc" (để thử "Xem thêm"), vài đánh giá cho 2 món khác, có đánh giá ẩn danh, đánh giá đã sửa và đánh giá có ảnh.
  - Điểm và số lượt của các món có đánh giá mẫu được tính lại từ đánh giá mẫu để tóm tắt khớp danh sách.
- **Lý do**: Spec ghi rõ dữ liệu mẫu chưa có mô tả, topping và đánh giá.

## R10. Kiểm thử

- **Quyết định**:
  - Unit test: `ItemSelection` (mọi tổ hợp size × topping × số lượng của dữ liệu mẫu cho SC-002), `formatReviewDate`, `ReviewModel.fromMap`, `MenuItemModel` có toppings, ViewModel với fake repository.
  - Widget test: màn hình chi tiết (đủ trạng thái, hết hàng, tùy chọn, số lượng, ghi chú, thêm vào giỏ, đánh giá, ngoại tuyến), `RatingStars`, 320 dp và 1,3×.
  - Rules test: R12–R16 (xem `contracts/firestore_review_access.md`).
- **Lý do**: Constitution V.

## R11. Phụ thuộc

- **Quyết định**: Không thêm phụ thuộc runtime hay dev mới.
