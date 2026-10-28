import 'package:flutter/material.dart';

import '../models/product.dart';

// Ảnh món: có imageUrl thì tải ảnh từ mạng, chưa có thì hiện icon theo danh mục
class ProductImage extends StatelessWidget {
  final Product product;
  final double iconSize;

  const ProductImage({super.key, required this.product, this.iconSize = 48});

  // Icon theo danh mục (id danh mục xem trong database_helper.dart)
  IconData get _icon {
    switch (product.categoryId) {
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

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final placeholder = Container(
      color: colors.primaryContainer,
      alignment: Alignment.center,
      child: Icon(_icon, size: iconSize, color: colors.onPrimaryContainer),
    );

    if (product.imageUrl.isEmpty) return placeholder;

    return Image.network(
      product.imageUrl,
      fit: BoxFit.cover,
      // Lỗi mạng / link hỏng -> hiện icon thay thế
      errorBuilder: (context, error, stackTrace) => placeholder,
    );
  }
}
