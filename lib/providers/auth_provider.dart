import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import '../repositories/user_repository.dart';

// Quản lý đăng nhập / đăng ký / phiên đăng nhập (Module 10)
class AuthProvider extends ChangeNotifier {
  static const _sessionKey =
      'logged_in_user_id'; // key lưu trong SharedPreferences
  final _userRepo = UserRepository();

  User? _currentUser;
  User? get currentUser => _currentUser;

  // Đăng nhập: thành công trả về null, thất bại trả về câu báo lỗi
  Future<String?> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1)); // giả lập gọi server
    final user = await _userRepo.login(email.trim(), password);
    if (user == null) return 'Email hoặc mật khẩu không đúng';

    _currentUser = user;
    // Lưu phiên đăng nhập -> lần sau mở app tự đăng nhập
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_sessionKey, user.id!);
    notifyListeners();
    return null;
  }

  // Đăng ký: thành công trả về null, thất bại trả về câu báo lỗi
  Future<String?> register(User user) async {
    await Future.delayed(const Duration(seconds: 1));
    final success = await _userRepo.register(user);
    return success ? null : 'Email này đã được sử dụng';
  }

  // Sửa thông tin cá nhân. Muốn đổi mật khẩu thì truyền newPassword
  // và phải nhập đúng mật khẩu hiện tại.
  // Thành công trả về null, thất bại trả về câu báo lỗi.
  Future<String?> updateProfile({
    required String name,
    required String phone,
    String? currentPassword,
    String? newPassword,
  }) async {
    final user = _currentUser;
    if (user == null) return 'Bạn chưa đăng nhập';

    if (newPassword != null && currentPassword != user.password) {
      return 'Mật khẩu hiện tại không đúng';
    }

    final updated = user.copyWith(
      name: name,
      phone: phone,
      password: newPassword, // null = giữ mật khẩu cũ
    );
    await _userRepo.updateUser(updated);
    _currentUser = updated;
    notifyListeners(); // màn Tài khoản tự hiện thông tin mới
    return null;
  }

  // Gọi ở SplashScreen: còn phiên đăng nhập thì vào thẳng app
  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt(_sessionKey);
    if (userId == null) return false;

    final user = await _userRepo.getUserById(userId);
    if (user == null) return false;

    _currentUser = user;
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    _currentUser = null;
    notifyListeners();
  }
}
