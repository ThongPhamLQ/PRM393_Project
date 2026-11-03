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

  // Đang tải / lỗi của từng danh sách -> màn hình phân biệt "đang tải", "lỗi" và "trống"
  bool _messagesLoading = false;
  String? _messagesError;
  bool _conversationsLoading = false;
  String? _conversationsError;

  List<ChatMessage> get messages => _messages;
  List<Conversation> get conversations => _conversations;
  bool get messagesLoading => _messagesLoading;
  String? get messagesError => _messagesError;
  bool get conversationsLoading => _conversationsLoading;
  String? get conversationsError => _conversationsError;

  Future<void> loadMessages(String customerId) {
    _messagesSub?.cancel();
    if (_openCustomerId != customerId) _messages = []; // không lẫn tin của khách trước
    _openCustomerId = customerId;
    _messagesLoading = true;
    _messagesError = null;
    notifyListeners();
    final firstData = Completer<void>();
    _messagesSub = _chatRepo
        .watchMessages(customerId)
        .listen(
          (messages) {
            _messages = messages;
            _messagesLoading = false;
            _messagesError = null;
            notifyListeners();
            if (!firstData.isCompleted) firstData.complete();
          },
          onError: (Object e) {
            debugPrint('Messages stream failed: $e');
            _messagesLoading = false;
            _messagesError = 'Không tải được tin nhắn. Vui lòng thử lại.';
            notifyListeners();
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
    _messagesLoading = false;
    _messagesError = null;
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
    _conversationsLoading = true;
    _conversationsError = null;
    notifyListeners();
    final firstData = Completer<void>();
    _conversationsSub = _chatRepo.watchConversations().listen(
      (conversations) {
        _conversations = conversations;
        _conversationsLoading = false;
        _conversationsError = null;
        notifyListeners();
        if (!firstData.isCompleted) firstData.complete();
      },
      onError: (Object e) {
        debugPrint('Conversations stream failed: $e');
        _conversationsLoading = false;
        _conversationsError = 'Không tải được danh sách tin nhắn. Vui lòng thử lại.';
        notifyListeners();
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
    _conversationsLoading = false;
    _conversationsError = null;
    notifyListeners();
  }
}
