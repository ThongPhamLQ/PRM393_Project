import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../utils/order_filter.dart';
import '../../widgets/empty_view.dart';
import '../../widgets/max_width_box.dart';
import '../../widgets/order_card.dart';
import '../shared/order_detail_screen.dart';

// Tab Đơn hàng: lịch sử đơn của khách
class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  late final String _userId;
  final _searchController = TextEditingController();
  String _query = '';
  CustomerOrderGroup _group = CustomerOrderGroup.all;

  @override
  void initState() {
    super.initState();
    _userId = context.read<AuthProvider>().currentUser!.id;
    Future.microtask(_loadOrders); // tải dữ liệu sau khi build xong
  }

  Future<void> _loadOrders() async {
    if (!mounted) return;
    await context.read<OrderProvider>().loadMyOrders(_userId);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _query = '';
      _group = CustomerOrderGroup.all;
    });
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final allOrders = orderProvider.orders;
    final orders = filterOrders(
      allOrders,
      query: _query,
      customerGroup: _group,
    );

    Widget body;
    if (orderProvider.isLoading && allOrders.isEmpty) {
      body = const Center(child: CircularProgressIndicator());
    } else if (allOrders.isEmpty) {
      final error = orderProvider.loadError;
      // Bọc trong ListView để vẫn kéo xuống làm mới được
      body = ListView(
        children: [
          const SizedBox(height: 120),
          // Lỗi tải thì báo lỗi + nút Thử lại, không giả vờ là "chưa có đơn"
          error != null
              ? EmptyView(
                  icon: Icons.cloud_off,
                  message: error,
                  onRetry: _loadOrders,
                )
              : const EmptyView(
                  icon: Icons.receipt_long,
                  message: 'Bạn chưa có đơn hàng nào',
                ),
        ],
      );
    } else if (orders.isEmpty) {
      body = ListView(
        children: [
          const SizedBox(height: 80),
          EmptyView(
            icon: Icons.search_off,
            message: 'Không tìm thấy đơn phù hợp',
            onRetry: _clearFilters,
            retryLabel: 'Xóa bộ lọc',
          ),
        ],
      );
    } else {
      body = ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
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
      body: MaxWidthBox(
        maxWidth: 800,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onChanged: (value) => setState(() => _query = value),
                onSubmitted: (_) => FocusScope.of(context).unfocus(),
                decoration: InputDecoration(
                  hintText: 'Tìm theo mã đơn, VD: #23',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Xóa tìm kiếm',
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                          icon: const Icon(Icons.clear),
                        ),
                ),
              ),
            ),
            SizedBox(
              height: 56,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                children: [
                  for (final group in CustomerOrderGroup.values)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(
                          '${_groupLabel(group)} (${filterOrders(allOrders, customerGroup: group).length})',
                        ),
                        selected: _group == group,
                        onSelected: (_) => setState(() => _group = group),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(onRefresh: _loadOrders, child: body),
            ),
          ],
        ),
      ),
    );
  }

  String _groupLabel(CustomerOrderGroup group) => switch (group) {
    CustomerOrderGroup.all => 'Tất cả',
    CustomerOrderGroup.processing => 'Đang xử lý',
    CustomerOrderGroup.completed => 'Hoàn thành',
    CustomerOrderGroup.cancelled => 'Đã hủy',
  };
}
