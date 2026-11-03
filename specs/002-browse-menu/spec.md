# Đặc tả tính năng (Feature Specification): Duyệt thực đơn

**Nhánh tính năng (Feature Branch)**: `002-browse-menu`

**Ngày tạo (Created)**: 2026-10-20

**Trạng thái (Status)**: Bản nháp (Draft)

**Đầu vào (Input)**: Mô tả của người dùng: "FR-007: Guests and Customers MUST be able to browse published categories and available menu items."

**Đặc tả gốc (Parent Specification)**: `specs/001-food-ordering-system/spec.md` (FR-007, User Story 1)

## Làm rõ (Clarifications)

### Phiên 2026-10-20

- H: Món đã đăng bán nhưng tạm hết hàng thì ẩn khỏi danh sách hay hiển thị kèm nhãn? → Đ: Hiển thị đúng vị trí thông thường, kèm nhãn "Hết hàng", vẫn mở được chi tiết; ở màn hình chi tiết không cho thêm vào giỏ. Cụm "available menu items" trong FR-007 của đặc tả gốc được hiểu là "các món đã đăng bán, có hiển thị tình trạng còn/hết hàng".
- H: Trang chủ có mục "Món nổi bật" không? → Đ: Có mục "Phổ biến" gồm tối đa 5 món (ban đầu là 10, giảm còn 5 ở phiên giao diện bên dưới), tự xếp theo điểm đánh giá trung bình rồi số lượt đánh giá; chỉ gồm món còn hàng; Admin không cần thao tác.
- H: Khi mất mạng, Trang chủ hiển thị gì? → Đ: Hiển thị thực đơn đã tải lần gần nhất (kể cả từ lần mở app trước) kèm nhãn "Đang ngoại tuyến – dữ liệu có thể chưa cập nhật"; nếu chưa từng tải thì hiển thị trạng thái lỗi kèm nút thử lại.
- H: Thẻ món hiển thị giá như thế nào khi món có nhiều size? → Đ: Hiển thị khoảng giá theo size, ví dụ "45.000 – 65.000 ₫"; món chỉ có một mức giá thì hiển thị một giá; không tính topping.
- H: Khi chọn "Tất cả", danh sách món sắp xếp thế nào? → Đ: Gom theo danh mục; mỗi danh mục là một nhóm có tiêu đề, các nhóm theo thứ tự danh mục, món trong nhóm theo thứ tự hiển thị rồi theo tên.

### Phiên 2026-10-20 (giao diện theo mẫu Food Ninja và thực đơn Ngô Chicken)

