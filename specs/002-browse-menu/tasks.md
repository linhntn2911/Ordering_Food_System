---
description: "Danh sách task triển khai tính năng Duyệt thực đơn"
---

# Tasks: Duyệt thực đơn

**Input**: Tài liệu thiết kế trong `specs/002-browse-menu/`

**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md), [data-model.md](data-model.md), [contracts/](contracts/), [quickstart.md](quickstart.md)

**Tests**: Có. Constitution (nguyên tắc V) và `AGENTS.md` bắt buộc unit test cho domain/ViewModel, widget test cho trạng thái màn hình và kiểm chứng rules bằng Emulator.

**Organization**: Task được nhóm theo user story để mỗi story triển khai và kiểm thử độc lập.

## Định dạng: `[ID] [P?] [Story] Mô tả`

- **[P]**: Chạy song song được (khác tệp, không phụ thuộc task chưa xong)
- **[Story]**: User story của task (US1, US2, US3, US4)
- Mọi đường dẫn tính từ gốc repository

---

## Phase 1: Setup (Hạ tầng dùng chung)

**Mục đích**: Chuẩn bị font, công cụ kiểm thử rules và công cụ dữ liệu mẫu.

- [X] T001 Tải Poppins Regular (400), Medium (500), SemiBold (600), Bold (700) từ Google Fonts (giấy phép OFL) vào `assets/fonts/` với tên `Poppins-Regular.ttf`, `Poppins-Medium.ttf`, `Poppins-SemiBold.ttf`, `Poppins-Bold.ttf`, kèm `assets/fonts/OFL.txt`; khai báo family `Poppins` với đủ 4 weight trong mục `flutter: fonts:` của `pubspec.yaml`, rồi chạy `flutter pub get`
- [X] T002 [P] Tạo `tests/firestore_rules/package.json` (type `module`, devDependencies `@firebase/rules-unit-testing`, `firebase`; script `test` = `firebase emulators:exec --only firestore --project demo-ordering "node --test"`) và thêm `tests/firestore_rules/node_modules/` vào `.gitignore`
- [X] T003 [P] Tạo `tools/seed_menu/package.json` (type `module`, dependency `firebase-admin`; script `seed` = `node seed.js`) và thêm `tools/seed_menu/node_modules/` vào `.gitignore`

---

## Phase 2: Foundational (Điều kiện tiên quyết, chặn mọi user story)

**Mục đích**: Theme chỉ chế độ sáng, app shell, widget trạng thái dùng chung, schema/rules/chỉ mục, entity domain và contract repository.

**⚠️ QUAN TRỌNG**: Chưa xong phase này thì không bắt đầu user story nào.

### Theme và app shell

- [X] T004 [P] Tạo `lib/core/theme/app_colors.dart`: lớp `AppColors` với các hằng `Color` đúng bảng màu trong `docs/design_system.md` (`primaryStart`, `primaryEnd`, `primarySolid`, `primarySoft`, `primaryTint`, `info`, `background`, `surface`, `textPrimary`, `textSecondary`, `textMuted`, `border`, `surfaceMuted`, `warning`, `warningMedium`, `warningSoft`, `warningSurface`, `foodAccentDark`, `foodAccent`, `foodAccentSoft`, `foodAccentMuted`, `error`, `errorSoft`, `success`, `successSoft`, `scrim`)
- [X] T005 [P] Tạo `lib/core/theme/app_gradients.dart` (`AppGradients.primary` từ `#53E88B` sang `#15BE77`, trái sang phải), `lib/core/theme/app_radii.dart` (`small 8`, `medium 12`, `input 15`, `card 16`, `large 20`, `dialog 24`, `pill 999`), `lib/core/theme/app_shadows.dart` (`card`, `primary` đúng giá trị trong `docs/design_system.md`) và `lib/core/theme/app_spacing.dart` (`xs 4`, `sm 8`, `md 12`, `lg 16`, `xl 20`, `xxl 24`, `xxxl 32`, `huge 40`, cùng `screenHorizontal(double width)` trả 16 khi `width < 360`, ngược lại 24)
- [X] T006 [P] Tạo `lib/core/theme/app_text_styles.dart`: `AppTextStyles` với family `Poppins` và 10 kiểu chữ trong bảng Typography của `docs/design_system.md` (cỡ, weight, line height), màu mặc định `AppColors.textPrimary`; thêm `price` (weight 700, `FontFeature.tabularFigures()`)
- [X] T007 Tạo `lib/core/theme/app_theme.dart`: `AppTheme.light` (`ThemeData` `Brightness.light`, `fontFamily: 'Poppins'`, `textTheme` từ `AppTextStyles`, `scaffoldBackgroundColor: AppColors.background`, `AppBarTheme` nền trắng, không elevation, `SystemUiOverlayStyle.dark`; `ChipThemeData` chọn = `primarySoft` + chữ `primaryEnd`; `SnackBarThemeData` sáng). Không tạo `darkTheme` (phụ thuộc T004–T006)
- [X] T008 Tạo `lib/app/bootstrap.dart`: hàm `Future<void> bootstrap()` gọi `WidgetsFlutterBinding.ensureInitialized()`, `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`, nếu `const bool.fromEnvironment('USE_FIRESTORE_EMULATOR')` thì `FirebaseFirestore.instance.useFirestoreEmulator(host, 8080)` (host `10.0.2.2` trên Android, `localhost` nơi khác), rồi `runApp(const ProviderScope(child: App()))`
- [X] T009 Tạo `lib/app/app.dart`: `App` (`StatelessWidget`) trả `MaterialApp(title: 'Food Ninja', theme: AppTheme.light, themeMode: ThemeMode.light, home: ...)` với `home` tạm là một `Scaffold` rỗng (US1 sẽ thay bằng `HomeView`); sửa `lib/main.dart` chỉ còn `Future<void> main() => bootstrap();` và xóa toàn bộ mã ứng dụng đếm số (phụ thuộc T007, T008)
- [X] T010 Sửa `test/widget_test.dart` thành smoke test bơm `ProviderScope(child: App())` và kiểm tra `MaterialApp` dùng `ThemeMode.light` và `darkTheme == null` (phụ thuộc T009)

