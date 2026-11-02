import '../utils/constants.dart';

// Người dùng: khách hàng hoặc chủ quán (admin).
// Mật khẩu do Firebase Auth giữ (đã mã hóa phía Google), không lưu trong Firestore.
class User {
  final String id; // uid do Firebase Auth cấp, cũng là id document users/{uid}
  final String name;
  final String email;
  final String phone;
  final String role; // 'customer' hoặc 'admin'

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.role = roleCustomer,
  });

  bool get isAdmin => role == roleAdmin;

  // Tạo bản sao với vài thông tin mới (vì các trường là final).
  // Email và vai trò không đổi.
  User copyWith({String? name, String? phone}) {
    return User(
      id: id,
      name: name ?? this.name,
      email: email,
      phone: phone ?? this.phone,
      role: role,
    );
  }

  // Chuyển object -> Map để lưu vào Firestore (id là tên document nên không lưu)
  Map<String, dynamic> toMap() {
    return {'name': name, 'email': email, 'phone': phone, 'role': role};
  }

  // Chuyển Map (1 document trong Firestore) -> object
  factory User.fromMap(String id, Map<String, dynamic> map) {
    return User(
      id: id,
      name: map['name'] as String,
      email: map['email'] as String,
      phone: (map['phone'] as String?) ?? '',
      role: map['role'] as String,
    );
  }
}
