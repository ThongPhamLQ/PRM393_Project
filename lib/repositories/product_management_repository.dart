import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/firestore_db.dart';
import '../models/cart_item.dart';

/// Tình trạng bán lưu ngay trong document món (trường `status`). Món bị xóa
/// mềm vẫn còn document: `deleted = true` + `previousStatus` để khôi phục.
enum ProductSaleStatus {
  available('Đang bán'),
  soldOut('Hết hàng'),
  hidden('Ngừng bán');

  const ProductSaleStatus(this.label);
  final String label;

  static ProductSaleStatus parse(Object? raw) {
    for (final status in ProductSaleStatus.values) {
      if (status.name == raw) return status;
    }
    return ProductSaleStatus.available;
  }
}

class ManagedCategory {
  const ManagedCategory({required this.id, required this.name});
  final int id;
  final String name;
}

class ManagedTopping {
  const ManagedTopping({
    required this.id,
    required this.name,
    required this.price,
  });
  final int id;
  final String name;
  final int price;
}

class ManagedProduct {
  const ManagedProduct({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.status,
  });
  final int id;
  final int categoryId;
  final String name;
  final String description;
  final int price;
  final String imageUrl;
  final ProductSaleStatus status;

  factory ManagedProduct.fromMap(Map<String, dynamic> map) => ManagedProduct(
    id: (map['id'] as num).toInt(),
    categoryId: (map['categoryId'] as num).toInt(),
    name: map['name'] as String,
    description: (map['description'] as String?) ?? '',
    price: (map['price'] as num).toInt(),
    imageUrl: (map['imageUrl'] as String?) ?? '',
    status: ProductSaleStatus.parse(map['status']),
  );
}

/// Pure business validation is separately testable without opening a database.
class ProductInputRules {
  static String? validateName(String name) {
    if (name.trim().isEmpty) return 'Tên không được để trống.';
    if (name.trim().length > 100) return 'Tên tối đa 100 ký tự.';
    return null;
  }

  static String? validatePrice(int price, {bool allowZero = false}) {
    if (price < 0 || (!allowZero && price == 0)) {
      return allowZero ? 'Giá không thể âm.' : 'Giá phải lớn hơn 0.';
    }
    if (price > 1000000000) return 'Giá vượt giới hạn.';
    return null;
  }

  static String? validateImageUrl(String value) {
    if (value.trim().isEmpty) return null;
    final uri = Uri.tryParse(value.trim());
    if (uri == null ||
        !uri.hasAuthority ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      return 'Ảnh phải dùng URL http hoặc https.';
    }
    return null;
  }
}

/// Stable selection/ID validation shared by UI, repository and tests.
class ProductDeletionRules {
  static List<int> validIds(Iterable<int> raw) {
    final distinct = <int>{};
    for (final id in raw) {
      if (id <= 0) throw StateError('ID sản phẩm không hợp lệ.');
      distinct.add(id);
    }
    return distinct.toList(growable: false);
  }

  static List<int> selectedVisibleIds(
    Iterable<int> selectedIds,
    Iterable<int> visibleIds,
  ) {
    final visible = visibleIds.toSet();
    return validIds(selectedIds)
        .where(visible.contains)
        .toList(growable: false);
  }
}

/// Quản lý menu cho chủ quán trên Firestore: products/{id}, categories/{id},
/// toppings/{id}. Security Rules chỉ cho tài khoản chủ quán ghi các collection này.
class ProductManagementRepository {
  ProductManagementRepository({FirebaseFirestore? db}) : _dbOverride = db;
  final FirebaseFirestore? _dbOverride;
  FirebaseFirestore get _db => _dbOverride ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _products =>
      _db.collection(Collections.products);
  CollectionReference<Map<String, dynamic>> get _categories =>
      _db.collection(Collections.categories);
  CollectionReference<Map<String, dynamic>> get _toppings =>
      _db.collection(Collections.toppings);

  // Sắp xếp theo tên không phân biệt hoa thường (thay cho COLLATE NOCASE)
  static int _byName(String a, String b) =>
      a.toLowerCase().compareTo(b.toLowerCase());

  static bool _isDeleted(Map<String, dynamic>? data) => data?['deleted'] == true;

  Future<List<ManagedCategory>> getCategories() async {
    final snap = await _categories.get();
    return [
      for (final d in snap.docs)
        ManagedCategory(
          id: (d['id'] as num).toInt(),
          name: d['name'] as String,
        ),
    ]..sort((a, b) => _byName(a.name, b.name));
  }

