import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shop_app/models/app_notification.dart';
import 'package:shop_app/models/order.dart';
import 'package:shop_app/providers/order_provider.dart';
import 'package:shop_app/repositories/order_repository.dart';
import 'package:shop_app/widgets/active_order_card.dart';

// Đơn mẫu tổng 35.000 đ (khớp với 1 món 35.000 đ ở dưới)
Order _order({int? id, OrderStatus status = OrderStatus.pending}) => Order(
  id: id,
  userId: 'uid-1',
  customerName: 'An',
  phone: '0912345678',
  address: '12 Lê Lợi, Q.1',
  paymentMethod: PaymentMethod.cash,
  isPaid: false,
  totalPrice: 35000,
  status: status,
  createdAt: DateTime(2026, 11, 2, 9),
);

final _items = [
  OrderItem(
    productName: 'Trà sữa trân châu',
    size: 'M',
    toppings: '',
    quantity: 1,
    unitPrice: 35000,
  ),
];

void main() {
  group('Theo dõi đơn - logic không cần Firestore', () {
    test('isActive: chỉ đơn chưa hoàn thành / chưa hủy', () {
      expect(
        OrderStatus.values.where((s) => s.isActive),
        [
          OrderStatus.pending,
          OrderStatus.confirmed,
          OrderStatus.preparing,
          OrderStatus.delivering,
        ],
      );
    });

    test('thanh tiến độ tăng dần theo từng bước', () {
      final steps = [
        OrderStatus.pending,
        OrderStatus.confirmed,
        OrderStatus.preparing,
        OrderStatus.delivering,
        OrderStatus.completed,
      ].map(ActiveOrderCard.progressOf).toList();
      expect(steps.first, closeTo(0.2, 1e-9));
      expect(steps.last, closeTo(1.0, 1e-9));
      for (int i = 1; i < steps.length; i++) {
        expect(steps[i], greaterThan(steps[i - 1]));
      }
    });

    test('newPendingOrders: lần nhận đầu tiên không báo các đơn cũ', () {
      final orders = [_order(id: 1), _order(id: 2)];
      expect(OrderProvider.newPendingOrders(null, orders), isEmpty);
    });

    test('newPendingOrders: chỉ báo đơn "Chờ xác nhận" có mã mới', () {
      final orders = [
        _order(id: 3), // mới, đang chờ -> báo
        _order(id: 4, status: OrderStatus.cancelled), // mới nhưng đã hủy
        _order(id: 1), // đã biết từ trước
      ];
      final result = OrderProvider.newPendingOrders({1, 2}, orders);
      expect(result.map((o) => o.id), [3]);
    });

    test('AppNotification: thông báo cũ không có orderId -> null', () {
      final old = AppNotification.fromMap('n1', 'uid-1', {
        'title': 'Đặt hàng thành công',
        'body': 'Đơn #1',
        'isRead': false,
        'createdAt': '2026-10-01T09:00:00',
      });
      expect(old.orderId, isNull);

      final withOrder = AppNotification(
        userId: 'uid-1',
        title: 't',
        body: 'b',
        createdAt: DateTime(2026, 11, 2),
        orderId: 7,
      );
      expect(withOrder.toMap()['orderId'], 7);
      // null thì không ghi field orderId lên Firestore
      final noOrder = AppNotification(
        userId: 'uid-1',
        title: 't',
        body: 'b',
        createdAt: DateTime(2026, 11, 2),
      );
      expect(noOrder.toMap().containsKey('orderId'), isFalse);
    });
  });

  group('OrderProvider với Firestore giả', () {
    late FakeFirebaseFirestore db;
    late OrderRepository repository;
    late OrderProvider provider;

    setUp(() {
      db = FakeFirebaseFirestore();
      repository = OrderRepository(db: db);
      provider = OrderProvider(db: db);
    });

    test('đổi trạng thái -> thông báo của khách gắn đúng mã đơn', () async {
      final id = await repository.createOrder(_order(), _items);
      final order = (await repository.getOrderById(id))!;

      await provider.updateStatus(order, OrderStatus.confirmed);

      expect((await repository.getOrderById(id))!.status, OrderStatus.confirmed);
      final notifications = await db
          .collection('users')
          .doc('uid-1')
          .collection('notifications')
          .get();
      expect(notifications.docs, hasLength(1));
      expect(notifications.docs.single.data()['orderId'], id);
    });

    test('findOrder: đọc từ Firestore khi đơn chưa có trong danh sách', () async {
      final id = await repository.createOrder(_order(), _items);
      expect(provider.orders, isEmpty);

      final found = await provider.findOrder(id);
      expect(found?.id, id);
      expect(await provider.findOrder(999), isNull);
    });
  });
}
