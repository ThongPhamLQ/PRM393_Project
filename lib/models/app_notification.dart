import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

import '../data/firestore_db.dart';

// Thông báo trong app, lưu ở users/{userId}/notifications để xem lại ở màn Thông báo
class AppNotification {
  final String? id; // id document do Firestore tự sinh, null khi chưa lưu
  final String userId; // thông báo gửi cho user nào
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    this.id,
    required this.userId,
    required this.title,
    required this.body,
    this.isRead = false,
    required this.createdAt,
  });

  // userId là tên document cha nên không cần lưu lại
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory AppNotification.fromMap(
    String id,
    String userId,
    Map<String, dynamic> map,
  ) {
    return AppNotification(
      id: id,
      userId: userId,
      title: map['title'] as String,
      body: map['body'] as String,
      isRead: map['isRead'] == true,
      createdAt: readDate(map['createdAt']),
    );
  }
}
