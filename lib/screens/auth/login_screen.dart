import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // 1. Kiểm tra form, sai thì dừng (lỗi hiện dưới từng ô)
    if (!_formKey.currentState!.validate()) return;

    // 2. Bật loading + khóa nút
    setState(() => _isLoading = true);

    // 3. Gọi AuthProvider đăng nhập
    final auth = context.read<AuthProvider>();
    final error = await auth.login(
      _emailController.text,
      _passwordController.text,
    );
    if (!mounted) return;

    if (error != null) {
      // Sai -> tắt loading + báo lỗi
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
      return;
    }

    // 4. Đúng -> chủ quán vào trang quản lý, khách vào trang chủ
    // pushReplacement: xóa Login khỏi stack, bấm Back không quay lại được
    final route = auth.currentUser!.isAdmin ? '/admin' : '/home';
    Navigator.pushReplacementNamed(context, route);
  }

  // Điền nhanh tài khoản demo (tiện khi demo trước giảng viên)
  void _fillDemoAccount(String email, String password) {
    _emailController.text = email;
    _passwordController.text = password;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Icon(Icons.local_cafe, size: 80, color: colors.primary),
                  const SizedBox(height: 8),
                  const Text(
                    shopName,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 32),

                  // Ô Email
                  TextFormField(
                    controller: _emailController,
                    enabled: !_isLoading,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                    validator: validateEmail,
                  ),
                  const SizedBox(height: 16),

                  // Ô Mật khẩu
                  TextFormField(
                    controller: _passwordController,
                    enabled: !_isLoading,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _handleLogin(),
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu',
                      prefixIcon: const Icon(Icons.lock),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                    validator: validatePassword,
                  ),
                  const SizedBox(height: 24),

                  // Nút Đăng nhập: loading hiển thị ngay trong nút
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      key: const Key('loginButton'), // dùng cho widget test
                      onPressed: _isLoading ? null : _handleLogin,
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              'Đăng nhập',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => Navigator.pushNamed(context, '/register'),
                    child: const Text('Chưa có tài khoản? Đăng ký ngay'),
                  ),
                  const SizedBox(height: 16),

                  // Tài khoản demo
                  const Text(
                    'Tài khoản demo:',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.person, size: 18),
                        label: const Text('Khách hàng'),
                        onPressed: () =>
                            _fillDemoAccount('khach@gmail.com', '123456'),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.store, size: 18),
                        label: const Text('Chủ quán'),
                        onPressed: () =>
                            _fillDemoAccount('admin@cafe.com', 'admin123'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
