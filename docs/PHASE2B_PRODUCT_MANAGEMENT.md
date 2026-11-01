# Giai đoạn 2B – Quản lý menu Mộc Cafe & Milk Tea

## Phạm vi triển khai

Bổ sung **Admin → Đơn hàng → Quản lý sản phẩm**, gồm 3 tab **Đồ uống / Danh mục / Topping**. Giao diện mới có `ChangeNotifierProvider` riêng, không phải sửa `main.dart` hay kiến trúc các tab hiện tại.

- **Đồ uống:** thêm, sửa, tìm kiếm, lọc trạng thái; lưu tên, danh mục, giá size S, mô tả, URL ảnh. Xóa mềm bằng trạng thái `hidden`.
- **Trạng thái:** `available` (đang bán), `soldOut` (hết hàng), `hidden` (ngừng bán). Trạng thái `soldOut` và `hidden` đều **không hiển thị trong menu khách**. Admin vẫn xem được cả ba.
- **Danh mục:** thêm, đổi tên, xóa chỉ khi **không còn bất kỳ sản phẩm nào** trong danh mục (kể cả sản phẩm đã ẩn).
- **Topping:** thêm, sửa tên/giá và xóa (có xác nhận). Giỏ hàng lưu topping cũ sẽ bị từ chối khi checkout.
- **Checkout:** kiểm tra sản phẩm còn bán và **giá gốc hiện tại** ngay trước khi ghi đơn; giỏ có món ngừng bán/hết hàng hoặc đổi giá bị từ chối, yêu cầu khách thêm lại món.
- **Đơn hàng cũ:** bảng `order_items` giữ nguyên `productName`, `unitPrice`, `quantity` và các tùy chọn đã lưu, không phụ thuộc vào tên/giá hiện tại của menu.

## Cơ chế cơ sở dữ liệu

Giữ nguyên 8 bảng cũ. Thêm bảng bổ sung được khởi tạo **tự động/idempotent** khi gọi repository:

```sql
CREATE TABLE IF NOT EXISTS product_sale_status (
  productId INTEGER PRIMARY KEY,
  status TEXT NOT NULL DEFAULT 'available'
  CHECK (status IN ('available', 'soldOut', 'hidden'))
);
```

- Sản phẩm không có bản ghi trong `product_sale_status` mặc định `available` (tương thích với 14 sản phẩm seed).
- Không xóa hoặc cài lại ứng dụng; không tăng `user_version` vì bảng được tạo idempotent khi repository được gọi.
- Nếu có nhu cầu phát triển production, nên chuyển cơ chế này thành migration trong `DatabaseHelper` có version rõ ràng, thêm khóa ngoại và đảm bảo đa thiết bị.

## Business rules và tính nhất quán

- Giá món size S lớn hơn 0 và là VND dạng số nguyên; topping có thể giá 0.
- URL ảnh phải là HTTP(S); danh mục phải tồn tại.
- Danh mục không được xóa khi còn sản phẩm liên kết.
- Sản phẩm **không hard-delete**. Không ảnh hưởng đến KPI/Top đồ uống của Dashboard vì thống kê dùng `order_items` snapshot.
- Giá mới (của đồ uống hoặc topping) **không tự cập nhật giỏ hàng cũ**; thay vào đó checkout báo lỗi và yêu cầu chọn lại để tránh thu tiền theo giá sai.
- Do SQLite là trên thiết bị, Admin và Customer vẫn phải dùng cùng thiết bị; không có đồng bộ trực tiếp giữa hai máy.

## Kiểm thử bắt buộc trước commit

1. Admin thêm một đồ uống thuộc danh mục có sẵn. Đăng xuất và vào Customer, tìm thấy món.
2. Admin đổi giá món → Customer tải lại Menu và thấy giá mới; giỏ cũ với giá cũ không được checkout.
3. Admin đặt món `soldOut`/`hidden` → Customer tải lại menu không tìm thấy món; đơn lịch sử vẫn có dữ liệu.
4. Admin chuyển lại `available` → Customer tải lại menu thấy món.
5. Admin sửa tên danh mục và topping; đơn cũ, KPI không thay đổi.
6. Thử xóa danh mục còn sản phẩm → có thông báo từ chối.
7. `flutter analyze`, `flutter test`, `flutter build apk --release` đạt. Test file `product_management_test.dart` kiểm tra quy tắc đầu vào; `verify_sqlite.py` kiểm tra SQL độc lập, **không thay thế Flutter test**.
8. Chạy APK release trên emulator/thiết bị và chụp màn hình để cập nhật Technical Report.

## Báo cáo môn học

- Thêm FR-14 **Admin Product Management** ở phần 3.1; thêm sơ đồ `product_sale_status` ở 3.4; cập nhật architecture với `ProductManagementProvider` và `ProductManagementRepository`.
- Cập nhật UI Flow (thêm màn Admin Products + Editor), kiểm thử, performance và màn demo.
- Thay mục *Future improvements* “owner cannot edit menu” bằng “đã triển khai trên local SQLite; còn giới hạn đồng bộ đa thiết bị”.
- Ghi rõ khi xóa/đổi giá topping, giỏ hàng cũ phải chọn lại món trước khi checkout.
- Không tự ghi số test PASS hoặc kết quả build release khi chưa chạy trên máy thực tế.
