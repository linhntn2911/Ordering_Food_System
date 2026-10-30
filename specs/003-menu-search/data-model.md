# Mô hình dữ liệu (Data Model): Tìm kiếm và lọc thực đơn

**Tính năng**: `003-menu-search` | **Ngày**: 2026-10-20 | **Spec**: [spec.md](spec.md)

Tính năng không thêm collection hay trường Firestore nào. `menu_items` và `categories` giữ nguyên như [tính năng 002](../002-browse-menu/data-model.md). Mọi thực thể dưới đây chỉ tồn tại trong bộ nhớ, trong phiên tìm kiếm.

## Thực thể dùng lại

| Thực thể | Nguồn | Trường dùng trong tìm kiếm |
|---|---|---|
| `MenuItem` | `lib/features/menu/domain/entities/menu_item.dart` | `id`, `categoryId`, `name`, `isAvailable`, `priceRange.min`, `ratingAverage`, `reviewCount`, `hasRating`; thứ tự đầu vào = thứ tự thực đơn |
| `MenuCategory` | `lib/features/menu/domain/entities/menu_category.dart` | `id`, `name` (danh sách chọn trong bảng lọc, nhãn bộ lọc) |
| `MenuFeed<T>` | `lib/features/menu/domain/entities/menu_feed.dart` | `items`, `isFromCache`, `hasMore` |

## Thực thể mới (domain)

### `MenuSortOrder` (enum)

`lib/features/menu/domain/entities/menu_search_query.dart`

| Giá trị | Nhãn | Quy tắc (research R3) |
|---|---|---|
| `relevance` | Phù hợp nhất (mặc định) | Tên bắt đầu bằng từ khóa trước, sau đó thứ tự thực đơn |
| `priceAsc` | Giá thấp đến cao | `priceRange.min` tăng dần, cùng giá theo tên |
| `priceDesc` | Giá cao đến thấp | `priceRange.min` giảm dần, cùng giá theo tên |
| `ratingDesc` | Đánh giá cao | Có đánh giá trước; `ratingAverage` giảm, `reviewCount` giảm, tên; chưa có đánh giá ở cuối theo thứ tự thực đơn |

### `MenuSearchFilters` (bất biến)

Phần do bảng lọc quản lý và được áp dụng cùng lúc bằng "Áp dụng" (FR-016).

| Trường | Kiểu | Mặc định | Ghi chú |
|---|---|---|---|
| `categoryId` | `String?` | `null` ("Tất cả") | Đúng một danh mục hoặc tất cả (FR-006) |
| `availableOnly` | `bool` | `false` | FR-007 |
| `sortOrder` | `MenuSortOrder` | `relevance` | FR-010 |

- `static const defaults = MenuSearchFilters()`.
- `bool get isDefault`: cả ba trường đều mặc định. Dùng để ẩn nút "Xóa bộ lọc".
- `copyWith(...)`, có cách đặt `categoryId` về `null` (ví dụ tham số `clearCategory`).
- So sánh bằng giá trị (`==`/`hashCode`), để ViewModel và test so sánh được.

### `MenuSearchQuery` (bất biến)

| Trường | Kiểu | Ghi chú |
|---|---|---|
| `keyword` | `String` | Từ khóa đã áp dụng (sau debounce), chưa chuẩn hóa; tối đa 50 ký tự sau khi cắt khoảng trắng |
| `filters` | `MenuSearchFilters` | |

- `String get normalizedKeyword => normalizeSearchText(keyword)`.
- `bool get hasKeyword => normalizedKeyword.isNotEmpty` (từ khóa chỉ gồm khoảng trắng coi như trống).

### Hàm thuần

| Hàm | Tệp | Hợp đồng |
|---|---|---|
| `String normalizeSearchText(String input)` | `lib/core/utils/search_text.dart` | Chữ thường; bỏ dấu tiếng Việt; `đ`→`d`; gộp khoảng trắng; cắt hai đầu. Giữ nguyên ký tự khác. Idempotent. |
| `String limitSearchKeyword(String input)` | cùng tệp | Cắt khoảng trắng hai đầu rồi lấy tối đa 50 ký tự đầu (theo rune). |
| `List<MenuItem> searchMenuItems(List<MenuItem> items, MenuSearchQuery query)` | `lib/features/menu/domain/services/menu_search.dart` | Lọc danh mục → còn hàng → từ khóa, rồi sắp xếp ổn định theo `sortOrder`. Không đổi danh sách đầu vào. |

## Trạng thái trình bày (presentation)

### `MenuSearchState` (bất biến)

`lib/features/menu/presentation/viewmodels/menu_search_state.dart`

| Trường | Kiểu | Ghi chú |
|---|---|---|
| `query` | `MenuSearchQuery` | Từ khóa đã áp dụng và bộ lọc |
| `status` | `MenuSearchStatus` | `loading`, `ready`, `error` |
| `results` | `List<MenuItem>` | Kết quả của `searchMenuItems`; rỗng khi đang tải hoặc lỗi |
| `categories` | `List<MenuCategory>` | Danh mục đã đăng bán cho bảng lọc |
| `isOffline` | `bool` | Sau khoảng chờ `menuOfflineGraceProvider` |
| `error` | `MenuFailure?` | Khi `status == error` (cùng tên trường với `HomeMenuState`) |
| `notice` | `MenuSearchNotice?` | Thông báo một lần: `categoryRemoved` |

Thuộc tính suy ra:

- `MenuSearchFilters get filters => query.filters`.
- `bool get isEmptyResult => status == ready && results.isEmpty` (hiện "Không tìm thấy món phù hợp").
- `MenuCategory? get selectedCategory`: tra theo `query.filters.categoryId`.

### Chuyển trạng thái

```text
loading ──(feed đầu tiên)──▶ ready ──(feed mới / đổi query)──▶ ready
   │                           │
   └──(lỗi)──▶ error ◀──(lỗi)──┘
                 │
                 └──(Thử lại)──▶ loading (query giữ nguyên)
```

- Feed từ cache, rỗng, và chưa từng có feed từ máy chủ: coi là `error` (unavailable), giống Trang chủ.
- Đổi từ khóa, bộ lọc hoặc cách sắp xếp không mở luồng mới. Kết quả chỉ được tính lại trên danh sách món hiện có.

## Quy tắc kiểm tra

- Kết quả không bao giờ chứa món chưa đăng bán hoặc thuộc danh mục chưa đăng bán: rules và truy vấn đã chặn (SC-003).
- Khi `availableOnly == true`, mọi món trong `results` có `isAvailable == true` (SC-004).
- `filters.categoryId` luôn là `null` hoặc id của một danh mục đã đăng bán. ViewModel tự đặt về `null` khi danh mục biến mất.
