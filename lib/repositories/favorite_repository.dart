import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/firestore_db.dart';
import '../models/product.dart';

class FavoriteRepository {
  FavoriteRepository({FirebaseFirestore? db}) : _dbOverride = db;
  final FirebaseFirestore? _dbOverride;
  FirebaseFirestore get _db => _dbOverride ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _favorites(String userId) => _db
      .collection(Collections.users)
      .doc(userId)
      .collection(Collections.favorites);

  Stream<Set<int>> watchFavoriteIds(String userId) =>
      _favorites(userId)
          .snapshots()
          .map((snap) => snap.docs.map((d) => int.parse(d.id)).toSet());

  Future<void> setFavorite(String userId, int productId, bool favorite) {
    final ref = _favorites(userId).doc('$productId');
    if (!favorite) return ref.delete();
    return _db.runTransaction((transaction) async {
      if ((await transaction.get(ref)).exists) return;
      transaction.set(ref, {
        'productId': productId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Stream<List<Product>> watchAllProducts() => _db
      .collection(Collections.products)
      .snapshots()
      .map(
        (snap) => snap.docs
            .map((d) => Product.fromMap(d.data()))
            .where((p) => !p.deleted)
            .toList(),
      );
}
