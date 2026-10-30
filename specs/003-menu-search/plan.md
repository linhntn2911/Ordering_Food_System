# Kế hoạch triển khai (Implementation Plan): Tìm kiếm và lọc thực đơn

**Branch**: `linh` (feature `003-menu-search`) | **Ngày**: 2026-10-20 | **Spec**: [spec.md](spec.md)

**Đầu vào**: Đặc tả tính năng tại `specs/003-menu-search/spec.md` (đã làm rõ 5 câu hỏi ngày 2026-10-20).

## Tóm tắt (Summary)

Thêm màn hình Tìm kiếm và lọc cho Guest và Customer, mở từ ô tìm kiếm và nút lọc ở Trang chủ (thay SnackBar "đang được phát triển"). Người dùng tìm món theo tên, không phân biệt dấu. Bộ lọc gồm một danh mục, "Chỉ món còn hàng" và 4 cách sắp xếp, nằm trong một bảng lọc chỉ có hiệu lực khi bấm "Áp dụng". Bộ lọc đang bật hiện thành nhãn bỏ được.

Về kỹ thuật: repository có thêm một luồng realtime trả toàn bộ món đủ điều kiện (cùng truy vấn "Tất cả" của tính năng 002, giới hạn 300). Tìm, lọc và sắp xếp là hàm thuần ở tầng domain. `MenuSearchViewModel` (`Notifier` autoDispose) giữ truy vấn, debounce 300 ms và gộp luồng thành `MenuSearchState` bất biến. Không đổi schema, rules hay chỉ mục.

## Bối cảnh kỹ thuật (Technical Context)

**Language/Version**: Dart `^3.13.2`, Flutter 3.47.x

**Primary Dependencies**: `flutter_riverpod ^3.4.3`, `cloud_firestore ^7.0.0`, `firebase_core ^5.0.0` (đã có). Không thêm phụ thuộc (research R9).

**Storage**: Cloud Firestore `menu_items`, `categories` (chỉ đọc). Dùng cache bền vững có sẵn khi ngoại tuyến. Trạng thái tìm kiếm chỉ trong bộ nhớ.

**Testing**: `flutter test` (unit cho `search_text`, `menu_search`, ViewModel; widget cho màn hình tìm kiếm, bảng lọc, điểm vào từ Trang chủ, ở 320 dp và 1,3×); `node --test` cho rules (thêm R11).

**Target Platform**: Android trước; giữ tương thích iOS; chạy được trên Chrome với Emulator để demo.

**Project Type**: Ứng dụng di động Flutter.

**Performance Goals**: Kết quả hiện ≤ 1 giây sau khi ngừng gõ (SC-001). Tính lại trên ≤ 300 món là thao tác bộ nhớ, dưới một khung hình.

**Constraints**: Debounce 300 ms; từ khóa tối đa 50 ký tự; một luồng Firestore cho toàn màn hình; rules là nơi chặn món chưa đăng bán; chỉ chế độ sáng, chỉ dùng token chung.

**Scale/Scope**: 28 món hiện tại, tối đa vài trăm. 1 màn hình mới (Medium, Member 2) và 1 bảng lọc.

## Kiểm tra Constitution (Constitution Check)

*GATE: phải đạt trước Phase 0 và kiểm tra lại sau Phase 1.*

