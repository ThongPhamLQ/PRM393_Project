import '../data/database_helper.dart';
import '../models/product.dart';
import 'product_management_repository.dart';

// Đọc menu: danh mục, món, topping
class MenuRepository {
  final _dbHelper = DatabaseHelper.instance;

  Future<List<MenuCategory>> getCategories() async {
    final db = await _dbHelper.database;
    final rows = await db.query('categories', orderBy: 'id');
    return rows.map((row) => MenuCategory.fromMap(row)).toList();
  }

  Future<List<Product>> getProducts() async {
    await ProductManagementRepository().ensureSchema();
    final db = await _dbHelper.database;
    final rows = await db.query(
      'products',
      where: "id NOT IN (SELECT productId FROM product_sale_status WHERE status != 'available')",
      orderBy: 'categoryId, id',
    );
    return rows.map((row) => Product.fromMap(row)).toList();
  }

  Future<List<Topping>> getToppings() async {
    final db = await _dbHelper.database;
    final rows = await db.query('toppings', orderBy: 'id');
    return rows.map((row) => Topping.fromMap(row)).toList();
  }
}
