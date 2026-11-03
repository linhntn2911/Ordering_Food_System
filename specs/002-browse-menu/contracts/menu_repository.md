# Contract: `MenuRepository`

**Vị trí**: `lib/features/menu/domain/repositories/menu_repository.dart`

Giao diện domain mà ViewModel dùng. Không có kiểu Firebase nào lộ ra ngoài. Mọi danh sách trả về đều không sửa đổi được.

```dart
abstract interface class MenuRepository {
  /// Danh mục đã đăng bán, theo sortOrder rồi name. Tối đa [limit].
  Stream<MenuFeed<MenuCategory>> watchPublishedCategories({int limit = 50});

  /// Món đã đăng bán thuộc danh mục đã đăng bán, gồm cả món hết hàng.
  /// categoryId == null: theo categorySortOrder, categoryId, sortOrder, name.
  /// categoryId != null: chỉ danh mục đó, theo sortOrder, name.
  Stream<MenuFeed<MenuItem>> watchBrowsableItems({
    String? categoryId,
    required int limit,
  });

  /// Tối đa [limit] món còn hàng, theo ratingAverage giảm, reviewCount giảm,
  /// name tăng. Đã loại món reviewCount == 0.
  Stream<MenuFeed<MenuItem>> watchPopularItems({int limit = 5});

  /// Một món để mở chi tiết; phát null khi món không còn đọc được.
  Stream<MenuItem?> watchItem(String menuItemId);
}
```

## Hành vi bắt buộc

| Mã | Hành vi |
|---|---|
| C1 | Mọi truy vấn danh sách món PHẢI có `isPublished == true` và `isCategoryPublished == true` (để rules chấp nhận). |
| C2 | `limit` ngoài khoảng 1–100 → `RangeError`. |
| C3 | `MenuFeed.isFromCache` phản ánh metadata của snapshot; luồng phát lại khi chỉ metadata thay đổi. |
| C4 | `MenuFeed.hasMore == (số tài liệu nhận được == limit)`. |
| C5 | Tài liệu sai định dạng (thiếu `name`, `basePrice`, …) bị bỏ qua và không làm hỏng cả luồng; lỗi quyền hoặc mạng được chuyển thành `MenuFailure` (`permissionDenied`, `unavailable`, `unknown`). |
| C6 | Trường mới thiếu trên tài liệu cũ: `sizes` → rỗng, `ratingAverage` → 0, `reviewCount` → 0. |

Bản giả lập `FakeMenuRepository` trong `test/` phải tuân theo cùng contract này.
