import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/menu_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/adaptive_shell.dart';
import 'menu_screen.dart';
import 'notifications_screen.dart';
import 'order_history_screen.dart';
import 'profile_screen.dart';
import 'store_screen.dart';

// Khung chính của khách hàng: 5 tab (thanh dưới trên điện thoại, thanh trái trên màn rộng)
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final _pages = const [
    MenuScreen(),
    OrderHistoryScreen(),
    NotificationsScreen(),
    StoreScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Future.microtask: đợi build xong rồi mới tải dữ liệu
    // (gọi notifyListeners ngay trong initState sẽ bị lỗi)
    Future.microtask(() {
      if (!mounted) return;
      final userId = context.read<AuthProvider>().currentUser!.id!;
      context.read<MenuProvider>().loadMenu();
      context.read<NotificationProvider>().loadNotifications(userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    // select: chỉ build lại khi số thông báo chưa đọc thay đổi
    final unread = context.select<NotificationProvider, int>(
      (provider) => provider.unreadCount,
    );
    Widget bell(IconData icon) => Badge(
          isLabelVisible: unread > 0,
          label: Text('$unread'),
          child: Icon(icon),
        );

    // Điện thoại: thanh dưới; màn rộng: thanh bên trái (xem AdaptiveShell)
    return AdaptiveShell(
      selectedIndex: _currentIndex,
      onSelected: (index) => setState(() => _currentIndex = index),
      body: _pages[_currentIndex],
      destinations: [
        const NavigationDestination(
          icon: Icon(Icons.local_cafe_outlined),
          selectedIcon: Icon(Icons.local_cafe),
          label: 'Menu',
        ),
        const NavigationDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long),
          label: 'Đơn hàng',
        ),
        NavigationDestination(
          icon: bell(Icons.notifications_outlined),
          selectedIcon: bell(Icons.notifications),
          label: 'Thông báo',
        ),
        const NavigationDestination(
          icon: Icon(Icons.storefront_outlined),
          selectedIcon: Icon(Icons.storefront),
          label: 'Cửa hàng',
        ),
        const NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Tài khoản',
        ),
      ],
    );
  }
}
