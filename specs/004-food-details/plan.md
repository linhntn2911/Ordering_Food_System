# Kế hoạch triển khai (Implementation Plan): Chi tiết món

**Branch**: `linh` (feature `004-food-details`) | **Ngày**: 2026-10-20 | **Spec**: [spec.md](spec.md)

**Đầu vào**: Đặc tả tính năng tại `specs/004-food-details/spec.md` (5 mục làm rõ ngày 2026-10-20).

## Tóm tắt (Summary)

Thay màn hình chi tiết tối thiểu của tính năng 002 bằng màn hình "Food Details" đầy đủ theo khung Product Detail của Food Ninja. Màn hình gồm:

- Ảnh, tên, mô tả, giá hoặc khoảng giá, tình trạng còn/hết hàng và tóm tắt đánh giá (điểm, 5 sao, số lượt).
- Chọn size và topping, số lượng 1–99, ghi chú ≤ 200 ký tự, giá tạm tính.
- Nút "Thêm vào giỏ" chỉ báo "Tính năng đang được phát triển".
- 5 đánh giá mới nhất, tải thêm theo lượt 10; người viết luôn hiển thị là "Khách hàng" hoặc "Khách hàng ẩn danh".

Về kỹ thuật:

- **Bảo mật đánh giá:** đánh giá đọc từ bản công khai `menu_items/{id}/reviews`, không chứa định danh khách. Collection `reviews` gốc bị thu hẹp quyền đọc về chủ đánh giá và Admin, sửa lỗ hổng lộ `customerId`/`orderId` hiện có.
- **Giá tạm tính:** tính trong `ItemSelection` ở domain.
- **ViewModel:** `MenuItemDetailViewModel` (`Notifier` autoDispose theo `menuItemId`) gộp luồng món và luồng đánh giá thành state bất biến.

## Bối cảnh kỹ thuật (Technical Context)

**Language/Version**: Dart `^3.13.2`, Flutter 3.47.x

**Primary Dependencies**: `flutter_riverpod ^3.4.3`, `cloud_firestore ^7.0.0`, `firebase_core ^5.0.0` (đã có). Không thêm phụ thuộc (research R11).

**Storage**: Cloud Firestore: `menu_items` (đọc), `menu_items/{id}/reviews` (mới, đọc), `reviews` (chỉ đổi rules). Cache bền vững có sẵn cho ngoại tuyến. Lựa chọn tạm chỉ trong bộ nhớ.

**Testing**: `flutter test` (unit cho `ItemSelection`, `formatReviewDate`, `ReviewModel`, `MenuItemModel`, ViewModel; widget cho màn hình chi tiết, `RatingStars`, 320 dp và 1,3×); `node --test` cho rules R1–R17.

**Target Platform**: Android trước; giữ tương thích iOS; chạy trên Chrome với Emulator để demo.

**Project Type**: Ứng dụng di động Flutter.

**Performance Goals**: Thông tin món hiện ≤ 2 giây (SC-001); thay đổi từ nhà hàng hiện ≤ 5 giây (SC-004); giá tạm tính cập nhật trong cùng khung hình.

**Constraints**: Truy vấn đánh giá có giới hạn (5, rồi +10); rules chặn đánh giá của món chưa đăng bán và mọi định danh khách; chỉ chế độ sáng, chỉ dùng token chung.

**Scale/Scope**: 1 màn hình High (Member 2), 1 hộp thoại xem ảnh; tối đa vài trăm đánh giá mỗi món.

## Kiểm tra Constitution (Constitution Check)

*GATE: phải đạt trước Phase 0 và kiểm tra lại sau Phase 1.*

