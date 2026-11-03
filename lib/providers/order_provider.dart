import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart' show FirebaseFirestore;
import 'package:flutter/foundation.dart';

import '../models/app_notification.dart';
import '../models/cart_item.dart';
import '../models/loyalty.dart';
import '../models/order.dart';
import '../models/user.dart';
import '../repositories/notification_repository.dart';
import '../repositories/loyalty_repository.dart';
import '../repositories/order_repository.dart';
import '../repositories/product_management_repository.dart';
import '../services/notification_service.dart';
import '../utils/format.dart';

// Quản lý đơn hàng: đặt hàng, lịch sử đơn, chủ quán cập nhật trạng thái.
// Danh sách đơn nghe Stream từ Firestore nên tự cập nhật khi máy khác thay đổi.
class OrderProvider extends ChangeNotifier {
  // db: test truyền FakeFirebaseFirestore vào; app thật để trống (dùng Firestore thật)
  OrderProvider({FirebaseFirestore? db})
    : _dbOverride = db,
      _orderRepo = OrderRepository(db: db),
      _notificationRepo = NotificationRepository(db: db),
      _productRepo = ProductManagementRepository(db: db);

  final OrderRepository _orderRepo;
  final FirebaseFirestore? _dbOverride;
  final NotificationRepository _notificationRepo;
  final ProductManagementRepository _productRepo;
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
    alertNewOrders: true,
  );

  // Các đơn "Chờ xác nhận" mới xuất hiện so với lần nghe trước.
  // knownIds == null: lần nhận dữ liệu đầu tiên -> không báo các đơn đã có sẵn.
  static List<Order> newPendingOrders(Set<int>? knownIds, List<Order> orders) {
    if (knownIds == null) return [];
    return orders
        .where(
          (o) =>
              o.status == OrderStatus.pending &&
              o.id != null &&
              !knownIds.contains(o.id),
        )
        .toList();
  }

  // Nghe Stream: mỗi lần Firestore báo thay đổi thì thay danh sách + notifyListeners.
  // Future xong khi có dữ liệu lần đầu (để RefreshIndicator biết lúc tắt vòng xoay).
  // alertNewOrders: màn chủ quán -> có đơn mới thì hiện thông báo hệ thống.
  Future<void> _listen(
    Stream<List<Order>> stream,
    String errorMessage, {
    bool alertNewOrders = false,
  }) {
    _subscription?.cancel();
    _isLoading = true;
    notifyListeners();
    final firstData = Completer<void>();
    Set<int>? knownIds; // mã các đơn đã thấy, null = chưa nhận lần nào
    _subscription = stream.listen(
      (orders) {
        if (alertNewOrders) {
          for (final o in newPendingOrders(knownIds, orders)) {
            NotificationService.instance.show(
              'Đơn mới #${o.id}',
              '${o.customerName} · ${formatVnd(o.totalPrice)}',
            );
          }
          knownIds = orders.map((o) => o.id).whereType<int>().toSet();
        }
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

  // Tìm đơn để mở chi tiết (từ thông báo / màn đặt hàng thành công):
  // có sẵn trong danh sách đang nghe thì dùng luôn, không thì đọc từ Firestore.
  Future<Order?> findOrder(int orderId) async {
    for (final o in _orders) {
      if (o.id == orderId) return o;
    }
    return _orderRepo.getOrderById(orderId);
  }

  // Đặt hàng từ giỏ hàng. Trả về mã đơn vừa tạo.
  Future<int> placeOrder({
    required User user,
    required List<CartItem> cartItems,
    required String customerName,
    required String phone,
    required String address,
    required String note,
    required PaymentMethod paymentMethod,
    int pointsToUse = 0,
  }) async {
    if (cartItems.isEmpty ||
        cartItems.any((item) => item.quantity <= 0 || item.unitPrice < 0)) {
      throw StateError('Giỏ hàng hoặc người dùng không hợp lệ.');
    }
    await _productRepo.assertCartSellable(cartItems);
    final subtotal = cartItems.fold<int>(
      0,
      (sum, item) => sum + item.totalPrice,
    );
    if (subtotal <= 0) throw StateError('Tổng tiền đơn hàng không hợp lệ.');
    final account = await LoyaltyRepository(db: _dbOverride)
        .getAccount(user.id);
    final quote = LoyaltyPolicy.quote(
      subtotal: subtotal,
      balance: account.balance,
      requestedPoints: pointsToUse,
    );

    final order = Order(
      userId: user.id,
      customerName: customerName,
      phone: phone,
      address: address,
      note: note,
      paymentMethod: paymentMethod,
      // Thanh toán online (giả lập) đã thành công trước khi gọi hàm này
      isPaid: paymentMethod != PaymentMethod.cash,
      subtotal: quote.subtotal,
      pointsUsed: quote.pointsUsed,
      discountAmount: quote.discountAmount,
      totalPrice: quote.totalPrice,
      createdAt: DateTime.now(),
    );

    // Chuyển CartItem -> OrderItem để lưu vào database
    final orderItems = cartItems
        .map(
          (c) => OrderItem(
            productId: c.product.id,
            productName: c.product.name,
            size: c.size,
            toppings: c.toppingNames,
            sugar: c.sugar,
            ice: c.ice,
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
      orderId: orderId,
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
      orderId: order.id,
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
  // orderId: gắn mã đơn để bấm thông báo thì mở đúng đơn đó.
  Future<void> _notify(
    String userId,
    String title,
    String body, {
    int? orderId,
  }) async {
    try {
      await _notificationRepo.insert(
        AppNotification(
          userId: userId,
          title: title,
          body: body,
          createdAt: DateTime.now(),
          orderId: orderId,
        ),
      );
    } catch (e) {
      debugPrint('Saving in-app notification failed: $e');
    }
  }
}