### Widget và tiện ích dùng chung

- [X] T011 [P] Tạo `lib/core/utils/vnd_format.dart`: `String formatVnd(int amount)` → `45.000 ₫` (nhóm nghìn bằng dấu chấm, khoảng trắng không ngắt trước `₫`) và `String formatVndRange(int min, int max)` → `45.000 – 65.000 ₫` hoặc một giá khi `min == max`; viết test trong `test/core/utils/vnd_format_test.dart` (0, 999, 1000, 45000, 1250000, khoảng bằng nhau, khoảng khác nhau)
- [X] T012 [P] Tạo `lib/core/widgets/app_loading_view.dart`, `lib/core/widgets/app_empty_view.dart` (`title`, `message`, tùy chọn `actionLabel` + `onAction`) và `lib/core/widgets/app_error_view.dart` (`message`, `onRetry` bắt buộc, nút "Thử lại" ≥ 48 dp), chỉ dùng token trong `lib/core/theme/`
- [X] T013 [P] Tạo `lib/core/widgets/offline_banner.dart`: dải thông báo "Đang ngoại tuyến – dữ liệu có thể chưa cập nhật" nền `warningSurface`, chữ `textPrimary`, có biểu tượng và `Semantics(liveRegion: true)`

### Schema, rules, chỉ mục, dữ liệu mẫu

- [X] T014 [P] Cập nhật `docs/database_schema.md` mục `menu_items`: thêm `isCategoryPublished` (bool) và `categorySortOrder` (int), mô tả `sizes`/`toppings` là `{ id, name, priceDelta }`, thay câu "Published and available items are publicly readable" bằng quy tắc đọc trong `specs/002-browse-menu/data-model.md`, thêm bất biến phi chuẩn hóa (đổi danh mục phải cập nhật mọi món trong cùng batch); đồng thời cập nhật FR-007 trong `SPEC.md` và `specs/001-food-ordering-system/spec.md` thành "Guests and Customers MUST be able to browse published categories and published menu items; unavailable items remain visible with a sold-out label (see `specs/002-browse-menu/spec.md`)", không đổi các FR khác
- [X] T015 [P] Sửa khối `match /menu_items/{menuItemId}` trong `firestore.rules` đúng như `specs/002-browse-menu/contracts/firestore_menu_access.md` (đọc công khai khi `isPublished == true && isCategoryPublished == true`, bỏ điều kiện `isAvailable`)
- [X] T016 [P] Trong `firestore.indexes.json`, xóa hai chỉ mục `menu_items` cũ có `isAvailable` và thêm 4 chỉ mục (danh mục; món – Tất cả; món – theo danh mục; phổ biến) đúng bảng trong `specs/002-browse-menu/contracts/firestore_menu_access.md`
- [X] T017 Viết `tests/firestore_rules/menu_rules.test.mjs` dùng `initializeTestEnvironment` với `firestore.rules`, nạp dữ liệu bằng `withSecurityRulesDisabled`, cài đặt đủ 9 ca R1–R9 trong `specs/002-browse-menu/contracts/firestore_menu_access.md` (Admin là `users/{uid}` có `role: 'admin'`, `status: 'active'`); chạy `npm test` trong `tests/firestore_rules/` và mọi ca phải đạt (phụ thuộc T002, T015)
- [X] T018 [P] Tạo `tools/seed_menu/menu_seed.json` (3 danh mục đã đăng bán trong đó 1 danh mục không có món, 1 danh mục chưa đăng bán; ít nhất 14 món gồm còn hàng, hết hàng, chưa đăng bán, thuộc danh mục chưa đăng bán, có 2–3 size khác `priceDelta`, một giá, có `reviewCount > 0`, `reviewCount == 0`, hai món trùng `sortOrder`, một món tên rất dài, một món `imageUrl` rỗng; đủ 25 món trong một danh mục để thử tải dần) và `tools/seed_menu/seed.js` (dùng `firebase-admin`, từ chối chạy khi thiếu `FIRESTORE_EMULATOR_HOST` trừ khi có cờ `--allow-production`; tự điền `isCategoryPublished`, `categorySortOrder` từ danh mục, `createdAt`/`updatedAt` bằng server timestamp) (phụ thuộc T003)

### Domain và contract

