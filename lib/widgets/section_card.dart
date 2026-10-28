import 'package:flutter/material.dart';

// Tiêu đề mục: chữ in hoa, giãn chữ, màu thương hiệu (VD: "CHỌN SIZE", "TẤT CẢ MÓN")
class SectionHeader extends StatelessWidget {
  final String text;

  const SectionHeader(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text.toUpperCase(),
      style: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
        color: theme.colorScheme.primary,
      ),
    );
  }
}

// Thẻ có tiêu đề cho 1 nhóm nội dung (chọn size, topping, thông tin nhận hàng...).
// Nội dung bên trong tự lo lề ngang (ListTile đã có sẵn lề 16).
class SectionCard extends StatelessWidget {
  final String? title;
  final Widget child;

  const SectionCard({super.key, this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: SectionHeader(title!),
              ),
            child,
          ],
        ),
      ),
    );
  }
}
