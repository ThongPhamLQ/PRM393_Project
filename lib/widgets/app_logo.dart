import 'dart:math';

import 'package:flutter/material.dart';

// Logo Mộc Cafe vẽ bằng code (CustomPainter): ly cà phê có quai trên đĩa lót,
// làn khói là một chiếc lá ("Mộc" = gỗ, cây lá). Không cần file ảnh, nét vẫn
// sắc ở mọi cỡ. Cùng hình này được xuất ra icon app (Android, web).
// background = null -> chỉ vẽ hình (VD: trên thanh điều hướng, icon thông báo).
class AppLogo extends StatelessWidget {
  final double size;
  final Color? background;
  final Color foreground;

  const AppLogo({
    super.key,
    this.size = 64,
    this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    // Logo chỉ để trang trí: tên quán luôn có chữ bên cạnh
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size.square(size),
        painter: AppLogoPainter(background: background, foreground: foreground),
      ),
    );
  }
}

class AppLogoPainter extends CustomPainter {
  final Color? background;
  final Color foreground;
  // Tỉ lệ hình so với khung: icon app cần thu nhỏ để nằm trong vùng an toàn
  final double glyphScale;

  const AppLogoPainter({
    this.background,
    required this.foreground,
    this.glyphScale = 1,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    canvas.save();
    canvas.translate((size.width - side) / 2, (size.height - side) / 2);
    canvas.scale(side); // từ đây vẽ trong khung 1 x 1

    if (background != null) {
      canvas.drawCircle(const Offset(0.5, 0.5), 0.5, Paint()..color = background!);
    }

    // Thu nhỏ quanh tâm khung; dịch phải 0.03 vì quai ly làm hình lệch trái
    canvas.translate(0.5, 0.5);
    canvas.scale(glyphScale);
    canvas.translate(-0.47, -0.5);

    // Vẽ hình trên 1 lớp riêng để khoét gân lá trong suốt (thấy nền bên dưới)
    canvas.saveLayer(const Rect.fromLTWH(0, 0, 1, 1), Paint());
    final fill = Paint()..color = foreground;

    // Thân ly: miệng phẳng, đáy bo tròn
    final cup = Path()
      ..moveTo(0.26, 0.47)
      ..lineTo(0.68, 0.47)
      ..cubicTo(0.68, 0.64, 0.60, 0.73, 0.47, 0.73)
      ..cubicTo(0.34, 0.73, 0.26, 0.64, 0.26, 0.47)
      ..close();
    canvas.drawPath(cup, fill);

    // Quai ly: nửa vòng tròn bên phải
    canvas.drawArc(
      Rect.fromCircle(center: const Offset(0.66, 0.56), radius: 0.08),
      -pi / 2,
      pi,
      false,
      Paint()
        ..color = foreground
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.045,
    );

    // Đĩa lót
    canvas.drawRRect(
      RRect.fromLTRBR(0.18, 0.77, 0.76, 0.815, const Radius.circular(0.0225)),
      fill,
    );

    // Làn khói hình chiếc lá, nghiêng nhẹ sang phải
    final leaf = Path()
      ..moveTo(0.45, 0.42)
      ..quadraticBezierTo(0.31, 0.28, 0.56, 0.15)
      ..quadraticBezierTo(0.62, 0.33, 0.45, 0.42)
      ..close();
    canvas.drawPath(leaf, fill);

    // Gân lá: khoét trong suốt
    canvas.drawLine(
      const Offset(0.465, 0.385),
      const Offset(0.54, 0.21),
      Paint()
        ..blendMode = BlendMode.clear
        ..strokeWidth = 0.022
        ..strokeCap = StrokeCap.round,
    );

    canvas.restore(); // lớp hình
    canvas.restore();
  }

  @override
  bool shouldRepaint(AppLogoPainter oldDelegate) =>
      oldDelegate.background != background ||
      oldDelegate.foreground != foreground ||
      oldDelegate.glyphScale != glyphScale;
}
