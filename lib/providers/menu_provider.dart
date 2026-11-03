import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/product.dart';
import '../repositories/menu_repository.dart';
import '../utils/text_search.dart';

// Quản lý menu: danh mục, món, topping, lọc theo danh mục + tìm kiếm.
// Nghe 3 Stream từ Firestore: chủ quán đổi menu thì máy khách tự cập nhật.
class MenuProvider extends ChangeNotifier {
  final _menuRepo = MenuRepository();
  final _subscriptions = <StreamSubscription<Object?>>[];

  List<MenuCategory> _categories = [];
  List<Product> _products = [];
  List<Topping> _toppings = [];
  int? _selectedCategoryId; // null = "Tất cả"
  String _searchText = '';
  bool _isLoading = false;
  String? _loadError;

  List<MenuCategory> get categories => _categories;
  List<Product> get products => _products; // tất cả món đang bán (chưa lọc)
  List<Topping> get toppings => _toppings;
  int? get selectedCategoryId => _selectedCategoryId;
  String get searchText => _searchText;
  bool get isLoading => _isLoading;
  String? get loadError => _loadError;

  // Danh sách món sau khi lọc theo danh mục và từ khóa tìm kiếm
  List<Product> get filteredProducts {
    return _products.where((p) {
      final matchCategory =
          _selectedCategoryId == null || p.categoryId == _selectedCategoryId;
      // Không phân biệt dấu: gõ "tra sua" vẫn ra "Trà sữa"
      final matchSearch = matchesSearch(p.name, _searchText);
      return matchCategory && matchSearch;
    }).toList();
  }

  // Future xong khi cả danh mục, món và topping đã về lần đầu
  Future<void> loadMenu() {
    _cancel();
    _isLoading = true;
    _loadError = null;
    notifyListeners();

    final received = <String>{};
    final ready = Completer<void>();
    void finishLoading() {
      _isLoading = false;
      if (!ready.isCompleted) ready.complete();
    }

    void update(String part, void Function() apply) {
      apply();
      received.add(part);
      if (received.length == 3) finishLoading();
      notifyListeners();
    }

    void onError(Object e) {
      debugPrint('Menu stream failed: $e');
      _loadError = 'Không tải được menu. Kiểm tra kết nối mạng rồi thử lại.';
      finishLoading();
      notifyListeners();
    }

    _subscriptions.addAll([
      _menuRepo.watchCategories().listen(
        (list) => update('categories', () {
          _categories = list;
          // Danh mục đang chọn vừa bị chủ quán xóa -> quay về "Tất cả"
          if (!list.any((c) => c.id == _selectedCategoryId)) {
            _selectedCategoryId = null;
          }
        }),
        onError: onError,
      ),
      _menuRepo.watchProducts().listen(
        (list) => update('products', () => _products = list),
        onError: onError,
      ),
      _menuRepo.watchToppings().listen(
        (list) => update('toppings', () => _toppings = list),
        onError: onError,
      ),
    ]);
    return ready.future;
  }

  void selectCategory(int? categoryId) {
    _selectedCategoryId = categoryId;
    notifyListeners();
  }

  void search(String text) {
    _searchText = text;
    notifyListeners();
  }

  // Gọi khi đăng xuất: ngừng nghe Firestore trước khi mất quyền đọc
  void clear() => _cancel();

  void _cancel() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
  }
}
