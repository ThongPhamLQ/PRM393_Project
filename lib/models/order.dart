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
  final int? id;
  final int userId;
  final String customerName;
  final String phone;
  final String address;
  final String note;
  final PaymentMethod paymentMethod;
  final bool isPaid;
  final int totalPrice;
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
    required this.totalPrice,
    this.status = OrderStatus.pending,
    required this.createdAt,
  });

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
      totalPrice: totalPrice,
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
      'isPaid': isPaid ? 1 : 0, // SQLite không có kiểu bool -> lưu 0/1
      'totalPrice': totalPrice,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'] as int,
      userId: map['userId'] as int,
      customerName: map['customerName'] as String,
      phone: map['phone'] as String,
      address: map['address'] as String,
      note: (map['note'] as String?) ?? '',
      paymentMethod: PaymentMethod.values.byName(
        map['paymentMethod'] as String,
      ),
      isPaid: map['isPaid'] == 1,
      totalPrice: map['totalPrice'] as int,
      status: OrderStatus.values.byName(map['status'] as String),
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}

// 1 món trong đơn hàng.
// Lưu lại tên, size, topping, giá tại thời điểm đặt
// -> sau này quán đổi giá menu thì lịch sử đơn vẫn đúng.
class OrderItem {
  final int? id;
  final int? orderId;
  final String productName;
  final String size;
  final String toppings;
  final String note;
  final int quantity;
  final int unitPrice;

  OrderItem({
    this.id,
    this.orderId,
    required this.productName,
    required this.size,
    required this.toppings,
    this.note = '',
    required this.quantity,
    required this.unitPrice,
  });

  int get totalPrice => unitPrice * quantity;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderId': orderId,
      'productName': productName,
      'size': size,
      'toppings': toppings,
      'note': note,
      'quantity': quantity,
      'unitPrice': unitPrice,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map['id'] as int,
      orderId: map['orderId'] as int,
      productName: map['productName'] as String,
      size: map['size'] as String,
      toppings: (map['toppings'] as String?) ?? '',
      note: (map['note'] as String?) ?? '',
      quantity: map['quantity'] as int,
      unitPrice: map['unitPrice'] as int,
    );
  }
}
