import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/validators.dart';
import '../../widgets/max_width_box.dart';
import '../../widgets/section_card.dart';

// Chỉnh sửa thông tin cá nhân: họ tên, số điện thoại, (tùy chọn) đổi mật khẩu
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmController = TextEditingController();
  late final String _email;
  bool _changePassword = false; // bật Switch mới hiện các ô đổi mật khẩu
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Điền sẵn thông tin hiện tại
    final user = context.read<AuthProvider>().currentUser!;
    _nameController.text = user.name;
    _phoneController.text = user.phone;
    _email = user.email;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final error = await context.read<AuthProvider>().updateProfile(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          // Không bật đổi mật khẩu -> truyền null để giữ mật khẩu cũ
          currentPassword:
              _changePassword ? _currentPasswordController.text : null,
          newPassword: _changePassword ? _newPasswordController.text : null,
        );
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      final colors = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error, style: TextStyle(color: colors.onError)),
          backgroundColor: colors.error,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã lưu thông tin')),
    );
    Navigator.pop(context);
  }

  // Ô mật khẩu dùng chung cho 3 ô ở phần đổi mật khẩu
  InputDecoration _passwordDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      suffixIcon: IconButton(
        tooltip: _obscurePassword ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
        icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chỉnh sửa thông tin')),
      // Chạm ra ngoài thì ẩn bàn phím
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: MaxWidthBox(
            maxWidth: 560,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SectionCard(
                  title: 'Thông tin cá nhân',
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Column(
                      children: [
                        // Email dùng để đăng nhập nên chỉ cho xem, không cho sửa
                        TextFormField(
                          initialValue: _email,
                          enabled: false,
                          decoration: const InputDecoration(
                            labelText: 'Email (không thể đổi)',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _nameController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Họ tên',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: validateName,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Số điện thoại',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                          validator: validatePhone,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                SectionCard(
                  child: Column(
                    children: [
                      SwitchListTile(
                        secondary: const Icon(Icons.lock_reset),
                        title: const Text('Đổi mật khẩu'),
                        value: _changePassword,
                        onChanged: (value) =>
                            setState(() => _changePassword = value),
                      ),

                      // Chỉ hiện khi bật Switch "Đổi mật khẩu"
                      if (_changePassword)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _currentPasswordController,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.next,
                                decoration: _passwordDecoration(
                                    'Mật khẩu hiện tại', Icons.lock_outline),
                                validator: (value) =>
                                    (value == null || value.isEmpty)
                                        ? 'Vui lòng nhập mật khẩu hiện tại'
                                        : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _newPasswordController,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.next,
                                decoration: _passwordDecoration(
                                    'Mật khẩu mới', Icons.lock),
                                validator: (value) {
                                  final error = validatePassword(value);
                                  if (error != null) return error;
                                  if (value == _currentPasswordController.text) {
                                    return 'Mật khẩu mới phải khác mật khẩu hiện tại';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _confirmController,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.done,
                                decoration: _passwordDecoration(
                                    'Nhập lại mật khẩu mới', Icons.lock),
                                validator: (value) =>
                                    value != _newPasswordController.text
                                        ? 'Mật khẩu nhập lại không khớp'
                                        : null,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  height: 56,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _save,
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : const Text('Lưu thay đổi'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
