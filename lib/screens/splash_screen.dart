import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/notification_service.dart';
import '../utils/constants.dart';

// Màn hình chờ: kiểm tra phiên đăng nhập (Module 10 - Demo 10.3 Auto Login)
// Splash -> (còn phiên?) -> Home / Admin / Login
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Xin quyền thông báo (không cần chờ người dùng trả lời)
    NotificationService.instance.requestPermission();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    final auth = context.read<AuthProvider>();
    await Future.delayed(
      const Duration(seconds: 1),
    ); // cho người dùng thấy logo
    final loggedIn = await auth.tryAutoLogin();
    if (!mounted) return;

    if (!loggedIn) {
      Navigator.pushReplacementNamed(context, '/login');
    } else if (auth.currentUser!.isAdmin) {
      Navigator.pushReplacementNamed(context, '/admin');
    } else {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_cafe, size: 100, color: colors.primary),
            const SizedBox(height: 16),
            const Text(
              shopName,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