- [X] T019 [P] Tạo các entity bất biến trong `lib/features/menu/domain/entities/`: `menu_option.dart` (`MenuOption`: `id`, `name`, `priceDelta`), `price_range.dart` (`PriceRange`: `min`, `max`, `isSingle`; factory `PriceRange.of(int basePrice, List<MenuOption> sizes)`), `menu_category.dart` (`MenuCategory`: `id`, `name`, `imageUrl`, `sortOrder`), `menu_feed.dart` (`MenuFeed<T>`: `items` không sửa đổi được, `isFromCache`, `hasMore`), `menu_failure.dart` (`MenuFailure` với `MenuFailureType.permissionDenied | unavailable | unknown`)
- [X] T020 Mở rộng `lib/features/menu/domain/entities/menu_item.dart`: thêm `sizes` (`List<MenuOption>`, bọc `List.unmodifiable`), `isCategoryPublished`, `categorySortOrder`, getter `priceRange` (dùng `PriceRange.of`) và `hasRating` (`reviewCount > 0`) (phụ thuộc T019)
- [X] T021 [P] Viết `test/features/menu/domain/price_range_test.dart`: không có size → một giá bằng `basePrice`; mọi size cùng `priceDelta` → một giá; size `0/10000/20000` trên `basePrice 45000` → `45000–65000`; thứ tự size không ảnh hưởng (phụ thuộc T019)
- [X] T022 Thay `lib/features/menu/domain/repositories/menu_repository.dart` bằng giao diện 4 phương thức trong `specs/002-browse-menu/contracts/menu_repository.md` (`watchPublishedCategories`, `watchBrowsableItems`, `watchPopularItems`, `watchItem`), kèm doc comment hành vi C1–C6 (phụ thuộc T019, T020)
- [X] T023 Tạo `test/support/fake_menu_repository.dart`: `FakeMenuRepository implements MenuRepository` dùng `StreamController.broadcast` cho từng luồng, có các hàm `emitCategories`, `emitItems({String? categoryId})`, `emitPopular`, `emitItem`, `emitError`, ghi lại mọi `limit` và `categoryId` đã yêu cầu để test kiểm tra (phụ thuộc T022)

**Checkpoint**: App chạy được với theme sáng, rules và chỉ mục đã cập nhật, kiểm thử rules đạt, contract repository sẵn sàng.

---

## Phase 3: User Story 1 - Duyệt thực đơn từ Trang chủ (Priority: P1) 🎯 MVP

**Goal**: Guest hoặc Customer mở app thấy mục "Phổ biến", danh mục đã đăng bán và mọi món đủ điều kiện gom theo danh mục, có đủ trạng thái tải/trống/lỗi và tải dần.

**Independent Test**: Nạp `tools/seed_menu`, mở app chưa đăng nhập: thấy đúng danh mục đã đăng bán, các nhóm món theo thứ tự danh mục, món hết hàng có nhãn, khoảng giá đúng, mục "Phổ biến" ≤ 10 món còn hàng có đánh giá; không thấy món/danh mục chưa đăng bán (US1 kịch bản 1–8).

### Tests cho User Story 1

- [X] T024 [P] [US1] Viết `test/features/menu/data/menu_item_model_test.dart` cho `MenuItemModel.fromMap`: đọc đủ trường mới; thiếu `sizes`/`ratingAverage`/`reviewCount` → mặc định (C6); `sizes` có phần tử sai kiểu → bỏ phần tử đó; thiếu `name` hoặc `basePrice` → `FormatException`; và `MenuCategoryModel.fromMap` tương tự
- [X] T025 [P] [US1] Viết `test/features/menu/presentation/home_menu_view_model_test.dart` (dùng `ProviderContainer` với `menuRepositoryProvider.overrideWithValue(FakeMenuRepository())`): ban đầu `loading`; có dữ liệu → `data` với `sections` gom theo `categoryId` đúng thứ tự; danh mục không có món không tạo nhóm; không có danh mục/món từ máy chủ → `empty`; lỗi luồng → `error`, `retry()` → `loading` rồi `data`; `popular` rỗng khi không có món đủ điều kiện; `loadMore()` tăng `limit` 20 → 40 và không gọi khi `hasMore == false` hoặc đang tải; trong lúc chờ snapshot mới sau `loadMore()` thì `sections` giữ nguyên và `status` vẫn là `data`; món có `categoryId` không có trong danh sách danh mục không tạo nhóm và không xuất hiện trong `popular`
- [X] T026 [P] [US1] Viết `test/features/menu/presentation/food_card_test.dart`: hiện tên, giá một giá, khoảng giá, "4,6 (23)", "Chưa có đánh giá", nhãn "Hết hàng" khi `isAvailable == false`, ảnh thay thế khi `imageUrl` rỗng, nhãn ngữ nghĩa gồm tên + giá + tình trạng, vùng chạm ≥ 48 dp
- [X] T027 [P] [US1] Viết `test/features/menu/presentation/home_view_test.dart`: với `FakeMenuRepository`, kiểm tra Home hiện skeleton khi tải, "Thực đơn chưa sẵn sàng" khi trống, `AppErrorView` + "Thử lại" khi lỗi, tiêu đề nhóm danh mục và mục "Phổ biến" khi có dữ liệu, mục "Phổ biến" bị ẩn khi rỗng

