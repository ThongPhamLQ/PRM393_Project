import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/cart_item.dart';

import '../../models/order.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../utils/format.dart';
import '../../utils/validators.dart';
import '../../widgets/fake_payment_dialog.dart';
import '../../widgets/max_width_box.dart';
import '../../widgets/product_image.dart';
import '../../widgets/section_card.dart';
import '../../widgets/total_bar.dart';
import 'order_success_screen.dart';

// Đặt hàng: nhập thông tin nhận hàng + chọn cách thanh toán
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _noteController = TextEditingController();
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Điền sẵn tên + SĐT từ tài khoản
    final user = context.read<AuthProvider>().currentUser!;
    _nameController.text = user.name;
    _phoneController.text = user.phone;
    // Nhớ địa chỉ: lấy địa chỉ của đơn gần nhất (danh sách đã sắp mới nhất lên đầu)
    _addressController.text =
        context.read<OrderProvider>().orders.firstOrNull?.address ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (_isLoading) return; // Chặn nhấn đúp, kể cả khi đang mở dialog.
    if (!_formKey.currentState!.validate()) return;

    final cart = context.read<CartProvider>();
    if (cart.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Giỏ hàng đang trống.')));
      return;
    }
    final orderProvider = context.read<OrderProvider>();
    final user = context.read<AuthProvider>().currentUser!;
    // Snapshot để tổng tiền và món lưu khớp với thời điểm bắt đầu checkout.
    final items = cart.items
        .map(
          (item) => CartItem(
            product: item.product,
            size: item.size,
            toppings: List.of(item.toppings),
            sugar: item.sugar,
            ice: item.ice,
            note: item.note,
            quantity: item.quantity,
          ),
        )
        .toList();
    final amount = items.fold<int>(0, (sum, item) => sum + item.totalPrice);
    final paymentMethod = _paymentMethod;
    setState(() => _isLoading = true);
    bool orderSaved = false;
    try {
      if (paymentMethod != PaymentMethod.cash) {
        final paid = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (_) =>
              FakePaymentDialog(method: paymentMethod, amount: amount),
        );
        if (!mounted || paid != true) return;
      }

      final orderId = await orderProvider.placeOrder(
        user: user,
        cartItems: items,
        customerName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        note: _noteController.text.trim(),
        paymentMethod: paymentMethod,
      );
      orderSaved = true;
      cart.clear(); // Không thể gửi lại đơn vì lỗi thông báo hoặc đóng dialog.
      // Badge thông báo tự tăng: NotificationProvider đang nghe Firestore
      if (!mounted) return;
      // Sang màn thành công, bỏ Giỏ hàng + Đặt hàng khỏi ngăn xếp:
      // bấm quay lại từ màn thành công là về thẳng Menu
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => OrderSuccessScreen(
            orderId: orderId,
            total: amount,
            paymentMethod: paymentMethod,
          ),
        ),
        (route) => route.isFirst,
      );
    } catch (e) {
      debugPrint('Checkout failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              orderSaved
                  ? 'Đơn đã được lưu nhưng có lỗi khi hiển thị kết quả. Hãy kiểm tra lịch sử đơn.'
                  : 'Không thể lưu đơn hàng. Vui lòng thử lại.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Topping + mức đường/đá của 1 món, VD: "Trân châu đen · Đường 70% · Ít đá"
  String _itemDetails(CartItem item) => [
    if (item.toppings.isNotEmpty) item.toppingNames,
    formatSugarIce(item.sugar, item.ice),
  ].where((s) => s.isNotEmpty).join(' · ');

  // Biểu tượng cho từng phương thức thanh toán của giao diện mới.
  IconData _paymentIcon(PaymentMethod method) {
    switch (method.name.toLowerCase()) {
      case 'cash':
        return Icons.payments_outlined;
      case 'momo':
        return Icons.account_balance_wallet_outlined;
      case 'card':
        return Icons.credit_card_outlined;
      default:
        return Icons.payment_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Đặt hàng')),
      body: Form(
        key: _formKey,
        child: MaxWidthBox(
          maxWidth: 720,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SectionCard(
                title: 'Thông tin nhận hàng',
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Người nhận',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: validateName,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Số điện thoại',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        validator: validatePhone,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _addressController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Địa chỉ giao hàng',
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                        validator: validateAddress,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _noteController,
                        decoration: const InputDecoration(
                          labelText: 'Ghi chú cho quán (không bắt buộc)',
                          prefixIcon: Icon(Icons.edit_note),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              SectionCard(
                title: 'Phương thức thanh toán',
                child: RadioGroup<PaymentMethod>(
                  groupValue: _paymentMethod,
                  onChanged: (value) => setState(() => _paymentMethod = value!),
                  child: Column(
                    children: PaymentMethod.values.map((method) {
                      return RadioListTile<PaymentMethod>(
                        value: method,
                        title: Text(method.label),
                        secondary: Icon(
                          _paymentIcon(method),
                          color: colors.onSurfaceVariant,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              SectionCard(
                title: 'Món đã chọn (${cart.itemCount} ly)',
                child: Column(
                  children: cart.items.map((item) {
                    return ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: ProductImage(
                            product: item.product,
                            iconSize: 24,
                          ),
                        ),
                      ),
                      title: Text(
                        '${item.quantity} x ${item.product.name} (${item.size})',
                      ),
                      subtitle: _itemDetails(item).isEmpty
                          ? null
                          : Text(_itemDetails(item)),
                      trailing: Text(formatVnd(item.totalPrice)),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: TotalBar(
        label: 'Tổng thanh toán',
        amount: cart.totalPrice,
        button: FilledButton(
          onPressed: _isLoading ? null : _placeOrder, // khóa nút khi đang xử lý
          child: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              : const Text('Xác nhận đặt hàng'),
        ),
      ),
    );
  }
}
