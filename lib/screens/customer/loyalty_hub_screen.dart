import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/loyalty.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/loyalty_provider.dart';
import '../../utils/format.dart';
import '../../utils/favorite_toggle.dart';
import '../../widgets/max_width_box.dart';
import '../../widgets/product_image.dart';
import 'product_detail_screen.dart';

class LoyaltyHubScreen extends StatelessWidget {
  const LoyaltyHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loyalty = context.watch<LoyaltyProvider>();
    final favorites = context.watch<FavoriteProvider>();
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Khách hàng thân thiết')),
      body: MaxWidthBox(
        maxWidth: 720,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: colors.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('SỐ DƯ ĐIỂM'),
                    Text(
                      '${loyalty.account.balance}',
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    Text('Đã tích lũy ${loyalty.account.lifetimeEarned} điểm'),
                    const SizedBox(height: 8),
                    const Text(
                      '10.000đ = 1 điểm · 1 điểm giảm 1.000đ · tối đa 20% đơn',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Món yêu thích',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (favorites.favoriteProducts.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text('Bạn chưa lưu món yêu thích nào.'),
              ),
            ...favorites.favoriteProducts.map((product) {
              final available = product.status == 'available';
              final status = switch (product.status) {
                'soldOut' => 'Hết hàng',
                'hidden' => 'Ngừng bán',
                _ => 'Đang bán',
              };
              return Card(
                child: ListTile(
                  leading: SizedBox(
                    width: 52,
                    height: 52,
                    child: ProductImage(product: product, iconSize: 24),
                  ),
                  title: Text(product.name),
                  subtitle: Text('$status · ${formatVnd(product.price)}'),
                  trailing: IconButton(
                    tooltip: 'Bỏ yêu thích',
                    onPressed: () => toggleFavorite(context, product.id),
                    icon: const Icon(Icons.favorite),
                  ),
                  onTap: available
                      ? () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ProductDetailScreen(product: product),
                          ),
                        )
                      : null,
                ),
              );
            }),
            const SizedBox(height: 20),
            Text('Lịch sử điểm', style: Theme.of(context).textTheme.titleLarge),
            if (loyalty.transactions.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text('Chưa có giao dịch điểm.'),
              ),
            ...loyalty.transactions.map((entry) {
              final positive = entry.type != LoyaltyTransactionType.redeem;
              final label = switch (entry.type) {
                LoyaltyTransactionType.earn => 'Tích điểm',
                LoyaltyTransactionType.redeem => 'Dùng điểm',
                LoyaltyTransactionType.refund => 'Hoàn điểm',
              };
              return ListTile(
                leading: Icon(
                  positive
                      ? Icons.add_circle_outline
                      : Icons.remove_circle_outline,
                ),
                title: Text('$label · Đơn #${entry.orderId}'),
                subtitle: Text(formatDateTime(entry.createdAt)),
                trailing: Text('${positive ? '+' : '-'}${entry.points}'),
              );
            }),
          ],
        ),
      ),
    );
  }
}
