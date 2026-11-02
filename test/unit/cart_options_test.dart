// UNIT TEST: mức đường / đá trong giỏ hàng, đọc đơn cũ và "Đặt lại"
import 'package:flutter_test/flutter_test.dart';
import 'package:shop_app/models/cart_item.dart';
import 'package:shop_app/models/order.dart';
import 'package:shop_app/models/product.dart';
import 'package:shop_app/providers/cart_provider.dart';
import 'package:shop_app/utils/format.dart';

void main() {
  final traSua = Product(
    id: 1,
    categoryId: 2,
    name: 'Trà sữa truyền thống',
    description: '',
    price: 35000,
  );
  final caPhe = Product(
    id: 2,
    categoryId: 1,
    name: 'Cà phê sữa đá',
    description: '',
    price: 29000,
  );
  final tranChau = Topping(id: 1, name: 'Trân châu đen', price: 5000);
  final pudding = Topping(id: 2, name: 'Pudding trứng', price: 8000);

  group('Mức đường / đá', () {
    test('cùng món nhưng khác mức đường -> 2 dòng riêng trong giỏ', () {
      final cart = CartProvider();
      cart.addItem(CartItem(product: traSua, size: 'M', toppings: []));
      cart.addItem(
        CartItem(product: traSua, size: 'M', toppings: [], sugar: '50%'),
      );
      cart.addItem(CartItem(product: traSua, size: 'M', toppings: []));

      expect(cart.items, hasLength(2));
      expect(cart.itemCount, 3);
    });

    test('mức đường / đá không đổi giá', () {
      final normal = CartItem(product: traSua, size: 'S', toppings: []);
      final custom = CartItem(
        product: traSua,
        size: 'S',
        toppings: [],
        sugar: '30%',
        ice: 'Không đá',
      );
      expect(custom.unitPrice, normal.unitPrice);
    });

    test('chỉ hiện phần khác mặc định', () {
      expect(formatSugarIce('100%', 'Bình thường'), '');
      expect(formatSugarIce('70%', 'Ít đá'), 'Đường 70% · Ít đá');
      expect(formatSugarIce('', ''), ''); // đơn cũ chưa có
    });

    test('món của đơn cũ (chưa có productId / đường / đá) vẫn đọc được', () {
      final old = OrderItem.fromMap({
        'productName': 'Trà sữa truyền thống',
        'size': 'M',
        'toppings': 'Trân châu đen',
        'quantity': 2,
        'unitPrice': 46000,
      });
      expect(old.productId, isNull);
      expect(old.sugar, '');
      expect(old.ice, '');
      // Ghi lại không có productId thì không tạo field rỗng
      expect(old.toMap().containsKey('productId'), isFalse);
    });
  });

  group('Đặt lại từ đơn cũ', () {
    test('món còn bán: giữ size, topping (khớp theo tên), đường, đá', () {
      final result = cartItemsFromOrder(
        [
          OrderItem(
            productId: 1,
            productName: 'Trà sữa truyền thống',
            size: 'L',
            toppings: 'Trân châu đen, Pudding trứng',
            sugar: '50%',
            ice: 'Ít đá',
            quantity: 2,
            unitPrice: 58000,
          ),
        ],
        [traSua, caPhe],
        [tranChau, pudding],
      );

      expect(result.skipped, 0);
      final item = result.items.single;
      expect(item.product.id, 1);
      expect(item.size, 'L');
      expect(item.toppings.map((t) => t.id), [1, 2]);
      expect(item.sugar, '50%');
      expect(item.ice, 'Ít đá');
      expect(item.quantity, 2);
      // Giá tính lại theo menu hiện tại: 35.000 + 10.000 (L) + 5.000 + 8.000
      expect(item.unitPrice, 58000);
    });

    test('món ngừng bán hoặc đơn cũ thiếu mã món -> bỏ qua và đếm lại', () {
      final result = cartItemsFromOrder(
        [
          OrderItem(
            productId: 99, // không còn trong menu
            productName: 'Món cũ',
            size: 'S',
            toppings: '',
            quantity: 1,
            unitPrice: 20000,
          ),
          OrderItem(
            productName: 'Cà phê sữa đá', // đơn cũ: không có productId
            size: 'S',
            toppings: '',
            quantity: 1,
            unitPrice: 29000,
          ),
          OrderItem(
            productId: 2,
            productName: 'Cà phê sữa đá',
            size: 'S',
            toppings: 'Topping đã xóa',
            quantity: 1,
            unitPrice: 29000,
          ),
        ],
        [traSua, caPhe],
        [tranChau],
      );

      expect(result.skipped, 2);
      expect(result.items.single.product.id, 2);
      expect(result.items.single.toppings, isEmpty); // topping đã xóa thì bỏ
      expect(result.items.single.sugar, '100%'); // rỗng -> mặc định
    });
  });
}
