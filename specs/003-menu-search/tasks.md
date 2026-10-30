---
description: "Danh sách task triển khai tính năng Tìm kiếm và lọc thực đơn"
---

# Tasks: Tìm kiếm và lọc thực đơn

**Input**: Tài liệu thiết kế trong `specs/003-menu-search/`

**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md), [data-model.md](data-model.md), [contracts/](contracts/), [quickstart.md](quickstart.md)

**Tests**: Có. Constitution (nguyên tắc V) và `AGENTS.md` bắt buộc unit test cho domain/ViewModel, widget test cho trạng thái màn hình và kiểm chứng rules bằng Emulator.

**Organization**: Task được nhóm theo user story để mỗi story triển khai và kiểm thử độc lập.

## Định dạng: `[ID] [P?] [Story] Mô tả`

- **[P]**: Chạy song song được (khác tệp, không phụ thuộc task chưa xong)
- **[Story]**: User story của task (US1, US2, US3)
- Mọi đường dẫn tính từ gốc repository

---

## Phase 1: Setup (Hạ tầng dùng chung)

**Mục đích**: Không cần cài thêm gì; chỉ xác nhận môi trường của tính năng 002 còn chạy.

- [X] T001 Chạy `flutter analyze` và `flutter test` trên mã hiện tại để có mốc xanh trước khi sửa (ghi số test đang đạt vào phần "Kết quả kiểm tra" cuối `specs/003-menu-search/tasks.md`)

---

## Phase 2: Foundational (Điều kiện tiên quyết, chặn mọi user story)

**Mục đích**: Chuẩn hóa chữ, thực thể truy vấn, luồng dữ liệu tìm kiếm, provider và fake cho kiểm thử.

**⚠️ QUAN TRỌNG**: Chưa xong phase này thì không bắt đầu user story nào.

- [X] T002 [P] Viết unit test `test/core/utils/search_text_test.dart` cho `normalizeSearchText` (chữ hoa → thường; mọi nguyên âm có dấu tiếng Việt ở cả 5 dấu và các biến thể `ă â ê ô ơ ư`, hoa và thường; `đ`/`Đ` → `d`; gộp khoảng trắng; cắt hai đầu; giữ nguyên `+ - &` và chữ số; idempotent) và `limitSearchKeyword` (cắt hai đầu; giữ tối đa 50 rune; chuỗi chỉ khoảng trắng → rỗng)
- [X] T003 Cài đặt `normalizeSearchText` và `limitSearchKeyword` bằng bảng ánh xạ ký tự trong `lib/core/utils/search_text.dart` (research R2, không thêm phụ thuộc) cho tới khi T002 đạt
- [X] T004 [P] Tạo `lib/features/menu/domain/entities/menu_search_query.dart`: enum `MenuSortOrder { relevance, priceAsc, priceDesc, ratingDesc }` kèm getter `label` tiếng Việt ("Phù hợp nhất", "Giá thấp đến cao", "Giá cao đến thấp", "Đánh giá cao"); lớp bất biến `MenuSearchFilters` (`categoryId`, `availableOnly`, `sortOrder`, `defaults`, `isDefault`, `copyWith` có `clearCategory`, `==`/`hashCode`); lớp bất biến `MenuSearchQuery` (`keyword`, `filters`, `normalizedKeyword`, `hasKeyword`, `copyWith`, `==`/`hashCode`) theo `data-model.md`
- [X] T005 Thêm `watchSearchableItems({int limit = 300})` kèm dartdoc vào `lib/features/menu/domain/repositories/menu_repository.dart` theo `contracts/menu_repository_search.md`
- [X] T006 Cài đặt `watchSearchableItems` trong `lib/features/menu/data/repositories/firestore_menu_repository.dart`: dùng `_browsableItems` với `orderBy categorySortOrder, categoryId, sortOrder, name` và `limit`, kiểm tra giới hạn 1–500 (ném `RangeError`, tách hằng giới hạn khỏi `_checkLimit` 1–100 hiện có), đi qua `_watchFeed` để có metadata, bỏ qua tài liệu lỗi và ánh xạ `MenuFailure` (S1–S6)
- [X] T007 Mở rộng `test/support/fake_menu_repository.dart`: danh sách `searchRequests`, kênh replay riêng cho `watchSearchableItems`, các hàm `emitSearchableItems(List<MenuItem> items, {bool isFromCache = false})` và `emitSearchableError(MenuFailure failure)`
- [X] T008 Thêm `searchableItemsProvider` (`StreamProvider.autoDispose`, `retry: _noAutomaticRetry`) và `menuSearchDebounceProvider` (`Duration(milliseconds: 300)`) vào `lib/features/menu/presentation/viewmodels/menu_providers.dart` theo contract
- [X] T009 [P] Thêm rules test R11 vào `tests/firestore_rules/menu_rules.test.mjs`: Guest `list` `menu_items` với `isPublished == true`, `isCategoryPublished == true`, `orderBy categorySortOrder, categoryId, sortOrder, name`, `limit(300)` → cho phép; cập nhật bảng ca kiểm thử trong `specs/002-browse-menu/contracts/firestore_menu_access.md` (thêm dòng R11 trỏ tới spec 003)

