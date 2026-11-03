import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/app_notification.dart';
import '../repositories/notification_repository.dart';
import '../services/notification_service.dart';

// Danh sách thông báo của người dùng + số thông báo chưa đọc.
// Nghe Stream từ Firestore: thông báo mới (vd: quán vừa đổi trạng thái đơn
// trên máy khác) hiện ngay + bật thông báo hệ thống trên máy này.
class NotificationProvider extends ChangeNotifier {
  final _notificationRepo = NotificationRepository();
  StreamSubscription<List<AppNotification>>? _subscription;
  String? _userId; // đang nghe thông báo của ai

  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  String? _loadError;

  List<AppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get loadError => _loadError;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  // Gọi nhiều lần (Trang chủ, tab Thông báo, kéo làm mới) vẫn chỉ nghe 1 Stream
  Future<void> loadNotifications(String userId) {
    if (_userId == userId && _subscription != null) return Future.value();
    _subscription?.cancel();
    _userId = userId;
    _isLoading = true;
    _loadError = null;
    notifyListeners();

    final firstData = Completer<void>();
    Set<String>? knownIds; // null = chưa nhận lần đầu
    _subscription = _notificationRepo
        .watchByUser(userId)
        .listen(
          (list) {
            // Lần đầu chỉ là dữ liệu cũ; các lần sau, id lạ chưa đọc = thông báo mới
            if (knownIds != null) {
              for (final n in list) {
                if (!n.isRead && !knownIds!.contains(n.id)) {
                  NotificationService.instance.show(n.title, n.body);
                }
              }
            }
            knownIds = {for (final n in list) n.id!};
            _notifications = list;
            _isLoading = false;
            _loadError = null;
            notifyListeners();
            if (!firstData.isCompleted) firstData.complete();
          },
          onError: (Object e) {
            debugPrint('Notifications stream failed: $e');
            // Bỏ subscription lỗi -> lần gọi sau (bấm Thử lại) nghe lại được
            _subscription = null;
            _isLoading = false;
            _loadError = 'Không tải được thông báo. Vui lòng thử lại.';
            notifyListeners();
            if (!firstData.isCompleted) firstData.complete();
          },
        );
    return firstData.future;
  }

  // Stream tự báo về danh sách mới, không cần tải lại
  Future<void> markAsRead(AppNotification notification) =>
      _notificationRepo.markAsRead(notification.userId, notification.id!);

  Future<void> markAllAsRead(String userId) =>
      _notificationRepo.markAllAsRead(userId);

  // Gọi khi đăng xuất: ngừng nghe Firestore trước khi mất quyền đọc
  void clear() {
    _subscription?.cancel();
    _subscription = null;
    _userId = null;
    _notifications = [];
    _isLoading = false;
    _loadError = null;
    notifyListeners();
  }
}
