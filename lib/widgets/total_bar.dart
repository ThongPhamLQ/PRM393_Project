import 'package:flutter/material.dart';
import '../utils/format.dart';
import 'max_width_box.dart';

// Thanh dính đáy màn hình: dòng tổng tiền + nút hành động chính
// (Chi tiết món, Giỏ hàng, Đặt hàng). Nút nằm riêng 1 dòng nên không bị tràn
// khi màn hẹp hoặc chữ phóng to.
class TotalBar extends StatelessWidget {
  final String label;
  final int amount;
  final Widget button;

  const TotalBar({
    super.key,
    required this.label,
    required this.amount,
    required this.button,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Nền thẻ (trắng) + bóng nhẹ phía trên -> nổi trên nền kem
    return Material(
      color: Theme.of(context).cardColor,
      elevation: 3,
      shadowColor: colors.shadow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: SafeArea(
        top: false,
        child: MaxWidthBox(
          maxWidth: 640,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: textTheme.bodyLarge
                            ?.copyWith(color: colors.onSurfaceVariant),
                      ),
                    ),
                    Text(
                      formatVnd(amount),
                      style: textTheme.titleLarge?.copyWith(color: colors.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, height: 56, child: button),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