**Checkpoint**: Nền xong; `flutter analyze` sạch, test T002 đạt, rules test R1–R11 đạt.

---

## Phase 3: User Story 1 - Tìm món theo tên (Priority: P1) 🎯 MVP

**Goal**: Từ Trang chủ mở màn hình tìm kiếm, gõ một phần tên (có hoặc không dấu) và thấy kết quả sau 300 ms, có đủ trạng thái và giữ trạng thái khi mở chi tiết.

**Independent Test**: Quickstart Q1–Q7 và Q19: chạm ô tìm kiếm, gõ "tra sua" chỉ còn "Trà sữa trân châu đường đen"; gõ "pizza" thấy trạng thái rỗng; mở chi tiết rồi quay lại vẫn giữ từ khóa.

### Tests cho User Story 1

- [X] T010 [P] [US1] Viết unit test `test/features/menu/domain/menu_search_test.dart` cho `searchMenuItems` phần từ khóa và "Phù hợp nhất" với dữ liệu kiểu Ngô Chicken từ `test/support/menu_fixtures.dart`: từ khóa rỗng hoặc chỉ khoảng trắng trả nguyên danh sách theo thứ tự đầu vào; "tra sua" khớp "Trà sữa trân châu đường đen"; "GA" và "gà" cho cùng kết quả; "mỳ ý + gà" khớp "Mỳ ý + Gà rán"; món có tên bắt đầu bằng từ khóa đứng trước, giữ thứ tự thực đơn trong mỗi nhóm; không có món khớp trả rỗng; không đổi danh sách đầu vào; SC-002 (với mọi món mẫu, 4 ký tự đầu của mỗi từ trong tên, có và không dấu, đều tìm thấy món đó)
- [X] T011 [P] [US1] Viết unit test `test/features/menu/presentation/menu_search_view_model_test.dart` (ProviderContainer, ghi đè `menuRepositoryProvider` bằng fake, `menuSearchDebounceProvider` bằng `Duration.zero` hoặc giá trị nhỏ, `menuOfflineGraceProvider`): trạng thái đầu `loading` với truy vấn mặc định; feed đầu tiên → `ready` với toàn bộ món; `updateKeyword` chỉ đổi kết quả sau độ trễ và gõ liên tiếp chỉ áp dụng lần cuối; `clearKeyword` áp dụng ngay; từ khóa > 50 ký tự bị cắt; feed mới (đổi tên, gỡ món) tự tính lại kết quả với truy vấn hiện tại; lỗi → `error` giữ nguyên truy vấn; `retry` quay về `loading` rồi `ready`; feed từ cache rỗng khi chưa có dữ liệu máy chủ → `error`; `isFromCache` quá khoảng chờ → `isOffline`; hủy provider thì timer bị hủy
- [X] T012 [P] [US1] Viết widget test `test/features/menu/presentation/menu_search_view_test.dart` phần US1 (bọc `ProviderScope` với fake, cỡ 390×844 và 320×640 ở cỡ chữ 1,3×): ô nhập tự focus khi `openFilters: false`; hiện "N món" và `FoodCard` cho mỗi kết quả; gõ rồi `pump(300ms)` lọc kết quả; nút `search-clear` chỉ hiện khi có chữ và xóa ngay; trạng thái đang tải, rỗng ("Không tìm thấy món phù hợp" kèm nút "Xóa từ khóa"), lỗi kèm "Thử lại", nhãn ngoại tuyến; chạm thẻ mở `MenuItemDetailView` và quay lại giữ từ khóa và vị trí cuộn; không tràn bố cục
- [X] T013 [P] [US1] Sửa `test/features/menu/presentation/home_view_test.dart`: chạm `home-search` mở `MenuSearchView` (không còn SnackBar); chuông `home-notifications` vẫn hiện SnackBar "Tính năng đang được phát triển"; đang chọn danh mục ở Trang chủ thì màn hình tìm kiếm vẫn mở với tất cả món (Q7); quay về rồi mở lại thì từ khóa trống (FR-015)