| Nguyên tắc | Đánh giá trước | Sau thiết kế |
|---|---|---|
| I. Đặc tả trước khi triển khai | ĐẠT: spec 004 có 4 user story, đã làm rõ 5 mục | ĐẠT |
| II. MVVM và Riverpod chính thức | ĐẠT: View → `MenuItemDetailViewModel` → `MenuRepository`/`ReviewRepository` → Firestore; quy tắc giá ở domain | ĐẠT |
| III. Bảo mật do máy chủ áp đặt | **CẦN LÀM**: rules hiện cho đọc công khai `reviews` có `customerId`, `orderId` | ĐẠT sau R1: bản công khai không có định danh, `reviews` gốc chỉ chủ/Admin, rules test R12–R17 |
| IV. User story trình diễn độc lập | ĐẠT: Q1–Q19 trong `quickstart.md`; Food Details là màn High của Member 2 | ĐẠT |
| V. Chất lượng kiểm chứng được | ĐẠT: đủ trạng thái tải/không còn bán/lỗi/thử lại/ngoại tuyến cho màn hình và phần đánh giá | ĐẠT |
| VI. Thiết kế Food Ninja chỉ chế độ sáng | ĐẠT: token và widget chung, thêm `RatingStars` dùng chung | ĐẠT |
| Phụ thuộc mới phải có lý do | ĐẠT: không thêm | ĐẠT |

Không có vi phạm cần biện minh. Mục III được xử lý bằng thiết kế ở R1, không phải ngoại lệ.

## Quyết định kiến trúc

Chi tiết ở [research.md](research.md).

1. **Đánh giá công khai (R1)**: subcollection `menu_items/{id}/reviews` chỉ có trường hiển thị; rules `get()` món cha; `reviews` gốc chỉ chủ/Admin; hệ thống tin cậy ghi cả hai trong một batch.
2. **Luồng món có metadata (R2)**: `watchItem` trả `MenuItemFeed(item?, isFromCache)`.
3. **Topping (R3)**: thêm `toppings` vào `MenuItem`.
4. **Lựa chọn và giá (R4)**: `ItemSelection` bất biến ở domain, có `reconcile` khi tùy chọn bị xóa.
5. **ViewModel (R5)**: `NotifierProvider.autoDispose.family` theo `menuItemId`, nên mỗi lần mở về mặc định (FR-016).
6. **Đánh giá (R6, R7)**: feature mới `lib/features/reviews/` chỉ đọc; trang đầu 5, tăng `limit` 10; ngoại tuyến dùng cache và khoảng chờ chung.
7. **Giao diện (R8)**: theo `contracts/food_details_ui.md`; `RatingStars` dùng chung; `formatReviewDate` không dùng `intl`.
8. **Dữ liệu mẫu (R9)**: thêm mô tả, topping và đánh giá công khai mẫu.

## Cấu trúc dự án (Project Structure)

### Tài liệu (feature này)

```text
specs/004-food-details/
├── spec.md
├── plan.md              # Tệp này
├── research.md          # Phase 0
├── data-model.md        # Phase 1
├── quickstart.md        # Phase 1
├── contracts/
│   ├── repositories.md
│   ├── firestore_review_access.md
│   └── food_details_ui.md
├── checklists/requirements.md
└── tasks.md             # Phase 2 (/speckit-tasks, chưa tạo)
```

### Mã nguồn (gốc repository)

