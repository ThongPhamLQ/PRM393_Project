import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order.dart';
import '../../providers/order_provider.dart';
import '../../utils/format.dart';
import '../../utils/motion.dart';
import '../../widgets/max_width_box.dart';
import '../shared/order_detail_screen.dart';

// Màn "Đặt hàng thành công" (thay hộp thoại OK cũ): có mã đơn, tổng tiền
// và nút "Theo dõi đơn" mở thẳng chi tiết đơn vừa đặt.
class OrderSuccessScreen extends StatefulWidget {
  final int orderId;
  final int total;
  final PaymentMethod paymentMethod;

  const OrderSuccessScreen({
    super.key,
    required this.orderId,
    required this.total,
    required this.paymentMethod,
  });

  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen> {
  bool _opening = false; // đang tìm đơn để mở -> khóa nút, hiện vòng xoay

  Future<void> _trackOrder() async {
    if (_opening) return;
    setState(() => _opening = true);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    Order? order;
    try {
      order = await context.read<OrderProvider>().findOrder(widget.orderId);
    } catch (e) {
      debugPrint('Find order #${widget.orderId} failed: $e');
    }
    if (!mounted) return;
    setState(() => _opening = false);
    if (order == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Chưa mở được đơn. Bạn xem ở tab "Đơn hàng" nhé.'),
        ),
      );
      return;
    }
    // pushReplacement: từ chi tiết đơn bấm quay lại là về Menu, không về màn này
    final found = order;
    navigator.pushReplacement(
      MaterialPageRoute(builder: (_) => OrderDetailScreen(order: found)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: MaxWidthBox(
              maxWidth: 480,
              child: Column(
                children: [
                  // Dấu tích phóng nhẹ từ 0.6 lên 1 và hiện dần (1 lần khi mở màn)
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: motionDuration(context, 250),
                    curve: motionCurve,
                    builder: (context, t, child) => Opacity(
                      opacity: t,
                      child: Transform.scale(scale: 0.6 + 0.4 * t, child: child),
                    ),
                    child: CircleAvatar(
                      radius: 48,
                      backgroundColor: colors.primaryContainer,
                      foregroundColor: colors.onPrimaryContainer,
                      child: const Icon(Icons.check_rounded, size: 56),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Semantics(
                    header: true,
                    child: Text(
                      'Đặt hàng thành công!',
                      textAlign: TextAlign.center,
                      style: textTheme.headlineSmall,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Mã đơn #${widget.orderId}',
                    style: textTheme.titleMedium?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.receipt_long_outlined),
                          title: const Text('Tổng thanh toán'),
                          trailing: Text(
                            formatVnd(widget.total),
                            style: textTheme.titleMedium?.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        ListTile(
                          leading: const Icon(Icons.payment),
                          title: Text(widget.paymentMethod.label),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Quán sẽ xác nhận đơn trong ít phút. '
                    'Mỗi lần đơn đổi trạng thái, bạn sẽ nhận được thông báo.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium
                        ?.copyWith(color: colors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _opening ? null : _trackOrder,
                      icon: _opening
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.delivery_dining),
                      label: const Text('Theo dõi đơn'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Tiếp tục chọn món'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
