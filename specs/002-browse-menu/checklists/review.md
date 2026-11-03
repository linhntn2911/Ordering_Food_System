# Checklist review yêu cầu: Duyệt thực đơn

**Mục đích**: Kiểm tra chất lượng yêu cầu (đầy đủ, rõ ràng, nhất quán, đo được) trước `/speckit-implement` và khi review PR. Mỗi mục kiểm tra *yêu cầu đã được viết tốt chưa*, không kiểm tra mã đã chạy đúng chưa.
**Ngày tạo**: 2026-10-20
**Tính năng**: [spec.md](../spec.md) · [plan.md](../plan.md) · [tasks.md](../tasks.md)
**Trọng tâm**: Bảo mật và phạm vi hiển thị dữ liệu; giao diện và trạng thái màn hình; realtime và ngoại tuyến
**Mức độ**: Tiêu chuẩn, dùng làm cổng review PR

## Mức độ đầy đủ của yêu cầu

- [ ] CHK001 Spec có định nghĩa rõ "món đủ điều kiện" (đã đăng bán + thuộc danh mục đã đăng bán) ở một chỗ duy nhất để các FR khác tham chiếu không? [Completeness, Spec §FR-003, §US1]
- [x] CHK002 Có yêu cầu nào nói phải xử lý món mà danh mục sở hữu không còn trong danh sách danh mục hiển thị (đã xóa, hoặc vượt giới hạn số danh mục) không? [Gap, Spec §Edge Cases]
- [ ] CHK003 Spec có nêu số lượng danh mục tối đa hiển thị trên thanh danh mục, hay mặc nhiên là không giới hạn? [Gap, Spec §FR-002]
- [ ] CHK004 Nội dung của "ảnh thay thế thống nhất" (biểu tượng, màu nền, tỉ lệ) đã được định nghĩa ở spec hoặc contract giao diện chưa? [Gap, Spec §Edge Cases, §FR-005]
- [ ] CHK005 Yêu cầu về cách hiển thị tóm tắt đánh giá (số chữ số thập phân, dấu phẩy thập phân, có hiện số lượt hay không) đã được nêu cụ thể chưa? [Completeness, Spec §FR-005]
- [ ] CHK006 Spec có định nghĩa nội dung thông báo cho từng trạng thái (trống, danh mục trống, lỗi, ngoại tuyến, danh mục bị gỡ) hay để cho bước thiết kế quyết định? [Completeness, Spec §FR-007, §US2-4]
- [ ] CHK007 Có yêu cầu về hành vi khi người dùng chạm "Thử lại" mà vẫn không có mạng (giữ lỗi, có chỉ báo đang thử) không? [Gap, Exception Flow, Spec §US1-6]

## Mức độ rõ ràng của yêu cầu

- [x] CHK008 "Không có kết nối mạng" trong FR-014 có được định nghĩa bằng tiêu chí quan sát được (ví dụ không đồng bộ được với máy chủ trong X giây) để phân biệt với trường hợp đang khởi động có mạng không? [Ambiguity, Spec §FR-014]
- [x] CHK009 Cụm "kết nối di động thông thường" và "điều kiện mạng bình thường" đã được lượng hóa (loại mạng, thiết bị, khởi động lạnh hay nóng) chưa? [Ambiguity, Spec §SC-001, §SC-004]
- [ ] CHK010 "Màn hình đầu tiên hiển thị nhanh" trong phần trường hợp biên có được gắn với một con số hay chỉ tham chiếu SC-001? [Clarity, Spec §Edge Cases]
- [ ] CHK011 "Được cắt gọn gàng" cho tên dài đã nói rõ số dòng tối đa cho tên món và tên danh mục chưa? [Clarity, Spec §Edge Cases]
- [ ] CHK012 Thứ tự "theo tên" đã nói rõ cách so sánh với chữ tiếng Việt có dấu chưa, hay chỉ yêu cầu "ổn định"? [Ambiguity, Spec §FR-002, §FR-003, Assumptions]
- [ ] CHK013 "Khoảng giá" đã nêu rõ giá gốc có được tính là một mức giá khi món có size không (size nhỏ nhất có cộng thêm hay không)? [Clarity, Spec §FR-005]
- [ ] CHK014 "Giới hạn số lượng" của danh sách ban đầu trong FR-009 có được chốt bằng con số trong spec, hay chỉ ở Assumptions ("khoảng 20")? [Clarity, Spec §FR-009, Assumptions]

## Mức độ nhất quán của yêu cầu

- [x] CHK015 FR-007 của đặc tả gốc ("available menu items") đã được cập nhật cho khớp với FR-004 của spec này chưa, hay hai tài liệu vẫn mâu thuẫn? [Conflict, Spec §FR-004, §Clarifications]
- [x] CHK016 Quy tắc đọc trong `docs/database_schema.md` có khớp với FR-004 và FR-011 không? [Conflict, Spec §Assumptions, Plan §R2]
- [ ] CHK017 Nhãn "Hết hàng" có được dùng thống nhất giữa danh sách, mục "Phổ biến" (không hiện món hết hàng) và màn hình chi tiết không? [Consistency, Spec §FR-004, §FR-013]
- [ ] CHK018 Yêu cầu giữ vị trí cuộn khi quay lại (FR-010) có mâu thuẫn với yêu cầu cuộn về đầu khi đổi danh mục (tasks T044) không, và spec có nêu cuộn về đầu khi đổi danh mục không? [Consistency, Spec §FR-010, §US2]
- [ ] CHK019 Hành vi khi danh mục đang chọn bị gỡ có nhất quán giữa US2-4, phần trường hợp biên và FR-008 không? [Consistency, Spec §US2-4, §Edge Cases]
- [ ] CHK020 Thời hạn 5 giây trong SC-004 và SC-008 có áp dụng cho cùng điều kiện đo không? [Consistency, Spec §SC-004, §SC-008]

