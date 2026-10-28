import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/order.dart';
import '../../providers/order_provider.dart';
import '../../widgets/empty_view.dart';
import '../../widgets/max_width_box.dart';
import '../../widgets/order_card.dart';
import '../../widgets/order_status_chip.dart';
import '../shared/order_detail_screen.dart';

// Chủ quán: danh sách tất cả đơn, lọc theo trạng thái
class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  OrderStatus? _filter; // null = tất cả

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadOrders);
  }

  Future<void> _loadOrders() async {
    if (!mounted) return;
    await context.read<OrderProvider>().loadAllOrders();
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final allOrders = orderProvider.orders;
    final orders = _filter == null
        ? allOrders
        : allOrders.where((o) => o.status == _filter).toList();

    return MaxWidthBox(
      maxWidth: 800,
      child: Column(
        children: [
          // Bộ lọc trạng thái, kèm số lượng đơn của từng trạng thái
          SizedBox(
            height: 64,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                _buildFilterChip('Tất cả', null, allOrders.length),
                ...OrderStatus.values.map((status) => _buildFilterChip(
                      status.label,
                      status,
                      allOrders.where((o) => o.status == status).length,
                    )),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadOrders,
              child: _buildOrderList(orderProvider.isLoading, orders),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderList(bool isLoading, List<Order> orders) {
    if (isLoading && orders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (orders.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 120),
          EmptyView(icon: Icons.inbox, message: 'Không có đơn hàng nào'),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      itemCount: orders.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final order = orders[index];
        return OrderCard(
          key: ValueKey(order.id),
          order: order,
          showCustomerName: true,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OrderDetailScreen(order: order, isAdmin: true),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String label, OrderStatus? status, int count) {
    final colors = Theme.of(context).colorScheme;
    final selected = _filter == status;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        // Icon cùng màu chữ của chip (theme chỉ đổi màu chữ theo trạng thái chọn)
        avatar: Icon(
          status?.icon ?? Icons.apps,
          size: 18,
          color: selected ? colors.onPrimary : colors.primary,
        ),
        label: Text('$label ($count)'),
        selected: selected,
        onSelected: (_) => setState(() => _filter = status),
      ),
    );
  }
}
