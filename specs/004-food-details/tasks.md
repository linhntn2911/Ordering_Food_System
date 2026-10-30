---
description: "Danh sách task triển khai tính năng Chi tiết món"
---

# Tasks: Chi tiết món

**Input**: Tài liệu thiết kế trong `specs/004-food-details/`

**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md), [data-model.md](data-model.md), [contracts/](contracts/), [quickstart.md](quickstart.md)

**Tests**: Có. Constitution (nguyên tắc V) và `AGENTS.md` bắt buộc unit test cho domain/ViewModel, widget test cho trạng thái màn hình và kiểm chứng rules bằng Emulator.

**Organization**: Task được nhóm theo user story để mỗi story triển khai và kiểm thử độc lập.

## Định dạng: `[ID] [P?] [Story] Mô tả`

- **[P]**: Chạy song song được (khác tệp, không phụ thuộc task chưa xong)
- **[Story]**: User story của task (US1, US2, US3, US4)
- Mọi đường dẫn tính từ gốc repository

---

## Phase 1: Setup (Hạ tầng dùng chung)

**Mục đích**: Mốc kiểm tra trước khi sửa.

- [X] T001 Chạy `flutter analyze` và `flutter test` trên mã hiện tại; ghi số test đang đạt vào phần "Kết quả kiểm tra" cuối `specs/004-food-details/tasks.md`

---

## Phase 2: Foundational (Điều kiện tiên quyết, chặn mọi user story)

**Mục đích**: Sửa quyền đọc đánh giá, luồng món có metadata, topping, feature `reviews` chỉ đọc, các fake và dữ liệu mẫu.

**⚠️ QUAN TRỌNG**: Chưa xong phase này thì không bắt đầu user story nào.

### Bảo mật và tài liệu dữ liệu

- [X] T002 Viết rules test R12–R17 vào `tests/firestore_rules/menu_rules.test.mjs` theo `contracts/firestore_review_access.md`: trong `beforeEach` (dùng `withSecurityRulesDisabled`) tạo `menu_items/item-visible/reviews/r1`, `menu_items/item-unpublished/reviews/r2`, `menu_items/item-hidden-category/reviews/r3` và `reviews/r1` gốc có `customerId: CUSTOMER_UID`; thêm một UID Customer thứ hai cho R16; cập nhật chú thích đầu tệp; xác nhận ít nhất R12, R13, R15 và ca Customer khác của R16 thất bại với rules cũ
- [X] T003 Sửa `firestore.rules` theo `contracts/firestore_review_access.md`: hàm `isPubliclyVisibleItem(menuItemId)` dùng `get()` món cha; `match /reviews/{reviewId}` lồng trong `match /menu_items/{menuItemId}` (đọc khi Admin hoặc món đọc được công khai, không ghi); `reviews/{reviewId}` gốc chỉ chủ đánh giá hoặc Admin đọc; chạy rules test R1–R17 đạt
- [X] T004 [P] Cập nhật `docs/database_schema.md`: thêm mục `menu_items/{menuItemId}/reviews/{reviewId}` (trường, không có định danh khách, bất biến ghi cùng batch với `reviews` gốc và với `ratingAverage`/`reviewCount`), sửa quyền đọc của `reviews/{reviewId}` thành chủ/Admin, ghi chú việc kéo theo cho tính năng viết đánh giá; thêm dòng R12–R17 vào bảng kiểm thử của `specs/002-browse-menu/contracts/firestore_menu_access.md`

### Món: topping và luồng có metadata

