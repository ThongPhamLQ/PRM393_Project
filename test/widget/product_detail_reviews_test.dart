import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shop_app/models/product.dart';
import 'package:shop_app/providers/cart_provider.dart';
import 'package:shop_app/providers/favorite_provider.dart';
import 'package:shop_app/providers/menu_provider.dart';
import 'package:shop_app/repositories/review_repository.dart';
import 'package:shop_app/screens/customer/product_detail_screen.dart';

void main() {
  testWidgets('product screen shows purchased reviews and persists favorite', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final db = FakeFirebaseFirestore();
    await db.doc('products/7/reviews/1').set({
      'userId': 'buyer',
      'orderId': 1,
      'rating': 4,
      'comment': 'Vị trà thơm',
      'createdAt': Timestamp.now(),
    });
    final favorites = FavoriteProvider(db: db);
    await favorites.load('buyer');
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => MenuProvider()),
          ChangeNotifierProvider(create: (_) => CartProvider()),
          ChangeNotifierProvider.value(value: favorites),
        ],
        child: MaterialApp(
          home: ProductDetailScreen(
            product: Product(
              id: 7,
              categoryId: 1,
              name: 'Trà',
              description: '',
              price: 25000,
            ),
            reviewRepository: ReviewRepository(db: db),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('★ 4.0/5 · 1 đánh giá'), findsOneWidget);
    expect(find.text('Vị trà thơm'), findsOneWidget);
    await tester.tap(find.byTooltip('Thêm yêu thích'));
    await tester.pumpAndSettle();
    expect((await db.doc('users/buyer/favorites/7').get()).exists, isTrue);
    expect(find.byTooltip('Bỏ yêu thích'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    favorites.dispose();
  });
}
