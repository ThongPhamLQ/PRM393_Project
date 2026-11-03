import 'package:flutter/material.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shop_app/models/product_review.dart';
import 'package:shop_app/repositories/review_repository.dart';
import 'package:shop_app/widgets/product_reviews.dart';

void main() {
  testWidgets('submits selected stars and comment then shows reviewed state', (
    tester,
  ) async {
    final db = FakeFirebaseFirestore();
    await db.doc('orders/1').set({
      'userId': 'buyer',
      'status': 'completed',
      'items': [
        {'productId': 7},
      ],
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OrderReviewButton(
            productId: 7,
            orderId: 1,
            userId: 'buyer',
            productName: 'Trà',
            repository: ReviewRepository(db: db),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đánh giá Trà'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('3 sao'));
    await tester.enterText(find.byType(TextField), 'Ít ngọt, ngon');
    await tester.tap(find.text('Gửi đánh giá'));
    await tester.pumpAndSettle();
    final data = (await db.doc('products/7/reviews/1').get()).data()!;
    expect(data['rating'], 3);
    expect(data['comment'], 'Ít ngọt, ngon');
    expect(find.text('Trà: Đã đánh giá'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('renders new review from realtime stream', (tester) async {
    final db = FakeFirebaseFirestore();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProductReviews(
            productId: 7,
            repository: ReviewRepository(db: db),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Chưa có đánh giá'), findsOneWidget);
    await db.doc('products/7/reviews/1').set({
      'userId': 'buyer',
      'orderId': 1,
      'rating': 4,
      'comment': 'Thơm',
      'createdAt': Timestamp.fromDate(DateTime(2026)),
    });
    await tester.pumpAndSettle();
    expect(find.text('★ 4.0/5 · 1 đánh giá'), findsOneWidget);
    expect(find.text('Thơm'), findsOneWidget);
  });
  testWidgets('shows empty state then rating average and comments', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ReviewList(reviews: [])),
      ),
    );
    expect(find.text('Chưa có đánh giá'), findsOneWidget);
    final reviews = [
      ProductReview.fromMap({
        'userId': 'a',
        'orderId': 1,
        'rating': 5,
        'comment': 'Rất ngon',
      }),
      ProductReview.fromMap({
        'userId': 'b',
        'orderId': 2,
        'rating': 2,
        'comment': '',
      }),
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ReviewList(reviews: reviews)),
      ),
    );
    expect(find.text('★ 3.5/5 · 2 đánh giá'), findsOneWidget);
    expect(find.text('Rất ngon'), findsOneWidget);
    expect(find.text('Chưa có đánh giá'), findsNothing);
  });
}
