import 'package:flutter/material.dart';

// Bộ tăng / giảm số lượng: (−) 2 (+) với 2 nút tròn viền (Chi tiết món, Giỏ hàng).
// Nút vẽ 40px nhưng vùng chạm vẫn 48px (theme: MaterialTapTargetSize.padded).
class QuantityStepper extends StatelessWidget {
  final int quantity;
  final VoidCallback? onDecrease; // null -> khóa nút giảm
  final VoidCallback onIncrease;

  const QuantityStepper({
    super.key,
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.outlined(
          tooltip: 'Giảm số lượng',
          icon: const Icon(Icons.remove),
          onPressed: onDecrease,
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 32),
          child: Text(
            '$quantity',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        IconButton.outlined(
          tooltip: 'Tăng số lượng',
          icon: const Icon(Icons.add),
          onPressed: onIncrease,
        ),
      ],
    );
  }
}
