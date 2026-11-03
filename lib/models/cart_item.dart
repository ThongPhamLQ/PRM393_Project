import '../utils/constants.dart';
import 'order.dart';
import 'product.dart';

// 1 dòng trong giỏ hàng = 1 món + size + topping + mức đường/đá + số lượng
class CartItem {
  final Product product;
  final String size; // 'S', 'M', 'L'
  final List<Topping> toppings;
  final String sugar; // mức đường: '100%', '70%'... (xem sugarLevels)
  final String ice; // mức đá: 'Bình thường', 'Ít đá', 'Không đá'
  final String note; // ghi chú thêm: thêm sữa, ống hút giấy...
  int quantity;

  CartItem({
    required this.product,
    required this.size,
    required this.toppings,
    this.sugar = defaultSugar,
    this.ice = defaultIce,
    this.note = '',
    this.quantity = 1,
  });

  // Giá 1 ly = giá gốc + giá size + tổng giá topping
  int get unitPrice {
    final toppingPrice = toppings.fold(0, (sum, t) => sum + t.price);
    return product.price + sizePrices[size]! + toppingPrice;
  }

  // Thành tiền của dòng này
  int get totalPrice => unitPrice * quantity;

  // Tên các topping, ví dụ: "Trân châu đen, Pudding"
  String get toppingNames => toppings.map((t) => t.name).join(', ');

  // Khóa để nhận biết 2 món giống hệt nhau (cùng món, size, topping, đường, đá,
  // ghi chú) -> thêm lần nữa thì chỉ tăng số lượng, không tạo dòng mới
  String get key {
    final toppingIds = toppings.map((t) => t.id).toList()..sort();
    return '${product.id}_${size}_${toppingIds.join(',')}_${sugar}_${ice}_$note';
  }
}

// "Đặt lại": dựng lại các dòng giỏ hàng từ món của đơn cũ theo menu HIỆN TẠI
// (giá mới; món đã ngừng bán hoặc đơn cũ chưa lưu mã món thì bỏ qua).
// Trả về record của Dart 3: các dòng thêm được + số món bị bỏ qua.
({List<CartItem> items, int skipped}) cartItemsFromOrder(
  List<OrderItem> orderItems,
  List<Product> products,
  List<Topping> toppings,
) {
  final items = <CartItem>[];
  var skipped = 0;
  for (final o in orderItems) {
    final product = products.where((p) => p.id == o.productId).firstOrNull;
    if (product == null) {
      skipped++;
      continue;
    }
    // Đơn lưu tên topping dạng "Trân châu đen, Pudding" -> khớp lại theo tên
    final names = o.toppings.split(', ').toSet();
    items.add(
      CartItem(
        product: product,
        size: sizePrices.containsKey(o.size) ? o.size : sizePrices.keys.first,
        toppings: toppings.where((t) => names.contains(t.name)).toList(),
        sugar: sugarLevels.contains(o.sugar) ? o.sugar : defaultSugar,
        ice: iceLevels.contains(o.ice) ? o.ice : defaultIce,
        note: o.note,
        quantity: o.quantity,
      ),
    );
  }
  return (items: items, skipped: skipped);
}
