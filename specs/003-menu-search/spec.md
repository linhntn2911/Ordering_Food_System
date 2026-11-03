# Đặc tả tính năng (Feature Specification): Tìm kiếm và lọc thực đơn

**Nhánh tính năng (Feature Branch)**: `003-menu-search`

**Ngày tạo (Created)**: 2026-10-20

**Trạng thái (Status)**: Bản nháp (Draft)

**Đầu vào (Input)**: Mô tả của người dùng: "FR-008: Users MUST be able to search menu items by name and filter by category and availability."

**Đặc tả gốc (Parent Specification)**: `specs/001-food-ordering-system/spec.md` (FR-008, User Story 1 kịch bản 2, màn hình "Search and Filter" của Member 2)

**Tính năng liên quan**: `specs/002-browse-menu/spec.md` — Trang chủ đã có ô tìm kiếm và nút lọc chỉ đọc (FR-019), hiện báo "Tính năng đang được phát triển". Tính năng này cung cấp màn hình đích cho hai nút đó.

## Làm rõ (Clarifications)

### Phiên 2026-10-20

- H: Bộ lọc danh mục chọn một hay nhiều danh mục? → Đ: Chọn một danh mục hoặc "Tất cả", giống thẻ danh mục ở Trang chủ.
- H: Sắp xếp kết quả có làm ngay trong bản này không? → Đ: Có, sắp xếp là yêu cầu bắt buộc, User Story 3 nâng lên P2.
- H: Thay đổi trong bảng lọc có hiệu lực khi nào? → Đ: Chỉ khi bấm "Áp dụng"; bảng có thêm nút "Đặt lại"; đóng bảng mà không áp dụng thì giữ bộ lọc cũ.
- H: Danh mục đang chọn ở Trang chủ có được mang sang màn hình tìm kiếm không? → Đ: Không; màn hình tìm kiếm luôn mở với "Tất cả".
- H: Người dùng chọn cách sắp xếp ở đâu? → Đ: Trong bảng lọc, có hiệu lực khi bấm "Áp dụng"; khác "Phù hợp nhất" thì hiện thành nhãn bỏ được; "Đặt lại" và "Xóa bộ lọc" đưa về "Phù hợp nhất".

## Kịch bản người dùng & Kiểm thử (User Scenarios & Testing) *(bắt buộc)*

### User Story 1 - Tìm món theo tên (Ưu tiên: P1)

Guest hoặc Customer gõ một phần tên món (ví dụ "gà", "tra sua") và thấy ngay các món phù hợp, để tìm nhanh món mình muốn mà không phải duyệt từng danh mục.

**Lý do ưu tiên**: Tìm theo tên là cách nhanh nhất để tới món đã biết tên; đây là phần cốt lõi của FR-008.

**Kiểm thử độc lập**: Nạp thực đơn mẫu Ngô Chicken, mở màn hình tìm kiếm từ ô tìm kiếm ở Trang chủ, gõ "ga" và xác nhận chỉ các món có "gà" trong tên xuất hiện, kể cả khi gõ không dấu.

**Kịch bản chấp nhận**:

1. **Giả sử** người dùng ở Trang chủ, **Khi** chạm ô tìm kiếm, **Thì** màn hình tìm kiếm mở ra với ô nhập đã sẵn sàng để gõ và bàn phím hiện lên.
2. **Giả sử** thực đơn có các món đã đăng bán, **Khi** người dùng gõ một phần tên món, **Thì** danh sách chỉ gồm các món đủ điều kiện có tên chứa cụm đã gõ, không phân biệt hoa/thường và có dấu/không dấu (ví dụ "tra sua" khớp "Trà sữa trân châu đường đen").
3. **Giả sử** người dùng đang gõ, **Khi** người dùng dừng gõ, **Thì** kết quả cập nhật mà không cần bấm nút tìm.
4. **Giả sử** không có món nào khớp, **Khi** kết quả hiển thị, **Thì** màn hình báo "Không tìm thấy món phù hợp" và gợi ý xóa từ khóa hoặc bỏ bộ lọc.
5. **Giả sử** ô tìm kiếm đang trống và chưa có bộ lọc, **Khi** màn hình mở, **Thì** hiển thị toàn bộ món đủ điều kiện theo thứ tự thực đơn.
6. **Giả sử** người dùng đang xem kết quả, **Khi** chạm một món, **Thì** chi tiết của món đó mở ra; khi quay lại, từ khóa, bộ lọc, cách sắp xếp và vị trí cuộn được giữ nguyên.
7. **Giả sử** người dùng đang chọn danh mục "Gà rán" ở Trang chủ, **Khi** mở màn hình tìm kiếm, **Thì** bộ lọc danh mục là "Tất cả" và kết quả gồm món của mọi danh mục.