- [X] T005 [P] Thêm `toppings` (`List<MenuOption>`, mặc định rỗng, `List.unmodifiable`) vào `lib/features/menu/domain/entities/menu_item.dart`; truyền `toppings` trong `toEntity()` của `lib/features/menu/data/models/menu_item_model.dart`; bổ sung ca topping (hợp lệ, sai định dạng bị bỏ qua, thiếu trường → rỗng) vào `test/features/menu/data/menu_item_model_test.dart`; thêm tham số `toppings` vào `menuItem()` trong `test/support/menu_fixtures.dart`
- [X] T006 [P] Tạo `lib/features/menu/domain/entities/menu_item_feed.dart`: lớp bất biến `MenuItemFeed({MenuItem? item, required bool isFromCache})`
- [X] T007 Đổi `watchItem` trong `lib/features/menu/domain/repositories/menu_repository.dart` sang `Stream<MenuItemFeed>` kèm dartdoc theo `contracts/repositories.md`; cài đặt trong `lib/features/menu/data/repositories/firestore_menu_repository.dart` với `snapshots(includeMetadataChanges: true)` (I1–I5); đổi `menuItemProvider` trong `lib/features/menu/presentation/viewmodels/menu_providers.dart` sang `StreamProvider.autoDispose.family<MenuItemFeed, String>`
- [X] T008 Sửa `test/support/fake_menu_repository.dart`: `watchItem` trả `Stream<MenuItemFeed>`; `emitItem(String id, MenuItem? item, {bool isFromCache = false})` và `emitItemError(String id, Object error)`; giữ các test hiện có (`home_view_test.dart`, `menu_search_view_test.dart`, `menu_item_detail_view_test.dart`) biên dịch và đạt

### Feature `reviews` (chỉ đọc)

- [X] T009 [P] Tạo `lib/features/reviews/domain/entities/review.dart` (`Review` bất biến: `id`, `rating`, `comment`, `imageUrls`, `isAnonymous`, `isEdited`, `createdAt`, getter `authorLabel`) và `lib/features/reviews/domain/repositories/review_repository.dart` (`watchMenuItemReviews(String menuItemId, {required int limit})` trả `Stream<MenuFeed<Review>>`, dartdoc V1–V5)
- [X] T010 [P] Viết unit test `test/features/reviews/data/review_model_test.dart` cho `ReviewModel.fromMap`: đủ trường; `rating` ngoài 1–5, thiếu `rating` hoặc `createdAt` → `FormatException`; `comment` thiếu → rỗng; `imageUrls` bỏ phần tử không phải chuỗi hoặc rỗng và lấy tối đa 3; `isAnonymous`/`isEdited` thiếu → `false`; `createdAt` dạng `Timestamp`
- [X] T011 Tạo `lib/features/reviews/data/models/review_model.dart` (`fromMap(String id, Map<String, dynamic> data)`, `toEntity()`) cho tới khi T010 đạt
- [X] T012 Tạo `lib/features/reviews/data/repositories/firestore_review_repository.dart`: truy vấn `menu_items/{menuItemId}/reviews` `orderBy('createdAt', descending: true).limit(limit)`, `snapshots(includeMetadataChanges: true)`, kiểm tra `limit` 1–100, bỏ qua tài liệu lỗi, `hasMore` khi đủ `limit`, ánh xạ lỗi sang `MenuFailure` giống `FirestoreMenuRepository`; thêm hằng đường dẫn subcollection vào `lib/core/firebase/firestore_paths.dart`
- [X] T013 Tạo `lib/features/reviews/presentation/review_providers.dart`: `reviewRepositoryProvider`, typedef `MenuItemReviewsQuery = ({String menuItemId, int limit})`, `menuItemReviewsProvider` (`StreamProvider.autoDispose.family`, không tự thử lại giống `menu_providers.dart`)
- [X] T014 [P] Tạo `test/support/fake_review_repository.dart`: `requests` ghi lại `(menuItemId, limit)`; `emitReviews(String menuItemId, List<Review> reviews, {bool isFromCache = false, bool hasMore = false})`; `emitReviewsError(String menuItemId, Object error)`; tùy chọn `holdReplays` như `FakeMenuRepository`; thêm hàm `review(...)` tạo đánh giá mẫu vào `test/support/menu_fixtures.dart`

### Dữ liệu mẫu

