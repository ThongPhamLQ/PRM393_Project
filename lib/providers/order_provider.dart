import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/app_notification.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../models/user.dart';
import '../repositories/notification_repository.dart';
import '../repositories/order_repository.dart';
import '../repositories/product_management_repository.dart';

// Quản lý đơn hàng: đặt hàng, lịch sử đơn, chủ quán cập nhật trạng thái.
// Danh sách đơn nghe Stream từ Firestore nên tự cập nhật khi máy khác thay đổi.
class OrderProvider extends ChangeNotifier {
  final _orderRepo = OrderRepository();
  final _notificationRepo = NotificationRepository();
  StreamSubscription<List<Order>>? _subscription;

  List<Order> _orders = [];
  bool _isLoading = false;
  String? _loadError;

  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get loadError => _loadError;

  // Khách hàng: chỉ nghe đơn của mình
  Future<void> loadMyOrders(String userId) => _listen(
    _orderRepo.watchOrdersByUser(userId),
    'Không thể tải lịch sử đơn hàng. Vui lòng thử lại.',
  );

  // Chủ quán: nghe tất cả đơn (khách đặt đơn mới là hiện ngay)
  Future<void> loadAllOrders() => _listen(
    _orderRepo.watchAllOrders(),
    'Không thể tải danh sách đơn. Vui lòng thử lại.',
  );

  // Nghe Stream: mỗi lần Firestore báo thay đổi thì thay danh sách + notifyListeners.
  // Future xong khi có dữ liệu lần đầu (để RefreshIndicator biết lúc tắt vòng xoay).
  Future<void> _listen(Stream<List<Order>> stream, String errorMessage) {
    _subscription?.cancel();
    _isLoading = true;
    notifyListeners();
    final firstData = Completer<void>();
    _subscription = stream.listen(
      (orders) {
        _orders = orders;
        _loadError = null;
        _isLoading = false;
        notifyListeners();
        if (!firstData.isCompleted) firstData.complete();
      },
      onError: (Object e) {
        _loadError = errorMessage;
        _isLoading = false;
        debugPrint('Orders stream failed: $e');
        notifyListeners();
        if (!firstData.isCompleted) firstData.complete();
      },
    );
    return firstData.future;
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
    if (cartItems.isEmpty ||
        cartItems.any((item) => item.quantity <= 0 || item.unitPrice < 0)) {
      throw StateError('Giỏ hàng hoặc người dùng không hợp lệ.');
    }
    await ProductManagementRepository().assertCartSellable(cartItems);
    final total = cartItems.fold<int>(0, (sum, item) => sum + item.totalPrice);
    if (total <= 0) throw StateError('Tổng tiền đơn hàng không hợp lệ.');

    final order = Order(
      userId: user.id,
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
      user.id,
      'Đặt hàng thành công',
      'Đơn #$orderId: ${OrderStatus.pending.message}',
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

    // Đơn đã được lưu: cập nhật danh sách ngay, không chờ Stream báo về
    final index = _orders.indexWhere((o) => o.id == order.id);
    if (index != -1) {
      _orders[index] = order.copyWith(status: newStatus);
    }
    notifyListeners();

    await _notify(
      order.userId,
      'Đơn #${order.id}: ${newStatus.label}',
      newStatus.message,
    );
  }

  // Gọi khi đăng xuất: ngừng nghe Firestore trước khi mất quyền đọc
  void clear() {
    _subscription?.cancel();
    _subscription = null;
    _orders = [];
    _loadError = null;
    notifyListeners();
  }

  // Lưu thông báo vào users/{userId}/notifications. Máy của khách đang nghe
  // collection này (NotificationProvider) nên tự hiện thông báo hệ thống,
  // kể cả khi chủ quán đổi trạng thái trên máy khác.
  // Thông báo là tác vụ phụ: nếu lỗi, đơn hàng vẫn đã được lưu.
  Future<void> _notify(String userId, String title, String body) async {
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
  }
}
