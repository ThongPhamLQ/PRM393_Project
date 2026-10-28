import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/cart_item.dart';
import '../providers/cart_provider.dart';
import '../utils/format.dart';
import 'product_image.dart';

// 1 dòng trong giỏ hàng: ảnh, tên, size, topping, nút tăng/giảm số lượng
class CartItemTile extends StatelessWidget {
  final CartItem item;

  const CartItemTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    // read: chỉ gọi hàm, không cần lắng nghe thay đổi
    final cart = context.read<CartProvider>();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 60,
                height: 60,
                child: ProductImage(product: item.product, iconSize: 28),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('Size ${item.size}'),
                  if (item.toppings.isNotEmpty)
                    Text(
                      'Topping: ${item.toppingNames}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  if (item.note.isNotEmpty)
                    Text(
                      'Ghi chú: ${item.note}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  Text(
                    formatVnd(item.totalPrice),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () => cart.decreaseQuantity(item),
            ),
            Text('${item.quantity}', style: const TextStyle(fontSize: 16)),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => cart.increaseQuantity(item),
            ),
          ],
        ),
      ),
    );
  }
}
