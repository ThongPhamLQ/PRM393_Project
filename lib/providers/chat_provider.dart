import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/chat_message.dart';
import '../repositories/chat_repository.dart';

// Chat giữa khách hàng và quán. Nghe Stream từ Firestore nên tin nhắn của
// bên kia hiện ngay, không cần tải lại.
class ChatProvider extends ChangeNotifier {
  final _chatRepo = ChatRepository();
  StreamSubscription<List<ChatMessage>>? _messagesSub;
  StreamSubscription<List<Conversation>>? _conversationsSub;
  String? _openCustomerId; // cuộc trò chuyện đang mở

  List<ChatMessage> _messages = []; // tin nhắn của cuộc trò chuyện đang mở
  List<Conversation> _conversations =
      []; // danh sách cuộc trò chuyện (chủ quán)

  List<ChatMessage> get messages => _messages;
  List<Conversation> get conversations => _conversations;

  Future<void> loadMessages(String customerId) {
    _messagesSub?.cancel();
    if (_openCustomerId != customerId) _messages = []; // không lẫn tin của khách trước
    _openCustomerId = customerId;
    final firstData = Completer<void>();
    _messagesSub = _chatRepo
        .watchMessages(customerId)
        .listen(
          (messages) {
            _messages = messages;
            notifyListeners();
            if (!firstData.isCompleted) firstData.complete();
          },
          onError: (Object e) {
            debugPrint('Messages stream failed: $e');
            if (!firstData.isCompleted) firstData.complete();
          },
        );
    return firstData.future;
  }

  // Gọi khi rời màn chat. Không notifyListeners vì đang ở dispose của màn hình.
  void closeMessages() {
    _messagesSub?.cancel();
    _messagesSub = null;
    _openCustomerId = null;
    _messages = [];
  }

  // sender: 'customer' (khách gửi) hoặc 'shop' (chủ quán trả lời).
  // customerName: khách gửi thì truyền tên để chủ quán thấy trong danh sách.
  // Tin vừa gửi tự hiện qua Stream (Firestore báo ngay cả khi chưa lên server).
  Future<void> sendMessage({
    required String customerId,
    required String sender,
    required String content,
    String? customerName,
  }) {
    return _chatRepo.sendMessage(
      ChatMessage(
        customerId: customerId,
        sender: sender,
        content: content,
        createdAt: DateTime.now(),
      ),
      customerName: customerName,
    );
  }

  Future<void> loadConversations() {
    _conversationsSub?.cancel();
    final firstData = Completer<void>();
    _conversationsSub = _chatRepo.watchConversations().listen(
      (conversations) {
        _conversations = conversations;
        notifyListeners();
        if (!firstData.isCompleted) firstData.complete();
      },
      onError: (Object e) {
        debugPrint('Conversations stream failed: $e');
        if (!firstData.isCompleted) firstData.complete();
      },
    );
    return firstData.future;
  }

  // Gọi khi đăng xuất: ngừng nghe Firestore trước khi mất quyền đọc
  void clear() {
    closeMessages();
    _conversationsSub?.cancel();
    _conversationsSub = null;
    _conversations = [];
    notifyListeners();
  }
}