---

### User Story 2 - Lọc theo danh mục và tình trạng còn hàng (Ưu tiên: P1)

Người dùng thu hẹp kết quả theo một danh mục (ví dụ "Đồ uống") và/hoặc chỉ xem món đang còn hàng, kết hợp được với từ khóa tìm kiếm.

**Lý do ưu tiên**: Lọc theo danh mục và tình trạng còn hàng là phần còn lại của FR-008; giúp tránh chọn món đang hết.

**Kiểm thử độc lập**: Mở bộ lọc, chọn danh mục "Đồ ăn vặt" và bật "Chỉ món còn hàng": danh sách chỉ còn món đồ ăn vặt còn hàng (không có "Cá viên chiên" đang hết hàng).

**Kịch bản chấp nhận**:

1. **Giả sử** người dùng ở màn hình tìm kiếm, **Khi** chạm nút lọc, **Thì** bảng lọc mở ra với danh sách danh mục đã đăng bán (chọn một hoặc "Tất cả"), công tắc "Chỉ món còn hàng" và lựa chọn sắp xếp (mục sắp xếp thuộc User Story 3), phản ánh bộ lọc đang áp dụng, cùng hai nút "Đặt lại" và "Áp dụng".
2. **Giả sử** người dùng chọn một danh mục trong bảng lọc, **Khi** bấm "Áp dụng", **Thì** bảng đóng lại và kết quả chỉ gồm món của danh mục đó.
3. **Giả sử** người dùng đã thay đổi lựa chọn trong bảng lọc, **Khi** đóng bảng mà không bấm "Áp dụng" (vuốt xuống, chạm ra ngoài hoặc nút quay lại), **Thì** bộ lọc và kết quả giữ nguyên như trước khi mở bảng.
4. **Giả sử** bảng lọc đang mở, **Khi** bấm "Đặt lại", **Thì** các lựa chọn trong bảng trở về mặc định ("Tất cả", tắt "Chỉ món còn hàng", "Phù hợp nhất") và chỉ có hiệu lực khi bấm "Áp dụng".
5. **Giả sử** người dùng bật "Chỉ món còn hàng" và áp dụng, **Khi** kết quả hiển thị, **Thì** món hết hàng bị loại khỏi kết quả.
6. **Giả sử** "Chỉ món còn hàng" đang tắt, **Khi** kết quả có món hết hàng, **Thì** món đó vẫn hiển thị kèm nhãn "Hết hàng" (nhất quán với Trang chủ).
7. **Giả sử** đã có từ khóa và bộ lọc, **Khi** kết quả hiển thị, **Thì** món phải thỏa đồng thời cả từ khóa và mọi bộ lọc.
8. **Giả sử** có bộ lọc đang áp dụng, **Khi** người dùng nhìn màn hình, **Thì** các bộ lọc đang bật hiển thị dưới dạng nhãn có thể bỏ từng cái (bỏ nhãn có hiệu lực ngay), kèm nút "Xóa bộ lọc".
9. **Giả sử** người dùng chạm nút lọc ở Trang chủ, **Khi** màn hình tìm kiếm mở, **Thì** bảng lọc mở sẵn.

---

### User Story 3 - Sắp xếp kết quả (Ưu tiên: P2)

Người dùng sắp xếp kết quả theo giá hoặc theo đánh giá để so sánh nhanh.

**Lý do ưu tiên**: Bảng phân công màn hình gốc nêu "sort" cho màn hình Search and Filter, nên phần này thuộc phạm vi bản này; làm sau hai story P1 vì phụ thuộc danh sách kết quả.

**Kiểm thử độc lập**: Tìm "trà", chọn "Giá thấp đến cao" và xác nhận món có giá thấp nhất đứng đầu.

**Kịch bản chấp nhận**:

1. **Giả sử** có kết quả, **Khi** người dùng chọn "Giá thấp đến cao" hoặc "Giá cao đến thấp" trong bảng lọc và bấm "Áp dụng", **Thì** kết quả sắp theo giá thấp nhất của món (giá size nhỏ nhất), món cùng giá sắp theo tên.
2. **Giả sử** có kết quả, **Khi** người dùng chọn "Đánh giá cao", **Thì** món có điểm đánh giá cao hơn đứng trước, món chưa có đánh giá đứng cuối.
3. **Giả sử** người dùng chưa chọn cách sắp xếp, **Khi** kết quả hiển thị, **Thì** dùng thứ tự mặc định "Phù hợp nhất": món có tên bắt đầu bằng từ khóa đứng trước, sau đó theo thứ tự thực đơn.
4. **Giả sử** đang áp dụng cách sắp xếp khác "Phù hợp nhất", **Khi** người dùng bỏ nhãn sắp xếp hoặc bấm "Xóa bộ lọc", **Thì** kết quả trở về thứ tự "Phù hợp nhất".

