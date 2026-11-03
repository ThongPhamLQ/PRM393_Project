import 'package:flutter/material.dart';

import '../models/order.dart';
import '../utils/motion.dart';
import 'order_status_chip.dart';

// Thẻ "Đơn đang thực hiện" ở đầu Menu: khách thấy ngay đơn đang ở bước nào.
// Trạng thái đổi (chủ quán bấm chuyển bước trên máy khác) thì icon đổi có hiệu ứng
// và thanh tiến độ chạy dần tới bước mới.
class ActiveOrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback onTap;

  const ActiveOrderCard({super.key, required this.order, required this.onTap});

  // 5 bước từ "Chờ xác nhận" tới "Hoàn thành" -> bước thứ i đạt (i + 1) / 5
  static double progressOf(OrderStatus status) =>
      (OrderStatus.values.indexOf(status) + 1) / 5;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final status = order.status;
    final (:background, :foreground) = status.colors(colors);

    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              AnimatedSwitcher(
                duration: motionDuration(context),
                transitionBuilder: fadeScale,
                child: CircleAvatar(
                  key: ValueKey(status),
                  radius: 24,
                  backgroundColor: background,
                  foregroundColor: foreground,
                  child: Icon(status.icon),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ĐƠN ĐANG THỰC HIỆN',
                      style: textTheme.labelSmall?.copyWith(
                        color: colors.primary,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Đơn #${order.id} · ${status.label}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium,
                    ),
                    Text(
                      status.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall
                          ?.copyWith(color: colors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 10),
                    // Thanh tiến độ chạy dần từ giá trị cũ tới giá trị mới
                    TweenAnimationBuilder<double>(
                      tween: Tween(end: progressOf(status)),
                      duration: motionDuration(context, 400),
                      curve: motionCurve,
                      builder: (context, value, _) => LinearProgressIndicator(
                        value: value,
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(3),
                        semanticsLabel: 'Tiến độ đơn hàng',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
