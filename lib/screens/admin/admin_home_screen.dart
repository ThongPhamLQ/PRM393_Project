import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order.dart';
import '../../providers/order_provider.dart';
import '../../utils/logout_helper.dart';
import '../../widgets/adaptive_shell.dart';
import 'admin_chat_list_screen.dart';
import 'admin_orders_screen.dart';

// Trang chủ quán: 2 tab Đơn hàng / Tin nhắn (thanh dưới hoặc thanh trái tùy bề rộng)
class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    // Số đơn đang chờ xác nhận -> badge trên tab Đơn hàng (đang ở tab Tin nhắn
    // vẫn thấy). select: chỉ build lại khi con số này đổi
    final pending = context.select<OrderProvider, int>(
      (p) => p.orders.where((o) => o.status == OrderStatus.pending).length,
    );
    Widget ordersIcon(IconData icon) => Badge(
          isLabelVisible: pending > 0,
          label: Text('$pending'),
          child: Icon(icon),
        );

    return AdaptiveShell(
      // Khu vực chủ quán: AppBar khối nâu (cặp màu Fixed, giống nhau ở sáng / tối);
      // AppBar tự tô tiêu đề, nút Đăng xuất và chọn icon trạng thái màu sáng
      appBar: AppBar(
        backgroundColor: colors.onPrimaryFixedVariant,
        foregroundColor: colors.primaryFixed,
        title: Text(_currentIndex == 0 ? 'Quản lý đơn hàng' : 'Tin nhắn khách hàng'),
        actions: [
          IconButton(
            tooltip: 'Đăng xuất',
            icon: const Icon(Icons.logout),
            onPressed: () => confirmLogout(context),
          ),
        ],
      ),
      selectedIndex: _currentIndex,
      onSelected: (index) => setState(() => _currentIndex = index),
      body: _currentIndex == 0
          ? const AdminOrdersScreen()
          : const AdminChatListScreen(),
      destinations: [
        NavigationDestination(
          icon: ordersIcon(Icons.receipt_long_outlined),
          selectedIcon: ordersIcon(Icons.receipt_long),
          label: 'Đơn hàng',
        ),
        const NavigationDestination(
          icon: Icon(Icons.chat_outlined),
          selectedIcon: Icon(Icons.chat),
          label: 'Tin nhắn',
        ),
      ],
    );
  }
}
