# Contract: Quyền truy cập đánh giá trên Firestore

## Rules (thay đoạn `reviews` trong `firestore.rules`)

```text
match /menu_items/{menuItemId} {
  // (giữ nguyên quy tắc hiện có của món)

  match /reviews/{reviewId} {
    // Public display copy without customer or order identifiers.
    allow get, list: if isAdmin() || isPubliclyVisibleItem(menuItemId);
    // Trusted code writes it with the private review in one batch.
    allow create, update, delete: if false;
  }
}

match /reviews/{reviewId} {
  // Private review: owner and Admin only.
  allow read: if signedIn()
    && (resource.data.customerId == request.auth.uid || isAdmin());
  allow create, update, delete: if false;
}

function isPubliclyVisibleItem(menuItemId) {
  let item = get(/databases/$(database)/documents/menu_items/$(menuItemId)).data;
  return item.isPublished == true && item.isCategoryPublished == true;
}
```

`get()` tính thêm một lượt đọc cho mỗi truy vấn đánh giá, chấp nhận được vì mỗi màn hình chi tiết chỉ có một truy vấn.

## Chỉ mục

Không thêm. Truy vấn `orderBy('createdAt', descending)` trên một subcollection dùng chỉ mục đơn trường tự động. Chỉ mục `reviews (menuItemId, createdAt)` hiện có giữ lại cho Admin.

## Kiểm thử rules bắt buộc (`tests/firestore_rules/`)

| Mã | Người gọi | Thao tác | Kết quả |
|---|---|---|---|
| R12 | Guest | `list` đánh giá công khai của món đã đăng bán, `orderBy createdAt desc`, `limit 5` | Cho phép |
| R13 | Guest | `list` đánh giá công khai của món chưa đăng bán hoặc thuộc danh mục chưa đăng bán | Từ chối |
| R14 | Customer | `create` đánh giá công khai | Từ chối |
| R15 | Guest | `get` một tài liệu `reviews/{id}` gốc | Từ chối |
| R16 | Customer chủ đánh giá | `get` `reviews/{id}` của mình | Cho phép; Customer khác: từ chối |
| R17 | Admin | `list` đánh giá công khai của món chưa đăng bán | Cho phép |

## Tài liệu kéo theo

`docs/database_schema.md`: thêm mục `menu_items/{menuItemId}/reviews/{reviewId}` (trường, bất biến ghi cùng batch, không có định danh khách) và sửa quyền đọc của `reviews/{reviewId}`.
