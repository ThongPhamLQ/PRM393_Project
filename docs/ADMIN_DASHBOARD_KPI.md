# Giai đoạn 2A — Admin Dashboard / Quy tắc KPI

**Nhánh duy nhất: `dat`.** Giữ nguyên SQLite/schema, không xóa dữ liệu cũ, không thay pubspec.

## KPI chính thức

- **Phạm vi thời gian:** 7 ngày, 30 ngày hoặc tất cả. Đếm theo `orders.createdAt` là thời điểm tạo đơn (không phải thời điểm hoàn thành). Các ngày được tính theo giờ địa phương từ 00:00, bao gồm hôm nay; phạm vi lịch sử *không* phải 7 × 24 giờ lăn.
- **Doanh thu ghi nhận:** tổng `orders.totalPrice` của đơn có `status='completed'`, **không dựa riêng vào `isPaid`**. Do ứng dụng dùng thanh toán giả lập và đơn tiền mặt, đây là **doanh thu đơn hoàn tất theo ngày tạo**, không phải doanh thu kế toán, doanh thu đã thu tiền, hay doanh thu theo ngày hoàn thành.
- **Tổng đơn:** tất cả đơn thuộc kỳ, tính cả đã hủy.
- **Chờ xác nhận:** `pending`.
- **Đang xử lý:** `confirmed`, `preparing`, `delivering`.
- **Hoàn thành:** `completed`.
- **Đã hủy:** `cancelled`.
- **Giá trị trung bình đơn hoàn thành (AOV):** doanh thu ghi nhận / số đơn `completed`, nếu mẫu số 0 hiển thị 0.
- **Tỷ lệ hủy:** số đơn `cancelled` / tổng đơn × 100%; kỳ không có đơn = 0%.
- **Tiền đã trả nhưng chưa hoàn tất:** tổng `totalPrice` có `isPaid=1` và trạng thái `pending/confirmed/preparing/delivering`. Theo dõi riêng, không cộng doanh thu.
- **Top 5 đồ uống:** tổng số lượng `order_items.quantity` theo `productName` của các đơn đã hoàn thành, lọc theo `orders.createdAt`. Giá sản phẩm được giữ theo thời điểm đặt ở `order_items`.

## Giới hạn cần nêu khi bảo vệ

- Chưa có cột ngày hoàn thành; báo cáo là cohort theo ngày **tạo** đơn, không phản ánh doanh thu phát sinh đúng ngày thực tế. Muốn báo cáo theo ngày hoàn thành, cần migration bổ sung `completedAt` và quy trình backfill rõ ràng, **không gán dữ liệu lịch sử giả**.
- `isPaid` từ thanh toán mô phỏng nên không thể coi là chứng từ thu tiền.
- Đơn đã trả trước rồi hủy cần quy trình refund trong giai đoạn riêng; Dashboard hiện không cộng vào doanh thu.
- Dashboard sử dụng cùng SQLite trên cùng thiết bị, không đồng bộ dữ liệu giữa Admin và Customer ở hai máy.
- Lọc top 5 theo tên món snapshot, tránh thay đổi lịch sử khi đổi menu; hai sản phẩm trùng tên có thể bị gộp, cần `productId` snapshot nếu yêu cầu thống kê theo SKU.
- Sửa trạng thái từ màn Admin khác rồi quay về Dashboard phải bấm refresh hoặc kéo xuống để tải dữ liệu mới.

## Bài kiểm thử chấp nhận

1. Không có đơn: các ô 0, top trống, không crash.
2. Đặt một đơn `pending`: Tổng đơn +1, doanh thu không tăng.
3. Chuyển `pending→confirmed→preparing→delivering`: đang xử lý tăng, doanh thu vẫn 0.
4. Chuyển `completed`: doanh thu tăng đúng `totalPrice`, Top 5 tăng theo quantity.
5. Hủy một đơn `pending`: tổng đơn +1, số hủy +1, doanh thu không tăng.
6. Đặt đơn giả lập đã thanh toán nhưng còn pending: chỉ ô “Đã trả tiền, chưa hoàn thành” tăng.
7. Chuyển lựa chọn 7/30/tất cả: kiểm tra dữ liệu thay đổi theo createdAt.
8. Thoát vào lại Dashboard / refresh: số liệu cập nhật đúng.
9. `flutter analyze`, `flutter test` đều pass.
