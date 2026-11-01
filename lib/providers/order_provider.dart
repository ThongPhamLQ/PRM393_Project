import 'package:flutter/foundation.dart';

import '../models/app_notification.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../models/user.dart';
import '../repositories/notification_repository.dart';
import '../repositories/order_repository.dart';
import '../services/notification_service.dart';
import '../repositories/product_management_repository.dart';

// Quản lý đơn hàng: đặt hàng, lịch sử đơn, chủ quán cập nhật trạng thái
class OrderProvider extends ChangeNotifier {
  final _orderRepo = OrderRepository();
  final _notificationRepo = NotificationRepository();

  List<Order> _orders = [];
  bool _isLoading = false;
  String? _loadError;

  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get loadError => _loadError;

  // Khách hàng: chỉ lấy đơn của mình
  Future<void> loadMyOrders(int userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _orders = await _orderRepo.getOrdersByUser(userId);
      _loadError = null;
    } catch (e) {
      _loadError = 'Không thể tải lịch sử đơn hàng. Vui lòng thử lại.';
      debugPrint('loadMyOrders failed: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Chủ quán: lấy tất cả đơn
  Future<void> loadAllOrders() async {
    _isLoading = true;
    notifyListeners();
    try {
      _orders = await _orderRepo.getAllOrders();
      _loadError = null;
    } catch (e) {
      _loadError = 'Không thể tải danh sách đơn. Vui lòng thử lại.';
      debugPrint('loadAllOrders failed: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<OrderItem>> getOrderItems(int orderId) {
    return _orderRepo.getOrderItems(orderId);
  }

  Future<Order?> getOrderById(int orderId) => _orderRepo.getOrderById(orderId);

  // Đặt hàng từ giỏ hàng. Trả về mã đơn vừa tạo.
  Future<int> placeOrder({
    required User user,
    required List<CartItem> cartItems,
    required String customerName,
    required String phone,
    required String address,
    required String note,
    required PaymentMethod paymentMethod,
  }) async {
    if (user.id == null ||
        cartItems.isEmpty ||
        cartItems.any((item) => item.quantity <= 0 || item.unitPrice < 0)) {
      throw StateError('Giỏ hàng hoặc người dùng không hợp lệ.');
    }
    await ProductManagementRepository().assertCartSellable(cartItems);
    final total = cartItems.fold<int>(0, (sum, item) => sum + item.totalPrice);
    if (total <= 0) throw StateError('Tổng tiền đơn hàng không hợp lệ.');

    final order = Order(
      userId: user.id!,
      customerName: customerName,
      phone: phone,
      address: address,
      note: note,
      paymentMethod: paymentMethod,
      // Thanh toán online (giả lập) đã thành công trước khi gọi hàm này
      isPaid: paymentMethod != PaymentMethod.cash,
      totalPrice: total,
      createdAt: DateTime.now(),
    );

    // Chuyển CartItem -> OrderItem để lưu vào database
    final orderItems = cartItems
        .map(
          (c) => OrderItem(
            productName: c.product.name,
            size: c.size,
            toppings: c.toppingNames,
            note: c.note,
            quantity: c.quantity,
            unitPrice: c.unitPrice,
          ),
        )
        .toList();

    final orderId = await _orderRepo.createOrder(order, orderItems);
    await _notify(
      user.id!,
      'Đặt hàng thành công',
      'Đơn #$orderId: ${OrderStatus.pending.message}',
      showLocalNotification: true, // Khách tự tạo đơn trên thiết bị này.
    );
    return orderId;
  }

  // Đổi trạng thái đơn (chủ quán chuyển bước, hoặc khách hủy đơn)
  Future<void> updateStatus(Order order, OrderStatus newStatus) async {
    if (order.id == null) throw StateError('Đơn hàng không có mã hợp lệ.');
    await _orderRepo.updateStatus(
      order.id!,
      newStatus,
      expectedStatus: order.status,
    );

    // Đơn đã được lưu: cập nhật danh sách trước khi ghi thông báo.
    final index = _orders.indexWhere((o) => o.id == order.id);
    if (index != -1) {
      _orders[index] = order.copyWith(status: newStatus);
    }
    notifyListeners();

    // Chỉ ghi lịch sử thông báo, không phát local notification trên máy Admin.
    await _notify(
      order.userId,
      'Đơn #${order.id}: ${newStatus.label}',
      newStatus.message,
    );
  }

  // Gọi khi đăng xuất
  void clear() {
    _orders = [];
    _loadError = null;
    notifyListeners();
  }

  // Lưu thông báo vào database (để xem ở màn Thông báo)
  // + hiện thông báo hệ thống trên điện thoại
  // Thông báo là tác vụ phụ: nếu lỗi, đơn hàng vẫn đã được lưu.
  // Không gửi local notification từ máy Admin sang máy khách.
  Future<void> _notify(
    int userId,
    String title,
    String body, {
    bool showLocalNotification = false,
  }) async {
    try {
      await _notificationRepo.insert(
        AppNotification(
          userId: userId,
          title: title,
          body: body,
          createdAt: DateTime.now(),
        ),
      );
    } catch (e) {
      debugPrint('Saving in-app notification failed: $e');
    }
    if (showLocalNotification) {
      try {
        await NotificationService.instance.show(title, body);
      } catch (e) {
        // Không báo "đặt hàng thất bại" khi SQLite đã lưu đơn thành công.
        debugPrint('Showing local notification failed: $e');
      }
    }
  }
}
