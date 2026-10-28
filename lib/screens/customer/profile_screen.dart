import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/constants.dart';
import '../../utils/logout_helper.dart';
import '../shared/chat_screen.dart';
import 'edit_profile_screen.dart';

// Tab Tài khoản: thông tin cá nhân, chế độ tối, đăng xuất
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dùng watch: sửa thông tin xong thì màn này tự cập nhật
    final user = context.watch<AuthProvider>().currentUser;
    if (user == null) return const SizedBox.shrink(); // vừa đăng xuất

    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Tài khoản')),
      body: ListView(
        children: [
          const SizedBox(height: 24),
          Center(
            child: CircleAvatar(
              radius: 40,
              child: Text(
                user.name[0].toUpperCase(),
                style: const TextStyle(fontSize: 32),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              user.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Center(
            child: Text(user.email, style: const TextStyle(color: Colors.grey)),
          ),
          const SizedBox(height: 16),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Chỉnh sửa thông tin'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EditProfileScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.phone),
            title: const Text('Số điện thoại'),
            subtitle: Text(user.phone),
          ),
          // Lưu lựa chọn bằng SharedPreferences -> mở lại app vẫn giữ
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode),
            title: const Text('Chế độ tối'),
            value: themeProvider.isDarkMode,
            onChanged: themeProvider.setDarkMode,
          ),
          ListTile(
            leading: const Icon(Icons.chat),
            title: const Text('Chat với quán'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatScreen(
                  customerId: user.id!,
                  title: shopName,
                  isShop: false,
                ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
            onTap: () => confirmLogout(context),
          ),
        ],
      ),
    );
  }
}
