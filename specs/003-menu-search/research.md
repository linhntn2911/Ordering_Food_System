# Nghiên cứu (Research): Tìm kiếm và lọc thực đơn

**Tính năng**: `003-menu-search` | **Ngày**: 2026-10-20 | **Spec**: [spec.md](spec.md)

Mỗi mục ghi theo dạng: Quyết định, Lý do, Phương án đã cân nhắc.

## R1. Nguồn dữ liệu cho tìm kiếm (FR-003, FR-005, FR-014)

- **Quyết định**: Thêm phương thức `watchSearchableItems({int limit = 300})` vào `MenuRepository`. Truy vấn giống hệt truy vấn "Tất cả" của tính năng 002: `isPublished == true`, `isCategoryPublished == true`, sắp xếp `categorySortOrder, categoryId, sortOrder, name`, chỉ khác giới hạn (cho phép 1–500, mặc định 300). Một luồng realtime duy nhất; tìm, lọc và sắp xếp chạy ở client trên danh sách đã tải.
- **Lý do**:
  - Firestore không hỗ trợ tìm "chứa chuỗi" hay bỏ dấu, nên muốn tìm theo bất kỳ vị trí nào trong tên thì phải tìm ở client.
  - Thực đơn nhỏ (28 món, tối đa vài trăm), một lần đọc là đủ.
  - Cùng hình dạng truy vấn nên dùng lại chỉ mục và rules sẵn có, không đổi schema. Món chưa đăng bán bị rules chặn ngay từ truy vấn (FR-005).
  - Luồng realtime giúp kết quả tự cập nhật (FR-014). Lọc danh mục cũng làm ở client nên đổi danh mục không mở luồng mới.
- **Phương án đã cân nhắc**:
  - Dùng lại `watchBrowsableItems`: giới hạn 1–100 của nó không đủ cho "vài trăm món", và nới giới hạn chung sẽ ảnh hưởng tới phân trang của Trang chủ.
  - Lưu trường `searchKeywords` (mảng tiền tố đã bỏ dấu) và truy vấn `array-contains`: chỉ khớp tiền tố, phải đổi schema và script ghi dữ liệu; chưa cần với quy mô hiện tại.
  - Dịch vụ tìm kiếm ngoài (Algolia, Typesense): thêm hạ tầng và khóa API, vượt phạm vi.

## R2. So khớp không dấu tiếng Việt (FR-003, edge case từ khóa dài/khoảng trắng)

- **Quyết định**: Hàm thuần `normalizeSearchText` trong `lib/core/utils/search_text.dart`: chuyển chữ thường, thay từng ký tự có dấu tiếng Việt (kể cả `đ`/`Đ`) bằng chữ gốc theo bảng ánh xạ, gộp khoảng trắng liên tiếp, cắt khoảng trắng hai đầu. Từ khóa được cắt còn 50 ký tự đầu (sau khi bỏ khoảng trắng hai đầu) trước khi chuẩn hóa. Ký tự đặc biệt giữ nguyên và so khớp như ký tự thường.
- **Lý do**: Dart không có sẵn chuẩn hóa Unicode NFD. Bảng ánh xạ cho bảng chữ tiếng Việt là hữu hạn, không cần thêm phụ thuộc, và dễ kiểm thử bằng unit test. Tên món được chuẩn hóa một lần mỗi khi danh sách đổi, không phải mỗi lần gõ.
- **Phương án đã cân nhắc**:
  - Gói `diacritic` hoặc `unorm_dart`: thêm phụ thuộc runtime cho một việc nhỏ.
  - Dùng regex trên chuỗi NFD: Dart không chuẩn hóa NFD được.

## R3. Quy tắc lọc và sắp xếp (FR-006 – FR-010, User Story 3)

- **Quyết định**: Hàm thuần `searchMenuItems(items, query)` trong `lib/features/menu/domain/services/menu_search.dart` áp dụng theo thứ tự:
  1. Lọc danh mục (`categoryId == query.categoryId` khi có danh mục được chọn).
  2. Lọc còn hàng (`isAvailable` khi `availableOnly`).
  3. Lọc từ khóa (tên đã chuẩn hóa chứa từ khóa đã chuẩn hóa; từ khóa rỗng thì bỏ qua).
  4. Sắp xếp:
     - **Phù hợp nhất**: món có tên chuẩn hóa bắt đầu bằng từ khóa đứng trước, giữ thứ tự thực đơn trong mỗi nhóm (sắp xếp ổn định). Không có từ khóa thì chỉ theo thứ tự thực đơn.
     - **Giá thấp đến cao / cao đến thấp**: theo `priceRange.min`, cùng giá sắp theo tên chuẩn hóa.
     - **Đánh giá cao**: món có đánh giá trước; trong nhóm đó `ratingAverage` giảm dần, `reviewCount` giảm dần, rồi tên. Món chưa có đánh giá ở cuối, theo thứ tự thực đơn.
- **Lý do**: Đặt ở tầng domain, không phụ thuộc Flutter, nên kiểm thử đơn vị được và không có logic nghiệp vụ trong widget (Constitution II). Danh sách đầu vào đã đúng thứ tự thực đơn nhờ truy vấn ở R1.
- **Phương án đã cân nhắc**: Sắp xếp trong ViewModel: trộn điều phối với quy tắc, khó kiểm thử riêng.

## R4. Cập nhật kết quả sau khi ngừng gõ 300 ms (FR-004, SC-001)

