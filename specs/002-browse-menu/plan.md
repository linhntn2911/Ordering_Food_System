# Kế hoạch triển khai (Implementation Plan): Duyệt thực đơn

**Branch**: `linh` (feature `002-browse-menu`) | **Ngày**: 2026-10-20 | **Spec**: [spec.md](spec.md)

**Đầu vào**: Đặc tả tính năng tại `specs/002-browse-menu/spec.md` (đã làm rõ 5 câu hỏi ngày 2026-10-20).

## Tóm tắt (Summary)

Dựng Trang chủ cho Guest và Customer: thanh danh mục, mục "Phổ biến" (tối đa 5 món), danh sách món gom theo danh mục, tải dần, cập nhật realtime, hiện cả món hết hàng kèm nhãn, khoảng giá theo size, và hiển thị thực đơn đã lưu khi ngoại tuyến. Về kỹ thuật: mở rộng `MenuRepository` hiện có thành bốn luồng Firestore realtime; thêm hai trường phi chuẩn hóa `isCategoryPublished` và `categorySortOrder` vào `menu_items` để rules tự chặn món của danh mục chưa đăng bán; một `HomeMenuViewModel` (Riverpod `Notifier`) gộp các luồng thành một `HomeMenuState` bất biến. Feature cũng dựng phần nền giao diện còn thiếu (theme token, Poppins, app shell chỉ chế độ sáng) mà Home cần.

## Bối cảnh kỹ thuật (Technical Context)

**Language/Version**: Dart `^3.13.2`, Flutter 3.47.x

**Primary Dependencies**: `flutter_riverpod ^3.4.3`, `cloud_firestore ^7.0.0`, `firebase_core ^5.0.0` (đã có). Không thêm phụ thuộc runtime mới. Phụ thuộc chỉ dùng khi phát triển (ngoài app Flutter): `@firebase/rules-unit-testing`, `firebase` cho kiểm thử rules; `firebase-admin` cho script dữ liệu mẫu.

**Storage**: Cloud Firestore (`categories`, `menu_items`), dùng cache bền vững có sẵn cho chế độ ngoại tuyến. Không dùng SharedPreferences trong feature này.

**Testing**: `flutter test` (unit cho domain/model/ViewModel với `FakeMenuRepository`; widget test cho các trạng thái Home và thẻ món ở 320 dp và cỡ chữ 1,3×); `node --test` trên Firebase Emulator cho rules.

**Target Platform**: Android trước; giữ tương thích iOS.

**Project Type**: Ứng dụng di động Flutter.

**Performance Goals**: Thực đơn hiện trong ≤ 3 giây (SC-001); thay đổi từ Admin hiện trong ≤ 5 giây (SC-004); cuộn mượt khi tải dần.

**Constraints**: Truy vấn có giới hạn (trang 20 món, danh mục ≤ 50, phổ biến 5); rules là nơi chặn dữ liệu chưa đăng bán; chỉ chế độ sáng; không token màu cục bộ.

**Scale/Scope**: Một nhà hàng, cỡ vài chục danh mục và vài trăm món; 1 màn hình chính (Home) và 1 màn hình chi tiết tối thiểu làm đích điều hướng.

## Kiểm tra Constitution (Constitution Check)

*GATE: phải đạt trước Phase 0 và kiểm tra lại sau Phase 1.*

| Nguyên tắc | Đánh giá trước | Sau thiết kế |
|---|---|---|
| I. Đặc tả trước khi triển khai | ĐẠT: spec 002 có 4 user story kiểm thử độc lập, đã làm rõ | ĐẠT |
| II. MVVM và Riverpod chính thức | ĐẠT: View → `HomeMenuViewModel` (`Notifier` của `flutter_riverpod`) → `MenuRepository` → Firestore; không gọi Firebase trong widget | ĐẠT |
| III. Bảo mật do máy chủ áp đặt | ĐẠT: rules chặn món/danh mục chưa đăng bán (R1); Guest/Customer không ghi được menu | ĐẠT, kèm kiểm thử rules R1–R9 |
| IV. User story trình diễn độc lập | ĐẠT: mỗi story có kịch bản trong `quickstart.md`; Home là màn hình Medium của Member 2 | ĐẠT |
| V. Chất lượng kiểm chứng được | ĐẠT: đủ trạng thái tải/trống/lỗi/thử lại; unit, widget và rules test; `flutter analyze` | ĐẠT |
| VI. Thiết kế Food Ninja chỉ chế độ sáng | CẦN LÀM: chưa có `lib/core/theme/` và Poppins | ĐẠT khi hoàn thành Phase nền (R11) |
| Phụ thuộc mới phải có lý do | ĐẠT: không thêm phụ thuộc runtime; công cụ Node cho rules/seed đã giải thích ở R10, R12 | ĐẠT |

