import 'package:sqflite/sqflite.dart';

import '../data/database_helper.dart';
import '../models/cart_item.dart';

/// Availability is stored separately so existing products and order history are
/// preserved without a destructive table migration.
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
}

/// Pure business validation is separately testable without opening SQLite.
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

class ProductManagementRepository {
  ProductManagementRepository({
    DatabaseHelper? helper,
    Future<Database> Function()? databaseOpener,
  }) : _helper = helper ?? DatabaseHelper.instance,
       _databaseOpener = databaseOpener;
  final DatabaseHelper _helper;
  final Future<Database> Function()? _databaseOpener;

  Future<Database> get _db async =>
      _databaseOpener == null ? _helper.database : _databaseOpener!();

  /// Idempotent schema extension. Called from both admin screens and the
  /// customer menu/checkout paths; existing SQLite files are not deleted.
  Future<void> ensureSchema() async {
    final db = await _db;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS product_sale_status (
        productId INTEGER PRIMARY KEY,
        status TEXT NOT NULL DEFAULT 'available'
          CHECK (status IN ('available', 'soldOut', 'hidden'))
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS product_deleted (
        productId INTEGER PRIMARY KEY,
        previousStatus TEXT NOT NULL,
        deletedAt TEXT NOT NULL
      )
    ''');
  }

  Future<List<ManagedCategory>> getCategories() async {
    final db = await _db;
    final rows = await db.query('categories', orderBy: 'name COLLATE NOCASE');
    return [
      for (final row in rows)
        ManagedCategory(id: row['id'] as int, name: row['name'] as String),
    ];
  }

  Future<List<ManagedTopping>> getToppings() async {
    final db = await _db;
    final rows = await db.query('toppings', orderBy: 'name COLLATE NOCASE');
    return [
      for (final row in rows)
        ManagedTopping(
          id: row['id'] as int,
          name: row['name'] as String,
          price: (row['price'] as num).toInt(),
        ),
    ];
  }

  Future<List<ManagedProduct>> getProducts() async {
    await ensureSchema();
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT p.*, COALESCE(s.status, 'available') AS saleStatus
      FROM products p
      LEFT JOIN product_sale_status s ON s.productId = p.id
      LEFT JOIN product_deleted d ON d.productId = p.id
      WHERE d.productId IS NULL
      ORDER BY p.name COLLATE NOCASE
    ''');
    return [
      for (final r in rows)
        ManagedProduct(
          id: r['id'] as int,
          categoryId: r['categoryId'] as int,
          name: r['name'] as String,
          description: (r['description'] as String?) ?? '',
          price: (r['price'] as num).toInt(),
          imageUrl: (r['imageUrl'] as String?) ?? '',
          status: ProductSaleStatus.parse(r['saleStatus']),
        ),
    ];
  }