- H: Trang chủ bố trí theo mẫu nào? → Đ: Theo khung Home của Food Ninja: tiêu đề "Tìm món bạn yêu thích" kèm nút chuông, ô tìm kiếm kèm nút lọc, banner giới thiệu nhà hàng, hàng thẻ danh mục cuộn ngang, mục "Phổ biến" dạng danh sách dọc, rồi thực đơn gom theo danh mục; dưới cùng là thanh điều hướng.
- H: Phần "Nearest Restaurant" của mẫu xử lý thế nào? → Đ: Thay bằng hàng thẻ danh mục, vì ứng dụng chỉ phục vụ một nhà hàng.
- H: Banner "Special Deal" xử lý thế nào? → Đ: Thay bằng banner giới thiệu Ngô Chicken (không phải khuyến mãi) với nút "Mua ngay" cuộn tới thực đơn; khuyến mãi vẫn nằm ngoài phạm vi.
- H: Ô tìm kiếm, nút lọc và nút chuông làm gì khi các tính năng đó chưa có? → Đ: Hiển thị đúng mẫu; khi chạm thì báo ngắn rằng tính năng đang được phát triển. Tìm kiếm/lọc thuộc FR-008 gốc, thông báo thuộc User Story 6 gốc.
- H: Thanh điều hướng dưới gồm những mục nào? → Đ: Trang chủ, Giỏ hàng, Đơn hàng, Tài khoản; bỏ mục Chat của mẫu vì chat nằm ngoài phạm vi. Các mục khác Trang chủ hiển thị màn chờ "đang phát triển" cho tới khi tính năng tương ứng được làm.
- H: Mục "Phổ biến" hiển thị bao nhiêu món? → Đ: Tối đa 5 món, dạng danh sách dọc như "Popular Menu" của mẫu.
- H: Khi chọn một danh mục (ví dụ "Gà rán"), mục "Phổ biến" có còn hiển thị không? → Đ: Không. Chỉ hiển thị món của danh mục đang chọn; "Phổ biến" chỉ xuất hiện khi chọn "Tất cả".
- H: Nút trên banner ghi gì? → Đ: "Mua ngay" (theo yêu cầu, thay cho "Xem thực đơn"). Vì giỏ hàng chưa có, nút cuộn tới hàng thẻ danh mục để người dùng chọn món; khi tính năng giỏ hàng có, hành vi giữ nguyên.
- H: Dữ liệu thực đơn mẫu lấy từ đâu? → Đ: Từ thực đơn đồ ăn và đồ uống của Ngô Chicken, giá VND; đồ uống có size M/L nên hiển thị khoảng giá.
- H: Có nên hiển thị đủ mọi nhóm món của thực đơn giấy không? → Đ: Không. Chỉ giữ các danh mục tiêu biểu: Gà rán, Cơm, Mỳ, Đồ ăn vặt, Combo, Đồ uống. Sáu nhóm đồ uống (Trà, Sữa chua, Sữa tươi, Latte, Nước ngọt, Nước ép + Sinh tố) gộp thành "Đồ uống"; nhóm "Combo đạt lớp" bỏ hẳn, không bán trong ứng dụng.
- H: Danh mục nhiều món quá thì sao? → Đ: Mỗi danh mục giữ tối đa 6 món tiêu biểu (cắt hai lần: lần đầu tối đa 8, sau đó bỏ thêm 2 món mỗi danh mục), ưu tiên giữ món có đánh giá và món hết hàng dùng để trình diễn. Danh sách món bị bỏ nằm trong `tools/seed_menu/build_seed.cjs`. Đây là giới hạn của dữ liệu thực đơn, không phải giới hạn hiển thị: ứng dụng vẫn hiển thị mọi món đã đăng bán.

## Kịch bản người dùng & Kiểm thử (User Scenarios & Testing) *(bắt buộc)*

### User Story 1 - Duyệt thực đơn từ Trang chủ (Ưu tiên: P1)

Guest hoặc Customer đã đăng nhập mở ứng dụng và thấy các danh mục đã đăng bán cùng các món nhà hàng đang cung cấp, để bắt đầu chọn món mà không cần đăng nhập.

**Lý do ưu tiên**: Khám phá thực đơn là điểm khởi đầu của mọi đơn hàng. Thiếu nó thì không hành trình đặt món nào có thể bắt đầu.

**Kiểm thử độc lập**: Tạo dữ liệu mẫu gồm cả danh mục và món đã đăng bán lẫn chưa đăng bán, mở ứng dụng khi chưa đăng nhập, xác nhận Trang chủ hiển thị đúng các danh mục đã đăng bán và các món đủ điều kiện, kèm tên, ảnh, giá và đánh giá.

**Kịch bản chấp nhận**:

