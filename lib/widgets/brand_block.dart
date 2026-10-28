import 'package:flutter/material.dart';

// Khối màu đậm của thương hiệu: dải nâu đầu trang (Splash, Đăng nhập, Menu,
// Chi tiết món), thẻ thành viên, thẻ cửa hàng.
// Dùng cặp màu "Fixed" của ColorScheme -> giống nhau ở chế độ sáng và tối.
// Theme riêng bên trong đổi chữ / icon / ListTile / IconButton / vòng loading
// sang màu sáng, nên các widget con không phải tự đặt màu.
// Lưu ý: TextStyle lấy từ Theme.of(context) của màn hình (context ngoài khối)
// vẫn mang màu cũ -> tự đặt màu primaryFixed / primaryFixedDim. Thứ gì có nền
// riêng đặt trên khối (avatar, ô nhập) cũng tự dùng màu Fixed.
class BrandBlock extends StatelessWidget {
  final Widget child;
  final BorderRadius? borderRadius;

  const BrandBlock({super.key, required this.child, this.borderRadius});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final background = colors.onPrimaryFixedVariant;
    final foreground = colors.primaryFixed;

    return Theme(
      data: theme.copyWith(
        colorScheme: colors.copyWith(
          surface: background,
          onSurface: foreground,
          onSurfaceVariant: colors.primaryFixedDim, // chữ phụ
          primary: foreground, // IconButton.filled, loading -> màu sáng
          onPrimary: background,
        ),
        textTheme: theme.textTheme.apply(
          bodyColor: foreground,
          displayColor: foreground,
        ),
        iconTheme: IconThemeData(color: foreground),
      ),
      // Material: ListTile / InkWell bên trong có chỗ vẽ hiệu ứng chạm
      child: Material(
        color: background,
        borderRadius: borderRadius,
        clipBehavior: borderRadius == null ? Clip.none : Clip.antiAlias,
        child: child,
      ),
    );
  }
}
