import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop_app/main.dart' as app;
import 'package:shop_app/screens/auth/login_screen.dart';

// Đợi một điều kiện UI theo các frame thực thay vì sleep cố định.
Future<void> pumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  int maxAttempts = 60,
}) async {
  for (var attempt = 0; attempt < maxAttempts; attempt++) {
    if (condition()) return;
    await tester.pump(const Duration(milliseconds: 250));
  }
  expect(condition(), isTrue, reason: 'UI không đạt trạng thái chờ đợi');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Customer đăng nhập thành công và chuyển đến màn chính', (
    WidgetTester tester,
  ) async {
    // ARRANGE: tạo phiên SharedPreferences mới, không xóa SQLite.
    // Nhờ đó app luôn bắt đầu ở Login, dù emulator từng đăng nhập.
    SharedPreferences.setMockInitialValues(<String, Object>{});

    // Khởi động entrypoint THẬT của dự án, bao gồm Providers và SQLite.
    app.main();

    await pumpUntil(tester, () => tester.any(find.byType(LoginScreen)));

    // ACT: điền thông tin của tài khoản khách được seed trong database.
    final fields = find.descendant(
      of: find.byType(LoginScreen),
      matching: find.byType(TextFormField),
    );
    expect(fields, findsNWidgets(2));

    await tester.enterText(fields.at(0), 'khach@gmail.com');
    await tester.enterText(fields.at(1), '123456');

    // Chỉ tìm nút có nhãn đăng nhập, không nhấn nhầm tiêu đề.
    final submitButton = find.ancestor(
      of: find.textContaining(
        RegExp(r'^\s*đăng nhập\s*$', caseSensitive: false),
      ),
      matching: find.byWidgetPredicate((widget) => widget is ButtonStyleButton),
    );
    expect(submitButton, findsWidgets);

    await tester.ensureVisible(submitButton.last);
    await tester.tap(submitButton.last);

    // ASSERT: LoginScreen biến mất sau điều hướng thành công.
    await pumpUntil(tester, () => !tester.any(find.byType(LoginScreen)));
    expect(find.byType(LoginScreen), findsNothing);
    expect(find.byType(Scaffold), findsWidgets);
  });
}