Không có vi phạm cần biện minh.

## Quyết định kiến trúc

Chi tiết và phương án đã cân nhắc ở [research.md](research.md).

1. **Rules và phi chuẩn hóa (R1, R2)**: món đọc công khai khi `isPublished && isCategoryPublished`, bất kể `isAvailable`. Ai đổi danh mục phải đồng bộ hai trường trên mọi món của danh mục trong cùng batch.
2. **Một truy vấn cho "Tất cả" (R3)**: sắp xếp theo `categorySortOrder, categoryId, sortOrder, name`; gom nhóm ở ViewModel; tải dần bằng cách tăng `limit` theo bước 20 trên luồng realtime. Mỗi khóa (`categoryId`, `limit`) là một provider `autoDispose`, nên luồng cũ tự đóng khi không còn được dùng.
3. **Phổ biến (R4)**: truy vấn riêng `limit(5)` sắp theo đánh giá, lọc `reviewCount > 0` ở client.
4. **Ngoại tuyến (R5)**: `snapshots(includeMetadataChanges: true)` → `MenuFeed.isFromCache`.
5. **Giá (R6, R7)**: `PriceRange` tính ở domain từ `basePrice + priceDelta`; định dạng VND bằng hàm nội bộ.
6. **Giữ trạng thái khi điều hướng (R9)**: `Navigator.push`; ViewModel không `autoDispose` trong khi Home còn trong stack; `ScrollController` sống trong `State` của view.
7. **Emulator**: `bootstrap.dart` gọi `useFirestoreEmulator` khi có `--dart-define=USE_FIRESTORE_EMULATOR=true`. Trên web, khi có cờ này, Firebase dùng project demo `demo-ordering` (không cần ID thật) vì `flutterfire configure` chưa sinh cấu hình web.
8. **Giao diện theo mẫu Food Ninja (FR-015 – FR-019)**:
   - `lib/app/main_shell.dart`: `MainShell` với `IndexedStack` + thanh điều hướng dưới 4 mục (Trang chủ, Giỏ hàng, Đơn hàng, Tài khoản); mục chưa có tính năng dùng `ComingSoonView` (`lib/core/widgets/coming_soon_view.dart`). Chỉ số mục đang chọn là trạng thái giao diện thuần, giữ trong `State` của shell.
   - Trang chủ chia thành widget nhỏ trong `lib/features/menu/presentation/widgets/`: `home_header.dart` (tiêu đề + chuông), `home_search_bar.dart` (ô tìm kiếm chỉ đọc + nút lọc), `restaurant_banner.dart`, `category_card_list.dart` (thay `category_chip_bar.dart`), `popular_section.dart` (chuyển sang danh sách dọc).
   - Tên nhà hàng "Ngõ Chicken" đặt ở `lib/core/config/restaurant_info.dart` cho banner; dữ liệu thực đơn vẫn chỉ đến từ Firestore.
   - Biểu tượng danh mục chọn theo từ khóa trong tên danh mục (gà, cơm, mỳ, trà…) trong một hàm thuần của tầng giao diện; danh mục lạ dùng biểu tượng mặc định.
   - `FoodCard` theo hàng "Popular Menu": ảnh trái, tên + đánh giá + nhãn hết hàng ở giữa, giá căn phải.

## Cấu trúc dự án (Project Structure)

### Tài liệu (feature này)

```text
specs/002-browse-menu/
├── spec.md
├── plan.md              # Tệp này
├── research.md          # Phase 0
├── data-model.md        # Phase 1
├── quickstart.md        # Phase 1
├── contracts/
│   ├── menu_repository.md
│   ├── firestore_menu_access.md
│   └── home_screen_ui.md
├── checklists/requirements.md
└── tasks.md             # Phase 2 (/speckit-tasks, chưa tạo)
```

### Mã nguồn (gốc repository)

