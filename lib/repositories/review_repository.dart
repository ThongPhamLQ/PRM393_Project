import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/product_review.dart';

class ReviewRepository {
  ReviewRepository({FirebaseFirestore? db}) : _override = db;
  final FirebaseFirestore? _override;
  FirebaseFirestore get _db => _override ?? FirebaseFirestore.instance;

  Stream<List<ProductReview>> watchProduct(int productId) => _db
      .collection('products/$productId/reviews')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => ProductReview.fromMap(doc.data()))
            .toList(),
      );

  Stream<bool> watchReviewed(int productId, int orderId) => _db
      .doc('products/$productId/reviews/$orderId')
      .snapshots()
      .map((snapshot) => snapshot.exists);

  Future<void> submit({
    required String userId,
    required int orderId,
    required int productId,
    required int rating,
    String comment = '',
  }) async {
    final text = comment.trim();
    if (rating < 1 || rating > 5 || text.length > 500) {
      throw ArgumentError('Số sao hoặc nhận xét không hợp lệ.');
    }
    final reviewRef = _db.doc('products/$productId/reviews/$orderId');
    await _db.runTransaction((transaction) async {
      final order = (await transaction.get(_db.doc('orders/$orderId'))).data();
      final existing = await transaction.get(reviewRef);
      final items = (order?['items'] as List?) ?? [];
      final index = items.indexWhere((item) => item['productId'] == productId);
      if (order == null ||
          order['userId'] != userId ||
          order['status'] != 'completed' ||
          index < 0 ||
          existing.exists) {
        throw StateError('Món không đủ điều kiện hoặc đã được đánh giá.');
      }
      transaction.set(reviewRef, {
        'userId': userId,
        'orderId': orderId,
        'itemIndex': index,
        'rating': rating,
        'comment': text,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
