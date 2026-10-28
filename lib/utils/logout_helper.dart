import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/order_provider.dart';

// Hỏi xác nhận rồi đăng xuất (dùng chung cho khách hàng và chủ quán)
Future<void> confirmLogout(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Đăng xuất'),
      content: const Text('Bạn có chắc muốn đăng xuất?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Đăng xuất'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;

  // Lấy các đối tượng cần dùng TRƯỚC khi await (tránh dùng context sau await)
  final navigator = Navigator.of(context);
  final auth = context.read<AuthProvider>();

  // Xóa dữ liệu của người dùng cũ để người sau không thấy
  context.read<CartProvider>().clear();
  context.read<OrderProvider>().clear();
  context.read<NotificationProvider>().clear();
  context.read<ChatProvider>().clear();

  await auth.logout(); // xóa phiên trong SharedPreferences

  // Về màn Login và xóa hết các màn hình cũ khỏi stack
  navigator.pushNamedAndRemoveUntil('/login', (route) => false);
}
