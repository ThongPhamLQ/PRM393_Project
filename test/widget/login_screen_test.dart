// WIDGET TEST: kiểm tra giao diện + tương tác của màn hình Đăng nhập
// Chạy: flutter test test/widget
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shop_app/providers/auth_provider.dart';
import 'package:shop_app/screens/auth/login_screen.dart';

void main() {
  // Dựng LoginScreen kèm AuthProvider (vì màn hình cần Provider)
  Widget buildLoginScreen() {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: const MaterialApp(home: LoginScreen()),
    );
  }

  testWidgets('Hiển thị đủ ô Email, Mật khẩu và nút Đăng nhập', (tester) async {
    await tester.pumpWidget(buildLoginScreen());

    expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Mật khẩu'), findsOneWidget);
    expect(find.byKey(const Key('loginButton')), findsOneWidget);
  });

  testWidgets('Bấm Đăng nhập khi để trống -> hiện lỗi dưới các ô', (
    tester,
  ) async {
    await tester.pumpWidget(buildLoginScreen());

    // Act: bấm nút khi chưa nhập gì
    await tester.tap(find.byKey(const Key('loginButton')));
    await tester.pump(); // vẽ lại để hiện lỗi

    // Assert: lỗi validate xuất hiện
    expect(find.text('Email không được để trống'), findsOneWidget);
    expect(find.text('Mật khẩu không được để trống'), findsOneWidget);
  });

  testWidgets('Nhập email sai định dạng -> báo "Email không hợp lệ"', (
    tester,
  ) async {
    await tester.pumpWidget(buildLoginScreen());

    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'abc');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Mật khẩu'),
      '123456',
    );
    await tester.tap(find.byKey(const Key('loginButton')));
    await tester.pump();

    expect(find.text('Email không hợp lệ'), findsOneWidget);
  });

  testWidgets('Bấm chip "Khách hàng" -> tự điền tài khoản demo', (
    tester,
  ) async {
    await tester.pumpWidget(buildLoginScreen());

    await tester.tap(find.text('Khách hàng'));
    await tester.pump();

    expect(find.text('khach@gmail.com'), findsOneWidget);
  });
}
