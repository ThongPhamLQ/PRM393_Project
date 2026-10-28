import 'package:flutter/material.dart';

import 'admin_dashboard_screen.dart';

import 'package:provider/provider.dart';

import '../../models/order.dart';
import '../../providers/order_provider.dart';
import '../../widgets/empty_view.dart';
import '../../widgets/order_card.dart';
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

    return Column(
      children: [
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

        // Bộ lọc trạng thái, kèm số lượng đơn của từng trạng thái
        SizedBox(
          height: 56,
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
        if (orderProvider.loadError != null)
          MaterialBanner(
            content: Text(orderProvider.loadError!),
            actions: [
              TextButton(onPressed: _loadOrders, child: const Text('Thử lại')),
            ],
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadOrders,
            child: _buildOrderList(orderProvider.isLoading, orders),
          ),
        ),
      ],
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
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: orders.length,
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
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text('$label ($count)'),
        selected: _filter == status,
        onSelected: (_) => setState(() => _filter = status),
      ),
    );
  }
}