1. **Giả sử** có danh mục đã đăng bán và món đủ điều kiện, **Khi** Guest mở Trang chủ, **Thì** các danh mục đã đăng bán hiển thị theo thứ tự nhà hàng cấu hình và các món đủ điều kiện hiển thị kèm ảnh, tên, giá gốc và tóm tắt đánh giá.
2. **Giả sử** Customer đã đăng nhập, **Khi** Customer mở Trang chủ, **Thì** hiển thị cùng các danh mục và món như với Guest.
3. **Giả sử** một danh mục hoặc món chưa đăng bán, **Khi** bất kỳ người dùng nào duyệt thực đơn, **Thì** danh mục hoặc món đó không xuất hiện ở bất kỳ màn hình duyệt nào.
4. **Giả sử** dữ liệu thực đơn đang tải, **Khi** Trang chủ mở, **Thì** hiển thị trạng thái đang tải thay vì danh sách trống.
5. **Giả sử** không có danh mục đã đăng bán hoặc món đủ điều kiện nào, **Khi** Trang chủ mở, **Thì** hiển thị trạng thái trống rõ ràng, giải thích rằng thực đơn chưa sẵn sàng.
6. **Giả sử** không tải được thực đơn, **Khi** Trang chủ mở, **Thì** hiển thị trạng thái lỗi giải thích vấn đề và có nút thử lại để tải lại thực đơn.
7. **Giả sử** có món đủ điều kiện, còn hàng và đã có ít nhất một đánh giá, **Khi** Trang chủ mở, **Thì** mục "Phổ biến" hiển thị tối đa 5 món đó, xếp theo điểm đánh giá trung bình giảm dần, rồi số lượt đánh giá giảm dần, rồi theo tên.
8. **Giả sử** không có món nào đủ điều kiện cho mục "Phổ biến", **Khi** Trang chủ mở, **Thì** mục "Phổ biến" bị ẩn và phần còn lại của Trang chủ vẫn hiển thị bình thường.
9. **Giả sử** Trang chủ có dữ liệu, **Khi** người dùng mở Trang chủ, **Thì** các phần hiển thị theo thứ tự: tiêu đề kèm nút chuông, ô tìm kiếm kèm nút lọc, banner nhà hàng, hàng thẻ danh mục, mục "Phổ biến", thực đơn gom theo danh mục; thanh điều hướng dưới luôn hiển thị với mục Trang chủ được chọn.
10. **Giả sử** người dùng đang ở Trang chủ, **Khi** chạm "Mua ngay" trên banner, **Thì** màn hình cuộn tới hàng thẻ danh mục.
11. **Giả sử** tính năng tìm kiếm, lọc hoặc thông báo chưa có, **Khi** người dùng chạm ô tìm kiếm, nút lọc hoặc nút chuông, **Thì** ứng dụng báo ngắn "Tính năng đang được phát triển" và không rời Trang chủ.

---

### User Story 2 - Duyệt món theo danh mục (Ưu tiên: P1)

Guest hoặc Customer chọn một danh mục để chỉ xem các món thuộc danh mục đó, giúp thu hẹp thực đơn theo loại món mình muốn.

**Lý do ưu tiên**: Danh mục là cách điều hướng chính của người dùng di động trong phiên ngắn; thiếu nó thì thực đơn lớn sẽ khó dùng.

**Kiểm thử độc lập**: Tạo hai danh mục đã đăng bán với các món khác nhau, lần lượt chọn từng danh mục và xác nhận chỉ hiển thị món đủ điều kiện của danh mục đó; chọn lại "Tất cả" thì hiển thị lại mọi món đủ điều kiện.

**Kịch bản chấp nhận**:

1. **Giả sử** một danh mục đã đăng bán có món đủ điều kiện, **Khi** người dùng chọn danh mục đó, **Thì** chỉ hiển thị các món đủ điều kiện của danh mục đó.
2. **Giả sử** một danh mục đã đăng bán không có món đủ điều kiện nào, **Khi** người dùng chọn danh mục đó, **Thì** hiển thị trạng thái trống riêng cho danh mục kèm cách quay về tất cả các món.
3. **Giả sử** đang chọn một danh mục, **Khi** người dùng chọn "Tất cả", **Thì** hiển thị lại mọi món đủ điều kiện thuộc các danh mục đã đăng bán, gom thành từng nhóm có tiêu đề theo danh mục và theo đúng thứ tự danh mục.
4. **Giả sử** người dùng đang xem một danh mục, **Khi** Admin gỡ đăng bán danh mục đó, **Thì** danh mục và các món của nó biến mất khỏi màn hình duyệt, màn hình quay về "Tất cả" kèm một thông báo ngắn.
5. **Giả sử** đang ở Trang chủ, **Khi** người dùng chọn một danh mục, **Thì** mục "Phổ biến" bị ẩn và chỉ còn các món của danh mục đó.

---

### User Story 3 - Thấy thay đổi thực đơn mà không cần làm mới (Ưu tiên: P2)

Trong khi người dùng đang duyệt, các thay đổi nhà hàng thực hiện trên thực đơn (món mới, đổi giá, đổi trạng thái đăng bán hoặc còn/hết hàng) xuất hiện trên màn hình mà người dùng không cần tự làm mới.

**Lý do ưu tiên**: Giữ giá và tình trạng còn/hết hàng chính xác trước khi người dùng chọn món, giảm số lần thanh toán thất bại. Không có tính năng này thì vẫn duyệt được thực đơn, nên xếp sau các story duyệt cốt lõi.

