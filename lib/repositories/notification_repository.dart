import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/firestore_db.dart';
import '../models/app_notification.dart';

// Đọc/ghi thông báo: users/{userId}/notifications
class NotificationRepository {
  NotificationRepository({FirebaseFirestore? db}) : _dbOverride = db;
  final FirebaseFirestore? _dbOverride;
  FirebaseFirestore get _db => _dbOverride ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _ofUser(String userId) => _db
      .collection(Collections.users)
      .doc(userId)
      .collection(Collections.notifications);

  Future<void> insert(AppNotification notification) =>
      _ofUser(notification.userId).add(notification.toMap());

  // Mới nhất lên đầu. Stream: quán đổi trạng thái đơn trên máy khác thì
  // thông báo xuất hiện ngay trên máy khách.
  Stream<List<AppNotification>> watchByUser(String userId) {
    return _ofUser(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => AppNotification.fromMap(d.id, userId, d.data()))
              .toList(),
        );
  }

  Future<void> markAsRead(String userId, String id) =>
      _ofUser(userId).doc(id).update({'isRead': true});

  Future<void> markAllAsRead(String userId) async {
    final unread = await _ofUser(userId).where('isRead', isEqualTo: false).get();
    final batch = _db.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}
