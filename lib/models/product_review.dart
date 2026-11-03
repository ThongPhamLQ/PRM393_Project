import 'package:cloud_firestore/cloud_firestore.dart';

class ProductReview {
  final String userId;
  final int orderId;
  final int rating;
  final String comment;
  final DateTime? createdAt;
  ProductReview.fromMap(Map<String, dynamic> data)
    : userId = data['userId'] as String,
      orderId = data['orderId'] as int,
      rating = data['rating'] as int,
      comment = data['comment'] as String,
      createdAt = (data['createdAt'] as Timestamp?)?.toDate();
}
