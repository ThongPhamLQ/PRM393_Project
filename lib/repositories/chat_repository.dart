import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/firestore_db.dart';
import '../models/chat_message.dart';

// Chat: chats/{customerId} giữ tên khách + tin mới nhất,
// các tin nằm ở subcollection chats/{customerId}/messages.
class ChatRepository {
  ChatRepository({FirebaseFirestore? db}) : _dbOverride = db;
  final FirebaseFirestore? _dbOverride;
  FirebaseFirestore get _db => _dbOverride ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _chats =>
      _db.collection(Collections.chats);

  // Toàn bộ tin nhắn giữa 1 khách và quán (cũ -> mới), tự cập nhật khi có tin mới
  Stream<List<ChatMessage>> watchMessages(String customerId) {
    return _chats
        .doc(customerId)
        .collection(Collections.messages)
        .orderBy('createdAt')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => ChatMessage.fromMap(customerId, d.data()))
              .toList(),
        );
  }

  // Ghi tin nhắn + cập nhật "tin mới nhất" trong 1 batch (cùng thành công hoặc cùng lỗi).
  // customerName chỉ cần khi khách gửi; quán trả lời thì giữ tên cũ (merge).
  Future<void> sendMessage(ChatMessage message, {String? customerName}) {
    final chatRef = _chats.doc(message.customerId);
    final batch = _db.batch();
    batch.set(chatRef.collection(Collections.messages).doc(), message.toMap());
    batch.set(chatRef, {
      'lastMessage': message.content,
      'lastTime': Timestamp.fromDate(message.createdAt),
      'customerName': ?customerName, // ? = chỉ ghi khi khác null
    }, SetOptions(merge: true));
    return batch.commit();
  }

  // Danh sách cuộc trò chuyện cho chủ quán, cuộc có tin mới nhất lên đầu
  Stream<List<Conversation>> watchConversations() {
    return _chats
        .orderBy('lastTime', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => Conversation.fromMap(d.id, d.data()))
              .toList(),
        );
  }
}