```text
lib/
├── core/
│   ├── utils/date_format.dart                         # Mới: formatReviewDate
│   └── widgets/rating_stars.dart                      # Mới: RatingStars
└── features/
    ├── menu/
    │   ├── domain/
    │   │   ├── entities/menu_item.dart                # Sửa: toppings
    │   │   ├── entities/menu_item_feed.dart           # Mới
    │   │   ├── entities/item_selection.dart           # Mới
    │   │   └── repositories/menu_repository.dart      # Sửa: watchItem → MenuItemFeed
    │   ├── data/
    │   │   ├── models/menu_item_model.dart            # Sửa: toEntity truyền toppings
    │   │   └── repositories/firestore_menu_repository.dart  # Sửa: watchItem có metadata
    │   └── presentation/
    │       ├── viewmodels/menu_providers.dart         # Sửa: menuItemProvider kiểu mới
    │       ├── viewmodels/menu_item_detail_state.dart # Mới
    │       ├── viewmodels/menu_item_detail_view_model.dart  # Mới
    │       ├── views/menu_item_detail_view.dart       # Viết lại
    │       └── widgets/
    │           ├── item_option_section.dart           # Mới: size + topping
    │           ├── item_order_bar.dart                # Mới: số lượng + "Thêm vào giỏ"
    │           ├── review_section.dart                # Mới: danh sách đánh giá
    │           ├── review_card.dart                   # Mới
    │           └── review_image_viewer.dart           # Mới
    └── reviews/                                       # Mới (chỉ đọc)
        ├── domain/entities/review.dart
        ├── domain/repositories/review_repository.dart
        ├── data/models/review_model.dart
        ├── data/repositories/firestore_review_repository.dart
        └── presentation/review_providers.dart

test/
├── core/utils/date_format_test.dart
├── core/widgets/rating_stars_test.dart
├── features/menu/domain/item_selection_test.dart
├── features/menu/data/menu_item_model_test.dart       # Sửa: toppings
├── features/menu/presentation/menu_item_detail_view_model_test.dart
├── features/menu/presentation/menu_item_detail_view_test.dart   # Viết lại
├── features/reviews/data/review_model_test.dart
├── features/menu/presentation/home_view_test.dart     # Sửa: emitItem kiểu mới
├── features/menu/presentation/menu_search_view_test.dart  # Sửa: emitItem kiểu mới
└── support/{fake_menu_repository.dart, fake_review_repository.dart}

tests/firestore_rules/menu_rules.test.mjs              # Sửa: R12–R17
firestore.rules                                        # Sửa theo contracts/firestore_review_access.md
tools/seed_menu/{build_seed.cjs, menu_seed.json, seed.js}  # Sửa: mô tả, topping, đánh giá mẫu
docs/database_schema.md                                # Sửa: bản công khai, quyền đọc reviews
docs/design_system.md                                  # Sửa: Food Details, RatingStars
```

**Quyết định cấu trúc**: Màn hình chi tiết thuộc `lib/features/menu/` vì giữ tên lớp và route sẵn có. Phần đọc đánh giá tách sang `lib/features/reviews/` để tính năng viết đánh giá (Member 4) mở rộng cùng chỗ.

## Thứ tự thực hiện gợi ý (đầu vào cho /speckit-tasks)

1. **Nền và bảo mật**:
   - Rules và rules test R12–R17.
   - `docs/database_schema.md`.
   - `MenuItem.toppings`, `MenuItemFeed`, `watchItem` mới.
   - Feature `reviews` (entity, model, repository, provider), các fake.
   - Dữ liệu mẫu.
2. **US1 (P1)**: ViewModel phần món (loading/ready/unavailable/error/offline) → màn hình phần thông tin món, khung ảnh, `RatingStars`.
3. **US2 (P1)**: `ItemSelection` → ViewModel (chọn size/topping, `reconcile`) → `item_option_section`.
4. **US3 (P2)**: ViewModel phần đánh giá (trang, tải thêm, ngoại tuyến) → `review_section`, `review_card`, `review_image_viewer`, `formatReviewDate`.
5. **US4 (P2)**: số lượng, ghi chú, `item_order_bar`, SnackBar "Thêm vào giỏ".
6. **Hoàn thiện**: 320 dp và 1,3×, `docs/design_system.md`, format/analyze/test/rules, chạy quickstart.

## Rủi ro và việc kéo theo

- **Ràng buộc với Member 4**: Màn hình viết đánh giá phải ghi bản công khai cùng batch với `reviews` gốc và cập nhật `ratingAverage`/`reviewCount`. Nếu quên, đánh giá sẽ không hiện ở chi tiết món. Ghi vào `docs/database_schema.md`.
- **Đổi quyền đọc `reviews`**: Màn hình nào đang đọc `reviews` công khai sẽ bị từ chối. Hiện chưa có màn hình nào dùng.
- **Chi phí `get()` trong rules**: thêm 1 lượt đọc cho mỗi truy vấn đánh giá; chấp nhận được.
- **Đổi kiểu `watchItem`**: các test hiện có gọi `emitItem` phải sửa theo kiểu mới.
- **Dữ liệu mẫu**: điểm và số lượt của các món có đánh giá mẫu được tính lại, nên mục "Phổ biến" ở Trang chủ có thể đổi thứ tự.

## Theo dõi độ phức tạp (Complexity Tracking)

Không có vi phạm constitution cần biện minh.
