import 'package:flutter/material.dart';
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
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long),
          label: 'Đơn hàng',
        ),
        NavigationDestination(
          icon: Icon(Icons.chat_outlined),
          selectedIcon: Icon(Icons.chat),
          label: 'Tin nhắn',
        ),
      ],
    );
  }
}