### Implementation cho User Story 1

- [X] T028 [P] [US1] Sửa `lib/features/menu/data/models/menu_item_model.dart`: thêm `MenuItemModel.fromMap(String id, Map<String, dynamic> data)` (để `fromFirestore` gọi lại), đọc `sizes` thành `List<MenuOption>`, `isCategoryPublished`, `categorySortOrder`, cập nhật `toFirestore` và `toEntity`
- [X] T029 [P] [US1] Tạo `lib/features/menu/data/models/menu_category_model.dart`: `MenuCategoryModel` với `fromMap`, `fromFirestore`, `toEntity`; `name` bắt buộc, `sortOrder` mặc định 0
- [X] T030 [US1] Viết lại `lib/features/menu/data/repositories/firestore_menu_repository.dart`: `watchPublishedCategories` (`isPublished == true`, `orderBy sortOrder, name`, `limit`); `watchBrowsableItems` khi `categoryId == null` (`isPublished == true`, `isCategoryPublished == true`, `orderBy categorySortOrder, categoryId, sortOrder, name`, `limit`); `watchPopularItems` (thêm `isAvailable == true`, `orderBy ratingAverage desc, reviewCount desc, name`, `limit`, rồi bỏ `reviewCount == 0`); mọi luồng dùng `snapshots(includeMetadataChanges: true)` → `MenuFeed` (`isFromCache` từ metadata, `hasMore` theo C4); bỏ qua tài liệu ném `FormatException`; ánh xạ `FirebaseException` `permission-denied` / `unavailable` / khác thành `MenuFailure`; kiểm tra `limit` 1–100 (phụ thuộc T022, T028, T029)
- [X] T031 [US1] Sửa `lib/features/menu/presentation/viewmodels/menu_providers.dart`: giữ `menuRepositoryProvider`; xóa `publishedMenuProvider` cũ; thêm `menuCategoriesProvider` (`StreamProvider.autoDispose<MenuFeed<MenuCategory>>`), `browsableItemsProvider` (`StreamProvider.autoDispose.family` theo record `({String? categoryId, int limit})`) và `popularItemsProvider` (`StreamProvider.autoDispose`); `HomeMenuViewModel` giữ cho các provider đang dùng luôn sống bằng `ref.watch` (phụ thuộc T030)
- [X] T032 [US1] Tạo `lib/features/menu/presentation/viewmodels/home_menu_state.dart`: `HomeMenuStatus` (`loading`, `data`, `empty`, `error`), `MenuSection` (`categoryId`, `title`, `items`), `HomeMenuNotice` (`categoryRemoved`), `HomeMenuState` bất biến với đủ trường trong `specs/002-browse-menu/data-model.md` và `copyWith` (danh sách bọc `List.unmodifiable`)
- [X] T033 [US1] Tạo `lib/features/menu/presentation/viewmodels/home_menu_view_model.dart`: `HomeMenuViewModel extends Notifier<HomeMenuState>` (không `autoDispose`) và `homeMenuViewModelProvider`; `build()` `ref.watch` ba provider ở T031 với `limit` hiện tại (khởi tạo 20) và gộp thành `HomeMenuState` theo phần "Chuyển trạng thái" của `data-model.md`; gom món liên tiếp cùng `categoryId` thành `MenuSection` với tiêu đề lấy từ danh sách danh mục; bỏ qua mọi món có `categoryId` không có trong danh sách danh mục hiện tại (cả nhóm lẫn "Phổ biến"); khi `limit` tăng thì giữ `sections` cũ, đặt `isLoadingMore = true`, giữ `status == data` tới khi có snapshot mới, lỗi khi tải thêm chỉ tắt `isLoadingMore` mà không chuyển cả màn hình sang `error`; phương thức `loadMore()` (+20, chặn khi `!hasMore` hoặc `isLoadingMore`) và `retry()` (`ref.invalidate` các provider) (phụ thuộc T031, T032)
- [X] T034 [P] [US1] Tạo `lib/core/widgets/food_card.dart` đúng `specs/002-browse-menu/contracts/home_screen_ui.md` mục "Thẻ món": nhận `MenuItem` và `VoidCallback? onTap`, dùng `formatVndRange`, ảnh `Image.network` có `errorBuilder` và ảnh thay thế, tên tối đa 2 dòng, giá được xuống dòng, nhãn "Hết hàng" (`error` trên `errorSoft`), `Semantics(button: true, label: ...)`, `ConstrainedBox(minHeight: 48)`, bo góc `AppRadii.card`, bóng `AppShadows.card`
- [X] T035 [P] [US1] Tạo `lib/features/menu/presentation/widgets/popular_section.dart`: tiêu đề "Phổ biến" + `ListView` cuộn ngang các `FoodCard` (chiều rộng thẻ cố định theo token), trả `SizedBox.shrink()` khi danh sách rỗng
- [X] T036 [P] [US1] Tạo `lib/features/menu/presentation/widgets/menu_section_list.dart`: sliver hiển thị danh sách `MenuSection`; hiện tiêu đề nhóm khi `showHeaders == true`; chỉ báo tải thêm ở cuối khi `isLoadingMore`
- [X] T037 [US1] Tạo `lib/features/menu/presentation/views/home_view.dart` (`ConsumerStatefulWidget`): `CustomScrollView` với `ScrollController` sống trong `State`; padding ngang `AppSpacing.screenHorizontal`; theo `HomeMenuState.status` hiện `AppLoadingView` (skeleton), `AppEmptyView` ("Thực đơn chưa sẵn sàng"), `AppErrorView` (`onRetry` → `retry()`), hoặc `PopularSection` + `MenuSectionList`; gọi `loadMore()` khi cuộn còn cách đáy < 400 px; không chứa logic nghiệp vụ (phụ thuộc T033–T036)
- [X] T038 [US1] Đặt `home: const HomeView()` trong `lib/app/app.dart` và cập nhật `test/widget_test.dart` override `menuRepositoryProvider` bằng `FakeMenuRepository` (phụ thuộc T037)

