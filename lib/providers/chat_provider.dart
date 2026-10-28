import 'package:flutter/foundation.dart';

import '../models/chat_message.dart';
import '../repositories/chat_repository.dart';

// Chat giữa khách hàng và quán
class ChatProvider extends ChangeNotifier {
  final _chatRepo = ChatRepository();

  List<ChatMessage> _messages = []; // tin nhắn của cuộc trò chuyện đang mở
  List<Conversation> _conversations =
      []; // danh sách cuộc trò chuyện (chủ quán)

  List<ChatMessage> get messages => _messages;
  List<Conversation> get conversations => _conversations;

  Future<void> loadMessages(int customerId) async {
    _messages = await _chatRepo.getMessages(customerId);
    notifyListeners();
  }

  // sender: 'customer' (khách gửi) hoặc 'shop' (chủ quán trả lời)
  Future<void> sendMessage({
    required int customerId,
    required String sender,
    required String content,
  }) async {
    await _chatRepo.sendMessage(
      ChatMessage(
        customerId: customerId,
        sender: sender,
        content: content,
        createdAt: DateTime.now(),
      ),
    );
    await loadMessages(customerId); // tải lại để hiện tin vừa gửi
  }

  Future<void> loadConversations() async {
    _conversations = await _chatRepo.getConversations();
    notifyListeners();
  }

  // Gọi khi đăng xuất
  void clear() {
    _messages = [];
    _conversations = [];
    notifyListeners();
  }
}
