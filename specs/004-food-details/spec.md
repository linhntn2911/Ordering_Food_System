# Đặc tả tính năng (Feature Specification): Chi tiết món

**Nhánh tính năng (Feature Branch)**: `004-food-details`

**Ngày tạo (Created)**: 2026-10-20

**Trạng thái (Status)**: Bản nháp (Draft)

**Đầu vào (Input)**: Mô tả của người dùng: "FR-009: Food Details MUST show image, name, description, base price, available options, rating summary, availability, and reviews."

**Đặc tả gốc (Parent Specification)**: `specs/001-food-ordering-system/spec.md` (FR-009, User Story 9 kịch bản về đánh giá hiển thị ở chi tiết món, màn hình "Food Details" mức High của Member 2: "Options, quantity, reviews, add to cart")

**Tính năng liên quan**:

- `specs/002-browse-menu/spec.md` (User Story 4, FR-010): Trang chủ đã mở một màn hình chi tiết tối thiểu theo mã món. Tính năng này thay màn hình đó và giữ nguyên cách mở.
- `specs/003-menu-search/spec.md` (FR-013): kết quả tìm kiếm mở cùng màn hình chi tiết.

## Làm rõ (Clarifications)

### Phiên 2026-10-20

- H: Đánh giá không ẩn danh hiển thị danh tính người viết thế nào? → Đ: Luôn hiển thị "Khách hàng", không hiển thị tên; đánh giá ẩn danh vẫn ghi "Khách hàng ẩn danh". (Ban đầu chọn tên che một phần "Linh N.", sau đổi sang phương án này để không phải thêm dữ liệu và không lộ tên.)
- H: Nút "Thêm vào giỏ" có lưu vào giỏ thật không? → Đ: Không. Làm đủ phần chọn (tùy chọn, số lượng, ghi chú, giá tạm tính); nút "Thêm vào giỏ" chỉ báo "Tính năng đang được phát triển" cho tới khi có tính năng Giỏ hàng (FR-011 gốc).
- H: "Tóm tắt đánh giá" gồm những gì? → Đ: Chỉ điểm trung bình (một chữ số thập phân), dãy 5 ngôi sao và số lượt đánh giá; không có thanh phân bố theo số sao.
- H: Lựa chọn của người dùng có được giữ khi mở lại cùng món? → Đ: Không; mỗi lần mở chi tiết đều về mặc định (size giá thấp nhất, không topping, số lượng 1, ghi chú trống).
- H: Phần đánh giá hoạt động thế nào khi mất mạng? → Đ: Hiện các đánh giá đã lưu trên thiết bị dưới cùng nhãn ngoại tuyến; "Xem thêm đánh giá" báo cần kết nối mạng; chưa từng tải thì báo lỗi kèm "Thử lại" trong phần đánh giá.

## Kịch bản người dùng & Kiểm thử (User Scenarios & Testing) *(bắt buộc)*

### User Story 1 - Xem thông tin đầy đủ của một món (Ưu tiên: P1)

Guest hoặc Customer mở một món từ Trang chủ hoặc kết quả tìm kiếm và thấy ảnh lớn, tên, mô tả, giá cơ bản, tình trạng còn/hết hàng và tóm tắt đánh giá, để quyết định có chọn món hay không.

**Lý do ưu tiên**: Đây là phần cốt lõi của FR-009 và là bước tiếp theo bắt buộc trong hành trình đặt món sau khi duyệt hoặc tìm kiếm.

**Kiểm thử độc lập**: Nạp thực đơn mẫu Ngô Chicken, mở "Trà sữa trân châu đường đen" từ Trang chủ và xác nhận đủ ảnh (hoặc ảnh thay thế), tên, mô tả, giá, nhãn tình trạng và "4,9 (210 đánh giá)".

**Kịch bản chấp nhận**:

