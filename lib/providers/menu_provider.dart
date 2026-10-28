import 'package:flutter/foundation.dart';

import '../models/product.dart';
import '../repositories/menu_repository.dart';

// Quản lý menu: danh mục, món, topping, lọc theo danh mục + tìm kiếm
class MenuProvider extends ChangeNotifier {
  final _menuRepo = MenuRepository();

  List<MenuCategory> _categories = [];
  List<Product> _products = [];
  List<Topping> _toppings = [];
  int? _selectedCategoryId; // null = "Tất cả"
  String _searchText = '';
  bool _isLoading = false;

  List<MenuCategory> get categories => _categories;
  List<Topping> get toppings => _toppings;
  int? get selectedCategoryId => _selectedCategoryId;
  String get searchText => _searchText;
  bool get isLoading => _isLoading;

  // Danh sách món sau khi lọc theo danh mục và từ khóa tìm kiếm
  List<Product> get filteredProducts {
    return _products.where((p) {
      final matchCategory =
          _selectedCategoryId == null || p.categoryId == _selectedCategoryId;
      final matchSearch = p.name.toLowerCase().contains(
        _searchText.toLowerCase(),
      );
      return matchCategory && matchSearch;
    }).toList();
  }

  Future<void> loadMenu() async {
    _isLoading = true;
    notifyListeners();

    _categories = await _menuRepo.getCategories();
    _products = await _menuRepo.getProducts();
    _toppings = await _menuRepo.getToppings();

    _isLoading = false;
    notifyListeners();
  }

  void selectCategory(int? categoryId) {
    _selectedCategoryId = categoryId;
    notifyListeners();
  }

  void search(String text) {
    _searchText = text;
    notifyListeners();
  }
}
