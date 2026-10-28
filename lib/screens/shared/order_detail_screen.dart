import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order.dart';
import '../../providers/order_provider.dart';
import '../../utils/format.dart';
import '../../widgets/order_status_chip.dart';

// Chi tiết đơn hàng (dùng chung):
// - Khách hàng: xem trạng thái, được hủy khi đơn còn "Chờ xác nhận"
// - Chủ quán (isAdmin = true): chuyển đơn sang trạng thái tiếp theo
class OrderDetailScreen extends StatefulWidget {
  final Order order;
  final bool isAdmin;

  const OrderDetailScreen({
    super.key,
    required this.order,
    this.isAdmin = false,
  });

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
    if (_isUpdating) return;
    final provider = context.read<OrderProvider>();
    setState(() => _isUpdating = true);
    try {
      await provider.updateStatus(_order, newStatus);
      if (!mounted) return;
      setState(() => _order = _order.copyWith(status: newStatus));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đơn #${_order.id}: ${newStatus.label}')),
      );
    } catch (e) {
      debugPrint('Update order status failed: $e');
      // Tải lại thực trạng khi đơn đã được chỉnh ở màn hình khác.
      try {
        final latest = await provider.getOrderById(_order.id!);
        if (mounted && latest != null) {
          setState(() => _order = latest);
        }
      } catch (reloadError) {
        debugPrint('Reload changed order failed: $reloadError');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Không thể cập nhật đơn. Trạng thái có thể đã thay đổi; vui lòng tải lại.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _confirmCancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hủy đơn hàng'),
        content: Text(
          _order.isPaid
              ? 'Bạn có chắc muốn hủy đơn #${_order.id}? Thanh toán hiện chỉ là giả lập; ứng dụng không thực hiện hoàn tiền.'
              : 'Bạn có chắc muốn hủy đơn #${_order.id}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Không'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
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
    return Scaffold(
      appBar: AppBar(title: Text('Đơn #${_order.id}')),
      body: ListView(
        padding: const EdgeInsets.all(12),
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
                      const Text(
                        'Trạng thái',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      OrderStatusChip(status: _order.status),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _StatusTimeline(status: _order.status),
                ],
              ),
            ),
          ),

          // ===== Thông tin nhận hàng =====
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(_order.customerName),
                  subtitle: Text(_order.phone),
                ),
                ListTile(
                  leading: const Icon(Icons.location_on),
                  title: Text(_order.address),
                ),
                ListTile(
                  leading: const Icon(Icons.payment),
                  title: Text(_order.paymentMethod.label),
                  subtitle: Text(
                    _order.isPaid
                        ? 'Đã thanh toán'
                        : 'Thanh toán khi nhận hàng',
                  ),
                ),
                if (_order.note.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.note_alt),
                    title: Text(_order.note),
                  ),
                ListTile(
                  leading: const Icon(Icons.access_time),
                  title: Text(formatDateTime(_order.createdAt)),
                ),
              ],
            ),
          ),

          // ===== Danh sách món: FutureBuilder xử lý loading / lỗi / có dữ liệu =====
          Card(
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
                    child: Text('Lỗi tải danh sách món: ${snapshot.error}'),
                  );
                }
                final items = snapshot.data ?? [];
                return Column(
                  children: [
                    ...items.map((item) {
                      // Gộp topping + ghi chú thành 1 dòng mô tả
                      final details = [
                        if (item.toppings.isNotEmpty)
                          'Topping: ${item.toppings}',
                        if (item.note.isNotEmpty) 'Ghi chú: ${item.note}',
                      ];
                      return ListTile(
                        title: Text(
                          '${item.quantity} x ${item.productName} (${item.size})',
                        ),
                        subtitle: details.isEmpty
                            ? null
                            : Text(details.join('\n')),
                        trailing: Text(formatVnd(item.totalPrice)),
                      );
                    }),
                    const Divider(height: 1),
                    ListTile(
                      title: const Text(
                        'Tổng cộng',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      trailing: Text(
                        formatVnd(_order.totalPrice),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildActions(),
    );
  }

  // Nút thao tác ở dưới cùng (null = không hiện)
  Widget? _buildActions() {
    final next = _order.status.next;
    final canCancel = _order.status == OrderStatus.pending;

    if (widget.isAdmin) {
      if (next == null) return null; // đơn đã kết thúc
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (canCancel) ...[
                Expanded(
                  child: OutlinedButton(
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
        ),
      );
    }

    // Khách hàng: chỉ được hủy khi quán chưa xác nhận
    if (!canCancel) return null;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: OutlinedButton.icon(
          icon: const Icon(Icons.cancel, color: Colors.red),
          label: const Text('Hủy đơn hàng'),
          onPressed: _isUpdating ? null : _confirmCancel,
        ),
      ),
    );
  }
}

// Các bước của đơn hàng: bước đã qua có dấu tích xanh
class _StatusTimeline extends StatelessWidget {
  final OrderStatus status;

  const _StatusTimeline({required this.status});

  @override
  Widget build(BuildContext context) {
    if (status == OrderStatus.cancelled) {
      return const Row(
        children: [
          Icon(Icons.cancel, color: Colors.red),
          SizedBox(width: 8),
          Text('Đơn hàng đã bị hủy'),
        ],
      );
    }

    // Các bước bình thường (bỏ "Đã hủy")
    final steps = OrderStatus.values
        .where((s) => s != OrderStatus.cancelled)
        .toList();
    final currentIndex = steps.indexOf(status);

    return Column(
      children: [
        for (int i = 0; i < steps.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(
                  i <= currentIndex
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: i <= currentIndex ? Colors.green : Colors.grey,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  steps[i].label,
                  style: TextStyle(
                    fontWeight: i == currentIndex
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