  Future<List<ManagedTopping>> getToppings() async {
    final snap = await _toppings.get();
    return [
      for (final d in snap.docs)
        ManagedTopping(
          id: (d['id'] as num).toInt(),
          name: d['name'] as String,
          price: (d['price'] as num).toInt(),
        ),
    ]..sort((a, b) => _byName(a.name, b.name));
  }

  Future<List<ManagedProduct>> getProducts() async {
    final snap = await _products.get();
    return [
      for (final d in snap.docs)
        if (!_isDeleted(d.data())) ManagedProduct.fromMap(d.data()),
    ]..sort((a, b) => _byName(a.name, b.name));
  }

  /// Product details stay intact, including their former sale status.
  Future<List<ManagedProduct>> getDeletedProducts() async {
    final snap = await _products.where('deleted', isEqualTo: true).get();
    final docs = snap.docs.toList()
      ..sort((a, b) {
        final byTime = (b['deletedAt'] as Timestamp).compareTo(
          a['deletedAt'] as Timestamp,
        );
        return byTime != 0 ? byTime : _byName(a['name'], b['name']);
      });
    return [for (final d in docs) ManagedProduct.fromMap(d.data())];
  }

  /// Customer menu hides sold-out, discontinued and deleted products.
  Future<Set<int>> getUnavailableIds() async {
    final snap = await _products.get();
    return {
      for (final d in snap.docs)
        if (d['status'] != ProductSaleStatus.available.name)
          (d['id'] as num).toInt(),
    };
  }

  Future<int> saveProduct({
    int? id,
    required int categoryId,
    required String name,
    required String description,
    required int price,
    required String imageUrl,
    required ProductSaleStatus status,
  }) async {
    final nameError = ProductInputRules.validateName(name);
    final priceError = ProductInputRules.validatePrice(price);
    final imageError = ProductInputRules.validateImageUrl(imageUrl);
    if (nameError != null || priceError != null || imageError != null) {
      throw StateError(
        nameError ?? priceError ?? imageError ?? 'Dữ liệu không hợp lệ.',
      );
    }
    return _db.runTransaction((txn) async {
      // Transaction: đọc hết (danh mục, món cũ, bộ đếm) rồi mới ghi
      final category = await txn.get(_categories.doc('$categoryId'));
      if (!category.exists) throw StateError('Danh mục không còn tồn tại.');
      if (id != null) {
        final existing = await txn.get(_products.doc('$id'));
        if (!existing.exists) {
          throw StateError('Không tìm thấy sản phẩm cần sửa.');
        }
        if (_isDeleted(existing.data())) {
          throw StateError('Hãy khôi phục sản phẩm trước khi sửa.');
        }
      }
      final savedId = id ?? await nextId(txn, _db, Collections.products);
      final values = <String, Object?>{
        'id': savedId,
        'categoryId': categoryId,
        'name': name.trim(),
        'description': description.trim(),
        'price': price,
        'imageUrl': imageUrl.trim(),
        'status': status.name,
      };
      final ref = _products.doc('$savedId');
      if (id == null) {
        txn.set(ref, {...values, 'deleted': false});
      } else {
        txn.update(ref, values);
      }
      return savedId;
    });
  }

  Future<void> changeProductStatus(int id, ProductSaleStatus status) async {
    await _db.runTransaction((txn) async {
      final ref = _products.doc('$id');
      final snap = await txn.get(ref);
      if (!snap.exists) throw StateError('Sản phẩm không còn tồn tại.');
      if (_isDeleted(snap.data())) {
        throw StateError('Hãy khôi phục sản phẩm trước khi sửa trạng thái.');
      }
      txn.update(ref, {'status': status.name});
    });
  }

  /// Move one or many products into the recycle bin atomically. Documents in
  /// products/orders are not deleted, and the previous sale status is saved.
  Future<int> softDeleteProducts(List<int> inputIds) async {
    final ids = ProductDeletionRules.validIds(inputIds);
    if (ids.isEmpty) throw StateError('Chưa chọn đồ uống cần xóa.');
    // shortcut: 1 transaction tối đa 500 lần ghi; quán có hơn 500 món thì phải chia đợt.
    return _db.runTransaction((txn) async {
      final snaps = [
        for (final id in ids) await txn.get(_products.doc('$id')),
      ];
      if (snaps.any((s) => !s.exists || _isDeleted(s.data()))) {
        throw StateError(
          'Danh sách có món không tồn tại hoặc đã xóa. Hãy làm mới.',
        );
      }
      final stamp = Timestamp.now();
      for (final snap in snaps) {
        txn.update(snap.reference, {
          'deleted': true,
          // Giữ đúng tình trạng cũ (vd: hết hàng), không mặc định "đang bán"
          'previousStatus': snap.data()!['status'] ?? 'available',
          'status': ProductSaleStatus.hidden.name,
          'deletedAt': stamp,
        });
      }
      return ids.length;
    });
  }

