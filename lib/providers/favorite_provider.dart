import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../repositories/favorite_repository.dart';
import '../models/product.dart';

class FavoriteProvider extends ChangeNotifier {
  FavoriteProvider({FirebaseFirestore? db})
    : _repository = FavoriteRepository(db: db);

  final FavoriteRepository _repository;
  StreamSubscription<Set<int>>? _subscription;
  Set<int> _ids = {};
  List<Product> _products = [];
  String? _userId;
  int _generation = 0;

  Set<int> get ids => Set.unmodifiable(_ids);
  List<Product> get favoriteProducts =>
      _products.where((p) => _ids.contains(p.id)).toList();
  bool contains(int productId) => _ids.contains(productId);

  Future<void> load(String userId) async {
    if (_userId == userId && _subscription != null) return;
    final generation = ++_generation;
    await _subscription?.cancel();
    if (generation != _generation) return;
    _userId = userId;
    _ids = {};
    final first = Completer<void>();
    _subscription = _repository
        .watchFavoriteIds(userId)
        .listen(
          (ids) {
            if (generation != _generation) return;
            _ids = ids;
            notifyListeners();
            if (!first.isCompleted) first.complete();
          },
          onError: (Object e) {
            debugPrint('Favorite stream failed: $e');
            if (!first.isCompleted) first.complete();
          },
        );
    _productsSubscription ??= _repository.watchAllProducts().listen(
      (products) {
        _products = products;
        notifyListeners();
      },
      onError: (Object e) => debugPrint('Favorite products stream failed: $e'),
    );
    return first.future;
  }

  Future<void> toggle(int productId) async {
    final userId = _userId;
    if (userId == null) throw StateError('Bạn chưa đăng nhập.');
    await _repository.setFavorite(userId, productId, !contains(productId));
  }

  void clear() {
    _generation++;
    _subscription?.cancel();
    _subscription = null;
    _userId = null;
    _ids = {};
    _productsSubscription?.cancel();
    _productsSubscription = null;
    _products = [];
    notifyListeners();
  }

  StreamSubscription<List<Product>>? _productsSubscription;

  @override
  void dispose() {
    _generation++;
    _subscription?.cancel();
    _productsSubscription?.cancel();
    super.dispose();
  }
}