1. **Giả sử** một món đã đăng bán, **Khi** người dùng mở chi tiết món, **Thì** màn hình hiển thị ảnh lớn ở đầu, tên, mô tả, giá cơ bản bằng VND và tóm tắt đánh giá (điểm trung bình một chữ số thập phân, dãy 5 ngôi sao tương ứng và số lượt đánh giá; không có thanh phân bố theo số sao).
2. **Giả sử** món không có ảnh hoặc ảnh tải lỗi, **Khi** màn hình hiển thị, **Thì** dùng ảnh thay thế cùng kiểu với thẻ món, bố cục không bị xô lệch.
3. **Giả sử** món không có mô tả, **Khi** màn hình hiển thị, **Thì** phần mô tả được ẩn, không để khoảng trống hay chữ giữ chỗ.
4. **Giả sử** món chưa có đánh giá nào, **Khi** màn hình hiển thị, **Thì** tóm tắt đánh giá ghi "Chưa có đánh giá" thay vì "0,0".
5. **Giả sử** món đang hết hàng, **Khi** màn hình hiển thị, **Thì** có nhãn chữ "Hết hàng" rõ ràng gần tên món và mọi hành động đặt món bị vô hiệu kèm lý do.
6. **Giả sử** món có nhiều size, **Khi** màn hình hiển thị, **Thì** giá cơ bản thể hiện dạng khoảng giá giống thẻ món (ví dụ "20.000 – 25.000 ₫").
7. **Giả sử** người dùng đang xem chi tiết, **Khi** món bị gỡ đăng bán hoặc danh mục của món bị gỡ đăng bán, **Thì** màn hình chuyển sang trạng thái "Món này không còn được bán" kèm nút quay lại.
8. **Giả sử** người dùng đang xem chi tiết, **Khi** nhà hàng đổi giá, tên, mô tả, ảnh hoặc tình trạng còn hàng, **Thì** màn hình cập nhật mà không cần mở lại.
9. **Giả sử** người dùng mở chi tiết từ Trang chủ hoặc kết quả tìm kiếm, **Khi** quay lại, **Thì** về đúng màn hình trước với trạng thái được giữ nguyên (theo FR-010 của tính năng 002 và FR-013 của tính năng 003).

---

### User Story 2 - Xem và chọn tùy chọn của món (Ưu tiên: P1)

Người dùng xem các size và topping nhà hàng cung cấp cho món, chọn thử và thấy giá tạm tính thay đổi theo lựa chọn.

**Lý do ưu tiên**: "Available options" là một phần bắt buộc của FR-009; người dùng cần biết món có những lựa chọn nào và giá bao nhiêu trước khi đặt.

**Kiểm thử độc lập**: Mở "Trà đào" (size M 20.000 ₫, size L 25.000 ₫), chọn L và xác nhận giá tạm tính đổi thành 25.000 ₫; mở một món không có tùy chọn và xác nhận không có phần tùy chọn.

**Kịch bản chấp nhận**:

1. **Giả sử** món có size, **Khi** màn hình mở, **Thì** danh sách size hiển thị kèm phần giá cộng thêm (ví dụ "L +5.000 ₫"), chọn đúng một size, mặc định là size có giá thấp nhất.
2. **Giả sử** món có topping, **Khi** màn hình mở, **Thì** danh sách topping hiển thị kèm giá cộng thêm, chọn được nhiều topping hoặc không chọn topping nào, mặc định không chọn.
3. **Giả sử** người dùng đổi size hoặc topping, **Khi** lựa chọn thay đổi, **Thì** giá tạm tính bằng giá cơ bản + giá cộng thêm của size + tổng giá cộng thêm của các topping, cập nhật ngay.
4. **Giả sử** món không có size và không có topping, **Khi** màn hình mở, **Thì** không hiển thị phần tùy chọn; giá tạm tính bằng giá cơ bản.
5. **Giả sử** món đang hết hàng, **Khi** màn hình hiển thị, **Thì** các tùy chọn vẫn xem được nhưng không chọn được.
6. **Giả sử** người dùng đã chọn size, topping, số lượng hoặc ghi chú rồi rời màn hình, **Khi** mở lại chi tiết của cùng món, **Thì** mọi lựa chọn về mặc định: size giá thấp nhất, không topping, số lượng 1, ghi chú trống.
7. **Giả sử** nhà hàng xóa size hoặc topping mà người dùng đang chọn, **Khi** màn hình cập nhật, **Thì** lựa chọn đó bị bỏ (size quay về size mặc định), giá tạm tính tính lại và có thông báo ngắn.

