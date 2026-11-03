# Phase Loyalty, tìm đơn và đánh giá món

## Hành vi và schema

- Favorites: `users/{uid}/favorites/{productId}`; realtime, không ghi trùng hoặc đổi `createdAt` khi lưu lại. Món hết hàng/ngừng bán xuất hiện trong Hub, không đặt được; món xóa mềm bị ẩn rồi xuất hiện khi khôi phục.
- Điểm: mỗi 10.000đ thanh toán của đơn hoàn tất được 1 điểm, làm tròn xuống. 1 điểm giảm 1.000đ, tối đa 20% tạm tính và số dư. Không hết hạn, không chuyển tài khoản, không cộng bù đơn đã hoàn tất.
- Account: `loyaltyAccounts/{uid}` gồm `balance`, `lifetimeEarned`, `updatedAt`, `lastMutationKey`, `lastOrderId`, `lastMutationType`. Chưa có document được xem là 0 điểm.
- Ledger bất biến: `loyaltyAccounts/{uid}/transactions/{orderId_action}` gồm `orderId`, `type`, `points`, `createdAt`; action là `earn`, `redeem`, `refund`.
- Order bổ sung `subtotal`, `pointsUsed`, `discountAmount`, `loyaltyAwarded`, `pointsRefunded`. Đơn cũ vẫn đọc được. Doanh thu dùng `totalPrice` sau giảm.
- Tìm đơn trên dữ liệu realtime hiện có: khách tìm mã có/không `#`, lọc nhóm trạng thái; admin tìm thêm tên không dấu và SĐT. Từ khóa và trạng thái kết hợp; không sửa collection/schema vì tìm kiếm.
- Review: `products/{productId}/reviews/{orderId}` gồm `userId`, `orderId`, `itemIndex`, `rating`, `comment`, `createdAt`. `itemIndex` cho Rules đối chiếu món trong mảng `items`, không cần sửa đơn cũ hay lưu bản sao danh sách món. Khách chỉ đánh giá đơn hoàn tất của mình, 1 review/món/đơn, không sửa/xóa; admin chỉ đọc.

## Kịch bản demo trên hai thiết bị

1. Đăng nhập cùng tài khoản khách trên hai máy: thả tim món ở Menu hoặc chi tiết; máy còn lại cập nhật. Vào Tài khoản → Khách hàng thân thiết để xem món và điểm.
2. Admin chuyển món yêu thích sang hết hàng/ngừng bán, xóa mềm rồi khôi phục: kiểm tra Hub và quyền đặt hàng.
3. Khách đặt đơn 100.000đ không dùng điểm, admin chuyển tuần tự đến hoàn tất: nhận 10 điểm, có ledger `earn`. Cập nhật lặp không cộng thêm.
4. Khách đặt đơn tiếp theo 100.000đ, dùng 10 điểm: giảm 10.000đ, trả 90.000đ. Hủy khi pending: hoàn 10 điểm đúng một lần; thử cả khách và admin hủy ở hai đơn riêng.
5. Tìm đơn theo mã `#123`, lọc Đang xử lý/Hoàn thành/Đã hủy. Admin tìm tên không dấu hoặc SĐT. Nhập từ khóa không khớp rồi bấm Xóa bộ lọc.
6. Mở đơn completed → Đánh giá món → chọn sao, nhập nhận xét → Gửi. Nút thành Đã đánh giá; mở chi tiết món trên máy còn lại để thấy điểm trung bình và nhận xét mới nhất. Món có nhiều size/dòng trong cùng đơn chỉ có 1 nút đánh giá.
7. Đơn pending/cancelled và món của đơn cũ thiếu productId không có nút đánh giá. Đăng xuất rồi đăng nhập tài khoản khác: không còn state điểm/yêu thích của tài khoản trước.

## Kiểm thử tự động

```sh
flutter analyze
flutter test --concurrency=1
firebase emulators:exec --project demo-prm393 --only firestore "node test/rules/firestore_rules_test.mjs"
flutter build apk --debug
flutter build web --release --no-web-resources-cdn --no-wasm-dry-run
node tool/web_smoke_test.mjs
```

- Bộ Flutter: 97 test pass ngày 03/11/2026 sau khi pull/merge origin/master, gồm policy điểm, lịch sử đơn cũ, repository transaction, yêu thích/xóa mềm/logout, tìm/lọc, review và widget gửi/hiển thị/realtime; giữ cả các test mới của nhóm.
- Rules Emulator: request hợp lệ và trái quyền; concurrent review chỉ 1 thành công; chặn sao sai/nhận xét dài/món chưa mua/đơn chưa hoàn tất; chặn sửa/xóa review và ledger, giả số dư, hoàn/tích lặp hoặc thiếu ghi đơn đồng thời; kiểm tra account mới, đơn 0 điểm và hủy đơn cũ.
- Test Rules dùng project `demo-prm393`, chỉ kết nối localhost. Dữ liệu seed dùng đặc quyền emulator, các request được kiểm thử dùng token khách/admin giả lập; không đụng Firebase thật.
- Web release sau merge build thành công. `tool/web_smoke_test.mjs` (Node 22+ và Chrome) chạy bản release trên localhost, dùng profile headless tạm: xác minh form đăng nhập render, submit trống hiện lỗi Email/Mật khẩu, không có exception JavaScript hoặc lỗi tải tài nguyên. Screenshot: `build/web-smoke.png`.
- APK debug đã build thành công bằng JDK 21; không chạy máy ảo Android theo yêu cầu. Kiểm thử thủ công hai tài khoản và đăng nhập Firebase thật chưa thực hiện. Test mới từ remote trong `integration_test/` dùng Firebase thật nên không được tính vào 97 test hoặc kết quả smoke.
- `flutter test --platform chrome` trên SDK Windows 3.47.2 hiện lỗi công cụ: snapshot trỏ tới cache máy đóng gói; chạy tools từ source còn gặp separator đường dẫn và CanvasKit 404. Đã dừng thử nghiệm đó, không báo nó là pass. Kiểm chứng web bằng release build và smoke Chrome thực tế ở trên; các widget nghiệp vụ đã pass bằng Flutter test thông thường.

## Triển khai và giới hạn

Deploy Rules mới bằng `firebase deploy --only firestore:rules` trước khi phát hành app. Đây là thao tác lên Firebase thật, cần người quản lý project thực hiện/phê duyệt. Không cần migration hoặc backfill đơn đã hoàn tất.

Không có backend tin cậy: Rules kiểm tra quan hệ đơn–điểm, mức giảm và quyền review, nhưng không thể đối chiếu toàn bộ giá từng item với menu. Repository kiểm tra giỏ với menu hiện tại phía client. Không có Cloud Functions, Blaze, voucher, upload ảnh, FCM hoặc thanh toán thật.

Hiện danh sách review được tải toàn bộ để tính trung bình chính xác; phù hợp dữ liệu demo. Khi có nhiều review cần thiết kế tổng hợp tin cậy hoặc aggregate query, không chỉ lấy trung bình của một trang.