**Checkpoint**: Trang chủ duyệt được toàn bộ thực đơn; T024–T027 đạt; kiểm tra thủ công dòng 1–4 trong `quickstart.md`.

---

## Phase 4: User Story 2 - Duyệt món theo danh mục (Priority: P1)

**Goal**: Chọn một danh mục để chỉ xem món của danh mục đó, chọn "Tất cả" để quay lại, xử lý danh mục trống và danh mục bị gỡ khi đang chọn.

**Independent Test**: Chọn lần lượt từng danh mục mẫu: chỉ thấy món của danh mục đó; danh mục không có món hiện trạng thái trống kèm nút quay về; gỡ đăng bán danh mục đang chọn trên Emulator UI (cập nhật cả `isCategoryPublished` của món) thì quay về "Tất cả" kèm SnackBar (US2 kịch bản 1–4).

### Tests cho User Story 2

- [X] T039 [P] [US2] Bổ sung `test/features/menu/presentation/home_menu_view_model_test.dart`: `selectCategory(id)` yêu cầu `watchBrowsableItems(categoryId: id, limit: 20)` và trả một `MenuSection` không tiêu đề; danh mục không có món → `data` với nhóm rỗng; `selectCategory(null)` quay về gom nhóm; đổi danh mục đặt lại `limit` về 20; danh mục đang chọn biến khỏi luồng danh mục → `selectedCategoryId == null` và `notice == categoryRemoved`; `clearNotice()` xóa thông báo
- [X] T040 [P] [US2] Bổ sung `test/features/menu/presentation/home_view_test.dart`: chạm chip danh mục hiện đúng món; chip "Tất cả" luôn ở đầu; danh mục trống hiện "Danh mục này chưa có món" và nút "Xem tất cả món" đưa về "Tất cả"; thông báo `categoryRemoved` hiện SnackBar "Danh mục này không còn được bán"

### Implementation cho User Story 2

- [X] T041 [US2] Bổ sung nhánh `categoryId != null` trong `watchBrowsableItems` của `lib/features/menu/data/repositories/firestore_menu_repository.dart` (`categoryId ==`, `isPublished == true`, `isCategoryPublished == true`, `orderBy sortOrder, name`, `limit`)
- [X] T042 [US2] Thêm vào `lib/features/menu/presentation/viewmodels/home_menu_view_model.dart`: `selectCategory(String? categoryId)` (đặt lại `limit` 20), phát hiện danh mục đang chọn không còn trong `menuCategoriesProvider` → về `null` và đặt `notice`, `clearNotice()`; trạng thái danh mục trống là `data` với một nhóm rỗng (phụ thuộc T041)
- [X] T043 [P] [US2] Tạo `lib/features/menu/presentation/widgets/category_chip_bar.dart`: hàng chip cuộn ngang "Tất cả" + danh mục, một chip được chọn (`primarySoft` + chữ `primaryEnd`), mỗi chip ≥ 48 dp và có `Semantics(selected: ...)`
- [X] T044 [US2] Tích hợp vào `lib/features/menu/presentation/views/home_view.dart`: đặt `CategoryChipBar` dưới mục "Phổ biến", gọi `selectCategory`; khi danh mục đang chọn rỗng hiện `AppEmptyView` với nút "Xem tất cả món"; `ref.listen` trên `notice` để hiện SnackBar rồi gọi `clearNotice()`; cuộn danh sách món về đầu khi đổi danh mục (phụ thuộc T042, T043)

**Checkpoint**: US1 và US2 cùng hoạt động; dòng 5 và 7 trong `quickstart.md` đạt.

---

## Phase 5: User Story 3 - Thấy thay đổi thực đơn mà không cần làm mới (Priority: P2)

**Goal**: Thay đổi từ Admin hiện ngay trên màn hình đang mở; khi mất mạng hiện thực đơn đã lưu kèm nhãn ngoại tuyến, nhãn tự tắt khi có mạng lại.

**Independent Test**: Mở Home, trên Emulator UI đổi giá một món, đăng bán một món mới, đánh dấu một món hết hàng, gỡ đăng bán một món: mọi thay đổi hiện trong ≤ 5 giây; tắt Emulator rồi mở lại app: thực đơn cũ kèm nhãn ngoại tuyến; bật lại: nhãn tắt (US3 kịch bản 1–3, FR-014, SC-004, SC-008).

