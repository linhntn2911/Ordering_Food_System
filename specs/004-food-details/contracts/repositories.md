# Contract: Repository cho chi tiết món

## `MenuRepository.watchItem` (đổi chữ ký)

```dart
/// One item for the details screen with snapshot metadata.
///
/// Emits a feed whose `item` is null when the document does not exist,
/// is malformed, or is no longer publicly readable (permission-denied);
/// the stream then stays open for later changes where possible.
Stream<MenuItemFeed> watchItem(String menuItemId);
```

| # | Điều kiện | Kết quả |
|---|---|---|
| I1 | Món đọc được | `MenuItemFeed(item: …, isFromCache: metadata.isFromCache)`, phát lại khi chỉ metadata đổi |
| I2 | Tài liệu không tồn tại hoặc sai định dạng | `item == null` |
| I3 | `permission-denied` (món hoặc danh mục bị gỡ đăng bán) | Phát `item == null` rồi đóng luồng; màn hình giữ trạng thái "không còn được bán" kể cả khi món được đăng bán lại (trường hợp biên của spec) |
| I4 | Lỗi khác | Phát `MenuFailure` |
| I5 | `MenuItem.toppings` | Có đủ topping hợp lệ của tài liệu |

## `ReviewRepository` (mới)

`lib/features/reviews/domain/repositories/review_repository.dart`

```dart
/// Read-only access to the public review copies of one menu item
/// (`menu_items/{menuItemId}/reviews`).
abstract interface class ReviewRepository {
  /// Newest first, at most [limit] reviews (1–100).
  Stream<MenuFeed<Review>> watchMenuItemReviews(
    String menuItemId, {
    required int limit,
  });
}
```

| # | Điều kiện | Kết quả |
|---|---|---|
| V1 | Gọi bình thường | `collection('menu_items/{id}/reviews').orderBy('createdAt', descending: true).limit(limit)`, `snapshots(includeMetadataChanges: true)` |
| V2 | `limit` ngoài 1–100 | `RangeError` |
| V3 | Tài liệu sai định dạng | Bỏ qua |
| V4 | `hasMore` | `true` khi số tài liệu nhận được bằng `limit` |
| V5 | Lỗi Firestore | `MenuFailure` (dùng lại ánh xạ lỗi của menu) |

`MenuFeed` và `MenuFailure` được dùng lại từ `lib/features/menu/domain/entities/`.

## Provider

```dart
// lib/features/reviews/presentation/review_providers.dart
final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return FirestoreReviewRepository(ref.watch(firebaseFirestoreProvider));
});

typedef MenuItemReviewsQuery = ({String menuItemId, int limit});

final menuItemReviewsProvider = StreamProvider.autoDispose
    .family<MenuFeed<Review>, MenuItemReviewsQuery>(...);

// lib/features/menu/presentation/viewmodels/menu_providers.dart (đổi kiểu)
final menuItemProvider =
    StreamProvider.autoDispose.family<MenuItemFeed, String>(...);
```

## Fake cho kiểm thử

- `FakeMenuRepository.emitItem(id, MenuItem? item, {bool isFromCache = false})` và `emitItemError(id, error)`.
- `test/support/fake_review_repository.dart`: `requests` (ghi lại `menuItemId`, `limit`), `emitReviews(menuItemId, reviews, {isFromCache, hasMore})`, `emitReviewsError(menuItemId, error)`.
