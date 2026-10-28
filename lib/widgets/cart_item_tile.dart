import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/cart_item.dart';
import '../providers/cart_provider.dart';
import '../utils/format.dart';
import 'product_image.dart';
import 'quantity_stepper.dart';

// 1 dòng trong giỏ hàng: ảnh, tên, size, topping, giá, nút tăng/giảm số lượng
class CartItemTile extends StatelessWidget {
  final CartItem item;

  const CartItemTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    // read: chỉ gọi hàm, không cần lắng nghe thay đổi
    final cart = context.read<CartProvider>();
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final detailStyle =
        textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 76,
                height: 76,
                child: ProductImage(product: item.product, iconSize: 32),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                // stretch: Wrap bên dưới rộng hết hàng -> giá trái, nút phải
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(item.product.name, style: textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text('Size ${item.size}', style: detailStyle),
                  if (item.toppings.isNotEmpty)
                    Text('Topping: ${item.toppingNames}', style: detailStyle),
                  if (item.note.isNotEmpty)
                    Text(
                      'Ghi chú: ${item.note}',
                      style: detailStyle?.copyWith(fontStyle: FontStyle.italic),
                    ),
                  const SizedBox(height: 8),
                  // Wrap: màn hẹp / chữ to thì nút số lượng tự xuống dòng
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        formatVnd(item.totalPrice),
                        style: textTheme.titleMedium?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      QuantityStepper(
                        quantity: item.quantity,
                        // Giảm từ 1 -> xóa món khỏi giỏ (CartProvider)
                        onDecrease: () => cart.decreaseQuantity(item),
                        onIncrease: () => cart.increaseQuantity(item),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