### Implementation cho User Story 1

- [X] T014 [US1] Tạo `lib/features/menu/domain/services/menu_search.dart` với `searchMenuItems(List<MenuItem> items, MenuSearchQuery query, {Map<String, String>? normalizedNames})`: lọc theo từ khóa đã chuẩn hóa (dùng `normalizedNames` nếu có để không chuẩn hóa lại) và sắp xếp ổn định `relevance` (research R3) cho tới khi T010 đạt; để sẵn chỗ cho bộ lọc và các cách sắp xếp khác ở US2/US3
- [X] T015 [US1] Tạo `lib/features/menu/presentation/viewmodels/menu_search_state.dart`: `MenuSearchStatus { loading, ready, error }`, `MenuSearchNotice { categoryRemoved }`, lớp bất biến `MenuSearchState` (`query`, `status`, `results`, `categories`, `isOffline`, `failure`, `notice`, `isEmptyResult`, `selectedCategory`, `copyWith`) theo `data-model.md`
- [X] T016 [US1] Tạo `lib/features/menu/presentation/viewmodels/menu_search_view_model.dart`: `MenuSearchViewModel extends Notifier<MenuSearchState>` và `menuSearchViewModelProvider = NotifierProvider.autoDispose`; `ref.listen(searchableItemsProvider)` (bỏ qua `AsyncError` có `isLoading: true` như `HomeMenuViewModel`), giữ bộ nhớ tạm `id → tên chuẩn hóa` cập nhật khi feed đổi; `updateKeyword(String)` dùng `Timer` với `menuSearchDebounceProvider` và `limitSearchKeyword`; `submitKeyword(String)` áp dụng ngay cho phím "Tìm" (FR-004); `clearKeyword()`; `retry()` gọi `ref.invalidate(searchableItemsProvider)`; khoảng chờ ngoại tuyến từ `menuOfflineGraceProvider`; `ref.onDispose` hủy mọi timer cho tới khi T011 đạt
- [X] T017 [P] [US1] Tạo `lib/features/menu/presentation/widgets/search_input_bar.dart`: nút quay lại tròn (`search-back`), ô `TextField` (`search-input`, `autofocus` theo tham số, cùng kiểu ô tìm kiếm Trang chủ: nền `AppColors.warningSurface`, `AppRadii.input`, kính lúp `AppColors.foodAccentDark`, gợi ý "Bạn muốn ăn gì?", nhãn ngữ nghĩa "Tìm kiếm món", `textInputAction: search`), nút "x" (`search-clear`) khi có chữ, nút lọc (`search-filter`, nhãn "Bộ lọc") có chấm `AppColors.primaryEnd` khi `hasActiveFilters`; vùng chạm ≥ 48 dp; chỉ dùng token trong `lib/core/theme/`
- [X] T018 [US1] Tạo `lib/features/menu/presentation/views/menu_search_view.dart`: `MenuSearchView({bool openFilters = false})` là `ConsumerStatefulWidget`, giữ `TextEditingController` và `ScrollController` trong `State`; bố cục theo `contracts/search_screen_ui.md` (thanh trên, `OfflineBanner`, dòng "N món", danh sách `FoodCard`); trạng thái tải (`AppLoadingView`), rỗng (`AppEmptyView` "Không tìm thấy món phù hợp" / "Thử từ khóa khác hoặc bỏ bộ lọc" kèm nút "Xóa từ khóa" khi có từ khóa), lỗi (`AppErrorView` + "Thử lại"); chạm thẻ `Navigator.push` `MenuItemDetailView(menuItemId)`; padding ngang 24 (16 khi < 360 dp) cho tới khi T012 đạt
- [X] T019 [US1] Sửa `lib/features/menu/presentation/views/home_view.dart`: `onSearchTap` đẩy `MenuSearchView()` lên navigator gốc (`Navigator.of(context, rootNavigator: true)`) thay cho `_showUnavailableFeature`; chuông vẫn dùng `_showUnavailableFeature`; cập nhật chú thích lớp trong `lib/features/menu/presentation/widgets/home_search_bar.dart` (ô tìm kiếm mở màn hình tìm kiếm) cho tới khi T013 đạt