| Nguyên tắc | Đánh giá trước | Sau thiết kế |
|---|---|---|
| I. Đặc tả trước khi triển khai | ĐẠT: spec 003 có 3 user story kiểm thử độc lập, đã làm rõ 5 câu | ĐẠT |
| II. MVVM và Riverpod chính thức | ĐẠT: `MenuSearchView` → `MenuSearchViewModel` (`Notifier` của `flutter_riverpod`) → `MenuRepository` → Firestore; quy tắc tìm/lọc/sắp xếp ở domain | ĐẠT: bản nháp bảng lọc chỉ là trạng thái biểu mẫu trong `State` của widget (R5) |
| III. Bảo mật do máy chủ áp đặt | ĐẠT: dùng lại rules R1–R10; truy vấn có đủ hai bộ lọc | ĐẠT, thêm R11 |
| IV. User story trình diễn độc lập | ĐẠT: Q1–Q20 trong `quickstart.md`; màn hình Search and Filter là màn Medium của Member 2 | ĐẠT |
| V. Chất lượng kiểm chứng được | ĐẠT: đủ trạng thái tải/rỗng/lỗi/thử lại/ngoại tuyến; unit, widget, rules test; `flutter analyze` | ĐẠT |
| VI. Thiết kế Food Ninja chỉ chế độ sáng | ĐẠT: dùng token và widget chung (`FoodCard`, `AppEmptyView`, `OfflineBanner`) | ĐẠT |
| Phụ thuộc mới phải có lý do | ĐẠT: không thêm | ĐẠT |

Không có vi phạm cần biện minh.

## Quyết định kiến trúc

Chi tiết và phương án đã cân nhắc ở [research.md](research.md).

1. **Nguồn dữ liệu (R1)**: `watchSearchableItems({limit = 300})` với giới hạn 1–500, cùng truy vấn và chỉ mục với "Tất cả". Lọc danh mục làm ở client, nên đổi bộ lọc không mở luồng mới.
2. **Chuẩn hóa không dấu (R2)**: `normalizeSearchText` bằng bảng ánh xạ ký tự tiếng Việt; tên món chuẩn hóa một lần mỗi khi danh sách đổi (ViewModel giữ bộ nhớ tạm `id → tên chuẩn hóa`).
3. **Tìm, lọc, sắp xếp (R3)**: `searchMenuItems(items, query)` thuần, sắp xếp ổn định trên danh sách đã theo thứ tự thực đơn.
4. **Debounce (R4)**: `Timer` trong ViewModel với `menuSearchDebounceProvider` (300 ms, ghi đè được trong test). Nút "x" áp dụng ngay.
5. **Bảng lọc (R5)**: bottom sheet giữ bản nháp trong `State`, trả `MenuSearchFilters` khi "Áp dụng", trả `null` khi đóng; ViewModel chỉ nhận bộ lọc đã xác nhận.
6. **Điều hướng (R6)**: `Navigator.push` từ Trang chủ trên navigator gốc; `openFilters` quyết định focus hay mở bảng; provider autoDispose cho FR-015; controller trong `State` cho FR-013.
7. **Biên (R7)**: danh mục biến mất thì bỏ bộ lọc và báo một lần; ngoại tuyến dùng `menuOfflineGraceProvider`; lỗi kèm "Thử lại" giữ truy vấn.

## Cấu trúc dự án (Project Structure)

### Tài liệu (feature này)

```text
specs/003-menu-search/
├── spec.md
├── plan.md              # Tệp này
├── research.md          # Phase 0
├── data-model.md        # Phase 1
├── quickstart.md        # Phase 1
├── contracts/
│   ├── menu_repository_search.md
│   └── search_screen_ui.md
├── checklists/requirements.md
└── tasks.md             # Phase 2 (/speckit-tasks, chưa tạo)
```

### Mã nguồn (gốc repository)

