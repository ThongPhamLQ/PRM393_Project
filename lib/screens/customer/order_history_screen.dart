import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../widgets/empty_view.dart';
import '../../widgets/order_card.dart';
import '../shared/order_detail_screen.dart';

// Tab Đơn hàng: lịch sử đơn của khách
class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  late final int _userId;

  @override
  void initState() {
    super.initState();
    _userId = context.read<AuthProvider>().currentUser!.id!;
    Future.microtask(_loadOrders); // tải dữ liệu sau khi build xong
  }

  Future<void> _loadOrders() async {
    if (!mounted) return;
    await context.read<OrderProvider>().loadMyOrders(_userId);
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final orders = orderProvider.orders;

    Widget body;
    if (orderProvider.isLoading && orders.isEmpty) {
      body = const Center(child: CircularProgressIndicator());
    } else if (orders.isEmpty) {
      // Bọc trong ListView để vẫn kéo xuống làm mới được
      body = ListView(
        children: const [
          SizedBox(height: 120),
          EmptyView(
            icon: Icons.receipt_long,
            message: 'Bạn chưa có đơn hàng nào',
          ),
        ],
      );
    } else {
      body = ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return OrderCard(
            key: ValueKey(order.id),
            order: order,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OrderDetailScreen(order: order),
              ),
            ),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Đơn hàng của tôi')),
      // Kéo xuống để tải lại (xem trạng thái mới nhất)
      body: Column(
        children: [
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
            child: RefreshIndicator(onRefresh: _loadOrders, child: body),
          ),
        ],
      ),
    );
  }
}
