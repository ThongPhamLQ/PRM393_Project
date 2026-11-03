import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

import '../data/firestore_db.dart';
import '../utils/constants.dart';

// 1 tin nhắn giữa khách hàng và quán.
// Mỗi khách có 1 cuộc trò chuyện riêng với quán: chats/{customerId}/messages
class ChatMessage {
  final String customerId; // uid của khách (cuộc trò chuyện nào)
  final String sender; // 'customer' hoặc 'shop'
  final String content;
  final DateTime createdAt;

  ChatMessage({
    required this.customerId,
    required this.sender,
    required this.content,
    required this.createdAt,
  });

  bool get isFromShop => sender == senderShop;

  // customerId là tên document cha nên không cần lưu trong từng tin
  Map<String, dynamic> toMap() {
    return {
      'sender': sender,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory ChatMessage.fromMap(String customerId, Map<String, dynamic> map) {
    return ChatMessage(
      customerId: customerId,
      sender: map['sender'] as String,
      content: map['content'] as String,
      createdAt: readDate(map['createdAt']),
    );
  }
}

// Dùng cho màn hình chủ quán: danh sách các cuộc trò chuyện.
// Mỗi document chats/{customerId} giữ sẵn tên khách + tin mới nhất,
// thay cho câu SQL JOIN + GROUP BY trước đây.
class Conversation {
  final String customerId;
  final String customerName;
  final String lastMessage;
  final DateTime lastTime;

  Conversation({
    required this.customerId,
    required this.customerName,
    required this.lastMessage,
    required this.lastTime,
  });

  factory Conversation.fromMap(String customerId, Map<String, dynamic> map) {
    return Conversation(
      customerId: customerId,
      customerName: map['customerName'] as String,
      lastMessage: map['lastMessage'] as String,
      lastTime: readDate(map['lastTime']),
    );
  }
}
