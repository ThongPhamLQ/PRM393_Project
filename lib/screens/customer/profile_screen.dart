import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/constants.dart';
import '../../utils/logout_helper.dart';
import '../../widgets/brand_block.dart';
import '../../widgets/max_width_box.dart';
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
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Tài khoản')),
      body: MaxWidthBox(
        maxWidth: 600,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Thẻ thành viên (khối nâu): tên quán, chữ cái đầu, họ tên, email, SĐT.
            // textTheme của màn (ngoài khối) -> tự đặt màu sáng cho chữ
            BrandBlock(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  // Ly cà phê lớn mờ ở góc: chỉ để trang trí
                  Positioned(
                    right: -16,
                    bottom: -24,
                    child: ExcludeSemantics(
                      child: Icon(
                        Icons.local_cafe,
                        size: 140,
                        color: colors.primaryFixed.withValues(alpha: 0.12),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shopName.toUpperCase(),
                          style: textTheme.labelLarge?.copyWith(
                            color: colors.primaryFixedDim,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 32,
                              backgroundColor: colors.primaryFixed,
                              foregroundColor: colors.onPrimaryFixedVariant,
                              child: Text(
                                user.name[0].toUpperCase(),
                                style: textTheme.headlineSmall?.copyWith(
                                  color: colors.onPrimaryFixedVariant,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.name,
                                    style: textTheme.titleLarge
                                        ?.copyWith(color: colors.primaryFixed),
                                  ),
                                  Text(
                                    user.email,
                                    style: textTheme.bodyMedium
                                        ?.copyWith(color: colors.primaryFixedDim),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // SĐT giãn chữ như số thẻ
                        Text(
                          user.phone,
                          style: textTheme.titleMedium?.copyWith(
                            color: colors.primaryFixed,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.edit_outlined),
                    title: const Text('Chỉnh sửa thông tin'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EditProfileScreen(),
                      ),
                    ),
                  ),
                  // Lưu lựa chọn bằng SharedPreferences -> mở lại app vẫn giữ
                  SwitchListTile(
                    secondary: const Icon(Icons.dark_mode_outlined),
                    title: const Text('Chế độ tối'),
                    value: themeProvider.isDarkMode,
                    onChanged: themeProvider.setDarkMode,
                  ),
                  ListTile(
                    leading: const Icon(Icons.chat_outlined),
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
                ],
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                iconColor: colors.error,
                textColor: colors.error,
                leading: const Icon(Icons.logout),
                title: const Text('Đăng xuất'),
                onTap: () => confirmLogout(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