```text
lib/
├── main.dart                                  # Sửa: gọi bootstrap, bỏ ứng dụng đếm số
├── app/
│   ├── app.dart                               # Mới: MaterialApp, AppTheme.light, ThemeMode.light
│   └── bootstrap.dart                         # Mới: Firebase.initializeApp, emulator tùy chọn, ProviderScope
├── core/
│   ├── firebase/                              # Có sẵn
│   ├── theme/                                 # Mới
│   │   ├── app_colors.dart
│   │   ├── app_gradients.dart
│   │   ├── app_radii.dart
│   │   ├── app_shadows.dart
│   │   ├── app_spacing.dart
│   │   ├── app_text_styles.dart
│   │   └── app_theme.dart
│   ├── utils/vnd_format.dart                  # Mới
│   └── widgets/                               # Mới
│       ├── app_loading_view.dart
│       ├── app_empty_view.dart
│       ├── app_error_view.dart
│       ├── offline_banner.dart
│       └── food_card.dart
└── features/menu/
    ├── domain/
    │   ├── entities/menu_item.dart            # Sửa: sizes, trường phi chuẩn hóa, priceRange
    │   ├── entities/menu_category.dart        # Mới
    │   ├── entities/menu_option.dart          # Mới
    │   ├── entities/price_range.dart          # Mới
    │   ├── entities/menu_feed.dart            # Mới
    │   ├── entities/menu_failure.dart         # Mới
    │   └── repositories/menu_repository.dart  # Sửa theo contracts/menu_repository.md
    ├── data/
    │   ├── models/menu_item_model.dart        # Sửa: fromMap, sizes, trường mới, bỏ qua tài liệu lỗi
    │   ├── models/menu_category_model.dart    # Mới
    │   └── repositories/firestore_menu_repository.dart  # Sửa: 4 luồng, metadata, ánh xạ lỗi
    └── presentation/
        ├── viewmodels/menu_providers.dart     # Sửa: provider repository và luồng
        ├── viewmodels/home_menu_state.dart    # Mới
        ├── viewmodels/home_menu_view_model.dart  # Mới
        ├── views/home_view.dart               # Mới
        ├── views/menu_item_detail_view.dart   # Mới (tối thiểu, đích điều hướng)
        └── widgets/
            ├── category_chip_bar.dart
            ├── popular_section.dart
            └── menu_section_list.dart

assets/fonts/Poppins-{Regular,Medium,SemiBold,Bold}.ttf   # Mới, khai báo trong pubspec.yaml

test/
├── core/utils/vnd_format_test.dart
├── features/menu/domain/price_range_test.dart
├── features/menu/data/menu_item_model_test.dart
├── features/menu/presentation/home_menu_view_model_test.dart
├── features/menu/presentation/home_view_test.dart
├── features/menu/presentation/food_card_test.dart
├── support/fake_menu_repository.dart
└── widget_test.dart                            # Sửa: smoke test app mới

tests/firestore_rules/                          # Mới: package.json, menu_rules.test.mjs
tools/seed_menu/                                # Mới: package.json, seed.js, menu_seed.json

firestore.rules                                 # Sửa theo contracts/firestore_menu_access.md
firestore.indexes.json                          # Sửa: 4 chỉ mục menu mới
docs/database_schema.md                         # Sửa: trường mới, quyền đọc, bất biến phi chuẩn hóa
```

**Quyết định cấu trúc**: Giữ MVVM theo feature như `AGENTS.md`. Mọi mã duyệt thực đơn nằm trong `lib/features/menu/`; token và widget dùng chung nằm trong `lib/core/`.

## Thứ tự thực hiện gợi ý (đầu vào cho /speckit-tasks)

1. **Nền**: theme token, Poppins, `app.dart`/`bootstrap.dart`, widget trạng thái dùng chung, `vnd_format`.
2. **Dữ liệu và bảo mật**: cập nhật `docs/database_schema.md`, rules, chỉ mục, script seed, kiểm thử rules R1–R9.
3. **US1 (P1)**: domain + repository (danh mục, "Tất cả", phổ biến) → ViewModel → Home với mọi trạng thái.
4. **US2 (P1)**: chọn danh mục, danh mục trống, danh mục bị gỡ khi đang chọn.
5. **US3 (P2)**: kiểm chứng realtime và nhãn ngoại tuyến.
6. **US4 (P2)**: màn hình chi tiết tối thiểu và giữ trạng thái khi quay lại.
7. **Hoàn thiện**: kiểm tra 320 dp và 1,3×, `dart format`, `flutter analyze`, `flutter test`, kiểm thử rules.

## Rủi ro và việc kéo theo

- **Đồng bộ phi chuẩn hóa**: Màn hình quản lý danh mục (User Story 7 của đặc tả gốc) phải cập nhật `isCategoryPublished` và `categorySortOrder` trên mọi món trong cùng batch. Nếu quên, món sẽ hiện sai nhóm hoặc bị ẩn sai.
- **Dữ liệu cũ**: Tài liệu `menu_items` thiếu `isCategoryPublished` sẽ không đọc được công khai. Script seed và mọi dữ liệu thật phải có đủ trường.
- **Script kiểm tra speckit**: `check-prerequisites.ps1` báo lỗi vì nhánh `linh` không theo mẫu `NNN-tên`. Feature được xác định qua `.specify/feature.json`.
- **Màn hình chi tiết**: chỉ là bản tối thiểu; feature chi tiết món (FR-009 gốc) sẽ thay thế mà vẫn giữ route và tham số `menuItemId`.

## Theo dõi độ phức tạp (Complexity Tracking)

Không có vi phạm constitution cần biện minh.
