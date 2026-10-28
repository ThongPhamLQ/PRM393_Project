import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../utils/format.dart';
import '../../widgets/empty_view.dart';

// Tab Thông báo: các thông báo về trạng thái đơn hàng
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final int _userId;

  @override
  void initState() {
    super.initState();
    _userId = context.read<AuthProvider>().currentUser!.id!;
    Future.microtask(_load);
  }

  Future<void> _load() async {
    if (!mounted) return;
    await context.read<NotificationProvider>().loadNotifications(_userId);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final notifications = provider.notifications;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        actions: [
          if (provider.unreadCount > 0)
            IconButton(
              tooltip: 'Đánh dấu đã đọc tất cả',
              icon: const Icon(Icons.done_all),
              onPressed: () => provider.markAllAsRead(_userId),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: notifications.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 120),
                  EmptyView(
                    icon: Icons.notifications_none,
                    message: 'Chưa có thông báo nào',
                  ),
                ],
              )
            : ListView.separated(
                itemCount: notifications.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final n = notifications[index];
                  return ListTile(
                    // Chưa đọc: nền đậm hơn + chữ đậm
                    tileColor: n.isRead
                        ? null
                        : colors.primaryContainer.withValues(alpha: 0.3),
                    leading: Icon(
                      n.isRead
                          ? Icons.notifications_none
                          : Icons.notifications_active,
                      color: colors.primary,
                    ),
                    title: Text(
                      n.title,
                      style: TextStyle(
                        fontWeight: n.isRead
                            ? FontWeight.normal
                            : FontWeight.bold,
                      ),
                    ),
                    subtitle: Text('${n.body}\n${formatDateTime(n.createdAt)}'),
                    isThreeLine: true,
                    onTap: n.isRead ? null : () => provider.markAsRead(n),
                  );
                },
              ),
      ),
    );
  }
}