- [X] T015 Mở rộng `tools/seed_menu/build_seed.cjs` (research R9): mô tả ngắn cho mọi món; topping cho món trà sữa (Trân châu đen +5.000, Thạch dừa +5.000, Kem cheese +8.000) và mỳ cay (Thêm trứng +5.000, Thêm xúc xích +7.000); danh sách `reviews` (12 đánh giá cho `ga-ran-ga-sot-cay-ngot-han-quoc`, 3–4 cho `do-uong-tra-sua-tran-chau-duong-den` và `com-com-ga-chien-mam-toi`, gồm ẩn danh, đã sửa, có 1–3 ảnh, có nội dung dài, `createdAt` cách nhau từng ngày); tính lại `ratingAverage` (làm tròn 1 chữ số) và `reviewCount` của các món này từ đánh giá mẫu; sinh lại `tools/seed_menu/menu_seed.json`
- [X] T016 Sửa `tools/seed_menu/seed.js`: ghi mỗi đánh giá mẫu vào `menu_items/{menuItemId}/reviews/{reviewId}` (chỉ trường công khai, `createdAt` là `Timestamp`) và bản gốc vào `reviews/{reviewId}` với `customerId`, `orderId`, `orderItemId` giả lập `demo-*`; giữ nguyên chốt chặn `FIRESTORE_EMULATOR_HOST`; chạy lại seed trên emulator và xác nhận số tài liệu

**Checkpoint**: `flutter analyze` sạch, test hiện có đạt, rules test R1–R17 đạt, emulator có dữ liệu mẫu mới.

---

## Phase 3: User Story 1 - Xem thông tin đầy đủ của một món (Priority: P1) 🎯 MVP

**Goal**: Màn hình chi tiết theo khung Food Ninja với ảnh, tên, mô tả, giá, tình trạng, tóm tắt đánh giá; đủ trạng thái tải, không còn bán, lỗi, ngoại tuyến; realtime.

**Independent Test**: Quickstart Q1–Q5: mở "Trà sữa trân châu đường đen" thấy đủ thông tin và "4,x (n đánh giá)"; gỡ đăng bán khi đang xem chuyển sang "Món này không còn được bán".

### Tests cho User Story 1

- [X] T017 [P] [US1] Viết widget test `test/core/widgets/rating_stars_test.dart`: 0 → 5 sao rỗng; 4,5 → 4 đầy + 1 nửa; 5 → 5 đầy; nhãn ngữ nghĩa "Đánh giá 4,5 trên 5"; cỡ tùy chỉnh
- [X] T018 [P] [US1] Viết unit test `test/features/menu/presentation/menu_item_detail_view_model_test.dart` phần US1 (ProviderContainer, fake menu + review repository, `menuOfflineGraceProvider` nhỏ): bắt đầu `loading`; feed có món → `ready`; `item == null` → `unavailable`; lỗi → `error`, `retry()` về `loading`; feed đổi giá/tên → state mới; món bị gỡ khi đang xem → `unavailable` và giữ nguyên dù luồng đóng; cache quá khoảng chờ → `isOffline`; cache không có món và chưa có dữ liệu máy chủ → `error` sau khoảng chờ; hủy provider rồi mở lại → state mới
- [X] T019 [P] [US1] Viết lại `test/features/menu/presentation/menu_item_detail_view_test.dart` phần US1 (390×844): khung xương khi tải; ảnh thay thế khi `imageUrl` rỗng; tên, mô tả, khoảng giá, `RatingStars` và "4,9 (210 đánh giá)"; "Chưa có đánh giá" khi `reviewCount == 0`; món có nhiều size cùng giá cộng thêm chỉ hiện một giá; mô tả trống bị ẩn; mô tả dài thu gọn kèm "Xem thêm"; nhãn "Hết hàng"; "Món này không còn được bán" kèm "Quay lại"; lỗi kèm "Thử lại"; `OfflineBanner`; `detail-back` đóng màn hình

### Implementation cho User Story 1

