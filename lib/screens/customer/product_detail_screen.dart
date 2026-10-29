import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/cart_item.dart';
import '../../models/product.dart';
import '../../providers/cart_provider.dart';
import '../../providers/menu_provider.dart';
import '../../utils/constants.dart';
import '../../utils/format.dart';
import '../../widgets/brand_block.dart';
import '../../widgets/cart_button.dart';
import '../../widgets/max_width_box.dart';
import '../../widgets/product_image.dart';
import '../../widgets/quantity_stepper.dart';
import '../../widgets/section_card.dart';
import '../../widgets/total_bar.dart';

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
  // RawRadio cần FocusNode: chọn size được bằng bàn phím (Chrome)
  final _sizeFocusNodes = [for (final _ in sizePrices.keys) FocusNode()];

  @override
  void dispose() {
    _noteController.dispose();
    for (final node in _sizeFocusNodes) {
      node.dispose();
    }
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
    final textTheme = Theme.of(context).textTheme;
    final priceStyle =
        textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant);

    final image = ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: ProductImage(product: product, iconSize: 100),
    );

    // Chữ trên khối nâu: tên in hoa, mô tả, giá (textTheme của màn -> tự đặt màu sáng)
    final details = <Widget>[
      const SizedBox(height: 16),
      Text(
        product.name.toUpperCase(),
        style: textTheme.headlineSmall?.copyWith(
          color: colors.primaryFixed,
          letterSpacing: 0.5,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        product.description,
        style: textTheme.bodyLarge?.copyWith(color: colors.primaryFixedDim),
      ),
      const SizedBox(height: 8),
      Text(
        formatVnd(product.price),
        style: textTheme.titleLarge?.copyWith(color: colors.primaryFixed),
      ),
    ];

    final options = <Widget>[
      // ===== Chọn size: chỉ chọn 1 -> RadioGroup, mỗi size là 1 hình ly =====
      SectionCard(
        title: 'Chọn size',
        // RadioGroup: cách mới (Flutter 3.32+) để quản lý nhóm Radio,
        // thay cho groupValue/onChanged đặt trên từng Radio
        child: RadioGroup<String>(
          groupValue: _size,
          onChanged: (value) => setState(() => _size = value!),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
            child: Row(
              children: [
                for (final (i, entry) in sizePrices.entries.indexed)
                  Expanded(
                    child: _SizeOption(
                      size: entry.key,
                      extraPrice: entry.value,
                      cupSize: 22.0 + i * 6, // ly to dần theo size
                      focusNode: _sizeFocusNodes[i],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: 12),

      // ===== Chọn topping: chọn nhiều -> Checkbox =====
      SectionCard(
        title: 'Topping',
        child: Column(
          children: toppings.map((topping) {
            return CheckboxListTile(
              value: _selectedToppings.contains(topping),
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(topping.name),
              secondary:
                  Text('+${formatVnd(topping.price)}', style: priceStyle),
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
          }).toList(),
        ),
      ),
      const SizedBox(height: 12),

      // ===== Ghi chú =====
      SectionCard(
        title: 'Ghi chú',
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: TextField(
            controller: _noteController,
            decoration: const InputDecoration(
              hintText: 'VD: ít đá, ít ngọt...',
              prefixIcon: Icon(Icons.edit_note),
            ),
          ),
        ),
      ),
      const SizedBox(height: 12),

      // ===== Số lượng =====
      Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          child: Row(
            children: [
              const Expanded(child: SectionHeader('Số lượng')),
              QuantityStepper(
                quantity: _quantity,
                // Số lượng tối thiểu là 1 -> null để khóa nút
                onDecrease:
                    _quantity > 1 ? () => setState(() => _quantity--) : null,
                onIncrease: () => setState(() => _quantity++),
              ),
            ],
          ),
        ),
      ),
    ];

    return Scaffold(
      // AppBar cùng màu khối nâu bên dưới -> phần đầu liền một mảng
      appBar: AppBar(
        backgroundColor: colors.onPrimaryFixedVariant,
        foregroundColor: colors.primaryFixed,
        title: Text(product.name),
        actions: const [CartButton()],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Màn rộng: cột trái là khối nâu (ảnh + tên + giá), cột phải là lựa chọn
          if (constraints.maxWidth >= 840) {
            return MaxWidthBox(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: BrandBlock(
                      child: ListView(
                        padding: const EdgeInsets.all(24),
                        children: [
                          AspectRatio(aspectRatio: 1, child: image),
                          ...details,
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(24),
                      children: options,
                    ),
                  ),
                ],
              ),
            );
          }
          // Màn hẹp: khối nâu tràn ngang (ảnh + tên + giá), lựa chọn bên dưới
          return ListView(
            children: [
              BrandBlock(
                child: MaxWidthBox(
                  maxWidth: 640,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: 280, child: image),
                        ...details,
                      ],
                    ),
                  ),
                ),
              ),
              MaxWidthBox(
                maxWidth: 640,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: options,
                  ),
                ),
              ),
            ],
          );
        },
      ),

      // Nút thêm vào giỏ luôn nằm dưới cùng, hiện tổng tiền theo lựa chọn
      bottomNavigationBar: TotalBar(
        label: 'Thành tiền',
        amount: _buildCartItem().totalPrice,
        button: FilledButton.icon(
          icon: const Icon(Icons.add_shopping_cart),
          label: const Text('Thêm vào giỏ'),
          onPressed: _addToCart,
        ),
      ),
    );
  }
}

// 1 lựa chọn size: hình ly trong vòng tròn, size đang chọn có viền đậm + nền.
// RawRadio lo phần chọn (qua RadioGroup bên ngoài), bàn phím và trợ năng;
// MergeSemantics gộp chữ "Size M, +6.000 ₫" vào cùng nút radio cho TalkBack.
class _SizeOption extends StatelessWidget {
  final String size;
  final int extraPrice;
  final double cupSize;
  final FocusNode focusNode;

  const _SizeOption({
    required this.size,
    required this.extraPrice,
    required this.cupSize,
    required this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return MergeSemantics(
      child: RawRadio<String>(
        value: size,
        groupRegistry: RadioGroup.maybeOf<String>(context),
        enabled: true,
        toggleable: false,
        autofocus: false,
        focusNode: focusNode,
        mouseCursor:
            const WidgetStatePropertyAll<MouseCursor>(SystemMouseCursors.click),
        builder: (context, state) {
          final selected = state.value ?? false;
          // Viền: đang chọn -> primary; đang focus bằng bàn phím -> onSurface
          final ringColor = selected
              ? colors.primary
              : state.states.contains(WidgetState.focused)
                  ? colors.onSurface
                  : colors.outlineVariant;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                ExcludeSemantics(
                  child: Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected ? colors.primaryContainer : null,
                      border: Border.all(color: ringColor, width: 2),
                    ),
                    child: Icon(
                      Icons.local_cafe,
                      size: cupSize,
                      color: selected
                          ? colors.onPrimaryContainer
                          : colors.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Size $size',
                  style: textTheme.titleSmall?.copyWith(
                    color: selected ? colors.primary : colors.onSurface,
                  ),
                ),
                Text(
                  extraPrice == 0 ? 'Mặc định' : '+${formatVnd(extraPrice)}',
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall
                      ?.copyWith(color: colors.onSurfaceVariant),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