---

### User Story 3 - Đọc đánh giá của khách đã mua (Ưu tiên: P2)

Người dùng đọc các đánh giá gần nhất của món (số sao, nội dung, ảnh, thời gian) để tin tưởng hơn khi chọn món.

**Lý do ưu tiên**: Đánh giá giúp quyết định mua nhưng màn hình vẫn dùng được khi chưa có đánh giá; việc viết đánh giá thuộc màn hình "Review Purchased Item" của Member 4.

**Kiểm thử độc lập**: Nạp vài đánh giá mẫu cho "Gà sốt cay ngọt Hàn Quốc", mở chi tiết và xác nhận các đánh giá hiển thị theo thứ tự mới nhất trước, có số sao, nội dung, ngày và tên người đánh giá theo quy tắc hiển thị.

**Kịch bản chấp nhận**:

1. **Giả sử** món có đánh giá, **Khi** người dùng cuộn tới phần "Đánh giá", **Thì** thấy tối đa 5 đánh giá mới nhất, mỗi đánh giá gồm tên người đánh giá, số sao (1–5), nội dung (nếu có), tối đa 3 ảnh thu nhỏ (nếu có), ngày đánh giá và nhãn "Đã chỉnh sửa" nếu đánh giá đã được sửa.
2. **Giả sử** món có hơn 5 đánh giá, **Khi** người dùng chạm "Xem thêm đánh giá", **Thì** tải thêm 10 đánh giá kế tiếp theo thứ tự mới nhất trước, đến khi hết.
3. **Giả sử** món chưa có đánh giá, **Khi** người dùng xem phần "Đánh giá", **Thì** thấy "Chưa có đánh giá cho món này".
4. **Giả sử** người đánh giá chọn ẩn danh, **Khi** đánh giá hiển thị, **Thì** tên hiển thị là "Khách hàng ẩn danh".
5. **Giả sử** người đánh giá không chọn ẩn danh, **Khi** đánh giá hiển thị, **Thì** tên hiển thị là "Khách hàng"; tên thật của người viết không bao giờ được hiển thị.
6. **Giả sử** nội dung đánh giá dài, **Khi** hiển thị, **Thì** chỉ hiện tối đa 4 dòng kèm "Xem thêm" để mở rộng tại chỗ.
7. **Giả sử** người dùng chạm một ảnh thu nhỏ, **Khi** ảnh mở, **Thì** ảnh được xem lớn toàn màn hình và đóng được để quay lại đúng vị trí.
8. **Giả sử** không tải được đánh giá, **Khi** phần "Đánh giá" hiển thị, **Thì** chỉ phần này báo lỗi kèm "Thử lại"; thông tin món phía trên vẫn hiển thị bình thường.
9. **Giả sử** mất mạng và đánh giá của món đã từng được tải, **Khi** phần "Đánh giá" hiển thị, **Thì** hiện các đánh giá đã lưu trên thiết bị dưới cùng nhãn ngoại tuyến của màn hình; chạm "Xem thêm đánh giá" thì báo ngắn "Cần kết nối mạng để tải thêm đánh giá".
10. **Giả sử** mất mạng và đánh giá của món chưa từng được tải, **Khi** phần "Đánh giá" hiển thị, **Thì** phần này báo lỗi kèm "Thử lại", thông tin món vẫn hiển thị.

---

### User Story 4 - Chọn số lượng, ghi chú và nút thêm vào giỏ (Ưu tiên: P2)

Từ chi tiết món, người dùng chọn số lượng, nhập ghi chú và thấy giá tạm tính cho cả lượt chọn; nút "Thêm vào giỏ" đã có sẵn ở vị trí cuối màn hình nhưng chưa lưu giỏ.