- [X] T020 [P] [US1] Tạo `lib/core/widgets/rating_stars.dart`: `RatingStars({required double rating, double size = 16})` vẽ 5 sao (`Icons.star_rounded`, `star_half_rounded`, `star_outline_rounded`) màu `AppColors.warning`, `Semantics` "Đánh giá x,y trên 5" (dấu phẩy thập phân) cho tới khi T017 đạt
- [X] T021 [US1] Tạo `lib/features/menu/presentation/viewmodels/menu_item_detail_state.dart` theo `data-model.md` (`MenuItemDetailStatus`, `MenuItemDetailNotice`, `ReviewSectionStatus`, `ReviewSectionState`, `MenuItemDetailState` với `unitPrice`, `total`, `canOrder`; tạm để `selection` có thể null)
- [X] T022 [US1] Tạo `lib/features/menu/presentation/viewmodels/menu_item_detail_view_model.dart`: `menuItemDetailViewModelProvider = NotifierProvider.autoDispose.family<MenuItemDetailViewModel, MenuItemDetailState, String>`; nghe `menuItemProvider(menuItemId)` bằng `ref.listen` (bỏ qua `AsyncError` có `isLoading: true`); ánh xạ `loading`/`ready`/`unavailable`/`error`; khoảng chờ ngoại tuyến từ `menuOfflineGraceProvider`; `retry()`; `clearNotice()`; `ref.onDispose` hủy timer cho tới khi T018 đạt
- [X] T023 [US1] Viết lại `lib/features/menu/presentation/views/menu_item_detail_view.dart` (giữ `MenuItemDetailView({required String menuItemId})`): `ConsumerStatefulWidget`, `CustomScrollView` với ảnh 4:3 (cao tối đa 45%) và nút `detail-back` nổi, khối nội dung bo góc trên `AppRadii.dialog` đè ảnh 24 dp, `SoldOutLabel`, tên, `RatingStars` + nhãn (`detail-rating`), giá (`formatVndRange`), mô tả thu gọn 6 dòng (`detail-description-toggle`), `OfflineBanner`; các trạng thái theo `contracts/food_details_ui.md`; chỉ dùng token cho tới khi T019 đạt

**Checkpoint**: US1 chạy độc lập; kiểm chứng Q1–Q5.

---

## Phase 4: User Story 2 - Xem và chọn tùy chọn của món (Priority: P1)

**Goal**: Danh sách size (chọn một) và topping (chọn nhiều) kèm giá cộng thêm; giá tạm tính cập nhật ngay; mặc định mỗi lần mở; xử lý tùy chọn bị xóa.

**Independent Test**: Quickstart Q6–Q10: "Trà đào" size L → 25.000 ₫; món không có tùy chọn không có phần tùy chọn; mở lại về mặc định.

### Tests cho User Story 2

- [X] T024 [P] [US2] Viết unit test `test/features/menu/domain/item_selection_test.dart`: `initial` chọn size giá thấp nhất (cùng giá: size đứng trước), không size khi món không có size; `withSize` chỉ nhận id hợp lệ; `toggleTopping` thêm/bỏ; `unitPrice`/`total` đúng với mọi tổ hợp size × tập topping × số lượng {1, 2, 99} của các món mẫu có tùy chọn trong `tools/seed_menu/menu_seed.json` (SC-002); `withQuantity` kẹp 1–99; `withNote` cắt 200 ký tự và `trimmedNote` của chuỗi chỉ khoảng trắng là rỗng; `reconcile` bỏ topping/size đã xóa, size về mặc định, trả `removedOptions` đúng; `==`/`hashCode`
- [X] T025 [P] [US2] Bổ sung `test/features/menu/presentation/menu_item_detail_view_model_test.dart`: `ready` có `selection` mặc định; `selectSize`, `toggleTopping` cập nhật `unitPrice`/`total`; món hết hàng thì các hàm thay đổi lựa chọn không làm gì; feed xóa topping đang chọn → `reconcile` và `notice == optionsRemoved`; feed đổi giá giữ nguyên lựa chọn và tính lại giá
- [X] T026 [P] [US2] Bổ sung `test/features/menu/presentation/menu_item_detail_view_test.dart` phần US2: size hiển thị "M" và "L +5.000 ₫", size rẻ nhất được chọn; chọn L đổi giá trên nút; topping chọn nhiều; món không có tùy chọn không có tiêu đề "Chọn size"/"Topping"; hết hàng thì dòng tùy chọn vô hiệu; SnackBar "Một số tùy chọn đã thay đổi, vui lòng chọn lại"

