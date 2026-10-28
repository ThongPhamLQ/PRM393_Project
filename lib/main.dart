import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/menu_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/order_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/admin/admin_home_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/customer/main_screen.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';
import 'utils/constants.dart';

void main() async {
  // Bắt buộc khi cần gọi plugin (thông báo, database...) trước runApp
  WidgetsFlutterBinding.ensureInitialized();

  // Chạy trên web (Chrome): sqflite không hỗ trợ web, nên dùng SQLite bản
  // WebAssembly (web/sqlite3.wasm); dữ liệu lưu trong IndexedDB của trình duyệt
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }

  await NotificationService.instance.init();

  runApp(
    // Đặt tất cả Provider ở gốc để mọi màn hình đều dùng được
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()..loadTheme()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MenuProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: const CafeApp(),
    ),
  );
}

class CafeApp extends StatelessWidget {
  const CafeApp({super.key});

  // Màu chủ đạo: nâu cà phê
  static const _seedColor = Color(0xFF795548);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;

    return MaterialApp(
      title: shopName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: _seedColor, useMaterial3: true),
      darkTheme: ThemeData(
        colorSchemeSeed: _seedColor,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      // Named routes (Module 5) cho các màn hình chính
      initialRoute: '/',
      routes: {
        '/': (_) => const SplashScreen(),
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/home': (_) => const MainScreen(),
        '/admin': (_) => const AdminHomeScreen(),
      },
    );
  }
}