**Lý do ưu tiên**: Bảng phân công màn hình gốc ghi "quantity, add to cart" cho Food Details, nhưng việc lưu giỏ hàng thuộc FR-011 gốc và tính năng Giỏ hàng chưa có; tính năng đó sau này chỉ cần gắn hành động vào nút.

**Kiểm thử độc lập**: Mở "Trà đào", chọn size L, tăng số lượng lên 3, nhập ghi chú "ít đá": giá tạm tính là 75.000 ₫; chạm "Thêm vào giỏ" thấy thông báo "Tính năng đang được phát triển" và lựa chọn vẫn giữ nguyên.

**Kịch bản chấp nhận**:

1. **Giả sử** món còn hàng, **Khi** người dùng tăng/giảm số lượng, **Thì** số lượng nằm trong khoảng 1–99 và giá tạm tính nhân theo số lượng.
2. **Giả sử** món còn hàng, **Khi** người dùng chạm "Thêm vào giỏ", **Thì** hiện thông báo ngắn "Tính năng đang được phát triển", không có gì được lưu, và size, topping, số lượng, ghi chú vẫn giữ nguyên trên màn hình.
3. **Giả sử** món đang hết hàng, **Khi** màn hình hiển thị, **Thì** nút "Thêm vào giỏ" bị vô hiệu và ghi "Hết hàng".
4. **Giả sử** người dùng nhập ghi chú, **Khi** ghi chú vượt 200 ký tự, **Thì** không nhập thêm được và có bộ đếm ký tự còn lại.

---

### Trường hợp biên (Edge Cases)

- Mở chi tiết bằng mã món không tồn tại hoặc món chưa đăng bán: hiển thị "Món này không còn được bán" kèm nút quay lại, không lộ thông tin món.
- Mất mạng khi mở chi tiết: hiển thị dữ liệu món và các đánh giá đã lưu trên thiết bị kèm nhãn ngoại tuyến giống Trang chủ; chưa từng tải món đó thì báo lỗi kèm "Thử lại"; chưa từng tải đánh giá thì chỉ phần đánh giá báo lỗi.
- Món có size nhưng mọi size có cùng giá cộng thêm: giá cơ bản hiển thị một giá, không hiển thị khoảng giá.
- Tên món hoặc mô tả rất dài: tên xuống dòng không bị cắt mất; mô tả dài hơn 6 dòng được thu gọn kèm "Xem thêm".
- Đánh giá có số sao ngoài khoảng 1–5 hoặc thiếu dữ liệu: bỏ qua đánh giá đó, không làm hỏng danh sách.
- Đánh giá mới được thêm, sửa hoặc xóa khi đang xem: tóm tắt đánh giá và danh sách đánh giá cập nhật mà không cần mở lại; đánh giá mới xuất hiện ở đầu danh sách, các đánh giá đang hiển thị giữ nguyên thứ tự tương đối.
- Món bị gỡ đăng bán khi đang xem rồi được đăng bán lại: màn hình giữ trạng thái "Món này không còn được bán"; người dùng phải quay lại và mở lại món mới thấy thông tin.
- Ảnh đánh giá tải lỗi: hiển thị ô thay thế, không chặn các ảnh khác.
- Ghi chú có nội dung chỉ gồm khoảng trắng: coi như không có ghi chú.

## Yêu cầu (Requirements) *(bắt buộc)*

### Yêu cầu chức năng (Functional Requirements)

