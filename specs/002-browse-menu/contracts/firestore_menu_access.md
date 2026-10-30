# Contract: Truy cập Firestore cho thực đơn

## Rules (thay đoạn `categories` và `menu_items` trong `firestore.rules`)

```text
match /categories/{categoryId} {
  allow get, list: if isAdmin() || resource.data.isPublished == true;
  allow create, update, delete: if isAdmin();
}

match /menu_items/{menuItemId} {
  allow get, list: if isAdmin()
    || (resource.data.isPublished == true
        && resource.data.isCategoryPublished == true);
  allow create, update, delete: if isAdmin();
}
```

## Truy vấn và chỉ mục (`firestore.indexes.json`)

| Truy vấn | Bộ lọc | Sắp xếp | Chỉ mục tổng hợp |
|---|---|---|---|
| Danh mục | `isPublished ==` | `sortOrder`, `name` | `isPublished ↑, sortOrder ↑, name ↑` |
| Món – Tất cả | `isPublished ==`, `isCategoryPublished ==` | `categorySortOrder`, `categoryId`, `sortOrder`, `name` | `isPublished ↑, isCategoryPublished ↑, categorySortOrder ↑, categoryId ↑, sortOrder ↑, name ↑` |
| Món – theo danh mục | `categoryId ==`, `isPublished ==`, `isCategoryPublished ==` | `sortOrder`, `name` | `categoryId ↑, isPublished ↑, isCategoryPublished ↑, sortOrder ↑, name ↑` |
| Phổ biến | `isPublished ==`, `isCategoryPublished ==`, `isAvailable ==` | `ratingAverage ↓`, `reviewCount ↓`, `name ↑` | `isPublished ↑, isCategoryPublished ↑, isAvailable ↑, ratingAverage ↓, reviewCount ↓, name ↑` |

Hai chỉ mục `menu_items` cũ có `isAvailable` trong danh sách chính không còn được dùng và được thay bằng các chỉ mục trên.

## Kiểm thử rules bắt buộc (`tests/firestore_rules/`)

| Mã | Người gọi | Thao tác | Kết quả |
|---|---|---|---|
| R1 | Guest | `list` món có đủ hai bộ lọc | Cho phép |
| R2 | Guest | `list` món thiếu `isCategoryPublished ==` | Từ chối |
| R3 | Guest | `get` món `isPublished == false` | Từ chối |
| R4 | Guest | `get` món đã đăng bán, `isCategoryPublished == false` | Từ chối |
| R5 | Guest | `get` món đã đăng bán, `isAvailable == false` | Cho phép |
| R6 | Guest | `get` danh mục `isPublished == false` | Từ chối |
| R7 | Customer | `update` một món bất kỳ | Từ chối |
| R8 | Customer | `create` một danh mục | Từ chối |
| R9 | Admin | `get` món chưa đăng bán | Cho phép |
| R10 | Customer | `list` món có đủ hai bộ lọc | Cho phép |
| R11 | Guest | `list` món có đủ hai bộ lọc, sắp theo thứ tự thực đơn, `limit(300)` (truy vấn tìm kiếm của `specs/003-menu-search`) | Cho phép |
| R12–R17 | Guest, Customer, Admin | Đánh giá công khai `menu_items/{id}/reviews` và đánh giá gốc `reviews` (xem `specs/004-food-details/contracts/firestore_review_access.md`) | Theo contract của tính năng 004 |
