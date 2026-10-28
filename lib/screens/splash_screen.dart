import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/notification_service.dart';
import '../utils/constants.dart';
import '../widgets/brand_block.dart';

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
    await Future.delayed(const Duration(seconds: 1)); // cho người dùng thấy logo
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
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      // AppBar cao 0 = dải màu dưới thanh trạng thái; AppBar tự chọn icon trạng
      // thái màu sáng vì nền đậm
      appBar: AppBar(
        toolbarHeight: 0,
        backgroundColor: colors.onPrimaryFixedVariant,
      ),
      // Cả màn là khối nâu đậm của thương hiệu
      body: BrandBlock(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                ExcludeSemantics(
                  child: CircleAvatar(
                    radius: 64,
                    backgroundColor: colors.primaryFixed,
                    foregroundColor: colors.onPrimaryFixedVariant,
                    child: const Icon(Icons.local_cafe, size: 72),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  shopName.toUpperCase(),
                  textAlign: TextAlign.center,
                  // textTheme lấy từ context ngoài khối -> tự đặt màu chữ sáng
                  style: textTheme.headlineSmall?.copyWith(
                    color: colors.primaryFixed,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Cà phê & trà sữa mỗi ngày',
                  textAlign: TextAlign.center,
                  style:
                      textTheme.bodyLarge?.copyWith(color: colors.primaryFixedDim),
                ),
                const SizedBox(height: 32),
                const CircularProgressIndicator(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
