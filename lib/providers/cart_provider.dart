import 'package:flutter/foundation.dart';

import '../models/cart_item.dart';

// Giỏ hàng (chỉ lưu trong bộ nhớ, đặt hàng xong thì xóa)
class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  // Trả về list chỉ đọc -> bên ngoài muốn sửa phải gọi hàm của Provider
  List<CartItem> get items => List.unmodifiable(_items);

  bool get isEmpty => _items.isEmpty;

  // Tổng số ly (hiển thị trên icon giỏ hàng)
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  // Tổng tiền cả giỏ
  int get totalPrice => _items.fold(0, (sum, item) => sum + item.totalPrice);

  // Thêm món: nếu đã có món y hệt (cùng size, topping, ghi chú) thì cộng dồn số lượng
  void addItem(CartItem newItem) {
    final index = _items.indexWhere((item) => item.key == newItem.key);
    if (index >= 0) {
      _items[index].quantity += newItem.quantity;
    } else {
      _items.add(newItem);
    }
    notifyListeners();
  }

  void increaseQuantity(CartItem item) {
    item.quantity++;
    notifyListeners();
  }

  // Giảm về 0 thì xóa khỏi giỏ
  void decreaseQuantity(CartItem item) {
    if (item.quantity > 1) {
      item.quantity--;
    } else {
      _items.remove(item);
    }
    notifyListeners();
  }

  void removeItem(CartItem item) {
    _items.remove(item);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
