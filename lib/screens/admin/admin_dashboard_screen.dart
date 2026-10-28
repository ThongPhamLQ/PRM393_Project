import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/dashboard_stats.dart';
import '../../providers/dashboard_provider.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late final DashboardProvider _dashboard;
  @override
  void initState() {
    super.initState();
    _dashboard = DashboardProvider();
    _dashboard.refresh();
  }

  @override
  void dispose() {
    _dashboard.dispose();
    super.dispose();
  }

  String money(num value) {
    final digits = value.round().abs().toString();
    final chunks = <String>[];
    for (int i = digits.length; i > 0; i -= 3) {
      chunks.insert(0, digits.substring(i - 3 < 0 ? 0 : i - 3, i));
    }
    return '${value < 0 ? '-' : ''}${chunks.join('.')} ₫';
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<DashboardProvider>.value(
      value: _dashboard,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Dashboard quản trị'),
          actions: [
            IconButton(
              tooltip: 'Làm mới',
              icon: const Icon(Icons.refresh),
              onPressed: () => _dashboard.refresh(),
            ),
          ],
        ),
        body: Consumer<DashboardProvider>(
          builder: (context, state, _) {
            final s = state.stats;
            return RefreshIndicator(
              onRefresh: () => state.refresh(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Thống kê đơn hàng',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      DropdownButton<int>(
                        value: state.days,
                        items: const [
                          DropdownMenuItem(value: 7, child: Text('7 ngày')),
                          DropdownMenuItem(value: 30, child: Text('30 ngày')),
                          DropdownMenuItem(value: 0, child: Text('Tất cả')),
                        ],
                        onChanged: (v) {
                          if (v != null) state.refresh(periodDays: v);
                        },
                      ),
                    ],
                  ),
                  const Text(
                    'Doanh thu chỉ ghi nhận đơn Hoàn thành; thống kê theo ngày tạo đơn.',
                    style: TextStyle(fontSize: 12),
                  ),
                  if (state.loading) const LinearProgressIndicator(),
                  if (state.error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Không tải được dữ liệu: ${state.error}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    TextButton(
                      onPressed: () => state.refresh(),
                      child: const Text('Thử lại'),
                    ),
                  ],
                  if (s != null) ...[
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final narrow = constraints.maxWidth < 550;
                        final width =
                            (constraints.maxWidth - 12) / (narrow ? 2 : 4);
                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _metric(
                              'Doanh thu đơn hoàn thành',
                              money(s.revenue),
                              Icons.payments,
                              width,
                            ),
                            _metric(
                              'Tổng đơn',
                              '${s.allOrders}',
                              Icons.receipt_long,
                              width,
                            ),
                            _metric(
                              'Chờ xác nhận',
                              '${s.pendingOrders}',
                              Icons.schedule,
                              width,
                            ),
                            _metric(
                              'Đang xử lý',
                              '${s.processingOrders}',
                              Icons.local_cafe,
                              width,
                            ),
                            _metric(
                              'Hoàn thành',
                              '${s.completedOrders}',
                              Icons.check_circle,
                              width,
                            ),
                            _metric(
                              'Đã hủy',
                              '${s.cancelledOrders}',
                              Icons.cancel,
                              width,
                            ),
                            _metric(
                              'Giá trị TB/đơn hoàn thành',
                              money(s.averageOrderValue),
                              Icons.analytics,
                              width,
                            ),
                            _metric(
                              'Tỷ lệ hủy',
                              '${s.cancellationRate.toStringAsFixed(1)}%',
                              Icons.percent,
                              width,
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 18),
                    Card(
                      child: ListTile(
                        title: const Text(
                          'Đã đánh dấu trả tiền, chưa hoàn thành',
                        ),
                        subtitle: const Text(
                          'Thanh toán có thể là giả lập; không cộng vào doanh thu.',
                        ),
                        trailing: Text(
                          money(s.paidNotCompleted),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Top 5 thức uống theo số lượng',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Text('Chỉ tính món thuộc đơn đã hoàn thành.'),
                    if (s.topDrinks.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Chưa có đơn hoàn thành trong kỳ.'),
                      ),
                    ...s.topDrinks.asMap().entries.map((e) {
                      final maxQty = s.topDrinks.first.quantity;
                      final qty = e.value.quantity;
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${e.key + 1}. ${e.value.name}',
                                    ),
                                  ),
                                  Text('$qty ly'),
                                ],
                              ),
                              const SizedBox(height: 6),
                              LinearProgressIndicator(
                                value: maxQty == 0 ? 0 : qty / maxQty,
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                  if (s == null && state.error == null && !state.loading)
                    const Center(child: Text('Chưa có dữ liệu')),
                  const SizedBox(height: 30),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _metric(String title, String value, IconData icon, double width) {
    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 22),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(title, style: const TextStyle(fontSize: 12), maxLines: 2),
            ],
          ),
        ),
      ),
    );
  }
}