- **FR-001**: Guest và Customer PHẢI xem được chi tiết của mọi món đã đăng bán thuộc danh mục đã đăng bán mà không cần đăng nhập.
- **FR-002**: Màn hình PHẢI hiển thị ảnh món (hoặc ảnh thay thế), tên, mô tả (ẩn khi trống), giá cơ bản hoặc khoảng giá theo size bằng VND, tóm tắt đánh giá (điểm trung bình, dãy 5 ngôi sao và số lượt, ví dụ "4,9 (210 đánh giá)", hoặc "Chưa có đánh giá"; dãy sao có nhãn chữ cho trình đọc màn hình) và tình trạng còn/hết hàng bằng chữ.
- **FR-003**: Màn hình PHẢI hiển thị mọi size và topping của món kèm giá cộng thêm; size chọn đúng một (mặc định size giá thấp nhất), topping chọn không hoặc nhiều.
- **FR-004**: Giá tạm tính PHẢI bằng (giá cơ bản + giá cộng thêm của size + tổng giá cộng thêm của topping) × số lượng, và cập nhật ngay khi lựa chọn thay đổi.
- **FR-005**: Món hết hàng PHẢI vẫn xem được đầy đủ thông tin nhưng không chọn được tùy chọn, số lượng hay thêm vào giỏ, kèm lý do "Hết hàng".
- **FR-006**: Màn hình PHẢI hiển thị tối đa 5 đánh giá mới nhất của món, và cho tải thêm theo lượt 10 đánh giá.
- **FR-007**: Mỗi đánh giá PHẢI hiển thị tên người đánh giá theo quy tắc: ẩn danh → "Khách hàng ẩn danh"; không ẩn danh → "Khách hàng"; số sao 1–5 bằng biểu tượng kèm chữ cho trình đọc màn hình, nội dung (nếu có), tối đa 3 ảnh, ngày đánh giá và nhãn "Đã chỉnh sửa" khi có.
- **FR-008**: Màn hình PHẢI KHÔNG hiển thị mã người dùng, số điện thoại, email hay bất kỳ dữ liệu cá nhân nào của người đánh giá ngoài nhãn "Khách hàng" hoặc "Khách hàng ẩn danh".
- **FR-009**: Màn hình PHẢI có các trạng thái: đang tải, có dữ liệu, món không còn được bán, lỗi kèm "Thử lại", và nhãn ngoại tuyến; phần đánh giá có trạng thái tải, trống và lỗi riêng không ảnh hưởng phần thông tin món; khi ngoại tuyến phần đánh giá hiện đánh giá đã lưu và "Xem thêm đánh giá" báo cần kết nối mạng.
- **FR-010**: Thay đổi của món (đăng bán, còn/hết hàng, giá, tên, mô tả, ảnh, tùy chọn, tóm tắt đánh giá) PHẢI phản ánh lên màn hình đang mở mà không cần mở lại.
- **FR-011**: Khi tùy chọn đang chọn bị nhà hàng xóa, lựa chọn đó PHẢI bị bỏ, giá tạm tính được tính lại và người dùng được báo ngắn.
- **FR-012**: Người dùng PHẢI chọn được số lượng từ 1 đến 99 và nhập ghi chú tối đa 200 ký tự cho món.
- **FR-013**: Nút "Thêm vào giỏ" PHẢI hiển thị ở cuối màn hình kèm giá tạm tính; khi món còn hàng, chạm nút PHẢI báo "Tính năng đang được phát triển" và KHÔNG lưu dữ liệu nào cho tới khi có tính năng Giỏ hàng (FR-011 gốc); lựa chọn đang có PHẢI được giữ nguyên.
- **FR-014**: Màn hình chi tiết PHẢI được mở theo mã món từ Trang chủ và kết quả tìm kiếm, và quay lại PHẢI trả về đúng màn hình trước với trạng thái được giữ.
- **FR-015**: Giao diện PHẢI theo khung Product Detail của mẫu Food Ninja, chỉ chế độ sáng, dùng token và thẻ dùng chung của hệ thống thiết kế; không tràn bố cục ở chiều rộng 320 điểm ảnh logic và cỡ chữ 1,3×.
- **FR-016**: Size, topping, số lượng và ghi chú chỉ tồn tại khi màn hình chi tiết đang mở; mỗi lần mở chi tiết PHẢI bắt đầu với mặc định (size giá thấp nhất, không topping, số lượng 1, ghi chú trống).

### Thực thể chính (Key Entities)

