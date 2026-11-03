// Tạo 2 tài khoản demo trên Firebase Auth + nạp menu mẫu lên Firestore.
// Chạy 1 lần sau khi tạo project (cần bật đăng nhập Email/Password trước):
//   dart run tool/seed_firestore.dart
// Chạy lại vẫn an toàn: document nào đã có thì giữ nguyên, nên không ghi đè
// menu chủ quán đã sửa và không đặt lại bộ đếm mã đơn.
//
// Dùng REST API của Firebase (không cần Flutter), đi qua Security Rules như app:
// hồ sơ do chính tài khoản đó ghi, menu do tài khoản chủ quán ghi.
import 'dart:convert';
import 'dart:io';

import 'package:shop_app/data/seed_data.dart';

final _http = HttpClient();
late final String _apiKey;
late final String _projectId;

Future<void> main() async {
  // Lấy project id + API key từ file cấu hình Android đã tải về
  final config = jsonDecode(
    File('android/app/google-services.json').readAsStringSync(),
  );
  _projectId = config['project_info']['project_id'] as String;
  _apiKey = config['client'][0]['api_key'][0]['current_key'] as String;
  stdout.writeln('Project: $_projectId');

  String? adminToken;
  for (final account in demoAccounts) {
    final auth = await _signUpOrIn(account['email']!, account['password']!);
    await _create('users/${auth.uid}', {
      'name': account['name'],
      'email': account['email'],
      'phone': account['phone'],
      'role': account['role'],
    }, auth.token);
    if (account['role'] == 'admin') adminToken = auth.token;
  }

  final token = adminToken!;
  for (var i = 0; i < seedCategories.length; i++) {
    await _create('categories/${i + 1}', {
      'id': i + 1,
      'name': seedCategories[i],
    }, token);
  }
  for (var i = 0; i < seedProducts.length; i++) {
    final p = seedProducts[i];
    await _create('products/${i + 1}', {
      'id': i + 1,
      'categoryId': p[0],
      'name': p[1],
      'description': p[2],
      'price': p[3],
      'imageUrl': p[4],
      'status': 'available',
      'deleted': false,
    }, token);
  }
  var toppingId = 0;
  for (final entry in seedToppings.entries) {
    toppingId++;
    await _create('toppings/$toppingId', {
      'id': toppingId,
      'name': entry.key,
      'price': entry.value,
    }, token);
  }
  // Bộ đếm: lần thêm mới tiếp theo nhận số kế tiếp; đơn hàng bắt đầu từ #1
  final counters = {
    'categories': seedCategories.length,
    'products': seedProducts.length,
    'toppings': seedToppings.length,
    'orders': 0,
  };
  for (final entry in counters.entries) {
    await _create('counters/${entry.key}', {'value': entry.value}, token);
  }

  _http.close();
  stdout.writeln('Xong.');
}

// Tạo tài khoản; đã có thì đăng nhập. Trả về uid + idToken để gọi Firestore.
Future<({String uid, String token})> _signUpOrIn(
  String email,
  String password,
) async {
  final body = {
    'email': email,
    'password': password,
    'returnSecureToken': true,
  };
  var res = await _send('POST', _authUrl('signUp'), body);
  if (res.status != 200 && _errorMessage(res.json) == 'EMAIL_EXISTS') {
    res = await _send('POST', _authUrl('signInWithPassword'), body);
    stdout.writeln('Tài khoản $email đã có, đăng nhập lại');
  } else if (res.status == 200) {
    stdout.writeln('Đã tạo tài khoản $email');
  }
  if (res.status != 200) {
    throw StateError('Firebase Auth lỗi với $email: ${_errorMessage(res.json)}');
  }
  return (
    uid: res.json['localId'] as String,
    token: res.json['idToken'] as String,
  );
}

// Tạo document nếu chưa có (precondition currentDocument.exists=false)
Future<void> _create(
  String path,
  Map<String, Object?> data,
  String token,
) async {
  final url = Uri.parse(
    'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents/$path'
    '?currentDocument.exists=false',
  );
  final res = await _send('PATCH', url, {
    'fields': data.map((key, value) => MapEntry(key, _value(value))),
  }, token: token);
  if (res.status == 200) {
    stdout.writeln('  + $path');
  } else if (res.status == 409 ||
      _errorMessage(res.json).contains('already exists') ||
      res.json['error']?['status'] == 'FAILED_PRECONDITION') {
    stdout.writeln('  = $path (đã có, giữ nguyên)');
  } else {
    throw StateError('Ghi $path lỗi ${res.status}: ${_errorMessage(res.json)}');
  }
}

// Định dạng giá trị theo REST API của Firestore
Map<String, Object> _value(Object? value) => switch (value) {
  int v => {'integerValue': '$v'},
  bool v => {'booleanValue': v},
  _ => {'stringValue': '$value'},
};

Uri _authUrl(String action) => Uri.parse(
  'https://identitytoolkit.googleapis.com/v1/accounts:$action?key=$_apiKey',
);

String _errorMessage(Map<String, dynamic> json) =>
    (json['error']?['message'] as String?) ?? '';

Future<({int status, Map<String, dynamic> json})> _send(
  String method,
  Uri url,
  Map<String, Object?> body, {
  String? token,
}) async {
  final request = await _http.openUrl(method, url);
  request.headers.contentType = ContentType.json;
  if (token != null) request.headers.set('Authorization', 'Bearer $token');
  request.add(utf8.encode(jsonEncode(body)));
  final response = await request.close();
  final text = await response.transform(utf8.decoder).join();
  return (
    status: response.statusCode,
    json: text.isEmpty ? <String, dynamic>{} : jsonDecode(text) as Map<String, dynamic>,
  );
}
