import 'package:flutter/material.dart';

import '../../utils/logout_helper.dart';
import 'admin_chat_list_screen.dart';
import 'admin_orders_screen.dart';

// Trang chủ quán: 2 tab Đơn hàng / Tin nhắn
class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentIndex == 0 ? 'Quản lý đơn hàng' : 'Tin nhắn khách hàng',
        ),
        actions: [
          IconButton(
            tooltip: 'Đăng xuất',
            icon: const Icon(Icons.logout),
            onPressed: () => confirmLogout(context),
          ),
        ],
      ),
      body: _currentIndex == 0
          ? const AdminOrdersScreen()
          : const AdminChatListScreen(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Đơn hàng',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Tin nhắn'),
        ],
      ),
    );
  }
}