### Implementation cho User Story 2

- [X] T027 [US2] Tạo `lib/features/menu/domain/entities/item_selection.dart` theo `data-model.md` (hằng `minQuantity = 1`, `maxQuantity = 99`, `maxNoteLength = 200`) cho tới khi T024 đạt
- [X] T028 [US2] Bổ sung vào `lib/features/menu/presentation/viewmodels/menu_item_detail_view_model.dart`: tạo `ItemSelection.initial` ở feed `ready` đầu tiên, `reconcile` ở các feed sau (đặt `notice = optionsRemoved` khi có thay đổi), `selectSize(String)`, `toggleTopping(String)` (bỏ qua khi `!canOrder`); làm `selection` thành bắt buộc khi `ready` trong `menu_item_detail_state.dart` cho tới khi T025 đạt
- [X] T029 [P] [US2] Tạo `lib/features/menu/presentation/widgets/item_option_section.dart`: phần "Chọn size" (`RadioListTile` hoặc dòng tương đương có biểu tượng radio, key `detail-size-<id>`) và "Topping" (dòng có checkbox, key `detail-topping-<id>`), nhãn giá "+x ₫" bằng `formatVnd` (ẩn khi 0), trạng thái vô hiệu với nhãn ngữ nghĩa "không khả dụng", vùng chạm ≥ 48 dp
- [X] T030 [US2] Nối `ItemOptionSection` và SnackBar `optionsRemoved` vào `lib/features/menu/presentation/views/menu_item_detail_view.dart` cho tới khi T026 đạt

**Checkpoint**: US1 và US2 chạy độc lập; kiểm chứng Q6–Q10.

---

## Phase 5: User Story 3 - Đọc đánh giá của khách đã mua (Priority: P2)

**Goal**: 5 đánh giá mới nhất, tải thêm 10; "Khách hàng"/"Khách hàng ẩn danh"; ảnh xem lớn; trạng thái tải/trống/lỗi riêng; ngoại tuyến.

**Independent Test**: Quickstart Q11–Q14: "Gà sốt cay ngọt Hàn Quốc" có 5 đánh giá, "Xem thêm" tải tới 12; ẩn danh hiện "Khách hàng ẩn danh".

### Tests cho User Story 3

- [X] T031 [P] [US3] Viết unit test `test/core/utils/date_format_test.dart` cho `formatReviewDate`: `dd/MM/yyyy` có số 0 đứng đầu, đổi sang giờ địa phương
- [X] T032 [P] [US3] Bổ sung `test/features/menu/presentation/menu_item_detail_view_model_test.dart`: phần đánh giá yêu cầu `limit` 5; `ready` với danh sách và `hasMore`; `loadMoreReviews()` yêu cầu `limit` 15 và giữ danh sách cũ khi đang tải (`isLoadingMore`); lỗi đánh giá → `reviews.status == error`, màn hình vẫn `ready`; feed đánh giá mới đưa đánh giá mới lên đầu danh sách; `retryReviews()`; ngoại tuyến quá khoảng chờ thì `loadMoreReviews()` không đổi `limit` và đặt `notice == reviewsNeedConnection`; cache đánh giá rỗng chưa có máy chủ → lỗi đánh giá sau khoảng chờ; không yêu cầu đánh giá khi món `unavailable`
- [X] T033 [P] [US3] Bổ sung `test/features/menu/presentation/menu_item_detail_view_test.dart` phần US3: "Chưa có đánh giá cho món này"; thẻ đánh giá có "Khách hàng"/"Khách hàng ẩn danh", sao, ngày, "Đã chỉnh sửa"; không có chữ nào chứa `customerId`/`orderId` (SC-003); nội dung dài thu gọn 4 dòng; `detail-more-reviews` gọi tải thêm và biến mất khi hết; lỗi đánh giá có `detail-reviews-retry` trong khi thông tin món vẫn hiển thị; chạm ảnh mở trình xem, vuốt sang ảnh 2, `review-image-close` đóng; SnackBar "Cần kết nối mạng để tải thêm đánh giá"