## Chất lượng tiêu chí chấp nhận

- [x] CHK021 SC-001 (3 giây) có thể đo khách quan được không: mốc bắt đầu và mốc kết thúc (thẻ món đầu tiên, hay toàn bộ màn hình đầu) đã được định nghĩa chưa? [Measurability, Spec §SC-001]
- [x] CHK022 SC-002 ("tối đa 2 lần chạm") có định nghĩa điểm bắt đầu khi thanh danh mục phải cuộn ngang mới thấy danh mục cần chọn không? [Measurability, Spec §SC-002]
- [ ] CHK023 SC-003 có nêu phạm vi kiểm thử ("bằng bất kỳ cách nào", tức gồm cả truy vấn trực tiếp ngoài giao diện) để có thể chứng minh 0 vi phạm không? [Measurability, Spec §SC-003, §FR-011]
- [ ] CHK024 Mọi kịch bản chấp nhận của US3 có gắn với ngưỡng thời gian đo được, hay chỉ kịch bản 1 tham chiếu tiêu chí thành công? [Acceptance Criteria, Spec §US3]

## Phạm vi kịch bản

- [ ] CHK025 Yêu cầu cho luồng chính (Guest mở Home), luồng thay thế (Customer đã đăng nhập) và luồng lỗi có được viết đầy đủ, hay luồng Customer chỉ là "giống Guest"? [Coverage, Spec §US1-2, §FR-001]
- [ ] CHK026 Có yêu cầu cho luồng khôi phục khi mạng trở lại giữa chừng lúc đang tải thêm món (tiếp tục tải, hay phải cuộn lại) không? [Gap, Recovery Flow, Spec §FR-009, §FR-014]
- [ ] CHK027 Có yêu cầu cho trường hợp món đang mở ở màn hình chi tiết bị gỡ đăng bán khi người dùng đang xem không? [Gap, Spec §US4]
- [ ] CHK028 Có yêu cầu cho trường hợp danh mục mới được đăng bán khi người dùng đang xem (vị trí chip mới, không đổi chip đang chọn) không? [Gap, Spec §FR-008]

## Trường hợp biên

- [ ] CHK029 Có yêu cầu cho món có `priceDelta` âm hoặc dữ liệu size không hợp lệ (bỏ qua, hay ẩn món) không? [Edge Case, Gap, Spec §FR-005]
- [ ] CHK030 Có yêu cầu cho trường hợp mục "Phổ biến" có ít hơn 10 món đủ điều kiện (hiện bao nhiêu, có ngưỡng tối thiểu không) không? [Edge Case, Spec §FR-013]
- [ ] CHK031 Có yêu cầu cho cache cũ chứa món đã bị gỡ đăng bán trong lúc ngoại tuyến (được phép hiện tạm, hay phải ẩn) không? [Edge Case, Gap, Spec §FR-014, §FR-011]

## Yêu cầu phi chức năng

- [ ] CHK032 Yêu cầu bảo mật có nói rõ rằng việc chặn món/danh mục chưa đăng bán phải được áp ở phía máy chủ (không chỉ lọc ở ứng dụng) và ai được phép ghi menu không? [Security, Spec §FR-011, §FR-012]
- [ ] CHK033 Ràng buộc đồng bộ trạng thái và thứ tự danh mục sang món (plan R1) có được ghi thành yêu cầu bắt buộc cho tính năng quản lý danh mục, kèm hậu quả nếu vi phạm không? [Dependency, Plan §R1, Spec §FR-011]
- [ ] CHK034 Yêu cầu tiếp cận đã nêu đủ cho mọi phần tử tương tác (thẻ món, chip, nút thử lại, nút quay về): vùng chạm tối thiểu, nhãn ngữ nghĩa, không dựa vào màu sắc? [Accessibility, Spec §FR-004, §SC-006]
- [ ] CHK035 Có yêu cầu về việc thông báo thay đổi trạng thái (ngoại tuyến, danh mục bị gỡ) cho trình đọc màn hình không? [Accessibility, Gap, Spec §FR-014, §US2-4]
- [ ] CHK036 Có yêu cầu về giới hạn dữ liệu tải khi dùng mạng di động (kích thước ảnh, số món mỗi lần tải) không, hay đã chủ động loại khỏi phạm vi? [Performance, Gap, Spec §FR-009]

## Phụ thuộc và giả định

- [ ] CHK037 Giả định "dữ liệu thực đơn do Admin tạo hoặc tạo sẵn" có nêu rõ cách có dữ liệu để kiểm thử độc lập khi màn hình quản trị chưa có không? [Assumption, Spec §Assumptions]
- [ ] CHK038 Phụ thuộc vào màn hình chi tiết món (FR-009 gốc) có nêu rõ phạm vi tối thiểu mà feature này phải cung cấp để US4 kiểm thử độc lập được không? [Dependency, Spec §US4, §Assumptions]
- [ ] CHK039 Giả định giao diện chỉ tiếng Việt có được ghi rõ, khi đặc tả gốc có lựa chọn ngôn ngữ (FR-042 gốc) không? [Assumption, Gap]

## Ghi chú

- Đánh dấu `[x]` khi yêu cầu tương ứng đã được viết đủ, rõ và nhất quán; ghi phát hiện ngay dưới mục.
- Các mục CHK002, CHK008, CHK015, CHK016, CHK021 trùng với các phát hiện U1, I1, I2, G1 của lần chạy `/speckit-analyze` gần nhất.