**Checkpoint**: Tìm theo tên chạy độc lập; kiểm chứng Q1–Q7, Q19.

---

## Phase 4: User Story 2 - Lọc theo danh mục và tình trạng còn hàng (Priority: P1)

**Goal**: Bảng lọc có danh mục (chọn một) và "Chỉ món còn hàng", chỉ có hiệu lực khi "Áp dụng"; nhãn bộ lọc bỏ được; nút lọc ở Trang chủ mở sẵn bảng.

**Independent Test**: Quickstart Q8–Q13 và Q17: chọn "Đồ ăn vặt" + "Chỉ món còn hàng" → không có "Cá viên chiên"; đổi rồi vuốt đóng không thay đổi gì.

### Tests cho User Story 2

- [X] T020 [P] [US2] Bổ sung `test/features/menu/domain/menu_search_test.dart`: lọc `categoryId` chỉ giữ món của danh mục đó; `availableOnly` loại mọi món `isAvailable == false` (SC-004); tắt thì món hết hàng vẫn có mặt; từ khóa + danh mục + còn hàng kết hợp theo "và" (FR-008); bộ lọc làm kết quả rỗng trả rỗng
- [X] T021 [P] [US2] Bổ sung `test/features/menu/presentation/menu_search_view_model_test.dart`: `categories` lấy từ `menuCategoriesProvider`; `applyFilters(filters)` tính lại kết quả ngay, không mở thêm luồng (`searchRequests` vẫn 1); `removeCategoryFilter()`, `removeAvailableFilter()` có hiệu lực ngay; `clearFilters()` đưa bộ lọc về mặc định nhưng giữ từ khóa; danh mục đang lọc biến mất khỏi feed danh mục từ máy chủ → bộ lọc về "Tất cả" và `notice == categoryRemoved`, feed từ cache không kích hoạt; `clearNotice()` xóa thông báo; `retry()` giữ nguyên bộ lọc
- [X] T022 [P] [US2] Viết widget test `test/features/menu/presentation/search_filter_sheet_test.dart` (320×640, 1,3×): bảng hiện "Tất cả" + danh mục đã đăng bán và công tắc "Chỉ món còn hàng" phản ánh bộ lọc ban đầu; chọn danh mục khác thay thế danh mục đang chọn; "Áp dụng" trả `MenuSearchFilters` mới; "Đặt lại" đưa nháp về mặc định mà không đóng bảng; đóng bằng nút quay lại hoặc chạm ra ngoài trả `null`; nội dung cuộn được, không tràn
- [X] T023 [P] [US2] Bổ sung `test/features/menu/presentation/menu_search_view_test.dart` phần US2: `openFilters: true` mở sẵn bảng và không focus ô nhập; áp dụng bộ lọc hiện nhãn `search-chip-category`, `search-chip-available` và `search-clear-filters`, nút lọc có chấm; bỏ nhãn có hiệu lực ngay; đóng bảng không áp dụng giữ kết quả cũ (FR-016); trạng thái rỗng do bộ lọc hiện nút "Xóa bộ lọc"; thông báo `categoryRemoved` hiện SnackBar "Danh mục đã chọn không còn được bán"
- [X] T024 [P] [US2] Bổ sung `test/features/menu/presentation/home_view_test.dart`: chạm `home-filter` mở `MenuSearchView` với bảng lọc mở sẵn

