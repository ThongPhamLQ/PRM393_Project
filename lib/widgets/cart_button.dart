import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../screens/customer/cart_screen.dart';

// Icon giỏ hàng trên AppBar, có số lượng món (Badge).
// Dùng Selector: chỉ vẽ lại khi số lượng thay đổi (Module 12 - tối ưu rebuild)
class CartButton extends StatelessWidget {
  const CartButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<CartProvider, int>(
      selector: (context, cart) => cart.itemCount,
      builder: (context, count, child) {
        return IconButton(
          tooltip: 'Giỏ hàng',
          icon: Badge(
            isLabelVisible: count > 0,
            label: Text('$count'),
            child: const Icon(Icons.shopping_cart),
          ),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CartScreen()),
          ),
        );
      },
    );
  }
}