---

### Trường hợp biên (Edge Cases)

- Từ khóa chỉ gồm khoảng trắng: coi như ô tìm kiếm trống.
- Từ khóa rất dài (trên 50 ký tự): chỉ dùng 50 ký tự đầu, không báo lỗi.
- Từ khóa có ký tự đặc biệt ("+", "-", "&"): được so khớp như ký tự thường (ví dụ "mỳ ý + gà" khớp combo "Mỳ ý + Gà rán").
- Danh mục đang được chọn trong bộ lọc bị gỡ đăng bán khi người dùng đang xem: bộ lọc danh mục tự bỏ, kết quả cập nhật và có thông báo ngắn.
- Một món trong kết quả bị gỡ đăng bán, đổi giá hoặc chuyển hết hàng khi đang xem: kết quả cập nhật mà không cần làm mới (nhất quán với FR-008 của tính năng 002).
- Mất mạng: hiển thị kết quả từ thực đơn đã lưu trên thiết bị kèm nhãn ngoại tuyến, giống Trang chủ; chưa từng tải thực đơn thì báo lỗi kèm "Thử lại".
- Không tải được thực đơn: trạng thái lỗi kèm "Thử lại", từ khóa và bộ lọc vẫn được giữ.
- Bật "Chỉ món còn hàng" khiến kết quả rỗng: dùng trạng thái "Không tìm thấy món phù hợp" và gợi ý tắt bộ lọc.

## Yêu cầu (Requirements) *(bắt buộc)*

### Yêu cầu chức năng (Functional Requirements)

- **FR-001**: Guest và Customer PHẢI tìm kiếm được mà không cần đăng nhập.
- **FR-002**: Ô tìm kiếm và nút lọc ở Trang chủ PHẢI mở màn hình tìm kiếm (thay cho thông báo "đang được phát triển" của FR-019 trong tính năng 002); nút lọc mở sẵn bảng lọc.
- **FR-003**: Hệ thống PHẢI tìm món theo tên, khớp khi tên chứa từ khóa ở bất kỳ vị trí nào, không phân biệt hoa/thường và có dấu/không dấu tiếng Việt (bao gồm "đ" khớp "d").
- **FR-004**: Kết quả PHẢI tự cập nhật khi người dùng ngừng gõ trong khoảng 300 ms, không cần nút tìm. Bấm phím "Tìm" trên bàn phím hoặc nút xóa từ khóa thì áp dụng ngay.
- **FR-005**: Kết quả tìm kiếm PHẢI chỉ gồm món đã đăng bán thuộc danh mục đã đăng bán; món chưa đăng bán KHÔNG được xuất hiện hay truy xuất được (cùng quy tắc với FR-011 của tính năng 002).
- **FR-006**: Người dùng PHẢI lọc được theo đúng một danh mục đã đăng bán, hoặc "Tất cả"; chọn danh mục khác sẽ thay thế danh mục đang chọn (không chọn nhiều danh mục cùng lúc).
- **FR-007**: Người dùng PHẢI bật/tắt được bộ lọc "Chỉ món còn hàng". Mặc định tắt; khi tắt, món hết hàng vẫn hiển thị kèm nhãn "Hết hàng".
- **FR-008**: Từ khóa và các bộ lọc PHẢI kết hợp theo điều kiện "và".
- **FR-009**: Bộ lọc và cách sắp xếp khác mặc định đang áp dụng PHẢI hiển thị thành nhãn bỏ được từng cái (có hiệu lực ngay), và có nút "Xóa bộ lọc" đưa mọi bộ lọc và cách sắp xếp về mặc định (không xóa từ khóa).
- **FR-010**: Người dùng PHẢI sắp xếp được kết quả theo "Phù hợp nhất" (mặc định), "Giá thấp đến cao", "Giá cao đến thấp", "Đánh giá cao", theo quy tắc ở User Story 3. Lựa chọn sắp xếp nằm trong bảng lọc và tuân theo FR-016.
- **FR-011**: Mỗi kết quả PHẢI dùng cùng thẻ món như Trang chủ (ảnh hoặc ảnh thay thế, tên, khoảng giá, đánh giá, nhãn "Hết hàng").
- **FR-012**: Màn hình PHẢI có các trạng thái: đang tải, có kết quả, không có kết quả, lỗi kèm "Thử lại", và nhãn ngoại tuyến khi dùng dữ liệu đã lưu.
- **FR-013**: Chạm một kết quả PHẢI mở chi tiết món; quay lại PHẢI giữ nguyên từ khóa, bộ lọc, cách sắp xếp và vị trí cuộn.
- **FR-014**: Thay đổi thực đơn (đăng bán, còn/hết hàng, giá, tên) PHẢI phản ánh vào kết quả đang mở mà không cần làm mới.
- **FR-015**: Từ khóa, bộ lọc và cách sắp xếp chỉ tồn tại trong phiên tìm kiếm hiện tại; mở lại màn hình tìm kiếm từ Trang chủ bắt đầu với trạng thái mặc định. Danh mục đang chọn ở Trang chủ KHÔNG được mang sang; bộ lọc danh mục luôn bắt đầu ở "Tất cả".
- **FR-016**: Lựa chọn trong bảng lọc PHẢI chỉ có hiệu lực khi bấm "Áp dụng"; đóng bảng mà không áp dụng PHẢI giữ nguyên bộ lọc trước đó; nút "Đặt lại" đưa lựa chọn trong bảng về mặc định nhưng chưa áp dụng.

