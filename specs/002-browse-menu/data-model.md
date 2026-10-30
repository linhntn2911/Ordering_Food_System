# Mô hình dữ liệu (Data Model): Duyệt thực đơn

**Tính năng**: `002-browse-menu` | **Ngày**: 2026-10-20

Tài liệu này chỉ mô tả phần dữ liệu mà tính năng duyệt thực đơn đọc. Schema đầy đủ nằm ở `docs/database_schema.md`; các thay đổi bên dưới phải được cập nhật vào đó.

## Firestore

### `categories/{categoryId}` (không đổi cấu trúc)

| Trường | Kiểu | Bắt buộc | Ghi chú |
|---|---|---:|---|
| `name` | string | có | Tên hiển thị, không rỗng |
| `imageUrl` | string | không | Rỗng thì dùng ảnh thay thế |
| `sortOrder` | int | có | Thứ tự hiển thị, tăng dần |
| `isPublished` | bool | có | Chỉ danh mục `true` mới đọc công khai được |
| `createdAt`, `updatedAt` | timestamp | có | Server timestamp |

### `menu_items/{menuItemId}` (thêm trường)

| Trường | Kiểu | Bắt buộc | Ghi chú |
|---|---|---:|---|
| `categoryId` | string | có | Tham chiếu `categories/{categoryId}` |
| `name` | string | có | Không rỗng |
| `description` | string | không | |
| `imageUrl` | string | không | Rỗng thì dùng ảnh thay thế |
| `basePrice` | int | có | VND, ≥ 0 |
| `sizes` | array<map> | không | `{ id: string, name: string, priceDelta: int ≥ 0 }` |
| `toppings` | array<map> | không | `{ id: string, name: string, priceDelta: int ≥ 0 }`; không dùng khi duyệt |
| `isPublished` | bool | có | |
| `isAvailable` | bool | có | `false` thì hiện nhãn "Hết hàng" |
| `sortOrder` | int | có | Thứ tự trong danh mục |
| `ratingAverage` | number | có | 0 khi chưa có đánh giá, ngược lại 1–5 |
| `reviewCount` | int | có | ≥ 0 |
| **`isCategoryPublished`** | bool | có | **Mới.** Bản sao `categories.isPublished` của danh mục sở hữu |
| **`categorySortOrder`** | int | có | **Mới.** Bản sao `categories.sortOrder` của danh mục sở hữu |
| `createdAt`, `updatedAt` | timestamp | có | Server timestamp |

**Bất biến phi chuẩn hóa**: với mọi món, `isCategoryPublished` và `categorySortOrder` phải bằng giá trị tương ứng của danh mục sở hữu. Ai đổi danh mục (Admin hoặc trusted code) phải cập nhật mọi món của danh mục đó trong cùng một batch hoặc transaction.

## Quyền đọc (thay cho câu cũ "Published and available items are publicly readable")

- Danh mục: đọc công khai khi `isPublished == true`; Admin đọc tất cả.
- Món: đọc công khai khi `isPublished == true && isCategoryPublished == true`, bất kể `isAvailable`; Admin đọc tất cả.
- Guest và Customer không được ghi `categories` hay `menu_items` (FR-012).

## Domain (Dart, bất biến)

### `MenuCategory`

`id`, `name`, `imageUrl`, `sortOrder`.

### `MenuItem` (mở rộng entity hiện có)

Thêm: `sizes: List<MenuOption>` (không sửa đổi được), `isCategoryPublished`, `categorySortOrder`.

Thuộc tính suy ra:

- `priceRange` → `PriceRange(min, max)`; `min == max` nghĩa là một giá.
- `hasRating` → `reviewCount > 0`.

### `MenuOption`

`id`, `name`, `priceDelta` (int ≥ 0). Dùng cho cả size và topping.

### `MenuFeed<T>`

Kết quả một luồng duyệt: `items: List<T>` (không sửa đổi được), `isFromCache: bool`, `hasMore: bool` (`items.length == limit` đã yêu cầu).

## Trạng thái màn hình (Presentation)

### `HomeMenuState`

| Trường | Kiểu | Ghi chú |
|---|---|---|
| `status` | enum `loading \| data \| empty \| error` | `empty`: không có danh mục hoặc món nào hiển thị được |
| `categories` | `List<MenuCategory>` | Thanh danh mục |
| `selectedCategoryId` | `String?` | `null` = "Tất cả" |
| `sections` | `List<MenuSection>` | "Tất cả": nhiều nhóm; một danh mục: một nhóm |
| `popular` | `List<MenuItem>` | Rỗng thì ẩn mục "Phổ biến" |
| `isOffline` | bool | Hiện nhãn ngoại tuyến |
| `hasMore`, `isLoadingMore` | bool | Tải dần |
| `notice` | `HomeMenuNotice?` | Thông báo một lần, ví dụ danh mục đang chọn vừa bị gỡ |
| `error` | `MenuFailure?` | Khi `status == error` |

`MenuSection`: `categoryId`, `title`, `items`.

### Chuyển trạng thái

- Mở màn hình → `loading`.
- Snapshot đầu tiên có dữ liệu → `data`; có danh mục nhưng danh mục đang chọn không có món → `data` với nhóm rỗng (trạng thái "danh mục trống").
- Không có danh mục hoặc món nào, snapshot từ máy chủ → `empty`.
- Snapshot từ cache rỗng và chưa từng có snapshot từ máy chủ → `error` (ngoại tuyến, có nút thử lại).
- Lỗi luồng → `error`; `retry()` → `loading`.
- Danh mục đang chọn biến khỏi danh sách danh mục → `selectedCategoryId = null`, đặt `notice`.
- Món có `categoryId` không thuộc danh sách danh mục đang hiển thị → bị bỏ khỏi `sections` và `popular`.
- `loadMore()` → giữ `sections` cũ, `isLoadingMore = true`, `status` vẫn là `data` tới khi có snapshot mới.
- Snapshot từ cache kéo dài quá 2 giây → `isOffline = true`; snapshot máy chủ → `isOffline = false`. Cache rỗng và chưa từng có snapshot máy chủ → giữ `loading` trong 2 giây, sau đó `error`.
