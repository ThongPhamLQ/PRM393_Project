import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shop_app/models/order.dart';
import 'package:shop_app/repositories/favorite_repository.dart';
import 'package:shop_app/repositories/loyalty_repository.dart';
import 'package:shop_app/repositories/order_repository.dart';
import 'package:shop_app/providers/favorite_provider.dart';

void main() {
  test(
    'favorite products retain unavailable items and reappear after restore',
    () async {
      final db = FakeFirebaseFirestore();
      final repo = FavoriteRepository(db: db);
      await db.doc('products/7').set({
        'id': 7,
        'categoryId': 1,
        'name': 'Trà',
        'price': 25000,
        'status': 'soldOut',
        'deleted': false,
      });
      expect((await repo.watchAllProducts().first).single.status, 'soldOut');
      await db.doc('products/7').update({'deleted': true});
      expect(await repo.watchAllProducts().first, isEmpty);
      await db.doc('products/7').update({'deleted': false, 'status': 'hidden'});
      expect((await repo.watchAllProducts().first).single.status, 'hidden');
    },
  );

  test('logout clears favorites and stops subscriptions', () async {
    final db = FakeFirebaseFirestore();
    await FavoriteRepository(db: db).setFavorite('u1', 7, true);
    final provider = FavoriteProvider(db: db);
    await provider.load('u1');
    expect(provider.ids, {7});
    provider.clear();
    await db.doc('users/u1/favorites/8').set({'productId': 8});
    await Future<void>.delayed(Duration.zero);
    expect(provider.ids, isEmpty);
    expect(provider.favoriteProducts, isEmpty);
    provider.dispose();
  });

  test(
    'insufficient balance leaves counter, order and ledger unchanged',
    () async {
      final db = FakeFirebaseFirestore();
      await db.doc('counters/orders').set({'value': 0});
      await db.doc('loyaltyAccounts/u1').set({
        'balance': 1,
        'lifetimeEarned': 1,
      });
      final order = Order(
        userId: 'u1',
        customerName: 'Khách',
        phone: '0900000000',
        address: 'Test',
        paymentMethod: PaymentMethod.cash,
        isPaid: false,
        subtotal: 100000,
        totalPrice: 80000,
        pointsUsed: 20,
        discountAmount: 20000,
        createdAt: DateTime(2026),
      );
      await expectLater(
        OrderRepository(db: db).createOrder(order, [
          OrderItem(
            productId: 7,
            productName: 'Trà',
            size: 'S',
            toppings: '',
            quantity: 1,
            unitPrice: 100000,
          ),
        ]),
        throwsStateError,
      );
      expect((await db.collection('orders').get()).docs, isEmpty);
      expect((await db.doc('counters/orders').get()).data()!['value'], 0);
      expect((await db.doc('loyaltyAccounts/u1').get()).data()!['balance'], 1);
      expect(
        (await db.collection('loyaltyAccounts/u1/transactions').get()).docs,
        isEmpty,
      );
    },
  );
  test('favorites are idempotent and stream product ids', () async {
    final db = FakeFirebaseFirestore();
    final repository = FavoriteRepository(db: db);

    await repository.setFavorite('u1', 7, true);
    final original = (await db.doc('users/u1/favorites/7').get())
        .data()!['createdAt'];
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await repository.setFavorite('u1', 7, true);
    expect(
      (await db.doc('users/u1/favorites/7').get()).data()!['createdAt'],
      original,
    );

    expect(await repository.watchFavoriteIds('u1').first, {7});
    await repository.setFavorite('u1', 7, false);
    expect(await repository.watchFavoriteIds('u1').first, isEmpty);
  });

  test(
    'creating an order redeems points atomically and records a ledger entry',
    () async {
      final db = FakeFirebaseFirestore();
      await db.collection('counters').doc('orders').set({'value': 0});
      await db.collection('loyaltyAccounts').doc('u1').set({
        'balance': 30,
        'lifetimeEarned': 30,
      });
      final repository = OrderRepository(db: db);
      final order = Order(
        userId: 'u1',
        customerName: 'Khach',
        phone: '0900',
        address: 'Da Nang',
        paymentMethod: PaymentMethod.cash,
        isPaid: false,
        subtotal: 100000,
        pointsUsed: 20,
        discountAmount: 20000,
        totalPrice: 80000,
        createdAt: DateTime(2026, 1, 1),
      );
      final items = [
        OrderItem(
          productId: 1,
          productName: 'Tra',
          size: 'S',
          toppings: '',
          quantity: 1,
          unitPrice: 100000,
        ),
      ];

      final id = await repository.createOrder(order, items);
      final account = await db.collection('loyaltyAccounts').doc('u1').get();
      final ledger = await db
          .collection('loyaltyAccounts')
          .doc('u1')
          .collection('transactions')
          .doc('${id}_redeem')
          .get();

      expect(account.data()!['balance'], 10);
      expect(ledger.data()!['points'], 20);
    },
  );

  test('completion earns once and cancellation refunds once', () async {
    final db = FakeFirebaseFirestore();
    await db.collection('loyaltyAccounts').doc('u1').set({
      'balance': 0,
      'lifetimeEarned': 0,
    });
    await db.collection('orders').doc('1').set({
      'id': 1,
      'userId': 'u1',
      'status': 'delivering',
      'totalPrice': 25000,
      'pointsUsed': 0,
      'loyaltyAwarded': false,
      'pointsRefunded': false,
    });
    final repository = OrderRepository(db: db);

    await repository.updateStatus(
      1,
      OrderStatus.completed,
      expectedStatus: OrderStatus.delivering,
    );
    final account = await LoyaltyRepository(db: db).getAccount('u1');
    expect(account.balance, 2);
    expect(account.lifetimeEarned, 2);
    expect(
      () => repository.updateStatus(
        1,
        OrderStatus.completed,
        expectedStatus: OrderStatus.delivering,
      ),
      throwsStateError,
    );
  });

  test('cancelling a redeemed order refunds points exactly once', () async {
    final db = FakeFirebaseFirestore();
    await db.collection('loyaltyAccounts').doc('u1').set({
      'balance': 5,
      'lifetimeEarned': 30,
    });
    await db.collection('orders').doc('9').set({
      'id': 9,
      'userId': 'u1',
      'status': 'pending',
      'totalPrice': 80000,
      'pointsUsed': 20,
      'loyaltyAwarded': false,
      'pointsRefunded': false,
    });
    final repository = OrderRepository(db: db);

    await repository.updateStatus(
      9,
      OrderStatus.cancelled,
      expectedStatus: OrderStatus.pending,
    );

    final account = await LoyaltyRepository(db: db).getAccount('u1');
    final order = await db.collection('orders').doc('9').get();
    expect(account.balance, 25);
    expect(order.data()!['pointsRefunded'], isTrue);
    expect(
      () => repository.updateStatus(
        9,
        OrderStatus.cancelled,
        expectedStatus: OrderStatus.pending,
      ),
      throwsStateError,
    );
  });
}