### Implementation cho User Story 2

- [X] T025 [US2] Bổ sung lọc danh mục và còn hàng (trước bước lọc từ khóa) vào `searchMenuItems` trong `lib/features/menu/domain/services/menu_search.dart` cho tới khi T020 đạt
- [X] T026 [US2] Bổ sung vào `lib/features/menu/presentation/viewmodels/menu_search_view_model.dart`: nghe `menuCategoriesProvider` để có `categories`; `applyFilters(MenuSearchFilters)`, `removeCategoryFilter()`, `removeAvailableFilter()`, `clearFilters()`, `clearNotice()`; tự bỏ danh mục bị gỡ khi feed danh mục đến từ máy chủ (research R7); `retry()` invalidate cả luồng danh mục cho tới khi T021 đạt
- [X] T027 [P] [US2] Tạo `lib/features/menu/presentation/widgets/search_filter_sheet.dart`: hàm `showSearchFilterSheet(BuildContext, {required MenuSearchFilters initial, required List<MenuCategory> categories})` trả `Future<MenuSearchFilters?>` qua `showModalBottomSheet` (`isScrollControlled`, cao tối đa 85%, `SafeArea`, tay nắm, tiêu đề "Bộ lọc"); `StatefulWidget` giữ bản nháp; mục "Danh mục" là `Wrap` chip chọn một (`filter-category-all`, `filter-category-<id>`); mục "Tình trạng" là công tắc "Chỉ món còn hàng" (`filter-available`); hàng nút "Đặt lại" (`filter-reset`, nút viền) và "Áp dụng" (`filter-apply`, nền `AppGradients.primary`); để chỗ cho mục "Sắp xếp" ở US3 cho tới khi T022 đạt
- [X] T028 [P] [US2] Tạo `lib/features/menu/presentation/widgets/search_filter_chips.dart`: hàng cuộn ngang nhãn bộ lọc (`search-chip-category` hiện tên danh mục, `search-chip-available` "Chỉ món còn hàng"), mỗi nhãn có nút bỏ với nhãn ngữ nghĩa "Bỏ bộ lọc <tên>", nút chữ "Xóa bộ lọc" (`search-clear-filters`) ở cuối; chỉ hiện khi `!filters.isDefault`
- [X] T029 [US2] Nối bảng lọc và nhãn vào `lib/features/menu/presentation/views/menu_search_view.dart`: nút lọc gọi `showSearchFilterSheet` rồi `applyFilters` khi kết quả khác `null`; `openFilters: true` mở bảng sau frame đầu (`WidgetsBinding.instance.addPostFrameCallback`) và tắt `autofocus`; trạng thái rỗng thêm nút "Xóa bộ lọc" khi có bộ lọc; `ref.listen` thông báo để hiện SnackBar rồi `clearNotice()` cho tới khi T023 đạt
- [X] T030 [US2] Sửa `lib/features/menu/presentation/views/home_view.dart`: `onFilterTap` đẩy `MenuSearchView(openFilters: true)` lên navigator gốc cho tới khi T024 đạt

**Checkpoint**: US1 và US2 chạy độc lập; kiểm chứng Q8–Q13, Q17.

---

## Phase 5: User Story 3 - Sắp xếp kết quả (Priority: P2)

**Goal**: Mục "Sắp xếp" trong bảng lọc với 4 cách; nhãn sắp xếp khi khác "Phù hợp nhất"; "Đặt lại" và "Xóa bộ lọc" đưa về mặc định.

**Independent Test**: Quickstart Q14–Q16: tìm "tra", chọn "Giá thấp đến cao" → "Trà đào" (20.000 ₫) đứng đầu; "Xóa bộ lọc" đưa thứ tự về "Phù hợp nhất".

### Tests cho User Story 3