### Implementation cho User Story 3

- [X] T034 [P] [US3] Tạo `lib/core/utils/date_format.dart` với `formatReviewDate(DateTime)` cho tới khi T031 đạt
- [X] T035 [US3] Bổ sung vào `lib/features/menu/presentation/viewmodels/menu_item_detail_view_model.dart`: nghe `menuItemReviewsProvider((menuItemId:, limit:))` khi món `ready` (hằng `reviewsFirstPage = 5`, `reviewsPageStep = 10`), giữ danh sách cũ khi tăng `limit`, `loadMoreReviews()`, `retryReviews()`, ngoại tuyến theo research R7, tính `reviews` vào trạng thái kết nối chung cho tới khi T032 đạt
- [X] T036 [P] [US3] Tạo `lib/features/menu/presentation/widgets/review_card.dart` (key `review-<id>`: `authorLabel`, `RatingStars` cỡ 14, `formatReviewDate`, "Đã chỉnh sửa", nội dung 4 dòng kèm "Xem thêm", hàng ảnh 64 dp `review-<id>-image-<i>` với `FoodImagePlaceholder` khi lỗi) và `lib/features/menu/presentation/widgets/review_image_viewer.dart` (hàm `showReviewImageViewer(context, imageUrls, initialIndex)`: hộp thoại toàn màn hình, `PageView` + `InteractiveViewer`, chỉ số "i/n", nút `review-image-close`)
- [X] T037 [US3] Tạo `lib/features/menu/presentation/widgets/review_section.dart`: tiêu đề "Đánh giá" kèm số lượt, khung xương khi tải, trống, lỗi kèm `detail-reviews-retry`, danh sách `ReviewCard`, nút `detail-more-reviews` hoặc chỉ báo tải; nối vào `lib/features/menu/presentation/views/menu_item_detail_view.dart` cùng SnackBar `reviewsNeedConnection` cho tới khi T033 đạt

**Checkpoint**: US1–US3 chạy độc lập; kiểm chứng Q11–Q14.

---

## Phase 6: User Story 4 - Chọn số lượng, ghi chú và nút thêm vào giỏ (Priority: P2)

**Goal**: Bộ chọn số lượng 1–99, ghi chú ≤ 200 ký tự, thanh dưới cố định với "Thêm vào giỏ · giá tạm tính" báo "Tính năng đang được phát triển".

**Independent Test**: Quickstart Q15–Q17: "Trà đào" L × 3 → nút "Thêm vào giỏ · 75.000 ₫"; chạm nút thấy SnackBar, lựa chọn giữ nguyên.

### Tests cho User Story 4

- [X] T038 [P] [US4] Bổ sung `test/features/menu/presentation/menu_item_detail_view_model_test.dart`: `increaseQuantity`/`decreaseQuantity` dừng ở 1 và 99; `updateNote` cắt 200 ký tự; `addToCart()` khi còn hàng đặt `notice == addToCartUnavailable` và không đổi `selection`; hết hàng thì mọi hàm không làm gì
- [X] T039 [P] [US4] Bổ sung `test/features/menu/presentation/menu_item_detail_view_test.dart` phần US4: `detail-quantity-minus` vô hiệu ở 1; tăng lên 3 đổi nút thành "Thêm vào giỏ · 75.000 ₫" (Trà đào L); `detail-note` dừng ở 200 ký tự và hiện "200/200"; chạm `detail-add-to-cart` hiện SnackBar "Tính năng đang được phát triển" và lựa chọn giữ nguyên; hết hàng: không có bộ chọn số lượng, nút "Hết hàng" vô hiệu, ghi chú vô hiệu

### Implementation cho User Story 4

