import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order.dart';
import '../../providers/order_provider.dart';
import '../../widgets/empty_view.dart';
import '../../widgets/max_width_box.dart';
import '../../widgets/order_card.dart';
import '../shared/order_detail_screen.dart';
import 'admin_dashboard_screen.dart';
import 'admin_products_screen.dart';

// Chủ quán: tổng quan, quản lý sản phẩm và danh sách đơn theo trạng thái.
class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  OrderStatus? _filter; // null = tất cả.

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
          // Giữ Dashboard trên nhánh dat.
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Card(
              child: ListTile(
                leading: const Icon(Icons.dashboard_outlined),
                title: const Text('Tổng quan kinh doanh'),
                subtitle: const Text('Doanh thu, đơn hàng và đồ uống bán chạy'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AdminDashboardScreen(),
                  ),
                ),
              ),
            ),
          ),
          // Giữ Product Management, Bulk Delete và khôi phục trên nhánh dat.
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: Card(
              child: ListTile(
                leading: const Icon(Icons.inventory_2_outlined),
                title: const Text('Quản lý sản phẩm'),
                subtitle: const Text(
                  'Đồ uống, danh mục, topping, tình trạng bán',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AdminProductsScreen(),
                  ),
                ),
              ),
            ),
          ),
          // Giữ bộ lọc trạng thái và icon theo giao diện redesign từ master.
          SizedBox(
            height: 64,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                _buildFilterChip('Tất cả', null, allOrders.length),
                ...OrderStatus.values.map(
                  (status) => _buildFilterChip(
                    status.label,
                    status,
                    allOrders.where((o) => o.status == status).length,
                  ),
                ),
              ],
            ),
          ),
          // Giữ phần thông báo lỗi tải đơn của nhánh dat.
          if (orderProvider.loadError != null)
            MaterialBanner(
              content: Text(orderProvider.loadError!),
              actions: [
                TextButton(
                  onPressed: _loadOrders,
                  child: const Text('Thử lại'),
                ),
              ],
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
    // Giữ ListView.separated và spacing từ giao diện redesign của master.
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
            MaterialPageRoute<void>(
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
        avatar: Icon(
          switch (status?.name) {
            'pending' => Icons.schedule_outlined,
            'confirmed' => Icons.check_circle_outline,
            'preparing' => Icons.local_cafe_outlined,
            'delivering' => Icons.delivery_dining_outlined,
            'completed' => Icons.task_alt_outlined,
            'cancelled' => Icons.cancel_outlined,
            _ => Icons.apps,
          },
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
