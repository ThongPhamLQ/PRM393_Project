import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shop_app/widgets/empty_view.dart';

void main() {
  testWidgets('EmptyView hiển thị đúng icon và thông báo khi không có đơn', (
    WidgetTester tester,
  ) async {
    // Arrange: render widget thực của ứng dụng trong MaterialApp.
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EmptyView(icon: Icons.inbox, message: 'Không có đơn hàng nào'),
        ),
      ),
    );

    // Act: chờ widget hoàn tất một frame.
    await tester.pump();

    // Assert: nội dung và icon của trạng thái rỗng đều hiển thị.
    expect(find.text('Không có đơn hàng nào'), findsOneWidget);
    expect(find.byIcon(Icons.inbox), findsOneWidget);
  });
}
