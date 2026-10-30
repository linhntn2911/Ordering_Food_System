# Contract: `MenuRepository.watchSearchableItems`

Bổ sung cho [contract của tính năng 002](../../002-browse-menu/contracts/menu_repository.md). Các phương thức sẵn có giữ nguyên.

## Chữ ký

```dart
/// Every published item of published categories, including sold-out items,
/// in menu order (category order, category, item order, name).
///
/// Used by search, which filters and sorts on the client.
Stream<MenuFeed<MenuItem>> watchSearchableItems({int limit = 300});
```

## Hành vi

| # | Điều kiện | Kết quả |
|---|---|---|
| S1 | Gọi bình thường | Truy vấn `menu_items` với `isPublished == true`, `isCategoryPublished == true`, `orderBy categorySortOrder, categoryId, sortOrder, name`, `limit(limit)` |
| S2 | `limit < 1` hoặc `limit > 500` | Ném `RangeError` ngay khi gọi |
| S3 | Snapshot chỉ đổi metadata | Phát lại feed với `isFromCache` mới |
| S4 | Số tài liệu nhận được bằng `limit` | `hasMore == true` (ViewModel bỏ qua, chỉ dùng để chẩn đoán) |
| S5 | Tài liệu sai định dạng | Bỏ qua tài liệu đó, không làm hỏng feed |
| S6 | Lỗi Firestore | Phát `MenuFailure` (`permissionDenied`, `unavailable`, `unknown`) như các luồng khác |

## Chỉ mục và rules

- Dùng lại chỉ mục tổng hợp `menu_items (isPublished, isCategoryPublished, categorySortOrder, categoryId, sortOrder, name)` của tính năng 002. Không thêm chỉ mục.
- Rules không đổi. Trường hợp thiếu bộ lọc đã có R2. Thêm một ca kiểm thử để khóa hình dạng truy vấn mới:

| ID | Người gọi | Thao tác | Kỳ vọng |
|---|---|---|---|
| R11 | Guest | `list` món với hai bộ lọc, sắp xếp thực đơn, `limit(300)` | Cho phép |

## Provider

```dart
final searchableItemsProvider =
    StreamProvider.autoDispose<MenuFeed<MenuItem>>((ref) {
      return ref.watch(menuRepositoryProvider).watchSearchableItems();
    }, retry: _noAutomaticRetry);

/// Delay after the last keystroke before the keyword is applied.
/// Overridden in tests.
final menuSearchDebounceProvider = Provider<Duration>((ref) {
  return const Duration(milliseconds: 300);
});
```

## Fake cho kiểm thử

`test/support/fake_menu_repository.dart` thêm `searchRequests` (ghi lại `limit`) và `emitSearchableItems(items, {isFromCache})` / `emitSearchableError(failure)`, dùng cùng `_ReplayChannel` như các luồng khác.
