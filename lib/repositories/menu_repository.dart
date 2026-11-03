import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/firestore_db.dart';
import '../models/product.dart';
import 'product_management_repository.dart';

// Đọc menu: danh mục, món, topping.
// Dùng snapshots() (Stream): chủ quán sửa giá / báo hết món trên máy khác thì
// menu của khách tự cập nhật, không cần tải lại.
class MenuRepository {
  MenuRepository({FirebaseFirestore? db}) : _dbOverride = db;
  final FirebaseFirestore? _dbOverride;
  FirebaseFirestore get _db => _dbOverride ?? FirebaseFirestore.instance;

  Stream<List<MenuCategory>> watchCategories() {
    return _db.collection(Collections.categories).snapshots().map(
          (snap) => snap.docs.map((d) => MenuCategory.fromMap(d.data())).toList()
            ..sort((a, b) => a.id.compareTo(b.id)),
        );
  }

  // Chỉ lấy món đang bán (món hết hàng / ngừng bán / đã xóa có status khác)
  Stream<List<Product>> watchProducts() {
    return _db
        .collection(Collections.products)
        .where('status', isEqualTo: ProductSaleStatus.available.name)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => Product.fromMap(d.data())).toList()
            ..sort(
              (a, b) => a.categoryId != b.categoryId
                  ? a.categoryId.compareTo(b.categoryId)
                  : a.id.compareTo(b.id),
            ),
        );
  }

  Stream<List<Topping>> watchToppings() {
    return _db.collection(Collections.toppings).snapshots().map(
          (snap) => snap.docs.map((d) => Topping.fromMap(d.data())).toList()
            ..sort((a, b) => a.id.compareTo(b.id)),
        );
  }
}