- [X] T031 [P] [US3] Bổ sung `test/features/menu/domain/menu_search_test.dart`: `priceAsc`/`priceDesc` theo `priceRange.min` (món nhiều size dùng giá size nhỏ nhất), cùng giá theo tên chuẩn hóa; `ratingDesc` món có đánh giá trước theo `ratingAverage` giảm, `reviewCount` giảm, tên; món chưa có đánh giá ở cuối theo thứ tự thực đơn; sắp xếp kết hợp với từ khóa và bộ lọc
- [X] T032 [P] [US3] Bổ sung `test/features/menu/presentation/search_filter_sheet_test.dart` và `test/features/menu/presentation/menu_search_view_test.dart`: bảng có 4 chip sắp xếp (`filter-sort-<tên enum>`) phản ánh giá trị ban đầu; "Đặt lại" đưa về "Phù hợp nhất"; áp dụng "Giá thấp đến cao" đổi thứ tự kết quả và hiện `search-chip-sort`; bỏ nhãn sắp xếp hoặc "Xóa bộ lọc" đưa về "Phù hợp nhất"; bổ sung `menu_search_view_model_test.dart`: `removeSortOrder()` có hiệu lực ngay

### Implementation cho User Story 3

- [X] T033 [US3] Bổ sung `priceAsc`, `priceDesc`, `ratingDesc` vào `searchMenuItems` trong `lib/features/menu/domain/services/menu_search.dart` (sắp xếp ổn định, so sánh tên bằng tên đã chuẩn hóa) cho tới khi T031 đạt
- [X] T034 [US3] Thêm `removeSortOrder()` vào `lib/features/menu/presentation/viewmodels/menu_search_view_model.dart`
- [X] T035 [US3] Thêm mục "Sắp xếp" (4 chip chọn một, nhãn từ `MenuSortOrder.label`) vào `lib/features/menu/presentation/widgets/search_filter_sheet.dart` và nhãn `search-chip-sort` vào `lib/features/menu/presentation/widgets/search_filter_chips.dart`; nối `removeSortOrder` trong `lib/features/menu/presentation/views/menu_search_view.dart` cho tới khi T032 đạt

**Checkpoint**: Cả ba story chạy độc lập; kiểm chứng Q14–Q16.

---

## Phase 6: Polish & Cross-Cutting Concerns

- [X] T036 [P] Cập nhật `docs/design_system.md`: mục "Search Field (Home)" không còn là ô chỉ đọc chờ tính năng mà mở màn hình tìm kiếm; thêm mục "Search Screen" (thanh trên, nhãn bộ lọc, danh sách `FoodCard`) và "Filter Sheet" (bottom sheet, chip chọn một, công tắc, nút "Đặt lại"/"Áp dụng") theo `contracts/search_screen_ui.md`
- [X] T037 [P] Cập nhật `specs/002-browse-menu/contracts/home_screen_ui.md` (dòng "Chạm tìm kiếm / lọc / chuông": tìm kiếm và lọc mở màn hình tìm kiếm của tính năng 003, chuông vẫn hiện SnackBar) và ghi chú trong `specs/002-browse-menu/spec.md` FR-019 rằng FR-002 của tính năng 003 thay hành vi của ô tìm kiếm và nút lọc
- [X] T038 Chạy `dart format lib test`, `flutter analyze` (phải sạch) và toàn bộ `flutter test`; chạy `npm test` trong `tests/firestore_rules` (R1–R11); ghi kết quả vào phần "Kết quả kiểm tra" cuối tệp này
- [ ] T039 Chạy ứng dụng trên Chrome với Emulator (`--dart-define=USE_FIRESTORE_EMULATOR=true`, dữ liệu mẫu đã seed) và đi qua quickstart Q1–Q20; ghi các kịch bản đạt hoặc lệch vào phần "Kết quả kiểm tra"
- [X] T040 So khớp mã với `spec.md` (FR-001 – FR-016, SC-001 – SC-006), `plan.md` và `contracts/`; đóng mọi khoảng trống bắt buộc còn lại

---

## Dependencies & Execution Order

### Phụ thuộc giữa các phase

