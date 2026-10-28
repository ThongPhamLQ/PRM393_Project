import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/chat_provider.dart';
import '../../utils/format.dart';
import '../../widgets/empty_view.dart';
import '../shared/chat_screen.dart';

// Chủ quán: danh sách khách đã nhắn tin
class AdminChatListScreen extends StatefulWidget {
  const AdminChatListScreen({super.key});

  @override
  State<AdminChatListScreen> createState() => _AdminChatListScreenState();
}

class _AdminChatListScreenState extends State<AdminChatListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    if (!mounted) return;
    await context.read<ChatProvider>().loadConversations();
  }

  @override
  Widget build(BuildContext context) {
    final conversations = context.watch<ChatProvider>().conversations;

    return RefreshIndicator(
      onRefresh: _load,
      child: conversations.isEmpty
          ? ListView(
              children: const [
                SizedBox(height: 120),
                EmptyView(
                  icon: Icons.chat_bubble_outline,
                  message: 'Chưa có khách nào nhắn tin',
                ),
              ],
            )
          : ListView.separated(
              itemCount: conversations.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final c = conversations[index];
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(c.customerName[0].toUpperCase()),
                  ),
                  title: Text(c.customerName),
                  subtitle: Text(
                    c.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    formatDateTime(c.lastTime),
                    style: const TextStyle(fontSize: 11),
                  ),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          customerId: c.customerId,
                          title: c.customerName,
                          isShop: true,
                        ),
                      ),
                    );
                    _load(); // quay lại thì tải lại tin nhắn mới nhất
                  },
                );
              },
            ),
    );
  }
}
