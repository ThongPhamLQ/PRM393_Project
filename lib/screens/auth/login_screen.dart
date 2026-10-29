import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';
import '../../widgets/brand_block.dart';
import '../../widgets/max_width_box.dart';
import '../../widgets/section_card.dart';

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
      final colors = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error, style: TextStyle(color: colors.onError)),
          backgroundColor: colors.error,
        ),
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
    final textTheme = Theme.of(context).textTheme;
    // Màn rộng (Chrome, tablet ngang): ảnh quán bên trái, form bên phải
    final wide = MediaQuery.sizeOf(context).width >= 900;

    // Thẻ trắng chứa form. Chip tài khoản demo nằm ngay dưới nút Đăng nhập
    // (widget test bấm chip trong khung 800x600 nên chip phải ở nửa trên)
    final formCard = Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionHeader('Đăng nhập'),
              const SizedBox(height: 16),

              // Ô Email
              TextFormField(
                controller: _emailController,
                enabled: !_isLoading,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
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
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    tooltip: _obscurePassword ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                    icon: Icon(_obscurePassword
                        ? Icons.visibility
                        : Icons.visibility_off),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: validatePassword,
              ),
              const SizedBox(height: 24),

              // Nút Đăng nhập: loading hiển thị ngay trong nút
              SizedBox(
                height: 56,
                child: FilledButton(
                  key: const Key('loginButton'), // dùng cho widget test
                  onPressed: _isLoading ? null : _handleLogin,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : const Text('Đăng nhập'),
                ),
              ),
              const SizedBox(height: 16),

              // Tài khoản demo
              Text(
                'Tài khoản demo:',
                textAlign: TextAlign.center,
                style:
                    textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.center,
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
    );

    final formColumn = MaxWidthBox(
      maxWidth: 420,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          formCard,
          const SizedBox(height: 8),
          TextButton(
            onPressed: _isLoading
                ? null
                : () => Navigator.pushNamed(context, '/register'),
            child: const Text('Chưa có tài khoản? Đăng ký ngay'),
          ),
        ],
      ),
    );

    return Scaffold(
      // AppBar cao 0 = dải dưới thanh trạng thái, đứng yên khi cuộn.
      // Điện thoại: cùng màu khối nâu -> AppBar tự cho icon trạng thái màu sáng
      appBar: AppBar(
        toolbarHeight: 0,
        scrolledUnderElevation: 0,
        backgroundColor: wide ? null : colors.onPrimaryFixedVariant,
      ),
      body: SafeArea(
        child: wide
            ? Row(
                children: [
                  const Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: _HeroPanel(),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: formColumn,
                      ),
                    ),
                  ),
                ],
              )
            // Điện thoại: dải nâu (logo + tên quán) rồi thẻ form trên nền kem
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    BrandBlock(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                        child: Column(
                          children: [
                            ExcludeSemantics(
                              child: CircleAvatar(
                                radius: 32,
                                backgroundColor: colors.primaryFixed,
                                foregroundColor: colors.onPrimaryFixedVariant,
                                child: const Icon(Icons.local_cafe, size: 36),
                              ),
                            ),
                            const SizedBox(height: 12),
                            // textTheme của màn (ngoài khối) -> tự đặt màu sáng
                            Text(
                              shopName.toUpperCase(),
                              textAlign: TextAlign.center,
                              style: textTheme.titleLarge?.copyWith(
                                color: colors.primaryFixed,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Đăng nhập để đặt món yêu thích',
                              textAlign: TextAlign.center,
                              style: textTheme.bodyMedium
                                  ?.copyWith(color: colors.primaryFixedDim),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: formColumn,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

// Ảnh banner + tên quán bên trái màn đăng nhập (chỉ hiện ở màn rộng)
class _HeroPanel extends StatelessWidget {
  const _HeroPanel();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/banner/hero.jpg',
            fit: BoxFit.cover,
            alignment: Alignment.centerRight, // 4 ly nằm ở bên phải ảnh
            excludeFromSemantics: true,
            // Thiếu file -> chỉ còn nền màu
            errorBuilder: (context, error, stackTrace) =>
                ColoredBox(color: colors.primaryContainer),
          ),
          // Khung chữ là khối nâu đặc -> chữ luôn đủ tương phản trên ảnh
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: BrandBlock(
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shopName.toUpperCase(),
                        style: textTheme.headlineSmall?.copyWith(
                          color: colors.primaryFixed,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Cà phê, trà sữa, trà trái cây và đá xay',
                        style: textTheme.bodyLarge
                            ?.copyWith(color: colors.primaryFixedDim),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
