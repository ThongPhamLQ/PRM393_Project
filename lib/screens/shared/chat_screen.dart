import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/chat_message.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../utils/constants.dart';
import '../../utils/format.dart';
import '../../widgets/empty_view.dart';
import '../../widgets/max_width_box.dart';

// Màn hình chat (dùng chung):
// - Khách hàng mở: isShop = false, tin của khách nằm bên phải
// - Chủ quán mở:   isShop = true,  tin của quán nằm bên phải
class ChatScreen extends StatefulWidget {
  final String customerId; // uid của khách: cuộc trò chuyện của khách nào
  final String title; // tên hiển thị trên AppBar
  final bool isShop;

  const ChatScreen({
    super.key,
    required this.customerId,
    required this.title,
    required this.isShop,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  // Giữ lại để gọi trong dispose (lúc đó không được dùng context nữa)
  late final ChatProvider _chat;

  // Người đang dùng màn hình này là ai
  String get _mySender => widget.isShop ? senderShop : senderCustomer;

  @override
  void initState() {
    super.initState();
    _chat = context.read<ChatProvider>();
    Future.microtask(() {
      if (!mounted) return;
      _chat.loadMessages(widget.customerId); // nghe tin nhắn realtime
    });
  }

  @override
  void dispose() {
    _chat.closeMessages(); // rời màn chat thì ngừng nghe Firestore
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();
    try {
      await _chat.sendMessage(
        customerId: widget.customerId,
        sender: _mySender,
        content: text,
        // Khách gửi thì kèm tên để chủ quán thấy trong danh sách tin nhắn
        customerName: widget.isShop
            ? null
            : context.read<AuthProvider>().currentUser?.name,
      );
    } catch (e) {
      debugPrint('Send message failed: $e');
      if (!mounted) return;
      _messageController.text = text; // trả lại nội dung để gửi lại
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không gửi được tin nhắn. Thử lại sau.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    final messages = chat.messages;
    final error = chat.messagesError;

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: MaxWidthBox(
        maxWidth: 800,
        child: Column(
          children: [
            Expanded(
              child: messages.isEmpty && chat.messagesLoading
                  ? const Center(child: CircularProgressIndicator())
                  : messages.isEmpty && error != null
                  ? EmptyView(
                      icon: Icons.cloud_off,
                      message: error,
                      onRetry: () => _chat.loadMessages(widget.customerId),
                    )
                  : messages.isEmpty
                  ? EmptyView(
                      icon: Icons.chat_bubble_outline,
                      message: widget.isShop
                          ? 'Chưa có tin nhắn'
                          : 'Hãy gửi tin nhắn cho quán.\nQuán sẽ trả lời bạn sớm nhất!',
                    )
                  : ListView.builder(
                      // reverse: danh sách bắt đầu từ dưới lên -> luôn thấy tin mới nhất
                      reverse: true,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        // Vì reverse nên lấy từ cuối danh sách
                        final message = messages[messages.length - 1 - index];
                        return _MessageBubble(
                          message: message,
                          isMine: message.sender == _mySender,
                        );
                      },
                    ),
            ),

            // Ô nhập tin nhắn (dạng viên thuốc theo theme) trên thanh màu thẻ,
            // tách khỏi nền kem của danh sách tin
            Material(
              color: Theme.of(context).cardColor,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _send(),
                          decoration: const InputDecoration(
                            hintText: 'Nhập tin nhắn...',
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton.filled(
                        tooltip: 'Gửi',
                        icon: const Icon(Icons.send),
                        onPressed: _send,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Bong bóng tin nhắn
class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMine; // tin của mình -> bên phải, màu chủ đạo

  const _MessageBubble({required this.message, required this.isMine});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textColor = isMine ? colors.onPrimary : colors.onSurface;
    const radius = Radius.circular(20);

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          // Tối đa 75% bề rộng màn hình, không quá 560px trên màn rộng
          maxWidth: min(MediaQuery.sizeOf(context).width * 0.75, 560),
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          // Tin của người kia: màu thẻ (trắng) trên nền kem
          color: isMine ? colors.primary : Theme.of(context).cardColor,
          // Góc nhọn ở phía người gửi giống "đuôi" bong bóng chat
          borderRadius: BorderRadius.only(
            topLeft: radius,
            topRight: radius,
            bottomLeft: isMine ? radius : const Radius.circular(6),
            bottomRight: isMine ? const Radius.circular(6) : radius,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message.content, style: TextStyle(color: textColor)),
            const SizedBox(height: 4),
            Text(
              formatDateTime(message.createdAt),
              style: TextStyle(
                fontSize: 11,
                // Giờ gửi: chữ mờ hơn nhưng vẫn ≥ 4.5:1 (onPrimary 80% trên primary)
                color: isMine
                    ? colors.onPrimary.withValues(alpha: 0.8)
                    : colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
