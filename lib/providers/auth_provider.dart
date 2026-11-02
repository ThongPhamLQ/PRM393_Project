import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';

import '../models/user.dart';
import '../repositories/user_repository.dart';
import '../utils/constants.dart';

// Quản lý đăng nhập / đăng ký / phiên đăng nhập (Module 10) bằng Firebase Auth.
// Firebase Auth giữ mật khẩu (đã mã hóa) và tự lưu phiên đăng nhập trên máy,
// Firestore giữ hồ sơ users/{uid} (họ tên, SĐT, vai trò).
class AuthProvider extends ChangeNotifier {
  final _userRepo = UserRepository();
  // Lấy instance khi dùng: widget test dựng màn Đăng nhập không cần Firebase
  fb.FirebaseAuth get _auth => fb.FirebaseAuth.instance;

  User? _currentUser;
  User? get currentUser => _currentUser;

  // Đăng nhập: thành công trả về null, thất bại trả về câu báo lỗi
  Future<String?> login(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      _currentUser = await _loadProfile(credential.user!);
      notifyListeners();
      return null;
    } on fb.FirebaseAuthException catch (e) {
      return _authMessage(e);
    } catch (e) {
      debugPrint('Login failed: $e');
      await _auth.signOut();
      return 'Không tải được hồ sơ tài khoản. Vui lòng thử lại.';
    }
  }

  // Đăng ký: thành công trả về null, thất bại trả về câu báo lỗi.
  // Vai trò lấy theo email: chỉ adminEmail là chủ quán (Security Rules kiểm tra lại).
  Future<String?> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      // Lấy email Firebase đã chuẩn hóa (chữ thường): Security Rules so khớp
      // email trong hồ sơ với email của tài khoản
      final savedEmail = credential.user!.email ?? email.trim();
      await _userRepo.saveUser(
        User(
          id: credential.user!.uid,
          name: name,
          email: savedEmail,
          phone: phone,
          role: _roleFor(savedEmail),
        ),
      );
      // Firebase tự đăng nhập sau khi tạo tài khoản; đăng xuất để giữ luồng cũ:
      // đăng ký xong quay lại màn Đăng nhập
      await _auth.signOut();
      return null;
    } on fb.FirebaseAuthException catch (e) {
      return _authMessage(e);
    } catch (e) {
      debugPrint('Register failed: $e');
      // Tài khoản đã tạo nhưng chưa lưu được hồ sơ: lần đăng nhập đầu sẽ tạo bù
      await _auth.signOut();
      return 'Đã tạo tài khoản nhưng chưa lưu được hồ sơ. Hãy thử đăng nhập.';
    }
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
    final fbUser = _auth.currentUser;
    if (user == null || fbUser == null) return 'Bạn chưa đăng nhập';

    try {
      if (newPassword != null) {
        // Firebase bắt đăng nhập lại (xác thực mật khẩu hiện tại) trước khi đổi
        await fbUser.reauthenticateWithCredential(
          fb.EmailAuthProvider.credential(
            email: user.email,
            password: currentPassword ?? '',
          ),
        );
        await fbUser.updatePassword(newPassword);
      }
      final updated = user.copyWith(name: name, phone: phone);
      await _userRepo.updateProfile(updated);
      _currentUser = updated;
      notifyListeners(); // màn Tài khoản tự hiện thông tin mới
      return null;
    } on fb.FirebaseAuthException catch (e) {
      return const {'wrong-password', 'invalid-credential'}.contains(e.code)
          ? 'Mật khẩu hiện tại không đúng'
          : _authMessage(e);
    } catch (e) {
      debugPrint('Update profile failed: $e');
      return 'Không lưu được thông tin. Vui lòng thử lại.';
    }
  }

  // Gọi ở SplashScreen: Firebase Auth còn phiên đăng nhập thì vào thẳng app
  Future<bool> tryAutoLogin() async {
    try {
      // first: chờ Firebase đọc xong phiên đã lưu trên máy
      final fbUser = await _auth.authStateChanges().first;
      if (fbUser == null) return false;
      _currentUser = await _loadProfile(fbUser);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Auto login failed: $e');
      return false;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    _currentUser = null;
    notifyListeners();
  }

  // Đọc hồ sơ users/{uid}; thiếu (vd: lúc đăng ký bị mất mạng) thì tạo bù
  // để tài khoản không bị khóa vĩnh viễn
  Future<User> _loadProfile(fb.User fbUser) async {
    final saved = await _userRepo.getUserById(fbUser.uid);
    if (saved != null) return saved;
    final email = fbUser.email ?? '';
    final profile = User(
      id: fbUser.uid,
      name: email.split('@').first,
      email: email,
      phone: '',
      role: _roleFor(email),
    );
    await _userRepo.saveUser(profile);
    return profile;
  }

  static String _roleFor(String email) =>
      email.trim().toLowerCase() == adminEmail ? roleAdmin : roleCustomer;

  // Đổi mã lỗi của Firebase Auth sang câu tiếng Việt
  static String _authMessage(fb.FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
      case 'invalid-email':
        return 'Email hoặc mật khẩu không đúng';
      case 'email-already-in-use':
        return 'Email này đã được sử dụng';
      case 'weak-password':
        return 'Mật khẩu quá yếu (tối thiểu 6 ký tự)';
      case 'too-many-requests':
        return 'Thử sai quá nhiều lần. Vui lòng đợi một lát';
      case 'network-request-failed':
        return 'Không có kết nối mạng. Vui lòng thử lại';
      default:
        debugPrint('FirebaseAuthException: ${e.code} ${e.message}');
        return 'Có lỗi xảy ra (${e.code})';
    }
  }
}
