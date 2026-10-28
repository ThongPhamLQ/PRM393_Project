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

  // Màu chủ đạo: nâu cà phê. Mọi màu trong app lấy từ ColorScheme sinh từ màu này
  static const _seedColor = Color(0xFF795548);

  // Theme sáng / tối chỉ khác brightness; style của các component gom hết ở đây.
  // Phong cách kiểu app chuỗi cà phê: dải nâu đậm (BrandBlock) - nền kem - thẻ
  // trắng bo 12 bóng rất nhẹ, nút viên thuốc, tiêu đề mục in hoa giãn chữ
  static ThemeData _buildTheme(Brightness brightness) {
    final colors = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: brightness,
    );
    final base = ThemeData(colorScheme: colors, useMaterial3: true);
    final text = base.textTheme;
    // Sáng: nền kem, thẻ trắng. Tối: 2 bậc surface tương ứng (thẻ sáng hơn nền)
    final isLight = brightness == Brightness.light;
    final canvas = isLight ? colors.surfaceContainer : colors.surface;
    final card = isLight ? colors.surfaceContainerLowest : colors.surfaceContainer;
    bool isSelected(Set<WidgetState> states) =>
        states.contains(WidgetState.selected);

    // Ô nhập dạng viên thuốc: dùng UnderlineInputBorder bo 28 để nhãn nổi nằm
    // trong ô; chỉ hiện vạch dưới khi đang nhập (focus) hoặc khi có lỗi
    InputBorder pill([BorderSide side = BorderSide.none]) => UnderlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(28)),
          borderSide: side,
        );

    return base.copyWith(
      scaffoldBackgroundColor: canvas,
      cardColor: card, // TotalBar, bong bóng chat... lấy qua Theme.of(context).cardColor
      // Chrome trên máy tính mặc định dùng mật độ "compact": giữ vùng chạm 48px
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      textTheme: text.copyWith(
        headlineSmall: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        titleSmall: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        labelLarge: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      // Không đặt titleTextStyle: AppBar nào đổi foregroundColor thì tiêu đề đổi theo
      appBarTheme: AppBarThemeData(
        centerTitle: false,
        backgroundColor: card,
        foregroundColor: colors.onSurface,
        shadowColor: colors.shadow,
        scrolledUnderElevation: 2,
      ),
      cardTheme: CardThemeData(
        color: card,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      // Chip đang chọn: khối màu primary đậm, chữ onPrimary; chưa chọn: nền thẻ
      chipTheme: ChipThemeData(
        showCheckmark: false, // chip đang chọn đổi màu nền, giữ nguyên icon
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        color: WidgetStateProperty.resolveWith(
          (states) => isSelected(states) ? colors.primary : card,
        ),
        labelStyle: text.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: WidgetStateColor.resolveWith(
            (states) => isSelected(states) ? colors.onPrimary : colors.onSurface,
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: colors.surfaceContainerHigh,
        contentPadding: const EdgeInsetsDirectional.fromSTEB(20, 10, 20, 10),
        border: pill(),
        enabledBorder: pill(),
        disabledBorder: pill(),
        focusedBorder: pill(BorderSide(color: colors.primary, width: 2)),
        errorBorder: pill(BorderSide(color: colors.error)),
        focusedErrorBorder: pill(BorderSide(color: colors.error, width: 2)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 48),
          textStyle: text.labelLarge?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(minimumSize: const Size(64, 48)),
      ),
      // Thanh điều hướng nền thẻ (trắng), mục đang chọn tô màu thương hiệu
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: card,
        elevation: 2,
        shadowColor: colors.shadow,
        indicatorColor: colors.primaryContainer,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: isSelected(states)
                ? colors.onPrimaryContainer
                : colors.onSurfaceVariant,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => text.labelMedium?.copyWith(
            color: isSelected(states) ? colors.primary : colors.onSurfaceVariant,
            fontWeight: isSelected(states) ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: card,
        indicatorColor: colors.primaryContainer,
        selectedIconTheme: IconThemeData(color: colors.onPrimaryContainer),
        unselectedIconTheme: IconThemeData(color: colors.onSurfaceVariant),
        selectedLabelTextStyle: text.labelMedium?.copyWith(
          color: colors.primary,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelTextStyle: text.labelMedium?.copyWith(
          color: colors.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // Tạo 1 lần, đổi sáng/tối không phải dựng lại theme
  static final _lightTheme = _buildTheme(Brightness.light);
  static final _darkTheme = _buildTheme(Brightness.dark);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;

    return MaterialApp(
      title: shopName,
      debugShowCheckedModeBanner: false,
      theme: _lightTheme,
      darkTheme: _darkTheme,
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
