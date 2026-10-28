import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/cart_item.dart';
import '../../models/product.dart';
import '../../providers/cart_provider.dart';
import '../../providers/menu_provider.dart';
import '../../utils/constants.dart';
import '../../utils/format.dart';
import '../../widgets/cart_button.dart';
import '../../widgets/product_image.dart';

// Chi tiết món: chọn size, topping, ghi chú, số lượng rồi thêm vào giỏ
class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  String _size = 'S';
  final Set<Topping> _selectedToppings = {}; // Set: mỗi topping chỉ chọn 1 lần
  int _quantity = 1;
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  // Tạo CartItem từ lựa chọn hiện tại -> dùng chung công thức tính giá với giỏ hàng
  CartItem _buildCartItem() {
    return CartItem(
      product: widget.product,
      size: _size,
      toppings: _selectedToppings.toList(),
      note: _noteController.text.trim(),
      quantity: _quantity,
    );
  }

  void _addToCart() {
    context.read<CartProvider>().addItem(_buildCartItem());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã thêm ${widget.product.name} vào giỏ'),
        duration: const Duration(seconds: 1),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final toppings = context.watch<MenuProvider>().toppings;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(product.name), actions: const [CartButton()]),
      body: ListView(
        children: [
          SizedBox(
            height: 220,
            width: double.infinity,
            child: ProductImage(product: product, iconSize: 100),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  product.description,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  formatVnd(product.price),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colors.primary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(),

          // ===== Chọn size: chỉ chọn 1 -> Radio =====
          _buildSectionTitle('Chọn size'),
          // RadioGroup: cách mới (Flutter 3.32+) để quản lý nhóm Radio,
          // thay cho groupValue/onChanged đặt trên từng RadioListTile
          RadioGroup<String>(
            groupValue: _size,
            onChanged: (value) => setState(() => _size = value!),
            child: Column(
              children: sizePrices.entries.map((entry) {
                return RadioListTile<String>(
                  value: entry.key,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text('Size ${entry.key}'),
                  secondary: Text(
                    entry.value == 0
                        ? 'Mặc định'
                        : '+${formatVnd(entry.value)}',
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(),

          // ===== Chọn topping: chọn nhiều -> Checkbox =====
          _buildSectionTitle('Topping'),
          ...toppings.map((topping) {
            return CheckboxListTile(
              value: _selectedToppings.contains(topping),
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(topping.name),
              secondary: Text('+${formatVnd(topping.price)}'),
              onChanged: (checked) {
                setState(() {
                  if (checked == true) {
                    _selectedToppings.add(topping);
                  } else {
                    _selectedToppings.remove(topping);
                  }
                });
              },
            );
          }),
          const Divider(),

          // ===== Ghi chú =====
          _buildSectionTitle('Ghi chú'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                hintText: 'VD: ít đá, ít ngọt...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ===== Số lượng =====
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filledTonal(
                icon: const Icon(Icons.remove),
                // Số lượng tối thiểu là 1 -> null để khóa nút
                onPressed: _quantity > 1
                    ? () => setState(() => _quantity--)
                    : null,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text('$_quantity', style: const TextStyle(fontSize: 20)),
              ),
              IconButton.filledTonal(
                icon: const Icon(Icons.add),
                onPressed: () => setState(() => _quantity++),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),

      // Nút thêm vào giỏ luôn nằm dưới cùng, hiện tổng tiền theo lựa chọn
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 50,
            child: FilledButton.icon(
              icon: const Icon(Icons.add_shopping_cart),
              label: Text(
                'Thêm vào giỏ - ${formatVnd(_buildCartItem().totalPrice)}',
              ),
              onPressed: _addToCart,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}