  /// Product details stay intact, including their former sale status.
  Future<List<ManagedProduct>> getDeletedProducts() async {
    await ensureSchema();
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT p.*, COALESCE(s.status, 'available') AS saleStatus
      FROM products p
      INNER JOIN product_deleted d ON d.productId = p.id
      LEFT JOIN product_sale_status s ON s.productId = p.id
      ORDER BY d.deletedAt DESC, p.name COLLATE NOCASE
    ''');
    return [
      for (final r in rows)
        ManagedProduct(
          id: r['id'] as int,
          categoryId: r['categoryId'] as int,
          name: r['name'] as String,
          description: (r['description'] as String?) ?? '',
          price: (r['price'] as num).toInt(),
          imageUrl: (r['imageUrl'] as String?) ?? '',
          status: ProductSaleStatus.parse(r['saleStatus']),
        ),
    ];
  }

  /// Customer menu hides sold-out, discontinued and deleted products.
  Future<Set<int>> getUnavailableIds() async {
    await ensureSchema();
    final db = await _db;
    final rows = await db.query(
      'product_sale_status',
      columns: ['productId'],
      where: 'status != ?',
      whereArgs: [ProductSaleStatus.available.name],
    );
    return rows.map((r) => r['productId'] as int).toSet();
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
    await ensureSchema();
    final db = await _db;
    return db.transaction((txn) async {
      final categories = await txn.query(
        'categories',
        columns: ['id'],
        where: 'id = ?',
        whereArgs: [categoryId],
        limit: 1,
      );
      if (categories.isEmpty) throw StateError('Danh mục không còn tồn tại.');
      final values = <String, Object?>{
        'categoryId': categoryId,
        'name': name.trim(),
        'description': description.trim(),
        'price': price,
        'imageUrl': imageUrl.trim(),
      };
      int savedId;
      if (id == null) {
        savedId = await txn.insert('products', values);
      } else {
        final changed = await txn.update(
          'products',
          values,
          where: 'id = ?',
          whereArgs: [id],
        );
        if (changed != 1) throw StateError('Không tìm thấy sản phẩm cần sửa.');
        savedId = id;
      }
      await txn.insert('product_sale_status', {
        'productId': savedId,
        'status': status.name,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      return savedId;
    });
  }

  Future<void> changeProductStatus(int id, ProductSaleStatus status) async {
    await ensureSchema();
    final db = await _db;
    await db.transaction((txn) async {
      final p = await txn.query(
        'products',
        columns: ['id'],
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (p.isEmpty) throw StateError('Sản phẩm không còn tồn tại.');
      final deleted = await txn.query(
        'product_deleted',
        columns: ['productId'],
        where: 'productId = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (deleted.isNotEmpty) {
        throw StateError('Hãy khôi phục sản phẩm trước khi sửa trạng thái.');
      }
      await txn.insert('product_sale_status', {
        'productId': id,
        'status': status.name,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  /// Move one or many products into the recycle bin atomically. No rows in
  /// products/order_items are deleted, and the previous sale status is saved.
  Future<int> softDeleteProducts(List<int> inputIds) async {
    final ids = ProductDeletionRules.validIds(inputIds);
    if (ids.isEmpty) throw StateError('Chưa chọn đồ uống cần xóa.');
    await ensureSchema();
    final db = await _db;
    return db.transaction((txn) async {
      // Keep SQL placeholder counts well below SQLite variable limits.
      for (var start = 0; start < ids.length; start += 300) {
        final part = ids.skip(start).take(300).toList();
        final markers = List.filled(part.length, '?').join(',');
        final present = await txn.rawQuery(
          'SELECT id FROM products WHERE id IN ($markers)',
          part,
        );
        final alreadyDeleted = await txn.rawQuery(
          'SELECT productId FROM product_deleted WHERE productId IN ($markers)',
          part,
        );
        if (present.length != part.length || alreadyDeleted.isNotEmpty) {
          throw StateError(
            'Danh sách có món không tồn tại hoặc đã xóa. Hãy làm mới.',
          );
        }
      }
      final stamp = DateTime.now().toUtc().toIso8601String();
      final batch = txn.batch();
      for (final id in ids) {
        // Preserve actual prior availability, not just a generic "available".
        batch.rawInsert(
          '''
          INSERT INTO product_deleted (productId, previousStatus, deletedAt)
          SELECT ?, COALESCE(s.status, 'available'), ?
          FROM products p
          LEFT JOIN product_sale_status s ON p.id = s.productId
          WHERE p.id = ?
        ''',
          [id, stamp, id],
        );
        batch.insert('product_sale_status', {
          'productId': id,
          'status': ProductSaleStatus.hidden.name,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
      return ids.length;
    });
  }

  /// Restores previous availability in the same SQLite transaction.
  Future<void> restoreProduct(int id) async {
    if (id <= 0) throw StateError('ID sản phẩm không hợp lệ.');
    await ensureSchema();
    final db = await _db;
    await db.transaction((txn) async {
      final rows = await txn.query(
        'product_deleted',
        columns: ['previousStatus'],
        where: 'productId = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isEmpty) throw StateError('Sản phẩm không nằm trong thùng rác.');
      final oldStatus = ProductSaleStatus.parse(rows.single['previousStatus']);
      await txn.insert('product_sale_status', {
        'productId': id,
        'status': oldStatus.name,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      final changed = await txn.delete(
        'product_deleted',
        where: 'productId = ?',
        whereArgs: [id],
      );
      if (changed != 1) throw StateError('Không khôi phục được sản phẩm.');
    });
  }

  Future<int> saveCategory(String name, {int? id}) async {
    if (ProductInputRules.validateName(name) != null) {
      throw StateError(
        ProductInputRules.validateName(name) ?? 'Tên không hợp lệ.',
      );
    }
    final db = await _db;
    final duplicate = await db.query(
      'categories',
      columns: ['id'],
      where: 'LOWER(name) = LOWER(?) AND id != ?',
      whereArgs: [name.trim(), id ?? -1],
      limit: 1,
    );
    if (duplicate.isNotEmpty) throw StateError('Danh mục đã tồn tại.');
    if (id == null) return db.insert('categories', {'name': name.trim()});
    final changed = await db.update(
      'categories',
      {'name': name.trim()},
      where: 'id = ?',
      whereArgs: [id],
    );
    if (changed != 1) throw StateError('Danh mục không còn tồn tại.');
    return id;
  }

  Future<void> deleteCategoryIfEmpty(int id) async {
    final db = await _db;
    await db.transaction((txn) async {
      final rows = await txn.rawQuery(
        'SELECT COUNT(*) AS count FROM products WHERE categoryId = ?',
        [id],
      );
      if ((rows.first['count'] as num).toInt() > 0) {
        throw StateError('Danh mục còn sản phẩm, kể cả sản phẩm đã ẩn.');
      }
      await txn.delete('categories', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<int> saveTopping(String name, int price, {int? id}) async {
    final nameError = ProductInputRules.validateName(name);
    final priceError = ProductInputRules.validatePrice(price, allowZero: true);
    if (nameError != null || priceError != null) {
      throw StateError(nameError ?? priceError ?? 'Dữ liệu không hợp lệ.');
    }
    final db = await _db;
    final duplicate = await db.query(
      'toppings',
      columns: ['id'],
      where: 'LOWER(name) = LOWER(?) AND id != ?',
      whereArgs: [name.trim(), id ?? -1],
      limit: 1,
    );
    if (duplicate.isNotEmpty) throw StateError('Topping đã tồn tại.');
    final values = {'name': name.trim(), 'price': price};
    if (id == null) return db.insert('toppings', values);
    final changed = await db.update(
      'toppings',
      values,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (changed != 1) throw StateError('Topping không còn tồn tại.');
    return id;
  }

  Future<void> deleteTopping(int id) async {
    final db = await _db;
    await db.delete('toppings', where: 'id = ?', whereArgs: [id]);
    // Order snapshots stay immutable; old carts fail validation at checkout.
  }

  /// Checkout validation is repeated just before persisting an order, so a
  /// previously cached cart cannot purchase a now-hidden/sold-out product.
  Future<void> assertCartSellable(List<CartItem> items) async {
    if (items.isEmpty) throw StateError('Giỏ hàng đang trống.');
    await ensureSchema();
    final db = await _db;
    for (final item in items) {
      final id = item.product.id;
      final rows = await db.rawQuery(
        '''
        SELECT p.price, COALESCE(s.status, 'available') AS status
        FROM products p LEFT JOIN product_sale_status s ON p.id = s.productId
        WHERE p.id = ?
      ''',
        [id],
      );
      if (rows.isEmpty || rows.single['status'] != 'available') {
        throw StateError(
          'Một món trong giỏ đã hết hàng hoặc ngừng bán. Vui lòng chọn lại.',
        );
      }
      if ((rows.single['price'] as num).toInt() != item.product.price) {
        throw StateError(
          'Giá sản phẩm đã thay đổi. Vui lòng xóa món cũ và thêm lại.',
        );
      }
      for (final topping in item.toppings) {
        final top = await db.query(
          'toppings',
          columns: ['price'],
          where: 'name = ?',
          whereArgs: [topping.name],
          limit: 1,
        );
        if (top.isEmpty ||
            (top.single['price'] as num).toInt() != topping.price) {
          throw StateError(
            'Topping đã bị xóa, đổi tên hoặc đổi giá. Vui lòng chọn lại món.',
          );
        }
      }
    }
  }
}