**Kiểm thử độc lập**: Để Trang chủ mở trên một thiết bị, dùng phiên Admin đổi giá một món và đăng bán một món mới, xác nhận cả hai thay đổi xuất hiện trên thiết bị đang duyệt mà người dùng không cần thao tác.

**Kịch bản chấp nhận**:

1. **Giả sử** người dùng đang xem Trang chủ, **Khi** Admin đổi giá một món, **Thì** giá mới hiển thị trong thời gian nêu ở tiêu chí thành công.
2. **Giả sử** người dùng đang xem Trang chủ, **Khi** Admin đăng bán một món mới trong một danh mục đã đăng bán, **Thì** món đó xuất hiện đúng vị trí.
3. **Giả sử** người dùng đang xem Trang chủ, **Khi** Admin đánh dấu một món là hết hàng, **Thì** món vẫn giữ nguyên vị trí và hiện thêm nhãn "Hết hàng"; **Khi** Admin gỡ đăng bán một món, **Thì** món đó bị loại khỏi danh sách.

---

### User Story 4 - Mở một món từ thực đơn (Ưu tiên: P2)

Từ bất kỳ món nào đang hiển thị khi duyệt, người dùng có thể mở chi tiết món đó để tìm hiểu thêm.

**Lý do ưu tiên**: Việc duyệt phải dẫn tới bước tiếp theo trong hành trình đặt món. Bản thân màn hình chi tiết được đặc tả riêng (FR-009 của đặc tả gốc); story này chỉ bao gồm việc điều hướng vào màn hình đó. *(Màn hình chi tiết tối thiểu của tính năng này đã được thay bằng màn hình đầy đủ của `specs/004-food-details`, giữ nguyên cách mở theo mã món.)*

**Kiểm thử độc lập**: Chạm vào bất kỳ món nào đang duyệt, xác nhận màn hình chi tiết của đúng món đó mở ra, và khi quay lại thì trở về đúng vị trí cuộn và danh mục trước đó.

**Kịch bản chấp nhận**:

1. **Giả sử** một món đang hiển thị, **Khi** người dùng chạm vào món đó, **Thì** chi tiết của món đó được mở.
2. **Giả sử** người dùng mở một món từ một danh mục đang chọn, **Khi** họ quay lại, **Thì** vẫn giữ nguyên danh mục đang chọn và vị trí cuộn của danh sách.

---

### Trường hợp biên (Edge Cases)

- Món đã đăng bán nhưng thuộc danh mục chưa đăng bán, đã bị xóa, hoặc không có trong danh sách danh mục đang hiển thị: món không hiển thị khi duyệt.
- Món thiếu ảnh hoặc ảnh tải lỗi: hiển thị ảnh thay thế thống nhất và món vẫn dùng được bình thường.
- Món chưa có đánh giá nào: phần tóm tắt đánh giá hiển thị trạng thái "Chưa có đánh giá" thay vì 0 sao.
- Tên món hoặc tên danh mục rất dài: chữ được cắt gọn gàng, không vỡ bố cục ở màn hình hẹp hoặc cỡ chữ lớn.
- Thực đơn lớn: màn hình đầu tiên hiển thị nhanh và các món tiếp theo được tải dần thay vì tải tất cả cùng lúc.
- Thiết bị mất mạng khi mở Trang chủ: hiển thị thực đơn đã tải lần gần nhất trên thiết bị (kể cả từ lần mở app trước) kèm nhãn "Đang ngoại tuyến – dữ liệu có thể chưa cập nhật"; nếu thiết bị chưa từng tải thực đơn thì hiển thị trạng thái lỗi kèm nút thử lại.
- Mất kết nối khi đang duyệt: nội dung đang hiển thị vẫn giữ nguyên, xuất hiện chỉ báo ngoại tuyến; chỉ báo tự tắt khi có mạng trở lại.
- Danh mục người dùng đang chọn bị gỡ đăng bán (xem User Story 2, kịch bản 4).
- Hai món có cùng thứ tự hiển thị: được sắp xếp ổn định theo tên.
- Một món trong mục "Phổ biến" chuyển sang hết hàng hoặc bị gỡ đăng bán khi người dùng đang xem: món bị loại khỏi mục "Phổ biến" (nhưng món hết hàng vẫn ở danh sách chính kèm nhãn "Hết hàng").
- Khoảng giá quá dài so với chiều rộng thẻ ở màn hình hẹp hoặc cỡ chữ lớn: giá được xuống dòng hoặc thu gọn nhưng vẫn hiển thị đủ cả giá thấp nhất và cao nhất, không bị cắt mất số.
- Mục "Phổ biến" chỉ hiển thị khi đang chọn "Tất cả"; khi chọn một danh mục, Trang chủ chỉ hiển thị món của danh mục đó. Mục này là lối tắt và không thay thế danh sách món chính.

