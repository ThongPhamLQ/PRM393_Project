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
    final title = showCustomerName
        ? 'Đơn #${order.id} - ${order.customerName}'
        : 'Đơn #${order.id}';

    return Card(
      child: ListTile(
        onTap: onTap,
        leading: const CircleAvatar(child: Icon(Icons.receipt_long)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          '${formatDateTime(order.createdAt)}\n${formatVnd(order.totalPrice)}',
        ),
        isThreeLine: true,
        trailing: OrderStatusChip(status: order.status),
      ),
    );
  }
}