- [X] T040 [US4] Bổ sung `increaseQuantity()`, `decreaseQuantity()`, `updateNote(String)`, `addToCart()` vào `lib/features/menu/presentation/viewmodels/menu_item_detail_view_model.dart` cho tới khi T038 đạt
- [X] T041 [P] [US4] Tạo `lib/features/menu/presentation/widgets/item_order_bar.dart`: thanh dưới nền trắng, `AppShadows.card`, `SafeArea`; bộ chọn số lượng (`detail-quantity-minus`, `detail-quantity`, `detail-quantity-plus`, vùng chạm 48 dp); nút gradient `AppGradients.primary` "Thêm vào giỏ · <giá>" (`detail-add-to-cart`, ≥ 48 dp, chữ xuống dòng được); biến thể hết hàng (nút xám "Hết hàng" vô hiệu, ẩn số lượng)
- [X] T042 [US4] Nối vào `lib/features/menu/presentation/views/menu_item_detail_view.dart`: `ItemOrderBar` làm `bottomNavigationBar` của `Scaffold`; ô ghi chú (`detail-note`, nhiều dòng, `maxLength` 200 với bộ đếm, gợi ý "Ví dụ: ít đá, không hành", vô hiệu khi hết hàng, `TextEditingController` trong `State`); SnackBar `addToCartUnavailable` dùng `ComingSoonView.message` cho tới khi T039 đạt

**Checkpoint**: Cả bốn story chạy độc lập; kiểm chứng Q15–Q17.

---

## Phase 7: Polish & Cross-Cutting Concerns

- [X] T043 [P] Bổ sung widget test 320×640 ở cỡ chữ 1,3× vào `test/features/menu/presentation/menu_item_detail_view_test.dart`: món tên dài, nhiều size/topping, đánh giá dài có ảnh, thanh dưới với giá 7 chữ số; không có lỗi tràn (SC-006)
- [X] T044 [P] Cập nhật `docs/design_system.md`: mục "Food Details" (ảnh đầu trang, khối nội dung bo góc đè ảnh, danh sách tùy chọn, thanh dưới cố định) và "Rating Stars"; cập nhật chú thích lớp `MenuItemDetailView` (bỏ câu "Minimal details screen"); ghi chú trong `specs/002-browse-menu/spec.md` User Story 4 rằng màn hình chi tiết tối thiểu đã được thay bằng `specs/004-food-details`
- [X] T045 Chạy `dart format lib test`, `flutter analyze` (phải sạch), toàn bộ `flutter test`, rules test R1–R17 trong `tests/firestore_rules/`; ghi kết quả vào "Kết quả kiểm tra" cuối `specs/004-food-details/tasks.md`
- [ ] T046 Chạy ứng dụng trên Chrome với Emulator đã seed dữ liệu mới và đi qua quickstart Q1–Q19 (đo bằng tay SC-001 ≤ 2 giây khi mở món và SC-004 ≤ 5 giây khi đổi giá trên Emulator UI); ghi kịch bản đạt hoặc lệch vào "Kết quả kiểm tra" cuối `specs/004-food-details/tasks.md`
- [X] T047 So khớp mã với `spec.md` (FR-001 – FR-016, SC-001 – SC-006), `plan.md` và `contracts/`; đóng mọi khoảng trống bắt buộc còn lại

---

## Dependencies & Execution Order

### Phụ thuộc giữa các phase

- **Setup (Phase 1)**: không phụ thuộc.
- **Foundational (Phase 2)**: sau Setup; chặn mọi user story. T002 → T003; T006 → T007 → T008; T009 → T010 → T011 → T012 → T013; T015 → T016.
- **US1 (Phase 3)**: sau Foundational. Là MVP.
- **US2 (Phase 4)**: domain (T024, T027) độc lập; ViewModel và giao diện cần T022, T023.
- **US3 (Phase 5)**: cần T022, T023 (gắn vào ViewModel và màn hình); `formatReviewDate`, `ReviewCard`, trình xem ảnh làm song song được.
- **US4 (Phase 6)**: cần `ItemSelection` (T027) và ViewModel (T028).
- **Polish (Phase 7)**: sau các story muốn giao.

### Trong mỗi story

