import 'package:flutter/material.dart';

import '../models/order.dart';
import '../utils/format.dart';

// Hộp thoại thanh toán GIẢ LẬP (không kết nối cổng thanh toán thật).
// Trả về true nếu "thanh toán thành công", false nếu khách bấm Hủy.
class FakePaymentDialog extends StatefulWidget {
  final PaymentMethod method;
  final int amount;

  const FakePaymentDialog({
    super.key,
    required this.method,
    required this.amount,
  });

  @override
  State<FakePaymentDialog> createState() => _FakePaymentDialogState();
}

class _FakePaymentDialogState extends State<FakePaymentDialog> {
  bool _isProcessing = false;

  Future<void> _pay() async {
    setState(() => _isProcessing = true);
    // Giả lập thời gian chờ cổng thanh toán xử lý
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final isMomo = widget.method == PaymentMethod.momo;

    return AlertDialog(
      title: Text(widget.method.label),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isMomo ? Icons.qr_code_2 : Icons.credit_card, size: 100),
          Text(
            isMomo
                ? 'Quét mã QR bằng ứng dụng MoMo'
                : 'Thẻ: **** **** **** 1234',
          ),
          const SizedBox(height: 8),
          Text(
            'Số tiền: ${formatVnd(widget.amount)}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          if (_isProcessing) ...[
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
            const SizedBox(height: 8),
            const Text('Đang xử lý thanh toán...'),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.pop(context, false),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: _isProcessing ? null : _pay,
          child: const Text('Thanh toán'),
        ),
      ],
    );
  }
}
