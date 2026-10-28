import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/cart_item_tile.dart';
import '../../widgets/empty_view.dart';
import '../../widgets/max_width_box.dart';
import '../../widgets/total_bar.dart';
import 'checkout_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  Future<void> _confirmClear(BuildContext context) async {
    final cart = context.read<CartProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa giỏ hàng'),
        content: const Text('Bạn có muốn xóa tất cả món trong giỏ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Không'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed == true) cart.clear();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Giỏ hàng'),
        actions: [
          if (!cart.isEmpty)
            IconButton(
              tooltip: 'Xóa tất cả',
              icon: const Icon(Icons.delete_sweep),
              onPressed: () => _confirmClear(context),
            ),
        ],
      ),
      body: cart.isEmpty
          ? const EmptyView(
              icon: Icons.shopping_cart_outlined,
              message: 'Giỏ hàng trống.\nHãy chọn món bạn thích nhé!',
            )
          : MaxWidthBox(
              maxWidth: 720,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: cart.items.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = cart.items[index];
                  // Vuốt sang trái để xóa món
                  return Dismissible(
                    key: ValueKey(item.key),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 24),
                      decoration: BoxDecoration(
                        color: colors.errorContainer,
                        borderRadius: BorderRadius.circular(12), // = thẻ món
                      ),
                      child: Icon(Icons.delete, color: colors.onErrorContainer),
                    ),
                    onDismissed: (_) => cart.removeItem(item),
                    child: CartItemTile(item: item),
                  );
                },
              ),
            ),
      bottomNavigationBar: cart.isEmpty
          ? null
          : TotalBar(
              label: 'Tổng cộng (${cart.itemCount} ly)',
              amount: cart.totalPrice,
              button: FilledButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                ),
                child: const Text('Đặt hàng'),
              ),
            ),
    );
  }
}
