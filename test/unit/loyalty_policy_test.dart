import 'package:flutter_test/flutter_test.dart';
import 'package:shop_app/models/loyalty.dart';
import 'package:shop_app/models/order.dart';

void main() {
  group('LoyaltyPolicy', () {
    test('earns one point for each complete 10,000 VND paid', () {
      expect(LoyaltyPolicy.pointsEarned(9999), 0);
      expect(LoyaltyPolicy.pointsEarned(25000), 2);
    });

    test('limits redemption by balance and twenty percent of subtotal', () {
      expect(
        LoyaltyPolicy.maxRedeemablePoints(subtotal: 100000, balance: 50),
        20,
      );
      expect(
        LoyaltyPolicy.maxRedeemablePoints(subtotal: 100000, balance: 7),
        7,
      );
    });

    test('calculates a checkout total from points without going negative', () {
      final quote = LoyaltyPolicy.quote(
        subtotal: 100000,
        balance: 50,
        requestedPoints: 20,
      );
      expect(quote.discountAmount, 20000);
      expect(quote.totalPrice, 80000);
      expect(
        () => LoyaltyPolicy.quote(
          subtotal: 100000,
          balance: 50,
          requestedPoints: 21,
        ),
        throwsStateError,
      );
    });
  });

  test('old order maps default loyalty fields without changing total', () {
    final order = Order.fromMap({
      'id': 1,
      'userId': 'u1',
      'customerName': 'Khach',
      'phone': '0900',
      'address': 'Da Nang',
      'paymentMethod': 'cash',
      'isPaid': false,
      'totalPrice': 45000,
      'status': 'completed',
      'createdAt': '2026-01-01T00:00:00.000Z',
    });

    expect(order.subtotal, 45000);
    expect(order.pointsUsed, 0);
    expect(order.discountAmount, 0);
    expect(order.loyaltyAwarded, isFalse);
    expect(order.pointsRefunded, isFalse);
  });
}
