import 'package:flutter/material.dart';

// Màn hình trống: giỏ hàng trống, chưa có đơn, chưa có thông báo...
// Có onRetry -> đây là màn lỗi: thêm nút "Thử lại" và để TalkBack đọc to thông báo lỗi.
class EmptyView extends StatelessWidget {
  final IconData icon;
  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;

  const EmptyView({
    super.key,
    required this.icon,
    required this.message,
    this.onRetry,
    this.retryLabel = 'Thử lại',
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Semantics(
          // liveRegion: trình đọc màn hình tự đọc khi lỗi xuất hiện
          liveRegion: onRetry != null,
          container: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 56,
                backgroundColor: colors.primaryContainer,
                foregroundColor: colors.onPrimaryContainer,
                child: Icon(icon, size: 56),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge
                    ?.copyWith(color: colors.onSurfaceVariant),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 16),
                FilledButton.tonalIcon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: Text(retryLabel),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
