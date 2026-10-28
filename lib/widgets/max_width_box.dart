import 'package:flutter/material.dart';

// Giới hạn bề rộng nội dung và căn giữa (Module 6 - Responsive):
// trên Chrome / tablet, form và danh sách không bị kéo dãn hết màn hình
class MaxWidthBox extends StatelessWidget {
  final double maxWidth;
  final Widget child;

  const MaxWidthBox({super.key, this.maxWidth = 1200, required this.child});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      heightFactor: 1, // cao bằng nội dung -> dùng được cả ở bottomNavigationBar
      child: SizedBox(width: maxWidth, child: child),
    );
  }
}