## Yêu cầu (Requirements) *(bắt buộc)*

### Yêu cầu chức năng (Functional Requirements)

- **FR-001**: Hệ thống PHẢI cho phép cả Guest và Customer đã đăng nhập duyệt thực đơn mà không bắt buộc đăng nhập.
- **FR-002**: Khi duyệt, hệ thống PHẢI chỉ hiển thị các danh mục đã đăng bán, sắp xếp theo thứ tự hiển thị do nhà hàng định nghĩa, sau đó theo tên.
- **FR-003**: Khi duyệt, hệ thống PHẢI chỉ hiển thị các món đã đăng bán và thuộc danh mục đã đăng bán. Trong một danh mục, món PHẢI được sắp xếp theo thứ tự hiển thị do nhà hàng định nghĩa, sau đó theo tên. Khi chọn "Tất cả", món PHẢI được gom theo danh mục: mỗi danh mục là một nhóm có tiêu đề là tên danh mục, các nhóm theo thứ tự danh mục ở FR-002; danh mục không có món nào để hiển thị thì không tạo nhóm.
- **FR-004**: Món đã đăng bán nhưng đang tạm hết hàng PHẢI vẫn hiển thị khi duyệt, ở đúng vị trí thông thường, kèm nhãn chữ "Hết hàng" rõ ràng, không chỉ dựa vào màu sắc; món đó PHẢI vẫn mở được chi tiết, nơi việc thêm vào giỏ bị chặn (User Story 1, kịch bản 3 của đặc tả gốc).
- **FR-005**: Mỗi món khi duyệt PHẢI hiển thị ảnh (hoặc ảnh thay thế), tên, giá bằng VND và tóm tắt đánh giá (điểm trung bình và số lượt đánh giá, hoặc trạng thái "Chưa có đánh giá"). Giá PHẢI hiển thị dạng khoảng từ giá size thấp nhất đến giá size cao nhất (ví dụ "45.000 – 65.000 ₫") khi các size có giá khác nhau, và hiển thị một giá duy nhất (ví dụ "45.000 ₫") khi món không có size hoặc mọi size cùng giá. Giá topping KHÔNG được tính vào giá hiển thị khi duyệt.
- **FR-006**: Người dùng PHẢI chọn được một danh mục tại một thời điểm, hoặc "Tất cả", để giới hạn danh sách món theo danh mục đó.
- **FR-007**: Các màn hình duyệt PHẢI có các trạng thái phân biệt rõ: đang tải, có dữ liệu, trống, danh mục trống và lỗi; trạng thái lỗi PHẢI có nút thử lại.
- **FR-008**: Các thay đổi thực đơn do nhà hàng thực hiện (trạng thái đăng bán, còn/hết hàng, giá, tên, ảnh, thứ tự) PHẢI được phản ánh trên các màn hình duyệt đang mở mà không cần làm mới thủ công.
- **FR-009**: Danh sách món ban đầu PHẢI có giới hạn số lượng, các món tiếp theo được tải dần khi người dùng cuộn; khi tải dần trong chế độ "Tất cả", món mới PHẢI được nối vào đúng nhóm danh mục và thứ tự nhóm PHẢI giữ nguyên.
- **FR-010**: Chọn một món khi duyệt PHẢI mở chi tiết của món đó; khi quay lại PHẢI giữ nguyên danh mục đang chọn và vị trí cuộn.
- **FR-011**: Danh mục và món chưa đăng bán, cũng như món thuộc danh mục chưa đăng bán, PHẢI KHÔNG truy xuất được bởi Guest hay Customer bằng bất kỳ cách nào, không chỉ bị ẩn trên giao diện.
- **FR-012**: Việc duyệt PHẢI KHÔNG cho phép thay đổi dữ liệu thực đơn; với Guest và Customer đây là chức năng chỉ đọc.
- **FR-013**: Trang chủ PHẢI có mục "Phổ biến", chỉ hiển thị khi đang chọn "Tất cả", gồm tối đa 5 món đã đăng bán, thuộc danh mục đã đăng bán, còn hàng và có ít nhất một đánh giá, xếp theo điểm đánh giá trung bình giảm dần, rồi số lượt đánh giá giảm dần, rồi theo tên; mục này PHẢI bị ẩn khi không có món nào đủ điều kiện và PHẢI tự cập nhật theo FR-008.
- **FR-014**: Khi không có kết nối mạng, các màn hình duyệt PHẢI hiển thị thực đơn đã tải lần gần nhất trên thiết bị (kể cả từ lần mở app trước) kèm nhãn "Đang ngoại tuyến – dữ liệu có thể chưa cập nhật"; nếu thiết bị chưa từng tải thực đơn thì PHẢI hiển thị trạng thái lỗi kèm nút thử lại. Nhãn ngoại tuyến PHẢI tự biến mất và dữ liệu PHẢI tự làm mới khi có mạng trở lại. Dữ liệu lưu trên thiết bị chỉ phục vụ hiển thị; giá và tình trạng còn hàng vẫn được kiểm tra lại khi thanh toán. Ứng dụng được coi là "không có kết nối" khi không nhận được dữ liệu từ máy chủ trong 2 giây, tính từ lúc mở màn hình hoặc từ lúc mất đồng bộ; trước mốc đó, nếu đã có dữ liệu lưu trên thiết bị thì hiển thị dữ liệu đó mà không hiện nhãn ngoại tuyến hay trạng thái lỗi.

