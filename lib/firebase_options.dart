import 'package:firebase_core/firebase_core.dart';

// Cấu hình Firebase (project moc-cafe-prm393) cho bản web (Chrome).
// Bản Android đọc android/app/google-services.json nên không cần ở đây.
// Các giá trị này chỉ định danh project, không phải mật khẩu: quyền đọc/ghi
// dữ liệu do Firestore Security Rules (firestore.rules) quyết định.
class DefaultFirebaseOptions {
  static const web = FirebaseOptions(
    apiKey: 'AIzaSyAYBDiEz399ErP_XfTTcychZnfq8k0mm14',
    appId: '1:712310450645:web:447692292840fb3607f55c',
    messagingSenderId: '712310450645',
    projectId: 'moc-cafe-prm393',
    authDomain: 'moc-cafe-prm393.firebaseapp.com',
    storageBucket: 'moc-cafe-prm393.firebasestorage.app',
  );
}
