import 'package:flutter/material.dart';
import '../models/product.dart';
import '../utils/format.dart';
import 'product_image.dart';

// Thẻ món trong lưới menu: ảnh vuông tràn mép trên, tên + mô tả + giá ở dưới.
// Chiều cao thẻ do màn Menu tính: ảnh vuông + 116px phần chữ (nhân cỡ chữ của máy).
// Đổi lề / cỡ chữ phần dưới thì phải sửa số 116 ở menu_screen.dart.
class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const ProductCard({super.key, required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Card đã cắt bo góc 12 -> ảnh tràn mép trên
            AspectRatio(
              aspectRatio: 1,
              child: ProductImage(product: product),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      product.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall
                          ?.copyWith(color: colors.onSurfaceVariant),
                    ),
                    const Spacer(), // giá luôn nằm đáy thẻ -> các thẻ thẳng hàng
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            formatVnd(product.price),
                            style: textTheme.titleMedium?.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        // Chỉ để trang trí: bấm cả thẻ mới mở chi tiết món
                        ExcludeSemantics(
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: colors.primary,
                            foregroundColor: colors.onPrimary,
                            child: const Icon(Icons.add, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