### Thực thể chính (Key Entities)

- **Truy vấn tìm kiếm (Search Query)**: Từ khóa đã chuẩn hóa (bỏ khoảng trắng thừa, chữ thường, bỏ dấu), danh mục được chọn (hoặc tất cả), cờ "chỉ món còn hàng", cách sắp xếp. Chỉ tồn tại trong phiên.
- **Món (Menu Item)**: Dùng lại thực thể của tính năng 002 (tên, danh mục, khoảng giá, cờ còn hàng, điểm và số lượt đánh giá, thứ tự hiển thị).
- **Danh mục (Category)**: Dùng lại thực thể của tính năng 002; chỉ danh mục đã đăng bán xuất hiện trong bộ lọc.

## Tiêu chí thành công (Success Criteria) *(bắt buộc)*

### Kết quả đo lường được (Measurable Outcomes)

- **SC-001**: Kết quả hiển thị trong vòng 1 giây sau khi người dùng ngừng gõ, với thực đơn đã tải.
- **SC-002**: Người dùng tìm thấy một món được chỉ định bằng cách gõ tối đa 4 ký tự đầu của một từ trong tên (có hoặc không dấu) trong 100% món của thực đơn mẫu.
- **SC-003**: Trong kiểm thử chấp nhận, 0 món chưa đăng bán hoặc thuộc danh mục chưa đăng bán xuất hiện trong kết quả.
- **SC-004**: Khi bật "Chỉ món còn hàng", 0 món hết hàng xuất hiện trong kết quả.
- **SC-005**: Ít nhất 90% người tham gia kiểm thử tìm được món chỉ định và áp dụng được một bộ lọc ngay lần đầu, không cần hướng dẫn.
- **SC-006**: Màn hình đọc được đầy đủ, không tràn bố cục ở chiều rộng 320 điểm ảnh logic và cỡ chữ 1,3×.

## Giả định (Assumptions)

- Phạm vi chỉ gồm FR-008 của đặc tả gốc; nội dung chi tiết món (FR-009 gốc), yêu thích và giỏ hàng nằm ngoài phạm vi.
- Tìm theo tên món; không tìm theo mô tả, nguyên liệu hay tên danh mục.
- Thực đơn một nhà hàng có quy mô nhỏ (hiện 28 món, tối đa vài trăm), nên tìm kiếm trên toàn bộ món đủ điều kiện là chấp nhận được; cách thực hiện cụ thể được quyết định ở bước lập kế hoạch.
- "Chỉ món còn hàng" mặc định tắt để nhất quán với quyết định của tính năng 002 (món hết hàng vẫn hiển thị kèm nhãn). Kịch bản 2 của User Story 1 gốc ("only matching available items are shown") được hiểu là "món đủ điều kiện", và bộ lọc còn hàng giúp đạt hành vi "chỉ món còn hàng" khi người dùng muốn.
- Không lưu lịch sử tìm kiếm hay từ khóa gần đây ở bản này.
- Giao diện theo hệ thống thiết kế chỉ chế độ sáng; ô tìm kiếm cùng kiểu với ô tìm kiếm ở Trang chủ; màn hình mở chồng lên `MainShell` của tính năng 002 (không có thanh tab dưới) và quay lại thì về Trang chủ.
- Màn hình "Search and Filter" thuộc Member 2 theo bảng phân công gốc.