- Viết test trước và xác nhận thất bại, rồi mới cài đặt.
- Các task cùng sửa `menu_item_detail_view_model.dart` hoặc `menu_item_detail_view.dart` chạy tuần tự (T022 → T028 → T035 → T040; T023 → T030 → T037 → T042).

## Parallel Opportunities

- Phase 2: T004, T005, T006, T009, T014 song song; T015 song song với chuỗi `reviews`.
- US1: T017, T018, T019 song song; T020 song song với T021–T022.
- US2: T024, T025, T026 song song; T029 song song với T027–T028.
- US3: T031, T032, T033 song song; T034, T036 song song với T035.
- US4: T038, T039 song song; T041 song song với T040.
- Polish: T043, T044 song song.

```text
# Ví dụ US3:
Task: "T031 unit test formatReviewDate trong test/core/utils/date_format_test.dart"
Task: "T034 formatReviewDate trong lib/core/utils/date_format.dart"
Task: "T036 ReviewCard và trình xem ảnh trong lib/features/menu/presentation/widgets/"
```

## Implementation Strategy

### MVP trước (chỉ User Story 1)

1. Phase 1 → Phase 2 (gồm sửa rules đánh giá).
2. Phase 3 (US1): màn hình thông tin món đầy đủ trạng thái.
3. **Dừng và kiểm chứng**: Q1–Q5 trên Chrome.

### Giao dần

1. US1 → thông tin món.
2. US2 → tùy chọn và giá.
3. US3 → đánh giá.
4. US4 → số lượng, ghi chú, nút thêm vào giỏ.
5. Polish → bố cục 320 dp, tài liệu, kiểm tra cuối.

## Notes

- Không thêm phụ thuộc mới.
- Sửa rules `reviews` là thay đổi bảo mật; phải có rules test R12–R17 trước khi giao.
- Tính năng viết đánh giá (Member 4) phải ghi bản công khai cùng batch; đã ghi trong `docs/database_schema.md` (T004).
- Dùng `SPECIFY_FEATURE=004-food-details` hoặc `.specify/feature.json` khi chạy script speckit vì nhánh là `linh`.

## Kết quả kiểm tra

### 2026-10-20

- **T001 (mốc trước khi sửa)**: `flutter analyze` sạch; `flutter test` 138/138 đạt.
- **T002–T003**: với rules cũ 4 trong 6 test mới thất bại (R12, R13, R15, R16 phần Customer khác); sau khi sửa `firestore.rules`, rules test R1–R17 đạt 17/17 trên Firestore Emulator.
- **T045**: `dart format lib test` không còn thay đổi; `flutter analyze` sạch; `flutter test` 222/222 đạt (thêm 84 test: `item_selection_test`, `review_model_test`, `rating_stars_test`, `date_format_test`, `menu_item_detail_view_model_test` 25, `menu_item_detail_view_test` 28 gồm ca 320 dp × 1,3×, ca topping của `menu_item_model_test`); rules test R1–R17 đạt 17/17.
- **T046**: ứng dụng đã chạy lại trên Chrome (`http://localhost:5555`, Emulator `demo-ordering` với 28 món và 18 đánh giá mẫu); chờ người dùng đi qua Q1–Q19 và đo bằng tay SC-001/SC-004.
- **T047**: FR-001 – FR-016 và SC-001 – SC-004, SC-006 đều có mã và test tương ứng; SC-005 là chỉ số đo với người dùng thật, chưa đo.
- Thay đổi ngoài kế hoạch:
  - Hàm ánh xạ lỗi Firestore được tách sang `lib/features/menu/data/firestore_failure.dart` để repository đánh giá dùng chung.
  - Dữ liệu mẫu bỏ điểm demo của các món không có đánh giá mẫu, để tóm tắt đánh giá luôn khớp danh sách; mục "Phổ biến" ở Trang chủ còn 3 món.
  - Ảnh đánh giá mẫu dùng ảnh ngẫu nhiên từ `picsum.photos` (cần mạng để hiện; lỗi thì hiện ảnh thay thế).
  - Test Trang chủ và tìm kiếm thêm `FakeReviewRepository` vì chúng mở màn hình chi tiết.
