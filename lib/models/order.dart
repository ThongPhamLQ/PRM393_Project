import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

import '../data/firestore_db.dart';

// Trạng thái đơn hàng (enum có kèm nhãn + câu mô tả để gửi thông báo)
enum OrderStatus {
  pending('Chờ xác nhận', 'Đơn hàng đang chờ quán xác nhận.'),
  confirmed('Đã xác nhận', 'Quán đã xác nhận đơn hàng của bạn.'),
  preparing('Đang pha chế', 'Đồ uống của bạn đang được pha chế.'),
  delivering('Đang giao', 'Shipper đang giao hàng đến bạn.'),
  completed('Hoàn thành', 'Đơn hàng đã hoàn thành. Cảm ơn bạn!'),
  cancelled('Đã hủy', 'Đơn hàng đã bị hủy.');

  final String label;
  final String message;
  const OrderStatus(this.label, this.message);

  // Chỉ cho phép tiến đúng một bước, hoặc hủy khi còn chờ xác nhận.
  bool canTransitionTo(OrderStatus target) =>
      (this == OrderStatus.pending && target == OrderStatus.cancelled) ||
      next == target;

  // Trạng thái kế tiếp khi chủ quán bấm "chuyển trạng thái"
  // Trả về null nếu đơn đã kết thúc (hoàn thành / đã hủy)
  OrderStatus? get next {
    switch (this) {
      case OrderStatus.pending:
        return OrderStatus.confirmed;
      case OrderStatus.confirmed:
        return OrderStatus.preparing;
      case OrderStatus.preparing:
        return OrderStatus.delivering;
      case OrderStatus.delivering:
        return OrderStatus.completed;
      case OrderStatus.completed:
      case OrderStatus.cancelled:
        return null;
    }
  }

  // Đơn còn đang chạy (chưa hoàn thành / chưa hủy) -> hiện thẻ theo dõi ở Menu
  bool get isActive => next != null;
}

// Phương thức thanh toán (online chỉ là giả lập)
enum PaymentMethod {
  cash('Tiền mặt khi nhận hàng'),
  momo('Ví MoMo (giả lập)'),
  card('Thẻ ngân hàng (giả lập)');

  final String label;
  const PaymentMethod(this.label);
}

// Đơn hàng
class Order {
  final int? id; // mã đơn #1, #2... (cấp từ counters/orders khi lưu)
  final String userId; // uid của khách đặt đơn
  final String customerName;
  final String phone;
  final String address;
  final String note;
  final PaymentMethod paymentMethod;
  final bool isPaid;
  final int subtotal;
  final int pointsUsed;
  final int discountAmount;
  final int totalPrice;
  final bool loyaltyAwarded;
  final bool pointsRefunded;
  final OrderStatus status;
  final DateTime createdAt;

  Order({
    this.id,
    required this.userId,
    required this.customerName,
    required this.phone,
    required this.address,
    this.note = '',
    required this.paymentMethod,
    required this.isPaid,
    int? subtotal,
    this.pointsUsed = 0,
    this.discountAmount = 0,
    required this.totalPrice,
    this.loyaltyAwarded = false,
    this.pointsRefunded = false,
    this.status = OrderStatus.pending,
    required this.createdAt,
  }) : subtotal = subtotal ?? totalPrice;

  // Tạo bản sao với trạng thái mới (vì các trường là final)
  Order copyWith({OrderStatus? status}) {
    return Order(
      id: id,
      userId: userId,
      customerName: customerName,
      phone: phone,
      address: address,
      note: note,
      paymentMethod: paymentMethod,
      isPaid: isPaid,
      subtotal: subtotal,
      pointsUsed: pointsUsed,
      discountAmount: discountAmount,
      totalPrice: totalPrice,
      loyaltyAwarded: loyaltyAwarded,
      pointsRefunded: pointsRefunded,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'customerName': customerName,
      'phone': phone,
      'address': address,
      'note': note,
      'paymentMethod': paymentMethod.name, // lưu dạng chữ: 'cash', 'momo'...
      'isPaid': isPaid, // Firestore có sẵn kiểu bool
      'subtotal': subtotal,
      'pointsUsed': pointsUsed,
      'discountAmount': discountAmount,
      'totalPrice': totalPrice,
      'loyaltyAwarded': loyaltyAwarded,
      'pointsRefunded': pointsRefunded,
      'status': status.name,
      'createdAt': Timestamp.fromDate(
        createdAt,
      ), // kiểu thời gian của Firestore
    };
  }

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: (map['id'] as num).toInt(),
      userId: map['userId'] as String,
      customerName: map['customerName'] as String,
      phone: map['phone'] as String,
      address: map['address'] as String,
      note: (map['note'] as String?) ?? '',
      paymentMethod: PaymentMethod.values.byName(
        map['paymentMethod'] as String,
      ),
      isPaid: map['isPaid'] == true,
      subtotal:
          (map['subtotal'] as num?)?.toInt() ??
          (map['totalPrice'] as num).toInt(),
      pointsUsed: (map['pointsUsed'] as num?)?.toInt() ?? 0,
      discountAmount: (map['discountAmount'] as num?)?.toInt() ?? 0,
      totalPrice: (map['totalPrice'] as num).toInt(),
      loyaltyAwarded: map['loyaltyAwarded'] == true,
      pointsRefunded: map['pointsRefunded'] == true,
      status: OrderStatus.values.byName(map['status'] as String),
      createdAt: readDate(map['createdAt']),
    );
  }
}

// 1 món trong đơn hàng, lưu trong mảng `items` của chính document đơn hàng
// (Firestore không có JOIN nên gộp vào 1 document thay cho bảng order_items).
// Lưu lại tên, size, topping, giá tại thời điểm đặt
// -> sau này quán đổi giá menu thì lịch sử đơn vẫn đúng.
class OrderItem {
  final int? productId; // để "Đặt lại"; đơn cũ chưa lưu -> null
  final String productName;
  final String size;
  final String toppings;
  final String sugar; // mức đường; đơn cũ chưa có -> ''
  final String ice; // mức đá; đơn cũ chưa có -> ''
  final String note;
  final int quantity;
  final int unitPrice;

  OrderItem({
    this.productId,
    required this.productName,
    required this.size,
    required this.toppings,
    this.sugar = '',
    this.ice = '',
    this.note = '',
    required this.quantity,
    required this.unitPrice,
  });

  int get totalPrice => unitPrice * quantity;

  Map<String, dynamic> toMap() {
    return {
      'productId': ?productId, // null thì không ghi field này
      'productName': productName,
      'size': size,
      'toppings': toppings,
      'sugar': sugar,
      'ice': ice,
      'note': note,
      'quantity': quantity,
      'unitPrice': unitPrice,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: (map['productId'] as num?)?.toInt(),
      productName: map['productName'] as String,
      size: map['size'] as String,
      toppings: (map['toppings'] as String?) ?? '',
      // Đơn đặt trước khi có mức đường / đá -> chuỗi rỗng (không hiện gì)
      sugar: (map['sugar'] as String?) ?? '',
      ice: (map['ice'] as String?) ?? '',
      note: (map['note'] as String?) ?? '',
      quantity: (map['quantity'] as num).toInt(),
      unitPrice: (map['unitPrice'] as num).toInt(),
    );
  }
}