  /// Restores previous availability in the same transaction.
  Future<void> restoreProduct(int id) async {
    if (id <= 0) throw StateError('ID sản phẩm không hợp lệ.');
    await _db.runTransaction((txn) async {
      final ref = _products.doc('$id');
      final snap = await txn.get(ref);
      if (!_isDeleted(snap.data())) {
        throw StateError('Sản phẩm không nằm trong thùng rác.');
      }
      final oldStatus = ProductSaleStatus.parse(snap.data()!['previousStatus']);
      txn.update(ref, {
        'deleted': false,
        'status': oldStatus.name,
        'previousStatus': FieldValue.delete(),
        'deletedAt': FieldValue.delete(),
      });
    });
  }

  // Danh mục và topping dùng chung cách lưu: kiểm tra trùng tên rồi thêm / sửa
  Future<int> _saveNamed(
    CollectionReference<Map<String, dynamic>> collection,
    String counterName,
    Map<String, Object> values, {
    required int? id,
    required String duplicateMessage,
    required String missingMessage,
  }) async {
    final name = values['name'] as String;
    final existing = await collection.get();
    final duplicate = existing.docs.any(
      (d) =>
          (d['name'] as String).toLowerCase() == name.toLowerCase() &&
          (d['id'] as num).toInt() != id,
    );
    if (duplicate) throw StateError(duplicateMessage);
    if (id == null) {
      return _db.runTransaction((txn) async {
        final newId = await nextId(txn, _db, counterName);
        txn.set(collection.doc('$newId'), {...values, 'id': newId});
        return newId;
      });
    }
    if (!existing.docs.any((d) => d.id == '$id')) {
      throw StateError(missingMessage);
    }
    await collection.doc('$id').update(values);
    return id;
  }

  Future<int> saveCategory(String name, {int? id}) async {
    final nameError = ProductInputRules.validateName(name);
    if (nameError != null) throw StateError(nameError);
    return _saveNamed(
      _categories,
      Collections.categories,
      {'name': name.trim()},
      id: id,
      duplicateMessage: 'Danh mục đã tồn tại.',
      missingMessage: 'Danh mục không còn tồn tại.',
    );
  }

  Future<void> deleteCategoryIfEmpty(int id) async {
    final used = await _products
        .where('categoryId', isEqualTo: id)
        .limit(1)
        .get();
    if (used.docs.isNotEmpty) {
      throw StateError('Danh mục còn sản phẩm, kể cả sản phẩm đã ẩn.');
    }
    await _categories.doc('$id').delete();
  }

  Future<int> saveTopping(String name, int price, {int? id}) async {
    final nameError = ProductInputRules.validateName(name);
    final priceError = ProductInputRules.validatePrice(price, allowZero: true);
    if (nameError != null || priceError != null) {
      throw StateError(nameError ?? priceError ?? 'Dữ liệu không hợp lệ.');
    }
    return _saveNamed(
      _toppings,
      Collections.toppings,
      {'name': name.trim(), 'price': price},
      id: id,
      duplicateMessage: 'Topping đã tồn tại.',
      missingMessage: 'Topping không còn tồn tại.',
    );
  }

  Future<void> deleteTopping(int id) async {
    await _toppings.doc('$id').delete();
    // Order snapshots stay immutable; old carts fail validation at checkout.
  }

  /// Checkout validation is repeated just before persisting an order, so a
  /// previously cached cart cannot purchase a now-hidden/sold-out product.
  Future<void> assertCartSellable(List<CartItem> items) async {
    if (items.isEmpty) throw StateError('Giỏ hàng đang trống.');
    final toppingPrices = {
      for (final d in (await _toppings.get()).docs)
        d['name'] as String: (d['price'] as num).toInt(),
    };
    for (final item in items) {
      final data = (await _products.doc('${item.product.id}').get()).data();
      if (data == null ||
          _isDeleted(data) ||
          data['status'] != ProductSaleStatus.available.name) {
        throw StateError(
          'Một món trong giỏ đã hết hàng hoặc ngừng bán. Vui lòng chọn lại.',
        );
      }
      if ((data['price'] as num).toInt() != item.product.price) {
        throw StateError(
          'Giá sản phẩm đã thay đổi. Vui lòng xóa món cũ và thêm lại.',
        );
      }
      for (final topping in item.toppings) {
        if (toppingPrices[topping.name] != topping.price) {
          throw StateError(
            'Topping đã bị xóa, đổi tên hoặc đổi giá. Vui lòng chọn lại món.',
          );
        }
      }
    }
  }
}