- **Món (Menu Item)**: Dùng lại thực thể của tính năng 002 (tên, mô tả, ảnh, giá cơ bản, size, topping, còn hàng, điểm và số lượt đánh giá, trạng thái đăng bán).
- **Tùy chọn (Option)**: Size hoặc topping, gồm tên và giá cộng thêm không âm.
- **Lựa chọn tạm (Item Selection)**: Size đang chọn, các topping đang chọn, số lượng, ghi chú và giá tạm tính. Chỉ tồn tại khi màn hình đang mở.
- **Đánh giá (Review)**: Số sao, nội dung, tối đa 3 ảnh, cờ ẩn danh, cờ đã chỉnh sửa, thời điểm tạo, món được đánh giá. Không chứa tên hiển thị của người viết. Chỉ đọc trong tính năng này.

## Tiêu chí thành công (Success Criteria) *(bắt buộc)*

### Kết quả đo lường được (Measurable Outcomes)

- **SC-001**: Thông tin món (ảnh hoặc ảnh thay thế, tên, giá, tình trạng, tóm tắt đánh giá) hiện trong vòng 2 giây sau khi chạm món, với kết nối bình thường.
- **SC-002**: Giá tạm tính đúng trong 100% tổ hợp size × topping × số lượng của thực đơn mẫu.
- **SC-003**: Trong kiểm thử chấp nhận, 0 trường hợp lộ dữ liệu cá nhân của người đánh giá ngoài nhãn "Khách hàng"/"Khách hàng ẩn danh", và 0 món chưa đăng bán mở được chi tiết.
- **SC-004**: Thay đổi giá hoặc tình trạng còn hàng từ nhà hàng hiện trên màn hình đang mở trong vòng 5 giây.
- **SC-005**: Ít nhất 90% người tham gia kiểm thử trả lời đúng "món này có những size nào, giá bao nhiêu, còn hàng không" sau khi xem màn hình, không cần hướng dẫn.
- **SC-006**: Màn hình đọc được đầy đủ, không tràn bố cục ở chiều rộng 320 điểm ảnh logic và cỡ chữ 1,3×.

## Giả định (Assumptions)

- Phạm vi chính là FR-009 của đặc tả gốc. Yêu thích (FR-010 gốc), lưu giỏ hàng (FR-011 gốc), viết/sửa/xóa đánh giá (FR-027 – FR-031 gốc) và phản hồi của nhà hàng nằm ngoài phạm vi.
- Đánh giá được hiển thị từ một bản sao công khai của mỗi đánh giá, chỉ gồm thông tin hiển thị (số sao, nội dung, ảnh, cờ ẩn danh, cờ đã chỉnh sửa, thời điểm) và không chứa định danh khách hay đơn hàng. Bản gốc chứa định danh chỉ chủ đánh giá và Admin đọc được.
- **Phụ thuộc**: tính năng viết đánh giá (màn hình "Review Purchased Item" của Member 4) phải ghi bản sao công khai cùng lúc với đánh giá gốc và với điểm/số lượt trên món; nếu không, đánh giá sẽ không hiện ở chi tiết món. Tính năng này chỉ đọc bản sao công khai.
- Tóm tắt đánh giá dùng điểm trung bình và số lượt đánh giá đã lưu sẵn trên món (do nhà hàng/hệ thống tin cậy cập nhật), không tính lại từ danh sách đánh giá.
- Đánh giá là dữ liệu công khai chỉ đọc với Guest và Customer; quyền ghi thuộc hệ thống tin cậy như đặc tả gốc đã nêu.
- Đánh giá chỉ hiển thị khi món còn xem được; đánh giá của món chưa đăng bán không được hiển thị ở đâu trong tính năng này.
- Size mặc định là size có giá thấp nhất, cùng quy tắc "giá thấp nhất" dùng cho thẻ món và sắp xếp theo giá ở tính năng 003.
- Giới hạn số lượng 1–99 và ghi chú 200 ký tự là giá trị mặc định hợp lý cho đến khi đặc tả gốc chốt giới hạn số lượng giỏ hàng (đang là mục cần làm rõ của đặc tả gốc).
- Dữ liệu mẫu hiện chưa có đánh giá và mô tả món; kiểm thử dùng đánh giá và mô tả mẫu bổ sung.
- Màn hình "Food Details" thuộc Member 2 theo bảng phân công gốc.
