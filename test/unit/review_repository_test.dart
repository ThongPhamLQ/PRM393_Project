import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shop_app/repositories/review_repository.dart';

void main() {
  late FakeFirebaseFirestore db;
  late ReviewRepository repo;
  setUp(() async {
    db = FakeFirebaseFirestore();
    repo = ReviewRepository(db: db);
    await db.doc('orders/1').set({
      'userId': 'buyer',
      'status': 'completed',
      'items': [
        {'productId': 7},
        {'productId': 7},
      ],
    });
  });
  Future<void> submit({
    String uid = 'buyer',
    int product = 7,
    int rating = 5,
    String comment = '',
  }) => repo.submit(
    userId: uid,
    orderId: 1,
    productId: product,
    rating: rating,
    comment: comment,
  );

  test(
    'saves verified purchase and rejects duplicate product across lines',
    () async {
      await submit(comment: ' ngon ');
      final saved = (await db.doc('products/7/reviews/1').get()).data()!;
      expect(saved['comment'], 'ngon');
      expect(saved['itemIndex'], 0);
      await expectLater(submit(), throwsStateError);
      expect(
        (await db.collection('products/7/reviews').get()).docs,
        hasLength(1),
      );
    },
  );
  test('rejects different customer and unpurchased product', () async {
    await expectLater(submit(uid: 'other'), throwsStateError);
    await expectLater(submit(product: 8), throwsStateError);
  });
  test('rejects unfinished and missing orders', () async {
    await db.doc('orders/1').update({'status': 'pending'});
    await expectLater(submit(), throwsStateError);
    await db.doc('orders/1').delete();
    await expectLater(submit(), throwsStateError);
  });
  test('enforces stars and comment boundaries', () async {
    await expectLater(submit(rating: 0), throwsArgumentError);
    await expectLater(submit(rating: 6), throwsArgumentError);
    await expectLater(submit(comment: 'x' * 501), throwsArgumentError);
    await submit(rating: 1, comment: 'x' * 500);
  });
  test('streams newest reviews before older purchases', () async {
    await submit(rating: 3);
    await db.doc('products/7/reviews/2').set({
      'userId': 'other',
      'orderId': 2,
      'rating': 5,
      'comment': 'Old',
      'createdAt': Timestamp.fromDate(DateTime(2020)),
    });
    final reviews = await repo.watchProduct(7).first;
    expect(reviews.map((review) => review.rating), [3, 5]);
    expect(reviews.first.userId, 'buyer');
  });
}
