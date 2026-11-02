import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Hiển thị thông báo hệ thống (Local Notification - Module 10, Demo 10.5).
// Tách riêng thành service để không trộn với logic đặt hàng / đăng nhập.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  int _nextId = 0;

  // Gọi 1 lần trong main() trước runApp()
  Future<void> init() async {
    try {
      const settings = InitializationSettings(
        // Icon nhỏ trên thanh trạng thái: logo trắng nền trong suốt
        // (Android tô trắng cả hình, dùng icon app có nền sẽ thành ô vuông trắng)
        android: AndroidInitializationSettings('@drawable/ic_stat_cafe'),
      );
      await _plugin.initialize(settings: settings);
    } catch (e) {
      // Nền tảng không hỗ trợ (VD: chạy test) -> bỏ qua, app vẫn chạy bình thường
      debugPrint('Không khởi tạo được thông báo: $e');
    }
  }

  // Xin quyền hiển thị thông báo (hiện hộp thoại hỏi người dùng):
  // Android 13+ và trình duyệt web đều bắt buộc
  Future<void> requestPermission() async {
    try {
      if (kIsWeb) {
        await _plugin
            .resolvePlatformSpecificImplementation<
              WebFlutterLocalNotificationsPlugin
            >()
            ?.requestNotificationsPermission();
      } else {
        await _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestNotificationsPermission();
      }
    } catch (e) {
      debugPrint('Không xin được quyền thông báo: $e');
    }
  }

  Future<void> show(String title, String body) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'order_channel', // id kênh
        'Đơn hàng', // tên kênh hiển thị trong Cài đặt
        channelDescription: 'Thông báo trạng thái đơn hàng',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );
    try {
      await _plugin.show(
        id: _nextId++,
        title: title,
        body: body,
        notificationDetails: details,
      );
    } catch (e) {
      debugPrint('Không hiển thị được thông báo: $e');
    }
  }
}
