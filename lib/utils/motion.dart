import 'package:flutter/material.dart';

// Ngôn ngữ chuyển động chung của app: ngắn (~200 ms), chỉ đổi độ mờ + kích thước,
// cùng một đường cong easeOutCubic (nhanh lúc đầu, chậm dần khi về đích).
const motionCurve = Curves.easeOutCubic;

// Thời lượng hiệu ứng. Người dùng bật "Tắt hiệu ứng" (Cài đặt > Hỗ trợ tiếp cận)
// thì trả về 0 -> giao diện đổi ngay, không chạy hiệu ứng.
Duration motionDuration(BuildContext context, [int milliseconds = 200]) =>
    MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : Duration(milliseconds: milliseconds);

// transitionBuilder cho AnimatedSwitcher: nội dung mới hiện dần và phóng nhẹ 0.9 -> 1
Widget fadeScale(Widget child, Animation<double> animation) {
  final curved = CurvedAnimation(parent: animation, curve: motionCurve);
  return FadeTransition(
    opacity: curved,
    child: ScaleTransition(
      scale: Tween(begin: 0.9, end: 1.0).animate(curved),
      child: child,
    ),
  );
}
