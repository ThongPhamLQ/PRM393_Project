import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/firestore_db.dart';
import '../models/user.dart';

// Đọc/ghi hồ sơ người dùng: collection users/{uid}.
// Đăng nhập / mật khẩu do Firebase Auth lo (xem AuthProvider).
class UserRepository {
  UserRepository({FirebaseFirestore? db}) : _dbOverride = db;
  final FirebaseFirestore? _dbOverride;
  // Lấy instance khi dùng (không lấy ở constructor) để test không cần Firebase
  FirebaseFirestore get _db => _dbOverride ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection(Collections.users);

  // Tạo hồ sơ ngay sau khi Firebase Auth tạo tài khoản
  Future<void> saveUser(User user) => _users.doc(user.id).set(user.toMap());

  Future<User?> getUserById(String id) async {
    final doc = await _users.doc(id).get();
    final data = doc.data();
    return data == null ? null : User.fromMap(doc.id, data);
  }

  // Chỉ cập nhật họ tên + SĐT (email dùng để đăng nhập nên không đổi;
  // Security Rules cũng chặn sửa các trường khác)
  Future<void> updateProfile(User user) =>
      _users.doc(user.id).update({'name': user.name, 'phone': user.phone});
}
