import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_notification.dart';
import '../../models/order.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/order_provider.dart';
import '../../utils/format.dart';
import '../../widgets/empty_view.dart';
import '../../widgets/max_width_box.dart';
import '../shared/order_detail_screen.dart';

// Tab Thông báo: các thông báo về trạng thái đơn hàng
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final String _userId;

  @override
  void initState() {
    super.initState();
    _userId = context.read<AuthProvider>().currentUser!.id;
    Future.microtask(_load);
  }

  Future<void> _load() async {
    if (!mounted) return;
    await context.read<NotificationProvider>().loadNotifications(_userId);
  }

  // Bấm thông báo: đánh dấu đã đọc; thông báo có gắn mã đơn thì mở chi tiết đơn đó
  Future<void> _open(AppNotification n) async {
    if (!n.isRead) {
      context
          .read<NotificationProvider>()
          .markAsRead(n)
          .catchError((Object e) => debugPrint('Mark as read failed: $e'));
    }
    final orderId = n.orderId;
    if (orderId == null) return; // thông báo cũ chưa gắn mã đơn
    final orderProvider = context.read<OrderProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    Order? order;
    try {
      order = await orderProvider.findOrder(orderId);
    } catch (e) {
      debugPrint('Find order #$orderId failed: $e');
    }
    if (!mounted) return;
    if (order == null) {
      messenger.showSnackBar(
        SnackBar(content: Text('Không mở được đơn #$orderId. Vui lòng thử lại.')),
      );
      return;
    }
    final found = order;
    navigator.push(
      MaterialPageRoute(builder: (_) => OrderDetailScreen(order: found)),
    );
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
        child: notifications.isEmpty && provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : notifications.isEmpty
            // Bọc ListView để vẫn kéo xuống làm mới được
            ? ListView(
                children: [
                  const SizedBox(height: 120),
                  provider.loadError != null
                      ? EmptyView(
                          icon: Icons.cloud_off,
                          message: provider.loadError!,
                          onRetry: _load,
                        )
                      : const EmptyView(
                          icon: Icons.notifications_none,
                          message: 'Chưa có thông báo nào',
                        ),
                ],
              )
            : MaxWidthBox(
                maxWidth: 800,
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: notifications.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final n = notifications[index];
                    // Chưa đọc: thẻ màu secondaryContainer + chữ on-color đi kèm, tiêu đề đậm
                    final unreadText = n.isRead ? null : colors.onSecondaryContainer;
                    return Card(
                      color: n.isRead ? null : colors.secondaryContainer,
                      child: ListTile(
                        textColor: unreadText,
                        iconColor: unreadText,
                        leading: Icon(
                          n.isRead
                              ? Icons.notifications_none
                              : Icons.notifications_active,
                        ),
                        title: Text(
                          n.title,
                          style: TextStyle(
                            fontWeight:
                                n.isRead ? FontWeight.normal : FontWeight.bold,
                          ),
                        ),
                        subtitle:
                            Text('${n.body}\n${formatDateTime(n.createdAt)}'),
                        isThreeLine: true,
                        // Có mã đơn -> mũi tên báo là bấm vào mở được đơn
                        trailing: n.orderId == null
                            ? null
                            : const Icon(Icons.chevron_right),
                        onTap: n.isRead && n.orderId == null
                            ? null
                            : () => _open(n),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
