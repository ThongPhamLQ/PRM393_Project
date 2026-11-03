import 'package:flutter_test/flutter_test.dart';
import 'package:shop_app/utils/validators.dart';

void main() {
  test('Email đăng nhập: hợp lệ được chấp nhận, sai định dạng bị từ chối', () {
    // Arrange: chuẩn bị hai giá trị đầu vào.
    const invalidEmail = 'khong-phai-email';
    const validEmail = 'demo@example.com';

    // Act: gọi validator mà LoginScreen sử dụng.
    final invalidResult = validateEmail(invalidEmail);
    final validResult = validateEmail(validEmail);

    // Assert: email sai có thông báo lỗi; email đúng không có lỗi.
    expect(invalidResult, isNotNull);
    expect(validResult, isNull);
  });
}
