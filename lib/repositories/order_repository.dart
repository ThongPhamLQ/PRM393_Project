import '../data/database_helper.dart';
import '../models/order.dart';

// Đọc/ghi bảng orders và order_items
class OrderRepository {
  final _dbHelper = DatabaseHelper.instance;

  // Lưu đơn hàng + các món trong đơn.
  // Dùng transaction: nếu lỗi giữa chừng thì không lưu gì cả.
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
    final db = await _dbHelper.database;
    return db.transaction((txn) async {
      final orderId = await txn.insert('orders', order.toMap()..remove('id'));
      for (final item in items) {
        final map = item.toMap()
          ..remove('id')
          ..['orderId'] = orderId;
        await txn.insert('order_items', map);
      }
      return orderId;
    });
  }

  // Đơn hàng của 1 khách (mới nhất lên đầu)
  Future<List<Order>> getOrdersByUser(int userId) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'orders',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'id DESC',
    );
    return rows.map((row) => Order.fromMap(row)).toList();
  }

  // Tất cả đơn hàng (cho chủ quán)
  Future<List<Order>> getAllOrders() async {
    final db = await _dbHelper.database;
    final rows = await db.query('orders', orderBy: 'id DESC');
    return rows.map((row) => Order.fromMap(row)).toList();
  }

  Future<List<OrderItem>> getOrderItems(int orderId) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'order_items',
      where: 'orderId = ?',
      whereArgs: [orderId],
    );
    return rows.map((row) => OrderItem.fromMap(row)).toList();
  }

  Future<Order?> getOrderById(int orderId) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'orders',
      where: 'id = ?',
      whereArgs: [orderId],
      limit: 1,
    );
    return rows.isEmpty ? null : Order.fromMap(rows.first);
  }

  // SQLite UPDATE là nguyên tử. Điều kiện status ngăn ghi đè bản cập nhật
  // từ màn hình đang giữ trạng thái cũ (optimistic concurrency control).
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
    final db = await _dbHelper.database;
    final changed = await db.update(
      'orders',
      {'status': newStatus.name},
      where: 'id = ? AND status = ?',
      whereArgs: [orderId, expectedStatus.name],
    );
    if (changed != 1) {
      throw StateError(
        'Đơn hàng đã thay đổi hoặc không còn tồn tại. Vui lòng tải lại.',
      );
    }
  }
}
