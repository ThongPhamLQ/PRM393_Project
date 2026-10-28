import 'package:flutter/material.dart';
import '../models/product.dart';

// Icon theo danh mục (id danh mục xem trong database_helper.dart).
// Dùng cho ảnh thay thế và chip danh mục ở màn Menu.
IconData categoryIcon(int categoryId) {
  switch (categoryId) {
    case 1:
      return Icons.coffee;
    case 2:
      return Icons.emoji_food_beverage;
    case 3:
      return Icons.local_drink;
    default:
      return Icons.icecream;
  }
}

// Ảnh món: 'assets/...' -> ảnh có sẵn trong app, 'http...' -> ảnh trên mạng,
// để trống / thiếu file / lỗi tải -> icon theo danh mục
class ProductImage extends StatelessWidget {
  final Product product;
  final double iconSize;

  const ProductImage({super.key, required this.product, this.iconSize = 48});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final placeholder = Container(
      color: colors.primaryContainer,
      alignment: Alignment.center,
      child: Icon(
        categoryIcon(product.categoryId),
        size: iconSize,
        color: colors.onPrimaryContainer,
      ),
    );
    // Thiếu file / link hỏng -> hiện icon thay thế
    Widget onError(BuildContext context, Object error, StackTrace? stack) =>
        placeholder;

    final url = product.imageUrl;
    if (url.startsWith('http')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        excludeFromSemantics: true, // tên món đã có chữ bên cạnh
        errorBuilder: onError,
      );
    }
    if (!url.startsWith('assets/')) return placeholder;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Giải mã ảnh gốc 800px theo đúng cỡ đang hiển thị -> tốn ít RAM hơn
        // (Module 12 - Demo 12.2). Ảnh vuông + BoxFit.cover nên lấy cạnh dài.
        final side = constraints.biggest.longestSide;
        return Image.asset(
          url,
          fit: BoxFit.cover,
          cacheWidth: side.isFinite && side > 0
              ? (side * MediaQuery.devicePixelRatioOf(context)).ceil()
              : null,
          excludeFromSemantics: true,
          errorBuilder: onError,
        );
      },
    );
  }
}
