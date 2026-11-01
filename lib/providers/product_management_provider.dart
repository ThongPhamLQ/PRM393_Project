import 'package:flutter/foundation.dart';

import '../repositories/product_management_repository.dart';

/// Local to the Admin product-management route; no main.dart changes needed.
class ProductManagementProvider extends ChangeNotifier {
  ProductManagementProvider({ProductManagementRepository? repository})
    : _repo = repository ?? ProductManagementRepository();

  final ProductManagementRepository _repo;
  List<ManagedProduct> products = [];
  List<ManagedProduct> deletedProducts = [];
  List<ManagedCategory> categories = [];
  List<ManagedTopping> toppings = [];
  bool loading = false;
  bool saving = false;
  String? error;
  bool _disposed = false;

  Future<void> refresh() async {
    if (_disposed) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final nextCategories = await _repo.getCategories();
      final nextToppings = await _repo.getToppings();
      final nextProducts = await _repo.getProducts();
      final nextDeleted = await _repo.getDeletedProducts();
      if (_disposed) return;
      categories = nextCategories;
      toppings = nextToppings;
      products = nextProducts;
      deletedProducts = nextDeleted;
    } catch (e) {
      if (!_disposed) error = e.toString();
    } finally {
      if (!_disposed) {
        loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> _save(Future<void> Function() operation) async {
    if (saving) throw StateError('Đang lưu, vui lòng thử lại.');
    saving = true;
    notifyListeners();
    try {
      await operation();
      await refresh();
      if (error != null)
        throw StateError('Đã lưu nhưng không tải lại được danh sách: $error');
    } finally {
      saving = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> saveProduct({
    int? id,
    required int categoryId,
    required String name,
    required String description,
    required int price,
    required String imageUrl,
    required ProductSaleStatus status,
  }) => _save(() async {
    await _repo.saveProduct(
      id: id,
      categoryId: categoryId,
      name: name,
      description: description,
      price: price,
      imageUrl: imageUrl,
      status: status,
    );
  });

  Future<void> setStatus(int id, ProductSaleStatus status) =>
      _save(() => _repo.changeProductStatus(id, status));

  /// A single transaction deletes the current selection; no half-deletes.
  Future<int> softDeleteProducts(List<int> ids) async {
    var deleted = 0;
    await _save(() async {
      deleted = await _repo.softDeleteProducts(ids);
    });
    return deleted;
  }

  Future<void> restoreProduct(int id) => _save(() => _repo.restoreProduct(id));

  Future<void> saveCategory(String name, {int? id}) => _save(() async {
    await _repo.saveCategory(name, id: id);
  });

  Future<void> deleteCategory(int id) =>
      _save(() => _repo.deleteCategoryIfEmpty(id));

  Future<void> saveTopping(String name, int price, {int? id}) =>
      _save(() async {
        await _repo.saveTopping(name, price, id: id);
      });

  Future<void> deleteTopping(int id) => _save(() => _repo.deleteTopping(id));

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