### Tests cho User Story 3

- [X] T045 [P] [US3] Bổ sung `test/features/menu/presentation/home_menu_view_model_test.dart`: phát snapshot mới với giá đổi / món mới / `isAvailable == false` / món bị loại → state cập nhật tương ứng mà không gọi `retry()`; món hết hàng rời `popular` nhưng vẫn ở `sections`; snapshot cache rồi tới snapshot máy chủ trong vòng 2 giây → `isOffline` luôn `false`; `isFromCache == true` kéo dài quá 2 giây → `isOffline == true`; snapshot máy chủ tiếp theo → `isOffline == false`; cache rỗng khi chưa từng có snapshot máy chủ → `loading` trong 2 giây đầu, sau đó `error` với `MenuFailureType.unavailable`
- [X] T046 [P] [US3] Bổ sung `test/features/menu/presentation/home_view_test.dart`: `OfflineBanner` hiện khi `isOffline` và biến mất khi trở lại trực tuyến; trạng thái lỗi ngoại tuyến có nút "Thử lại"

### Implementation cho User Story 3

- [X] T047 [US3] Trong `lib/features/menu/presentation/viewmodels/home_menu_view_model.dart`: `isOffline` chỉ bật khi ít nhất một luồng có `isFromCache == true` liên tục quá `offlineGrace` (mặc định 2 giây, cung cấp qua provider để test thay được), tắt ngay khi nhận snapshot máy chủ; theo dõi đã từng nhận snapshot máy chủ hay chưa; cache rỗng khi chưa từng có snapshot máy chủ → giữ `loading` trong `offlineGrace`, sau đó `status = error` với `MenuFailure(unavailable)` thay vì `empty`
- [X] T048 [US3] Trong `lib/features/menu/presentation/views/home_view.dart`: hiện `OfflineBanner` ở đầu `CustomScrollView` khi `state.isOffline`, kể cả khi đang hiện dữ liệu (phụ thuộc T047)

**Checkpoint**: Dòng 6, 9 và 10 trong `quickstart.md` đạt.

---

## Phase 6: User Story 4 - Mở một món từ thực đơn (Priority: P2)

**Goal**: Chạm một món để mở chi tiết; quay lại giữ nguyên danh mục và vị trí cuộn.

**Independent Test**: Chọn một danh mục, cuộn xuống, chạm một món (kể cả món hết hàng): mở đúng món; quay lại: vẫn đúng danh mục và vị trí cuộn (US4 kịch bản 1–2).

### Tests cho User Story 4

- [X] T049 [P] [US4] Viết `test/features/menu/presentation/menu_item_detail_view_test.dart`: hiện tên, ảnh, giá hoặc khoảng giá; món hết hàng hiện "Hết hàng – chưa thể thêm vào giỏ"; `watchItem` phát `null` → thông báo "Món này không còn được bán" và nút quay lại
- [X] T050 [P] [US4] Bổ sung `test/features/menu/presentation/home_view_test.dart`: chạm `FoodCard` mở `MenuItemDetailView` với đúng `menuItemId`; `Navigator.pop` quay về với chip đang chọn và `ScrollController.offset` không đổi

### Implementation cho User Story 4

- [X] T051 [US4] Cài `watchItem(String menuItemId)` trong `lib/features/menu/data/repositories/firestore_menu_repository.dart` (`doc(id).snapshots()`, tài liệu không tồn tại hoặc `permission-denied` → phát `null`) và thêm `menuItemProvider` (`StreamProvider.autoDispose.family<MenuItem?, String>`) vào `lib/features/menu/presentation/viewmodels/menu_providers.dart`
- [X] T052 [US4] Tạo `lib/features/menu/presentation/views/menu_item_detail_view.dart` (`ConsumerWidget`, tham số `menuItemId`): màn hình tối thiểu hiện ảnh, tên, mô tả, giá/khoảng giá, nhãn "Hết hàng – chưa thể thêm vào giỏ" khi hết hàng; trạng thái tải, lỗi, không còn bán; không có nút thêm vào giỏ (thuộc feature khác) (phụ thuộc T051)
- [X] T053 [US4] Trong `lib/features/menu/presentation/views/home_view.dart`, truyền `onTap` cho `FoodCard` ở `PopularSection` và `MenuSectionList` để `Navigator.of(context).push(MaterialPageRoute(builder: (_) => MenuItemDetailView(menuItemId: item.id)))`; giữ `ScrollController` và `PageStorageKey` cho danh sách để không mất vị trí cuộn (phụ thuộc T052)

**Checkpoint**: Dòng 8 trong `quickstart.md` đạt; cả 4 user story hoạt động độc lập.

---

## Phase 7: Polish & Cross-Cutting Concerns

