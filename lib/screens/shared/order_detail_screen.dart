import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/order.dart';
import '../../providers/order_provider.dart';
import '../../utils/format.dart';
import '../../widgets/max_width_box.dart';
import '../../widgets/order_status_chip.dart';
import '../../widgets/section_card.dart';

// Chi tiết đơn hàng (dùng chung):
// - Khách hàng: xem trạng thái, được hủy khi đơn còn "Chờ xác nhận"
// - Chủ quán (isAdmin = true): chuyển đơn sang trạng thái tiếp theo
class OrderDetailScreen extends StatefulWidget {
  final Order order;
  final bool isAdmin;

  const OrderDetailScreen({super.key, required this.order, this.isAdmin = false});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late Order _order;
  late final Future<List<OrderItem>> _itemsFuture;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    // Tạo Future 1 lần ở initState, KHÔNG gọi trong build (Module 8)
    _itemsFuture = context.read<OrderProvider>().getOrderItems(_order.id!);
  }

  Future<void> _changeStatus(OrderStatus newStatus) async {
    setState(() => _isUpdating = true);
    await context.read<OrderProvider>().updateStatus(_order, newStatus);
    if (!mounted) return;

    setState(() {
      _order = _order.copyWith(status: newStatus);
      _isUpdating = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đơn #${_order.id}: ${newStatus.label}')),
    );
  }

  Future<void> _confirmCancel() async {
    final colors = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hủy đơn hàng'),
        content: Text('Bạn có chắc muốn hủy đơn #${_order.id}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Không'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colors.error,
              foregroundColor: colors.onError,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hủy đơn'),
          ),
        ],
      ),
    );
    if (confirmed == true) await _changeStatus(OrderStatus.cancelled);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text('Đơn #${_order.id}')),
      body: MaxWidthBox(
        maxWidth: 720,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ===== Trạng thái =====
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(child: SectionHeader('Trạng thái')),
                        OrderStatusChip(status: _order.status),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _StatusTimeline(status: _order.status),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ===== Thông tin nhận hàng =====
            SectionCard(
              title: 'Thông tin nhận hàng',
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text(_order.customerName),
                    subtitle: Text(_order.phone),
                  ),
                  ListTile(
                    leading: const Icon(Icons.location_on_outlined),
                    title: Text(_order.address),
                  ),
                  ListTile(
                    leading: const Icon(Icons.payment),
                    title: Text(_order.paymentMethod.label),
                    subtitle: Text(
                      _order.isPaid ? 'Đã thanh toán' : 'Thanh toán khi nhận hàng',
                    ),
                  ),
                  if (_order.note.isNotEmpty)
                    ListTile(
                      leading: const Icon(Icons.edit_note),
                      title: Text(_order.note),
                    ),
                  ListTile(
                    leading: const Icon(Icons.access_time),
                    title: Text(formatDateTime(_order.createdAt)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ===== Danh sách món: FutureBuilder xử lý loading / lỗi / có dữ liệu =====
            SectionCard(
              title: 'Món đã đặt',
              child: FutureBuilder<List<OrderItem>>(
                future: _itemsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Lỗi tải danh sách món: ${snapshot.error}',
                        style: TextStyle(color: colors.error),
                      ),
                    );
                  }
                  final items = snapshot.data ?? [];
                  return Column(
                    children: [
                      ...items.map((item) {
                        // Gộp topping + ghi chú thành 1 dòng mô tả
                        final details = [
                          if (item.toppings.isNotEmpty) 'Topping: ${item.toppings}',
                          if (item.note.isNotEmpty) 'Ghi chú: ${item.note}',
                        ];
                        return ListTile(
                          title: Text(
                            '${item.quantity} x ${item.productName} (${item.size})',
                          ),
                          subtitle:
                              details.isEmpty ? null : Text(details.join('\n')),
                          trailing: Text(formatVnd(item.totalPrice)),
                        );
                      }),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      ListTile(
                        title: Text('Tổng cộng', style: textTheme.titleMedium),
                        trailing: Text(
                          formatVnd(_order.totalPrice),
                          style: textTheme.titleLarge
                              ?.copyWith(color: colors.primary),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildActions(),
    );
  }

  // Nút thao tác ở dưới cùng (null = không hiện)
  Widget? _buildActions() {
    final next = _order.status.next;
    final canCancel = _order.status == OrderStatus.pending;
    final colors = Theme.of(context).colorScheme;
    // Nút hủy dùng màu error để khác nút chính
    final cancelStyle = OutlinedButton.styleFrom(
      foregroundColor: colors.error,
      side: BorderSide(color: colors.error),
    );

    Widget bar(Widget child) => SafeArea(
          child: MaxWidthBox(
            maxWidth: 720,
            child: Padding(padding: const EdgeInsets.all(16), child: child),
          ),
        );

    if (widget.isAdmin) {
      if (next == null) return null; // đơn đã kết thúc
      return bar(
        Row(
          children: [
            if (canCancel) ...[
              Expanded(
                child: OutlinedButton(
                  style: cancelStyle,
                  onPressed: _isUpdating ? null : _confirmCancel,
                  child: const Text('Hủy đơn'),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: _isUpdating ? null : () => _changeStatus(next),
                child: Text('Chuyển: ${next.label}'),
              ),
            ),
          ],
        ),
      );
    }

    // Khách hàng: chỉ được hủy khi quán chưa xác nhận
    if (!canCancel) return null;
    return bar(
      OutlinedButton.icon(
        style: cancelStyle,
        icon: const Icon(Icons.cancel_outlined),
        label: const Text('Hủy đơn hàng'),
        onPressed: _isUpdating ? null : _confirmCancel,
      ),
    );
  }
}

// Dòng thời gian trạng thái đơn: bước đã qua có dấu tích, bước hiện tại tô màu
// của trạng thái + câu mô tả, bước chưa tới để viền; các bước nối bằng đường dọc
class _StatusTimeline extends StatelessWidget {
  final OrderStatus status;

  const _StatusTimeline({required this.status});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (status == OrderStatus.cancelled) {
      final (:background, :foreground) = status.colors(colors);
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(status.icon, color: foreground),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Đơn hàng đã bị hủy',
                style: textTheme.titleSmall?.copyWith(color: foreground),
              ),
            ),
          ],
        ),
      );
    }

    // Các bước bình thường (bỏ "Đã hủy")
    final steps =
        OrderStatus.values.where((s) => s != OrderStatus.cancelled).toList();
    final currentIndex = steps.indexOf(status);

    return Column(
      children: [
        for (int i = 0; i < steps.length; i++)
          // IntrinsicHeight: đường nối cao bằng phần chữ bên phải
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Column(
                  children: [
                    _buildDot(colors, steps[i], i, currentIndex),
                    if (i < steps.length - 1)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: i < currentIndex
                              ? colors.primary
                              : colors.outlineVariant,
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          steps[i].label,
                          style: i == currentIndex
                              ? textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700)
                              : textTheme.bodyMedium?.copyWith(
                                  color: i < currentIndex
                                      ? colors.onSurface
                                      : colors.onSurfaceVariant,
                                ),
                        ),
                        if (i == currentIndex)
                          Text(
                            steps[i].message,
                            style: textTheme.bodySmall
                                ?.copyWith(color: colors.onSurfaceVariant),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDot(
    ColorScheme colors,
    OrderStatus step,
    int index,
    int currentIndex,
  ) {
    if (index < currentIndex) {
      // Bước đã qua
      return CircleAvatar(
        radius: 14,
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        child: const Icon(Icons.check, size: 16),
      );
    }
    if (index == currentIndex) {
      // Bước hiện tại: cùng màu với nhãn trạng thái
      final (:background, :foreground) = step.colors(colors);
      return CircleAvatar(
        radius: 14,
        backgroundColor: background,
        foregroundColor: foreground,
        child: Icon(step.icon, size: 16),
      );
    }
    // Bước chưa tới
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: colors.outlineVariant, width: 2),
      ),
      child: Icon(step.icon, size: 14, color: colors.onSurfaceVariant),
    );
  }
}
