import 'package:flutter/foundation.dart';

import '../models/app_notification.dart';
import '../repositories/notification_repository.dart';

// Danh sách thông báo của người dùng + số thông báo chưa đọc
class NotificationProvider extends ChangeNotifier {
  final _notificationRepo = NotificationRepository();

  List<AppNotification> _notifications = [];

  List<AppNotification> get notifications => _notifications;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> loadNotifications(int userId) async {
    _notifications = await _notificationRepo.getByUser(userId);
    notifyListeners();
  }

  Future<void> markAsRead(AppNotification notification) async {
    await _notificationRepo.markAsRead(notification.id!);
    await loadNotifications(notification.userId);
  }

  Future<void> markAllAsRead(int userId) async {
    await _notificationRepo.markAllAsRead(userId);
    await loadNotifications(userId);
  }

  // Gọi khi đăng xuất
  void clear() {
    _notifications = [];
    notifyListeners();
  }
}
