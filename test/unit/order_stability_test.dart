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
      userId: 1,
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

  test('order persistence keeps payment, total and status', () {
    final order = Order(
      id: 123,
      userId: 5,
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
