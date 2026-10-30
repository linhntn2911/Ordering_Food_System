# Mô hình dữ liệu (Data Model): Chi tiết món

**Tính năng**: `004-food-details` | **Ngày**: 2026-10-20 | **Spec**: [spec.md](spec.md)

## Firestore

### `menu_items/{menuItemId}` (không đổi schema)

Dùng các trường sẵn có: `name`, `description`, `imageUrl`, `basePrice`, `sizes`, `toppings`, `isAvailable`, `ratingAverage`, `reviewCount`, `isPublished`, `isCategoryPublished`.

### `menu_items/{menuItemId}/reviews/{reviewId}` (mới, bản công khai)

| Trường | Kiểu | Ràng buộc |
|---|---|---|
| `rating` | int | 1–5 |
| `comment` | string | Có thể rỗng; ≤ 500 ký tự (FR-028 gốc) |
| `imageUrls` | array<string> | ≤ 3 phần tử |
| `isAnonymous` | bool | |
| `isEdited` | bool | |
| `createdAt` | timestamp | Thời gian máy chủ |
| `updatedAt` | timestamp | Thời gian máy chủ |

- **Không có** `customerId`, `orderId`, `orderItemId` hay tên khách (research R1).
- `reviewId` trùng với `reviews/{reviewId}` gốc.
- **Bất biến**: hệ thống tin cậy tạo, sửa, xóa bản công khai cùng batch với tài liệu gốc và với cập nhật `ratingAverage`/`reviewCount` của món.
- Đọc: công khai khi món cha đọc được công khai; Admin đọc tất cả. Ghi: không client nào.

### `reviews/{reviewId}` (thay đổi quyền đọc)

Schema giữ nguyên. Quyền đọc thu hẹp: chỉ chủ đánh giá hoặc Admin (trước đây công khai).

## Domain

### `MenuItem` (sửa)

Thêm `toppings: List<MenuOption>` (mặc định rỗng, không sửa đổi được).

### `MenuItemFeed` (mới)

`lib/features/menu/domain/entities/menu_item_feed.dart`

| Trường | Kiểu | Ghi chú |
|---|---|---|
| `item` | `MenuItem?` | `null`: món không tồn tại hoặc không còn được bán |
| `isFromCache` | `bool` | Theo metadata của snapshot |

### `ItemSelection` (mới, bất biến)

`lib/features/menu/domain/entities/item_selection.dart`

| Trường | Kiểu | Mặc định | Ràng buộc |
|---|---|---|---|
| `sizeId` | `String?` | Size `priceDelta` nhỏ nhất (cùng giá: size đứng trước); `null` khi món không có size | Phải thuộc `item.sizes` |
| `toppingIds` | `Set<String>` | rỗng | Mỗi id thuộc `item.toppings` |
| `quantity` | `int` | 1 | 1–99 (`minQuantity`, `maxQuantity`) |
| `note` | `String` | `''` | ≤ 200 ký tự (`maxNoteLength`); chỉ khoảng trắng coi là trống |

Phương thức:

- `ItemSelection.initial(MenuItem item)`.
- `withSize(item, id)`, `toggleTopping(item, id)` (bỏ qua id không thuộc món), `withQuantity(n)` (kẹp trong 1–99), `withNote(text)` (cắt ở 200 ký tự).
- `int unitPrice(MenuItem item)` = `basePrice + size.priceDelta + Σ topping.priceDelta`.
- `int total(MenuItem item)` = `unitPrice × quantity`.
- `({ItemSelection selection, bool removedOptions}) reconcile(MenuItem item)`: bỏ id không còn tồn tại; size không còn thì về size mặc định.
- `String get trimmedNote`.

### `Review` (mới)

`lib/features/reviews/domain/entities/review.dart`

| Trường | Kiểu |
|---|---|
| `id` | `String` |
| `rating` | `int` (1–5) |
| `comment` | `String` |
| `imageUrls` | `List<String>` (≤ 3) |
| `isAnonymous` | `bool` |
| `isEdited` | `bool` |
| `createdAt` | `DateTime` |

- `String get authorLabel => isAnonymous ? 'Khách hàng ẩn danh' : 'Khách hàng'`.

### `ReviewModel` (data)

`lib/features/reviews/data/models/review_model.dart`. `fromMap` ném `FormatException` khi `rating` ngoài 1–5 hoặc thiếu `createdAt`. `imageUrls` bỏ phần tử không phải chuỗi rỗng và lấy tối đa 3.

## Trạng thái trình bày

### `MenuItemDetailState` (bất biến)

`lib/features/menu/presentation/viewmodels/menu_item_detail_state.dart`

| Trường | Kiểu | Ghi chú |
|---|---|---|
| `status` | `MenuItemDetailStatus` | `loading`, `ready`, `unavailable`, `error` |
| `item` | `MenuItem?` | Khi `ready` |
| `selection` | `ItemSelection?` | Khi `ready` |
| `isOffline` | `bool` | Sau khoảng chờ |
| `error` | `MenuFailure?` | Khi `error` |
| `reviews` | `ReviewSectionState` | |
| `notice` | `MenuItemDetailNotice?` | `optionsRemoved`, `reviewsNeedConnection`, `addToCartUnavailable` |

Thuộc tính suy ra: `unitPrice`, `total`, `canOrder` (= `ready && item.isAvailable`).

### `ReviewSectionState` (bất biến)

| Trường | Kiểu |
|---|---|
| `status` | `ReviewSectionStatus` (`loading`, `ready`, `error`) |
| `reviews` | `List<Review>` |
| `hasMore` | `bool` |
| `isLoadingMore` | `bool` |

### Chuyển trạng thái màn hình

```text
loading ──(feed có món)──▶ ready ──(feed item == null)──▶ unavailable
   │                         │
   ├──(feed item == null)──▶ unavailable
   └──(lỗi / cache rỗng quá khoảng chờ)──▶ error ──(Thử lại)──▶ loading
```

Phần đánh giá có vòng `loading → ready | error` riêng; lỗi đánh giá không đổi `status` của màn hình.

## Quy tắc kiểm tra

- `total` đúng với mọi tổ hợp size × topping × số lượng (SC-002).
- Không có trường nào trong `Review` chứa dữ liệu định danh khách (SC-003).
- Món không còn hàng: `canOrder == false`; mọi hàm thay đổi lựa chọn trong ViewModel không làm gì.
