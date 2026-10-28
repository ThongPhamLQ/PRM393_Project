import 'package:flutter/material.dart';

import '../models/order.dart';
import '../utils/format.dart';
import 'order_status_chip.dart';

// Thẻ đơn hàng trong danh sách (dùng chung cho khách và chủ quán)
class OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback onTap;
  final bool showCustomerName; // chủ quán cần biết đơn của ai

  const OrderCard({
    super.key,
    required this.order,
    required this.onTap,
    this.showCustomerName = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final (:background, :foreground) = order.status.colors(colors);
    final title = showCustomerName
        ? 'Đơn #${order.id} - ${order.customerName}'
        : 'Đơn #${order.id}';

    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon trạng thái: lướt danh sách là thấy đơn nào đang ở bước nào
              CircleAvatar(
                radius: 24,
                backgroundColor: background,
                foregroundColor: foreground,
                child: Icon(order.status.icon),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatDateTime(order.createdAt),
                      style: textTheme.bodySmall
                          ?.copyWith(color: colors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        OrderStatusChip(status: order.status),
                        Text(
                          formatVnd(order.totalPrice),
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
