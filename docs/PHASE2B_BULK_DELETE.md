# Giai đoạn 2B.1 — Xóa đồ uống an toàn

## Quy tắc nghiệp vụ

- **Xóa một món:** biểu tượng thùng rác trên thẻ sản phẩm, cần xác nhận.
- **Chọn nhiều:** chọn từng món bằng checkbox, chọn tất cả đang hiển thị, bỏ chọn và xóa đã chọn.
- **Xóa tất cả:** chỉ tác động tới **danh sách đang hiển thị sau tìm kiếm/bộ lọc**, không mặc định xoá các món khác. Bắt buộc xác nhận với checkbox.
- **Thùng rác:** món đã xóa được ẩn khỏi danh sách quản lý bình thường và khỏi menu khách; Admin có thể khôi phục từng món.
- **Phân biệt ngừng bán và đã xóa:** sản phẩm ngừng bán vẫn nằm trong danh sách Admin; chỉ sản phẩm có bản ghi `product_deleted` mới nằm trong Thùng rác.
- **An toàn:** không thực hiện DELETE đối với bảng `products`, `orders`, `order_items`; thực hiện cập nhật trạng thái + tombstone trong **một SQLite transaction**. Khi khôi phục, trạng thái trước khi xóa (`available` / `soldOut` / `hidden`) được phục hồi.
- **Checkout:** món đã xóa được tạm chuyển sang `hidden`, vì vậy bộ kiểm tra giỏ hàng hiện tại không cho phép đặt món đã xóa. Khi khôi phục, tình trạng bán được trả về trước đó.
- **Lưu ý:** danh mục có sản phẩm trong thùng rác vẫn chưa thể bị xóa vì các bản ghi sản phẩm gốc được giữ lại.

## Cấu trúc bảng bổ sung

```sql
CREATE TABLE IF NOT EXISTS product_deleted (
  productId INTEGER PRIMARY KEY,
  previousStatus TEXT NOT NULL,
  deletedAt TEXT NOT NULL
);
```

Không xóa database và không thay đổi cấu trúc bảng cũ.

## Các trường hợp kiểm thử

1. Tìm kiếm "Trà sữa" → chọn tất cả → xóa → các món ngoài bộ lọc còn nguyên.
2. Xóa một món đang bán → vắng khỏi menu và thùng rác có món; giỏ cũ không đặt được.
3. Khôi phục món → quay về trạng thái ban đầu; đơn cũ và KPI không thay đổi.
4. Xóa món hết hàng → khôi phục → vẫn hết hàng.
5. Xóa nhiều món, nếu một ID lỗi → **không món nào bị xóa**.
6. Bộ lọc không có món → nút Xóa tất cả bị vô hiệu hóa.
7. Kiểm tra Test Suite, Analyzer và build APK release trước khi push.

## Giới hạn

Ứng dụng sử dụng SQLite cục bộ, nên các thao tác xóa/khôi phục chỉ tác động đến dữ liệu trên thiết bị hiện hành. Không có phân quyền server hoặc đồng bộ qua nhiều máy.
