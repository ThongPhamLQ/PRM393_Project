import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shop_app/models/order.dart';
import 'package:shop_app/repositories/order_repository.dart';

void main() {
  group('OrderStatus transitions', () {
    test('happy path uses exactly one step each time', () {
      expect(
        OrderStatus.pending.canTransitionTo(OrderStatus.confirmed),
        isTrue,
      );
      expect(
        OrderStatus.confirmed.canTransitionTo(OrderStatus.preparing),
        isTrue,
      );
      expect(
        OrderStatus.preparing.canTransitionTo(OrderStatus.delivering),
        isTrue,
      );
      expect(
        OrderStatus.delivering.canTransitionTo(OrderStatus.completed),
        isTrue,
      );
    });

    test('can cancel pending order only', () {
      expect(
        OrderStatus.pending.canTransitionTo(OrderStatus.cancelled),
        isTrue,
      );
      for (final status in OrderStatus.values.where(
        (s) => s != OrderStatus.pending,
      )) {
        expect(
          status.canTransitionTo(OrderStatus.cancelled),
          isFalse,
          reason: status.name,
        );
      }
    });

    test('skipping, reversing, and repeating status are rejected', () {
      expect(
        OrderStatus.pending.canTransitionTo(OrderStatus.delivering),
        isFalse,
      );
      expect(
        OrderStatus.confirmed.canTransitionTo(OrderStatus.pending),
        isFalse,
      );
      for (final status in OrderStatus.values) {
        expect(status.canTransitionTo(status), isFalse, reason: status.name);
      }
    });

    test('terminal statuses cannot be changed', () {
      for (final terminal in [OrderStatus.completed, OrderStatus.cancelled]) {
        for (final target in OrderStatus.values) {
          expect(
            terminal.canTransitionTo(target),
            isFalse,
            reason: '${terminal.name} -> ${target.name}',
          );
        }
      }
    });
  });

  group('OrderRepository order validation (no database access)', () {
    final sample = Order(
      userId: 'uid-1',
      customerName: 'Test',
      phone: '0912345678',
      address: 'Test address',
      paymentMethod: PaymentMethod.cash,
      isPaid: false,
      totalPrice: 42000,
      createdAt: DateTime(2026, 10, 27),
    );
    test('rejects empty order', () async {
      await expectLater(
        OrderRepository().createOrder(sample, []),
        throwsStateError,
      );
    });
    test('rejects mismatch total', () async {
      final items = [
        OrderItem(
          productName: 'Cafe',
          size: 'S',
          toppings: '',
          quantity: 1,
          unitPrice: 12000,
        ),
      ];
      await expectLater(
        OrderRepository().createOrder(sample, items),
        throwsStateError,
      );
    });
    test('rejects negative quantity', () async {
      final items = [
        OrderItem(
          productName: 'Cafe',
          size: 'S',
          toppings: '',
          quantity: -1,
          unitPrice: 42000,
        ),
      ];
      await expectLater(
        OrderRepository().createOrder(sample, items),
        throwsStateError,
      );
    });
  });

  group('OrderRepository on in-memory Firestore', () {
    late FakeFirebaseFirestore db;
    late OrderRepository repository;
    final order = Order(
      userId: 'uid-1',
      customerName: 'Test',
      phone: '0912345678',
      address: 'Test address',
      paymentMethod: PaymentMethod.momo,
      isPaid: true,
      totalPrice: 84000,
      createdAt: DateTime(2026, 11, 2),
    );
    final items = [
      OrderItem(
        productName: 'Trà sữa',
        size: 'M',
        toppings: 'Pudding trứng',
        quantity: 2,
        unitPrice: 42000,
      ),
    ];

    setUp(() {
      db = FakeFirebaseFirestore();
      repository = OrderRepository(db: db);
    });

    test('order numbers increase from the counter and keep items', () async {
      expect(await repository.createOrder(order, items), 1);
      expect(await repository.createOrder(order, items), 2);
      final saved = await repository.getOrderById(2);
      expect(saved!.userId, 'uid-1');
      expect(saved.isPaid, isTrue);
      final savedItems = await repository.getOrderItems(2);
      expect(savedItems.single.quantity, 2);
      expect(savedItems.single.totalPrice, 84000);
    });

    test('status update from a stale screen is rejected', () async {
      final id = await repository.createOrder(order, items);
      await repository.updateStatus(
        id,
        OrderStatus.confirmed,
        expectedStatus: OrderStatus.pending,
      );
      // Màn hình thứ hai vẫn tưởng đơn đang "Chờ xác nhận"
      await expectLater(
        repository.updateStatus(
          id,
          OrderStatus.cancelled,
          expectedStatus: OrderStatus.pending,
        ),
        throwsStateError,
      );
      expect((await repository.getOrderById(id))!.status, OrderStatus.confirmed);
    });
  });

  test('order persistence keeps payment, total and status', () {
    final order = Order(
      id: 123,
      userId: 'uid-5',
      customerName: 'Khách thử nghiệm',
      phone: '0912345678',
      address: 'Đà Nẵng',
      paymentMethod: PaymentMethod.cash,
      isPaid: false,
      totalPrice: 42000,
      createdAt: DateTime(2026, 10, 27),
    );
    final restored = Order.fromMap(order.toMap());
    expect(restored.id, 123);
    expect(restored.userId, 'uid-5');
    expect(restored.createdAt, DateTime(2026, 10, 27));
    expect(restored.totalPrice, 42000);
    expect(restored.paymentMethod, PaymentMethod.cash);
    expect(restored.status, OrderStatus.pending);
    expect(restored.isPaid, isFalse);
    expect(
      restored.copyWith(status: OrderStatus.confirmed).status,
      OrderStatus.confirmed,
    );
  });
}