- **Setup (Phase 1)**: không phụ thuộc.
- **Foundational (Phase 2)**: sau Setup; chặn mọi user story.
- **US1 (Phase 3)**: sau Foundational. Là MVP.
- **US2 (Phase 4)**: sau Foundational. Phần domain (T020, T025) độc lập với US1; phần giao diện (T023, T029, T030) cần `MenuSearchView` của T018.
- **US3 (Phase 5)**: sau Foundational. Phần domain (T031, T033) độc lập; phần giao diện cần bảng lọc của T027.
- **Polish (Phase 6)**: sau các story muốn giao.

### Trong mỗi story

- Viết test trước và xác nhận test thất bại, rồi mới cài đặt.
- Domain (`menu_search.dart`) → state → ViewModel → widget → view → điểm vào ở Trang chủ.
- Các task cùng sửa `menu_search.dart`, `menu_search_view_model.dart` hoặc `menu_search_view.dart` chạy tuần tự.

## Parallel Opportunities

- Phase 2: T002, T004, T009 song song; T005 → T006 → T007/T008.
- US1: T010, T011, T012, T013 (bốn tệp test khác nhau) song song; T017 song song với T014–T016.
- US2: T020, T021, T022, T023, T024 song song; T027 và T028 song song với T025–T026.
- US3: T031 và T032 song song; T035 sau T034 (cần `removeSortOrder`).
- Polish: T036 và T037 song song.

```text
# Ví dụ US1:
Task: "T010 unit test searchMenuItems trong test/features/menu/domain/menu_search_test.dart"
Task: "T011 unit test ViewModel trong test/features/menu/presentation/menu_search_view_model_test.dart"
Task: "T012 widget test MenuSearchView trong test/features/menu/presentation/menu_search_view_test.dart"
Task: "T017 SearchInputBar trong lib/features/menu/presentation/widgets/search_input_bar.dart"
```

## Implementation Strategy

### MVP trước (chỉ User Story 1)

1. Phase 1 → Phase 2.
2. Phase 3 (US1): tìm theo tên với đủ trạng thái, mở từ Trang chủ.
3. **Dừng và kiểm chứng**: Q1–Q7, Q19 trên Chrome.

### Giao dần

1. US1 → demo tìm kiếm.
2. US2 → bộ lọc và nút lọc ở Trang chủ.
3. US3 → sắp xếp.
4. Polish → tài liệu, kiểm tra cuối.

## Notes

- Không đổi schema, rules hay chỉ mục; chỉ thêm rules test R11.
- Không thêm phụ thuộc mới.
- Chuông thông báo ở Trang chủ vẫn giữ SnackBar "Tính năng đang được phát triển".
- Dùng `SPECIFY_FEATURE=003-menu-search` hoặc `.specify/feature.json` khi chạy script speckit vì nhánh là `linh`.

## Kết quả kiểm tra

### 2026-10-20

- **T001 (mốc trước khi sửa)**: `flutter analyze` sạch; `flutter test` 61/61 đạt.
- **T038**: `dart format lib test` không còn thay đổi; `flutter analyze` sạch (No issues found); `flutter test` 138/138 đạt (thêm 77 test: `search_text_test` 13, `menu_search_test` 21, `menu_search_view_model_test` 19, `menu_search_view_test` 17, `search_filter_sheet_test` 6, `home_view_test` thêm 3 test lối vào tìm kiếm và gộp 3 test "đang phát triển" thành 1 test cho chuông); rules test R1–R11 đạt 11/11 trên Firestore Emulator (chạy `node --test` với `FIRESTORE_EMULATOR_HOST` vì emulator đang mở cho ứng dụng; đã nạp lại dữ liệu mẫu sau đó).
- **T039**: ứng dụng đã chạy lại trên Chrome (`http://localhost:5555`, Emulator `demo-ordering`); chờ người dùng đi qua Q1–Q20.
- **T040**: FR-001 – FR-016 và SC-001 – SC-004, SC-006 đều có mã và test tương ứng; SC-005 là chỉ số đo với người dùng thật, chưa đo.
- Thay đổi ngoài kế hoạch: `AppEmptyView` có thêm hành động phụ (`secondaryActionLabel`) để trạng thái rỗng hiện cả "Xóa từ khóa" và "Xóa bộ lọc"; thông báo danh mục bị gỡ dùng chung câu với Trang chủ.