- [X] T054 [P] Viết `test/features/menu/presentation/home_layout_test.dart`: bơm Home với dữ liệu có tên rất dài và khoảng giá dài ở `Size(320, 640)` và `textScaler: TextScaler.linear(1.3)`, khẳng định không có `FlutterError` tràn bố cục và giá hiện đủ hai đầu (SC-006)
- [X] T055 [P] Thêm mục "Credits" ghi công Pixel True – Food Delivery UI Kit và giấy phép OFL của Poppins vào `README.md` (theo mục Attribution trong `docs/design_system.md`)
- [X] T056 Rà soát `lib/features/menu/` và `lib/core/widgets/` không còn mã màu hex, bán kính, cỡ chữ hay bóng tự đặt ngoài `lib/core/theme/` (tìm `Color(0x`, `BorderRadius.circular(` có số trực tiếp, `fontSize:`), không có `darkTheme`
- [X] T057 Chạy `dart format lib test`, `flutter analyze` (0 lỗi), `flutter test` (đạt hết) và `npm test` trong `tests/firestore_rules/` (R1–R9 đạt); ghi kết quả hoặc lý do không chạy được vào phần cuối của tệp này
- [ ] T058 Chạy toàn bộ bảng kiểm tra trong `specs/002-browse-menu/quickstart.md` trên Emulator với dữ liệu mẫu; ghi thời gian đo được cho SC-001 (trung bình 3 lần khởi động lạnh) và số lần chạm cho SC-002; đánh dấu từng dòng đạt/không đạt; cập nhật `**Trạng thái (Status)**` trong `specs/002-browse-menu/spec.md` khi mọi dòng đạt

---

## Phase 8: Giao diện theo mẫu Food Ninja và thực đơn Ngõ Chicken (FR-015 – FR-019)

**Goal**: Trang chủ theo khung Home của mẫu, thanh điều hướng dưới, dữ liệu mẫu là thực đơn Ngõ Chicken.

**Independent Test**: Nạp `tools/seed_menu` (Ngõ Chicken), mở app trên Chrome hoặc Android: thấy tiêu đề + chuông, ô tìm kiếm + nút lọc, banner, thẻ danh mục, "Phổ biến" ≤ 5 món dạng dọc, thực đơn gom nhóm và thanh điều hướng 4 mục (US1 kịch bản 9–11).

- [X] T059 [P] [US1] Sinh lại `tools/seed_menu/menu_seed.json` từ thực đơn Ngõ Chicken (6 danh mục, 28 món, đồ uống size M/L bằng `priceDelta`, 7 món có điểm đánh giá trình diễn, 2 món hết hàng, `restaurantName`) và cho `tools/seed_menu/seed.js` ghi `restaurant_configs/main`
- [X] T060 [P] [US1] Tạo `lib/core/config/restaurant_info.dart` (`RestaurantInfo.name = 'Ngõ Chicken'`, dòng giới thiệu) và `lib/core/widgets/coming_soon_view.dart` (màn chờ "Tính năng đang được phát triển" dùng token)
- [X] T061 [US1] Đổi giới hạn "Phổ biến" còn 5: mặc định `watchPopularItems({int limit = 5})` trong `lib/features/menu/domain/repositories/menu_repository.dart` và `lib/features/menu/data/repositories/firestore_menu_repository.dart`
- [X] T062 [P] [US1] Tạo `lib/features/menu/presentation/widgets/home_header.dart` (tiêu đề hai dòng `headlineLarge` + nút chuông tròn) và `lib/features/menu/presentation/widgets/home_search_bar.dart` (ô tìm kiếm chỉ đọc nền `warningSurface` + nút lọc), cả hai nhận callback `onUnavailableFeature`
- [X] T063 [P] [US1] Tạo `lib/features/menu/presentation/widgets/restaurant_banner.dart` (nền `AppGradients.primary`, tên và giới thiệu từ `RestaurantInfo`, nút "Mua ngay" gọi `onViewMenu`)
- [X] T064 [P] [US2] Tạo `lib/features/menu/presentation/widgets/category_card_list.dart` thay `category_chip_bar.dart`: thẻ "Tất cả" + thẻ danh mục cuộn ngang, biểu tượng chọn theo tên danh mục, thẻ chọn có nền `primarySoft` + viền `primaryEnd`, `Semantics(selected)`, key `category-chip-<id>`; xóa `category_chip_bar.dart`
- [X] T065 [US1] Viết lại `lib/core/widgets/food_card.dart` theo hàng "Popular Menu" (ảnh trái, tên + đánh giá + nhãn hết hàng giữa, giá căn phải được xuống dòng) và chuyển `lib/features/menu/presentation/widgets/popular_section.dart` sang danh sách dọc
- [X] T066 [US1] Ghép lại `lib/features/menu/presentation/views/home_view.dart` theo thứ tự ở `contracts/home_screen_ui.md`: header, tìm kiếm, nhãn ngoại tuyến, banner, danh mục (có `GlobalKey` để "Mua ngay" cuộn tới), "Phổ biến", thực đơn; ô tìm kiếm/lọc/chuông hiện SnackBar "Tính năng đang được phát triển"
- [X] T067 [US1] Tạo `lib/app/main_shell.dart` (`IndexedStack` + thanh điều hướng dưới 4 mục, mục khác Trang chủ dùng `ComingSoonView`) và đặt `home: const MainShell()` trong `lib/app/app.dart`
- [X] T068 [US1] Cập nhật test: `test/features/menu/presentation/home_view_test.dart` (bố cục US1-9, banner cuộn US1-10, SnackBar US1-11, thẻ danh mục thay chip), `test/features/menu/presentation/food_card_test.dart` (bố cục mới), `test/widget_test.dart` (thanh điều hướng 4 mục, chuyển mục giữ trạng thái Trang chủ), `test/features/menu/presentation/home_layout_test.dart` (320 dp, 1,3×)
- [ ] T069 Chạy `dart format lib test`, `flutter analyze`, `flutter test`; nạp dữ liệu Ngõ Chicken vào Emulator và chạy app trên Chrome để kiểm tra bằng mắt theo `quickstart.md`

