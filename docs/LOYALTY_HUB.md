# Loyalty Hub

## Chính sách

- Đơn chuyển sang `completed` tích `totalPrice ~/ 10000` điểm đúng một lần.
- 1 điểm giảm 1.000đ; tối đa 20% tạm tính và không vượt số dư.
- Điểm bị trừ khi tạo đơn và hoàn đúng một lần nếu đơn bị hủy.
- Đơn hoàn tất trước khi phát hành tính năng không được cộng bù.

## Firestore

- `users/{uid}/favorites/{productId}` lưu yêu thích realtime.
- `loyaltyAccounts/{uid}` lưu số dư và tổng điểm từng tích.
- `loyaltyAccounts/{uid}/transactions/{orderId_action}` là sổ giao dịch bất biến.
- Order mới lưu `subtotal`, `pointsUsed`, `discountAmount`, `loyaltyAwarded`, `pointsRefunded`; order cũ đọc được bằng giá trị mặc định.

Tạo đơn, đổi trạng thái, trừ/cộng/hoàn điểm và ghi ledger chạy trong Firestore transaction. Revenue dashboard tiếp tục dùng `totalPrice` sau giảm và chỉ ghi nhận đơn hoàn tất.
