// Danh mục món: Cà phê, Trà sữa, ...
// (Đặt tên MenuCategory để không trùng với class Category có sẵn của Flutter)
class MenuCategory {
  final int id;
  final String name;

  MenuCategory({required this.id, required this.name});

  factory MenuCategory.fromMap(Map<String, dynamic> map) {
    return MenuCategory(id: map['id'] as int, name: map['name'] as String);
  }
}

// Món đồ uống
class Product {
  final int id;
  final int categoryId;
  final String name;
  final String description;
  final int price; // giá size S (VND)
  final String imageUrl; // để trống thì hiển thị icon

  Product({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.price,
    this.imageUrl = '',
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int,
      categoryId: map['categoryId'] as int,
      name: map['name'] as String,
      description: map['description'] as String,
      price: map['price'] as int,
      imageUrl: (map['imageUrl'] as String?) ?? '',
    );
  }
}

// Topping thêm vào món: trân châu, pudding, ...
class Topping {
  final int id;
  final String name;
  final int price;

  Topping({required this.id, required this.name, required this.price});

  factory Topping.fromMap(Map<String, dynamic> map) {
    return Topping(
      id: map['id'] as int,
      name: map['name'] as String,
      price: map['price'] as int,
    );
  }
}