- **Quyết định**: View giữ `TextEditingController` và gửi mỗi thay đổi tới `MenuSearchViewModel.updateKeyword`. ViewModel dùng `Timer` với độ trễ lấy từ `menuSearchDebounceProvider` (mặc định 300 ms): mỗi lần gõ hủy timer cũ, khi timer chạy thì cập nhật từ khóa đã áp dụng và tính lại kết quả. Timer bị hủy trong `ref.onDispose`. Xóa từ khóa bằng nút "x" thì áp dụng ngay, không chờ.
- **Lý do**: Tách "đang gõ" khỏi "đã áp dụng" để không tính lại trên mỗi phím. Provider độ trễ ghi đè được trong test, giống `menuOfflineGraceProvider`, nên unit test không phải chờ thật hay thêm phụ thuộc `fake_async`. Widget test dùng `tester.pump(Duration)`.
- **Phương án đã cân nhắc**: Debounce trong widget: logic trạng thái lọt vào view và khó kiểm thử ViewModel độc lập.

## R5. Bảng lọc với "Áp dụng" và "Đặt lại" (FR-016, FR-010, User Story 2)

- **Quyết định**: Bảng lọc là `showModalBottomSheet` nhận bộ lọc đang áp dụng (`MenuSearchFilters`) làm giá trị ban đầu. Lựa chọn nháp nằm trong `State` của widget bảng (trạng thái biểu mẫu thuần giao diện). "Áp dụng" đóng bảng và trả `MenuSearchFilters` mới qua `Navigator.pop`. View gọi `viewModel.applyFilters(filters)`. Đóng bằng cách khác trả `null`, bộ lọc giữ nguyên. "Đặt lại" chỉ đặt lại nháp về `MenuSearchFilters.defaults`.
- **Lý do**: Bản nháp không cần tồn tại ngoài bảng, và đóng bảng nghĩa là bỏ nháp. Như vậy ViewModel chỉ nhận bộ lọc đã xác nhận, đúng FR-016. Bảng dạng bottom sheet vừa với màn hình 320 dp khi cuộn được.
- **Phương án đã cân nhắc**: Giữ nháp trong ViewModel: thêm trạng thái và phải tự dọn khi bảng đóng bất thường.

## R6. Điều hướng và giữ trạng thái (FR-002, FR-013, FR-015)

- **Quyết định**:
  - Trang chủ mở `MenuSearchView` bằng `Navigator.push` trên navigator gốc, nên màn hình tìm kiếm phủ toàn màn hình và ẩn thanh tab dưới.
  - Ô tìm kiếm mở với `openFilters: false` và ô nhập tự focus. Nút lọc mở với `openFilters: true`: không tự focus, bảng lọc mở sau frame đầu.
  - `menuSearchViewModelProvider` là `NotifierProvider.autoDispose`: tồn tại khi màn hình còn trong stack (kể cả khi đang mở chi tiết món) và bị hủy khi người dùng quay về Trang chủ. Vì vậy mỗi lần mở lại đều bắt đầu từ mặc định, không mang danh mục của Trang chủ sang.
  - `ScrollController` và `TextEditingController` sống trong `State` của view, nên vị trí cuộn và từ khóa giữ nguyên khi quay lại từ chi tiết.
- **Lý do**: Đúng FR-013 và FR-015 mà không cần lưu trạng thái thủ công. Cách mở chi tiết giống Trang chủ.
- **Phương án đã cân nhắc**: Tìm kiếm là một tab trong `MainShell`: tab giữ trạng thái lâu dài, trái với FR-015.

## R7. Danh mục bị gỡ khi đang lọc, ngoại tuyến và lỗi (edge cases, FR-012)

- **Quyết định**:
  - ViewModel nghe `menuCategoriesProvider` để có danh sách danh mục cho bảng lọc. Nếu danh mục đang lọc không còn trong danh sách nhận từ máy chủ (không phải từ cache), ViewModel bỏ bộ lọc danh mục và phát thông báo một lần `categoryRemoved`, View hiện SnackBar. Đây là cùng cách làm với Home của tính năng 002.
  - Ngoại tuyến dùng lại `menuOfflineGraceProvider`: chỉ coi là ngoại tuyến khi `isFromCache` kéo dài quá 2 giây.
  - Lỗi tải hiện `AppErrorView` kèm "Thử lại", gọi `ref.invalidate` các luồng. Từ khóa và bộ lọc nằm trong state riêng nên không bị mất khi thử lại.
- **Lý do**: Hành vi nhất quán với Trang chủ, dùng lại widget và provider có sẵn.

## R8. Kiểm thử

- **Quyết định**:
  - Unit test cho `normalizeSearchText` và `searchMenuItems` (bảng ví dụ từ thực đơn mẫu Ngô Chicken, gồm SC-002: 4 ký tự đầu của mỗi từ đều tìm thấy món).
  - Unit test ViewModel với `FakeMenuRepository` (thêm `watchSearchableItems`).
  - Widget test cho `MenuSearchView`, bảng lọc, nhãn bộ lọc, trạng thái rỗng/lỗi/ngoại tuyến, ở 320 dp và cỡ chữ 1,3×.
  - Cập nhật widget test Trang chủ: chạm ô tìm kiếm hoặc nút lọc mở màn hình tìm kiếm.
  - Thêm rules test R11: truy vấn tìm kiếm (limit 300) được chấp nhận với Guest. Trường hợp thiếu `isCategoryPublished` đã có R2.
- **Lý do**: Constitution V yêu cầu kiểm thử quy tắc domain và ViewModel. Rules không đổi nhưng thêm một ca để khóa hình dạng truy vấn mới.

## R9. Phụ thuộc

- **Quyết định**: Không thêm phụ thuộc runtime hay dev mới.
- **Lý do**: Mọi việc dùng Flutter, `flutter_riverpod` và `cloud_firestore` sẵn có.