---

## Dependencies & Execution Order

### Phụ thuộc giữa các phase

- **Setup (Phase 1)**: không phụ thuộc gì.
- **Foundational (Phase 2)**: sau Setup (T001 cần cho T006/T007, T002 cho T017, T003 cho T018). Chặn mọi user story.
- **US1 (Phase 3)**: sau Foundational. Là MVP.
- **US2 (Phase 4)**: sau US1 (dùng chung `HomeMenuViewModel`, `HomeView` và repository).
- **US3 (Phase 5)**: sau US1; độc lập với US2.
- **US4 (Phase 6)**: sau US1; độc lập với US2 và US3.
- **Polish (Phase 7)**: sau các story muốn phát hành.

### Thứ tự trong từng story

- Viết test trước và xác nhận test thất bại, rồi mới cài đặt.
- Model → repository → provider → state → ViewModel → widget → view.
- Các task sửa cùng tệp `home_menu_view_model.dart`, `home_view.dart`, `firestore_menu_repository.dart` không chạy song song với nhau.

### Biểu đồ hoàn thành

```text
Setup ─► Foundational ─► US1 (MVP) ─┬─► US2
                                    ├─► US3
                                    └─► US4
                                          └─► Polish (sau các story đã chọn)
```

## Parallel Opportunities

### Phase 2

```text
Cùng lúc: T004, T005, T006, T011, T012, T013, T014, T015, T016, T018, T019
Sau T019: T020 và T021 song song
```

### User Story 1

```text
Tests cùng lúc: T024, T025, T026, T027
Cài đặt cùng lúc: T028, T029, T034, T035, T036
Rồi tuần tự: T030 → T031 → T032 → T033 → T037 → T038
```

### Sau khi US1 xong

```text
US2 (T039–T044), US3 (T045–T048), US4 (T049–T053) có thể giao cho ba người khác nhau,
miễn là phối hợp khi sửa chung home_menu_view_model.dart và home_view.dart.
```

## Implementation Strategy

### MVP trước (chỉ User Story 1)

1. Xong Phase 1 và Phase 2 (gồm kiểm thử rules T017).
2. Xong Phase 3 (US1).
3. **Dừng và kiểm chứng**: dòng 1–4 trong `quickstart.md`, T024–T027 đạt.
4. Demo Trang chủ cho nhóm.

### Bàn giao tăng dần

1. Setup + Foundational → nền sẵn sàng.
2. US1 → kiểm thử độc lập → demo (MVP).
3. US2 → chọn danh mục → demo.
4. US3 → realtime và ngoại tuyến → demo.
5. US4 → mở chi tiết → demo.
6. Polish → kiểm tra bố cục, format, analyze, test, rules.

## Notes

- Không sửa tay các tệp `.g.dart`; feature này không dùng sinh mã Riverpod.
- Khi tính năng quản lý danh mục (User Story 7 của đặc tả gốc) được làm, nó phải đồng bộ `isCategoryPublished` và `categorySortOrder` trên mọi món của danh mục trong cùng batch (xem `docs/database_schema.md` sau T014).
- `check-prerequisites.ps1` báo lỗi vì nhánh `linh` không theo mẫu `NNN-tên`; thư mục feature được xác định qua `.specify/feature.json`.

## Kết quả kiểm tra (2026-10-20)

| Kiểm tra | Kết quả |
|---|---|
| `npm test` trong `tests/firestore_rules/` (R1–R10) | ĐẠT 10/10 trên Firestore Emulator |
| `node tools/seed_menu/seed.js` trên Emulator | ĐẠT: 4 danh mục, 33 món |
| `dart format lib test` | Đạt (chạy lại sau khi tìm được Flutter SDK) |
| `flutter analyze` | Không có lỗi |
| `flutter test` | Đạt (xem Phase 8: 61/61) |
| `quickstart.md` thủ công (T058) | CHƯA CHẠY: cần Flutter SDK và thiết bị Android |

Ghi chú: trên Windows, `firebase emulators:exec` để lại tiến trình Java của Emulator sau khi chạy xong; cần tắt thủ công nếu cổng 8080 bị chiếm. firebase-tools cảnh báo sẽ cần JDK 21+ (máy đang dùng JDK 17).

## Kết quả kiểm tra Phase 8 (2026-10-20)

| Kiểm tra | Kết quả |
|---|---|
| `dart format lib test` | Đạt |
| `flutter analyze` | Không có lỗi |
| `flutter test` | Đạt 61/61 |
| Nạp dữ liệu Ngõ Chicken vào Emulator (`demo-ordering`) | Đạt: 6 danh mục, 28 món |
| `flutter run -d chrome --dart-define=USE_FIRESTORE_EMULATOR=true` | Khởi động không lỗi; chờ người dùng kiểm tra bằng mắt (T069) |
