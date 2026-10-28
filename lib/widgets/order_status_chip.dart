import 'package:flutter/material.dart';
import '../models/order.dart';

// Icon + màu của từng trạng thái đơn (chỉ phục vụ giao diện, model giữ nguyên).
// Mỗi trạng thái là 1 cặp nền / chữ của ColorScheme -> tự đổi theo sáng/tối,
// chữ luôn dùng màu "on" đi kèm nền nên đủ tương phản. Bộ 6 cặp được chọn để
// khác nhau rõ ở cả 2 chế độ (ΔE ≥ 14); riêng ở chế độ sáng primaryContainer
// và secondaryContainer trùng màu, gần như errorContainer nên không dùng chung.
extension OrderStatusStyle on OrderStatus {
  IconData get icon {
    switch (this) {
      case OrderStatus.pending:
        return Icons.hourglass_top;
      case OrderStatus.confirmed:
        return Icons.thumb_up_alt_outlined;
      case OrderStatus.preparing:
        return Icons.coffee_maker_outlined;
      case OrderStatus.delivering:
        return Icons.delivery_dining;
      case OrderStatus.completed:
        return Icons.task_alt;
      case OrderStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }

  ({Color background, Color foreground}) colors(ColorScheme c) {
    switch (this) {
      case OrderStatus.pending:
        return (background: c.tertiaryContainer, foreground: c.onTertiaryContainer);
      case OrderStatus.confirmed:
        return (background: c.secondary, foreground: c.onSecondary);
      case OrderStatus.preparing:
        return (background: c.primaryFixedDim, foreground: c.onPrimaryFixed);
      case OrderStatus.delivering:
        return (background: c.tertiary, foreground: c.onTertiary);
      case OrderStatus.completed:
        return (background: c.inverseSurface, foreground: c.onInverseSurface);
      case OrderStatus.cancelled:
        return (background: c.errorContainer, foreground: c.onErrorContainer);
    }
  }
}

// Nhãn trạng thái đơn: icon + chữ trên nền màu của trạng thái
class OrderStatusChip extends StatelessWidget {
  final OrderStatus status;

  const OrderStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (:background, :foreground) =
        status.colors(Theme.of(context).colorScheme);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: ShapeDecoration(
        color: background,
        shape: const StadiumBorder(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 16, color: foreground),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