- **FR-015**: Trang chủ PHẢI bố trí theo khung Home của mẫu Food Ninja theo thứ tự ở User Story 1 kịch bản 9, dùng token của hệ thống thiết kế chỉ chế độ sáng.
- **FR-016**: Danh mục PHẢI hiển thị dạng thẻ cuộn ngang (thẻ đầu là "Tất cả"), thẻ đang chọn phân biệt bằng nền và viền, không chỉ bằng màu chữ; chọn thẻ có cùng hành vi như FR-006.
- **FR-017**: Banner PHẢI giới thiệu nhà hàng và có nút "Mua ngay" cuộn tới hàng thẻ danh mục; banner KHÔNG được trình bày như khuyến mãi.
- **FR-018**: Ứng dụng PHẢI có thanh điều hướng dưới gồm Trang chủ, Giỏ hàng, Đơn hàng, Tài khoản; chuyển mục KHÔNG làm mất trạng thái của Trang chủ (danh mục đang chọn, vị trí cuộn).
- **FR-019**: Ô tìm kiếm, nút lọc, nút chuông và các mục điều hướng chưa có tính năng đích PHẢI phản hồi rõ ràng ("đang được phát triển") thay vì không phản hồi. *(Từ tính năng 003, ô tìm kiếm và nút lọc mở màn hình tìm kiếm theo FR-002 của `specs/003-menu-search/spec.md`.)*

### Thực thể chính (Key Entities)

- **Danh mục (Category)**: Nhóm món do nhà hàng định nghĩa. Thuộc tính liên quan: tên, ảnh, thứ tự hiển thị, cờ đăng bán.
- **Món (Menu Item)**: Món ăn hoặc đồ uống nhà hàng cung cấp. Thuộc tính liên quan: danh mục sở hữu, tên, ảnh, giá gốc (số nguyên VND), các size và giá tương ứng của từng size (dùng để tính khoảng giá), cờ đăng bán, cờ còn hàng, thứ tự hiển thị, điểm đánh giá trung bình, số lượt đánh giá.

## Tiêu chí thành công (Success Criteria) *(bắt buộc)*

### Kết quả đo lường được (Measurable Outcomes)

