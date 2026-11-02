import 'package:cloud_firestore/cloud_firestore.dart' hide Order;

import '../data/firestore_db.dart';
import '../models/order.dart';

// Đọc/ghi collection orders. Mỗi đơn là 1 document, các món nằm trong mảng items.
class OrderRepository {
  OrderRepository({FirebaseFirestore? db}) : _dbOverride = db;
  final FirebaseFirestore? _dbOverride;
  // Lấy instance khi dùng: kiểm tra dữ liệu sai thì báo lỗi luôn, không cần Firebase
  FirebaseFirestore get _db => _dbOverride ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _orders =>
      _db.collection(Collections.orders);

  // Lưu đơn hàng + các món trong đơn.
  // Dùng transaction: cấp mã đơn và lưu đơn cùng lúc, lỗi giữa chừng thì không lưu gì.
  Future<int> createOrder(Order order, List<OrderItem> items) async {
    if (items.isEmpty ||
        items.any((item) => item.quantity <= 0 || item.unitPrice < 0)) {
      throw StateError('Danh sách món trong đơn không hợp lệ.');
    }
    final calculatedTotal = items.fold<int>(
      0,
      (sum, item) => sum + item.totalPrice,
    );
    if (calculatedTotal <= 0 || calculatedTotal != order.totalPrice) {
      throw StateError('Tổng tiền và chi tiết đơn hàng không khớp.');
    }
    return _db.runTransaction((txn) async {
      final orderId = await nextId(txn, _db, Collections.orders);
      txn.set(_orders.doc('$orderId'), {
        ...order.toMap(),
        'id': orderId,
        'items': items.map((item) => item.toMap()).toList(),
      });
      return orderId;
    });
  }

  static List<Order> _toOrders(QuerySnapshot<Map<String, dynamic>> snap) =>
      snap.docs.map((d) => Order.fromMap(d.data())).toList()
        ..sort((a, b) => b.id!.compareTo(a.id!)); // mới nhất lên đầu

  // Đơn hàng của 1 khách. Stream: quán đổi trạng thái thì danh sách tự cập nhật.
  // Sắp xếp ở máy để không phải tạo composite index (userId + id) trên Firestore.
  Stream<List<Order>> watchOrdersByUser(String userId) =>
      _orders.where('userId', isEqualTo: userId).snapshots().map(_toOrders);

  // Tất cả đơn hàng (cho chủ quán): khách đặt đơn mới là hiện ngay
  Stream<List<Order>> watchAllOrders() => _orders.snapshots().map(_toOrders);

  Future<List<OrderItem>> getOrderItems(int orderId) async {
    final doc = await _orders.doc('$orderId').get();
    final items = (doc.data()?['items'] as List?) ?? const [];
    return items
        .map((m) => OrderItem.fromMap(Map<String, dynamic>.from(m as Map)))
        .toList();
  }

  Future<Order?> getOrderById(int orderId) async {
    final data = (await _orders.doc('$orderId').get()).data();
    return data == null ? null : Order.fromMap(data);
  }

  // Transaction đọc lại trạng thái hiện tại trước khi ghi: máy khác vừa đổi
  // trạng thái thì báo lỗi thay vì ghi đè (optimistic concurrency control).
  Future<void> updateStatus(
    int orderId,
    OrderStatus newStatus, {
    required OrderStatus expectedStatus,
  }) async {
    if (!expectedStatus.canTransitionTo(newStatus)) {
      throw StateError(
        'Không thể chuyển đơn từ ${expectedStatus.label} sang ${newStatus.label}.',
      );
    }
    await _db.runTransaction((txn) async {
      final ref = _orders.doc('$orderId');
      final snap = await txn.get(ref);
      if (snap.data()?['status'] != expectedStatus.name) {
        throw StateError(
          'Đơn hàng đã thay đổi hoặc không còn tồn tại. Vui lòng tải lại.',
        );
      }
      txn.update(ref, {'status': newStatus.name});
    });
  }
}
