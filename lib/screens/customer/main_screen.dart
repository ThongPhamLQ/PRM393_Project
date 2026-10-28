import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/menu_provider.dart';
import '../../providers/notification_provider.dart';
import 'menu_screen.dart';
import 'notifications_screen.dart';
import 'order_history_screen.dart';
import 'profile_screen.dart';
import 'store_screen.dart';

// Khung chính của khách hàng: 5 tab ở thanh điều hướng dưới
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

    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed, // 5 tab -> phải dùng fixed
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.local_cafe),
            label: 'Menu',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Đơn hàng',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: unread > 0,
              label: Text('$unread'),
              child: const Icon(Icons.notifications),
            ),
            label: 'Thông báo',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.store),
            label: 'Cửa hàng',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Tài khoản',
          ),
        ],
      ),
    );
  }
}