- **SC-001**: Guest lần đầu mở ứng dụng thấy được thực đơn trên Trang chủ trong vòng 3 giây với kết nối di động thông thường, không cần đăng nhập.
- **SC-002**: Người dùng có thể tới danh sách món của bất kỳ danh mục nào trong không quá 2 lần chạm từ Trang chủ.
- **SC-003**: Trong kiểm thử chấp nhận, có 0 danh mục hoặc món chưa đăng bán (hoặc món thuộc danh mục chưa đăng bán) mà Guest hay Customer có thể nhìn thấy hoặc truy xuất.
- **SC-004**: Thay đổi về giá, trạng thái đăng bán hoặc còn/hết hàng do nhà hàng thực hiện xuất hiện trên màn hình duyệt đang mở trong vòng 5 giây với điều kiện mạng bình thường.
- **SC-005**: 100% các kịch bản lỗi và dữ liệu trống được kiểm thử đều hiển thị trạng thái đang tải, trống hoặc lỗi đã định nghĩa; không có màn hình trắng.
- **SC-006**: Các màn hình duyệt vẫn đọc được đầy đủ, không tràn bố cục ở màn hình rộng 320 điểm ảnh logic và cỡ chữ 1,3×.
- **SC-007**: Ít nhất 90% người tham gia kiểm thử tìm được một món được chỉ định bằng cách duyệt danh mục ngay lần đầu mà không cần hướng dẫn.
- **SC-008**: Trên thiết bị đã từng tải thực đơn, mở app khi không có mạng vẫn hiển thị thực đơn kèm nhãn ngoại tuyến trong 100% lần kiểm thử; nhãn biến mất trong vòng 5 giây sau khi có mạng trở lại.

## Giả định (Assumptions)

- Tính năng này chỉ bao gồm FR-007 của đặc tả gốc. Tìm kiếm theo từ khóa, bộ lọc còn/hết hàng hay giá, và tùy chọn sắp xếp (FR-008 của đặc tả gốc), nội dung chi tiết món (FR-009), yêu thích (FR-010) và thao tác giỏ hàng được đặc tả riêng.
- Việc chọn danh mục trên Trang chủ được xem là một phần của duyệt thực đơn; khác với màn hình bộ lọc nâng cao trong FR-008 của đặc tả gốc.
- Dữ liệu thực đơn do Admin tạo và quản lý (User Story 7 của đặc tả gốc) hoặc được tạo sẵn; tính năng này không tạo dữ liệu thực đơn.
- Giá là số nguyên VND và hiển thị theo cách nhóm số của Việt Nam (ví dụ: 45.000 ₫).
- "Thứ tự hiển thị" là một con số do nhà hàng đặt cho danh mục và món; khi trùng thì sắp xếp theo tên theo bảng chữ cái.
- Trải nghiệm duyệt là như nhau với Guest và Customer trong tính năng này; các thao tác chỉ dành cho Customer trên thẻ món (như yêu thích) sẽ do tính năng riêng bổ sung.
- Giao diện tuân theo hệ thống thiết kế chỉ dùng chế độ sáng của dự án và khung Home của mẫu Food Ninja (xem Clarifications, phiên giao diện).
- Nhà hàng là Ngô Chicken. Dữ liệu mẫu (`tools/seed_menu/menu_seed.json`) chép từ thực đơn đồ ăn và đồ uống của nhà hàng và được sinh bằng `tools/seed_menu/build_seed.cjs`: 6 danh mục Gà rán, Cơm, Mỳ, Đồ ăn vặt, Combo, Đồ uống (28 món, tối đa 6 món mỗi danh mục; nhóm "Combo đạt lớp" không đưa vào). Dòng "Đùi, Cánh, Má đùi" không có giá nên chưa đưa vào. Điểm đánh giá và trạng thái hết hàng trong dữ liệu mẫu chỉ dùng để trình diễn trên Emulator.
- Chưa có ảnh món; mọi món dùng ảnh thay thế cho tới khi Admin tải ảnh lên (User Story 7 gốc).
- Kích thước trang đầu hợp lý là khoảng 20 món; con số chính xác được quyết định ở bước lập kế hoạch.
- Câu về quyền đọc trong `docs/database_schema.md` ("Published and available items are publicly readable") cần được điều chỉnh ở bước lập kế hoạch để các món đã đăng bán thuộc danh mục đã đăng bán đọc được công khai bất kể tình trạng còn/hết hàng.
