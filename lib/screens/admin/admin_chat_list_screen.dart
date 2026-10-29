import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/chat_provider.dart';
import '../../utils/format.dart';
import '../../widgets/empty_view.dart';
import '../../widgets/max_width_box.dart';
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
    final colors = Theme.of(context).colorScheme;

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
          : MaxWidthBox(
              maxWidth: 800,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: conversations.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final c = conversations[index];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: colors.primaryContainer,
                        foregroundColor: colors.onPrimaryContainer,
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
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: colors.onSurfaceVariant),
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
                    ),
                  );
                },
              ),
            ),
    );
  }
}
