import 'package:cloud_firestore/cloud_firestore.dart';

// Tên các collection trên Cloud Firestore (thay cho các bảng SQLite trước đây).
//
// users/{uid}                     hồ sơ người dùng (uid lấy từ Firebase Auth)
//   notifications/{autoId}        thông báo của người dùng đó
// categories/{id}, products/{id}, toppings/{id}   menu (id là số: "1", "2"...)
// orders/{id}                     đơn hàng, các món nằm luôn trong mảng items
// chats/{customerUid}             1 cuộc trò chuyện / khách (tin mới nhất để hiện danh sách)
//   messages/{autoId}             từng tin nhắn
// counters/{name}                 bộ đếm để cấp mã số tăng dần (mã đơn #1, #2...)
class Collections {
  static const users = 'users';
  static const notifications = 'notifications';
  static const categories = 'categories';
  static const products = 'products';
  static const toppings = 'toppings';
  static const orders = 'orders';
  static const chats = 'chats';
  static const messages = 'messages';
  static const counters = 'counters';
}

// Firestore không có AUTOINCREMENT như SQLite: đọc bộ đếm counters/{name} rồi
// tăng thêm 1 trong cùng transaction -> 2 máy đặt đơn cùng lúc vẫn nhận 2 mã khác nhau.
// Transaction bắt buộc đọc hết rồi mới ghi, nên hãy gọi hàm này SAU các lệnh txn.get khác.
Future<int> nextId(Transaction txn, FirebaseFirestore db, String name) async {
  final ref = db.collection(Collections.counters).doc(name);
  final snap = await txn.get(ref);
  final next = ((snap.data()?['value'] as num?)?.toInt() ?? 0) + 1;
  txn.set(ref, {'value': next});
  return next;
}

// Firestore lưu thời gian dạng Timestamp; đọc ra thì đổi về DateTime
DateTime readDate(Object? value) =>
    value is Timestamp ? value.toDate() : DateTime.parse(value as String);