```text
lib/
├── core/utils/search_text.dart                       # Mới: normalizeSearchText, limitSearchKeyword
└── features/menu/
    ├── domain/
    │   ├── entities/menu_search_query.dart           # Mới: MenuSortOrder, MenuSearchFilters, MenuSearchQuery
    │   ├── services/menu_search.dart                 # Mới: searchMenuItems
    │   └── repositories/menu_repository.dart         # Sửa: thêm watchSearchableItems
    ├── data/repositories/firestore_menu_repository.dart  # Sửa: cài đặt watchSearchableItems
    └── presentation/
        ├── viewmodels/menu_providers.dart            # Sửa: searchableItemsProvider, menuSearchDebounceProvider
        ├── viewmodels/menu_search_state.dart         # Mới
        ├── viewmodels/menu_search_view_model.dart    # Mới
        ├── views/menu_search_view.dart               # Mới
        ├── views/home_view.dart                      # Sửa: ô tìm kiếm và nút lọc mở MenuSearchView
        └── widgets/
            ├── home_search_bar.dart                  # Sửa: cập nhật chú thích
            ├── search_input_bar.dart                 # Mới: thanh trên (quay lại, ô nhập, x, lọc)
            ├── search_filter_chips.dart              # Mới: nhãn bộ lọc + "Xóa bộ lọc"
            └── search_filter_sheet.dart              # Mới: bảng lọc

test/
├── core/utils/search_text_test.dart                  # Mới
├── features/menu/domain/menu_search_test.dart        # Mới
├── features/menu/presentation/menu_search_view_model_test.dart  # Mới
├── features/menu/presentation/menu_search_view_test.dart        # Mới
├── features/menu/presentation/search_filter_sheet_test.dart     # Mới
├── features/menu/presentation/home_view_test.dart    # Sửa: điểm vào tìm kiếm
└── support/fake_menu_repository.dart                 # Sửa: luồng searchable

tests/firestore_rules/menu_rules.test.mjs             # Sửa: thêm R11
docs/design_system.md                                 # Sửa: ô tìm kiếm Home không còn "chỉ đọc chờ tính năng"; thêm Search screen và Filter sheet
specs/002-browse-menu/contracts/home_screen_ui.md     # Sửa: dòng "Chạm tìm kiếm / lọc" trỏ sang màn hình tìm kiếm
```

**Quyết định cấu trúc**: Giữ MVVM theo feature. Tìm kiếm dùng cùng dữ liệu thực đơn nên nằm trong `lib/features/menu/`, không tạo feature riêng. Hàm chuẩn hóa chữ là tiện ích chung ở `lib/core/utils/` để dùng lại cho tìm kiếm của Admin sau này.

## Thứ tự thực hiện gợi ý (đầu vào cho /speckit-tasks)

1. **Nền**: `search_text.dart` và test; `menu_search_query.dart`; `watchSearchableItems` (repository, fake, provider); rules test R11.
2. **US1 (P1)**: `searchMenuItems` (lọc từ khóa, sắp xếp "Phù hợp nhất") → ViewModel (debounce, trạng thái) → `MenuSearchView` với thanh trên và danh sách → điểm vào từ ô tìm kiếm ở Trang chủ → giữ trạng thái khi mở chi tiết.
3. **US2 (P1)**: lọc danh mục và còn hàng trong `searchMenuItems` → `applyFilters`, `removeFilter`, `clearFilters`, danh mục bị gỡ → bảng lọc (Áp dụng, Đặt lại, đóng không áp dụng) → nhãn bộ lọc → điểm vào từ nút lọc.
4. **US3 (P2)**: 3 cách sắp xếp còn lại trong `searchMenuItems` → mục sắp xếp trong bảng lọc → nhãn sắp xếp.
5. **Hoàn thiện**: kiểm tra 320 dp và 1,3×, cập nhật `docs/design_system.md` và contract Home của 002, `dart format`, `flutter analyze`, `flutter test`, rules test, chạy quickstart trên Chrome.

## Rủi ro và việc kéo theo

- **Giới hạn 300 món**: nếu thực đơn vượt 300, món cuối sẽ không tìm được. Hiện là 28 món nên chấp nhận được; `hasMore` được giữ để phát hiện sau này.
- **Bảng ánh xạ dấu**: chỉ phủ chữ cái tiếng Việt. Tên có ký tự ngoài bảng vẫn so khớp đúng nguyên văn (sau khi chuyển chữ thường).
- **Thay đổi hành vi Trang chủ**: test FR-019 của tính năng 002 ("Chạm tìm kiếm hiện SnackBar") phải sửa theo FR-002 của tính năng này; chuông thông báo vẫn giữ SnackBar.
- **Script speckit**: nhánh `linh` không theo mẫu `NNN-tên`. Feature được xác định qua `.specify/feature.json` hoặc `SPECIFY_FEATURE=003-menu-search`.

## Theo dõi độ phức tạp (Complexity Tracking)

Không có vi phạm constitution cần biện minh.
