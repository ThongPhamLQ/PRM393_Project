# Phụ lục cập nhật SampleProjectReport.docx

Nguồn đối chiếu: `D:\SampleProjectReport.docx` trước phase mới. Phụ lục này cập nhật phần việc mới, không thay đổi ghi nhận công việc cũ của thành viên khác.

## 1. Team Introduction — nội dung đề xuất

**Vương Minh Quân (DE190747) — Loyalty & Customer Feedback Developer**

Triển khai Loyalty Hub (món yêu thích, số dư và lịch sử điểm, đổi/tích/hoàn điểm bằng transaction); tìm kiếm/lọc đơn hàng cho khách và admin; đánh giá món sau mua với xác minh đơn hoàn tất; bổ sung Security Rules, unit/widget test, kiểm thử request trên Firebase Emulator, tài liệu schema và demo. Mã được phát triển với hỗ trợ công cụ AI; thành viên cần nắm và giải thích được các luồng mình nhận phụ trách.

**Contribution đề xuất: 25%, chờ nhóm thống nhất.** Không thay các tỷ lệ của thành viên khác thành số chính thức chỉ dựa trên tỷ lệ commit. Bảng đóng góp theo từng topic (phần 7) cũng cần nhóm đánh giá lại theo công việc thực tế; không tự gán đồng loạt 25% cho mọi topic.

## 3–4. Yêu cầu, kiến trúc, database và triển khai

- Bổ sung yêu thích realtime và thẻ điểm thành viên. Policy: 10.000đ = 1 điểm, 1 điểm giảm 1.000đ, tối đa 20% subtotal; không hết hạn hoặc cộng bù đơn đã hoàn tất.
- Redeem cùng transaction tạo đơn pending; earn cùng transaction admin hoàn tất đơn; refund cùng transaction hủy đơn pending. Ledger có ID xác định và bất biến, Rules ràng buộc cả trước/sau ghi để chống lặp.
- Bổ sung tìm/lọc đơn tại client theo danh sách realtime, không cần collection hoặc chỉ mục mới cho tìm kiếm.
- Bổ sung đánh giá món đã mua: 1–5 sao, nhận xét tùy chọn tối đa 500 ký tự; 1 review/món/đơn completed, không sửa/xóa; admin chỉ đọc.
- Thêm FavoriteProvider, LoyaltyProvider và các repository loyalty/favorite/review. Review UI sử dụng StreamBuilder và repository trực tiếp, không tạo state toàn cục mới.
- Bổ sung schema account/ledger/favorites/reviews và các field order tương thích ngược theo README và `PHASE_DEMO.md`. Review thêm `itemIndex` để Rules xác minh sản phẩm trong đơn.
- Sửa nhận định bảo mật: giá menu được repository đối chiếu phía client; Rules không cung cấp xác thực toàn bộ giá từng item như một backend tin cậy.

## 4.2. Testing — kết quả cập nhật

97 Flutter test pass ngày 03/11/2026 sau khi tích hợp code mới của nhóm; thêm test policy điểm, transaction, favorites/logout/xóa mềm, tìm kiếm đơn, điều kiện review và giao diện gửi/hiển thị realtime. Test Rules thực hiện request khách/admin hợp lệ và giả mạo trên Emulator, gồm đồng thời, chống ghi trùng, quyền riêng tư và ledger bất biến. Web release build và smoke Chrome headless pass; APK debug build pass, không chạy máy ảo. Kiểm thử đăng nhập Firebase thật và hai tài khoản chưa nghiệm thu; không tính chúng vào kết quả đã pass.

## 5–6. Demo và hướng phát triển

Dùng kịch bản trong `PHASE_DEMO.md` để trình bày tích/đổi/hoàn điểm, yêu thích đa thiết bị, tìm đơn và review sau mua. Loại tích điểm và đánh giá món khỏi danh sách “chưa triển khai”; các hướng còn lại gồm voucher, FCM, upload ảnh và thanh toán thật.

## 7. Bằng chứng đóng góp

Đối chiếu commit và chức năng trong `CONTRIBUTION_EVIDENCE.md`. Tỷ lệ commit là một chỉ số lịch sử Git, không thay thế đánh giá công sức/thiết kế/kiểm thử/tài liệu. Ghi rõ nhánh và có/không tính merge khi báo cáo tỷ lệ.
