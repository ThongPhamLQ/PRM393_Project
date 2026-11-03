import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../screens/customer/cart_screen.dart';
import '../utils/format.dart';
import '../utils/motion.dart';

void _openCart(BuildContext context) => Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const CartScreen()),
);

// Icon giỏ hàng trên AppBar, có số lượng món (Badge).
// Dùng Selector: chỉ vẽ lại khi số lượng thay đổi (Module 12 - tối ưu rebuild)
class CartButton extends StatelessWidget {
  const CartButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<CartProvider, int>(
      selector: (context, cart) => cart.itemCount,
      builder: (context, count, child) {
        return IconButton(
          tooltip: 'Giỏ hàng',
          icon: CartBadge(count: count, child: const Icon(Icons.shopping_cart)),
          onPressed: () => _openCart(context),
        );
      },
    );
  }
}

// Icon giỏ + số ly. Số ly tăng (vừa thêm món) thì nảy lên 1 nhịp:
// phóng 1 -> 1.2 -> 1 trong 180 ms. Bật "Tắt hiệu ứng" thì không nảy.
class CartBadge extends StatefulWidget {
  final int count;
  final Widget child;

  const CartBadge({super.key, required this.count, required this.child});

  @override
  State<CartBadge> createState() => _CartBadgeState();
}

class _CartBadgeState extends State<CartBadge>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
  );
  late final _scale = TweenSequence([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 1),
    TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 1),
  ]).animate(CurvedAnimation(parent: _controller, curve: motionCurve));

  @override
  void didUpdateWidget(CartBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.count > oldWidget.count &&
        !MediaQuery.disableAnimationsOf(context)) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Badge(
        isLabelVisible: widget.count > 0,
        label: Text('${widget.count}'),
        child: widget.child,
      ),
    );
  }
}

// Nút giỏ nổi ở tab Menu: "Xem giỏ · 135.000 đ". Luôn trong tầm tay khi cuộn
// (nút giỏ ở khối nâu cuộn mất). Giỏ trống thì thu nhỏ biến mất.
class CartFab extends StatelessWidget {
  const CartFab({super.key});

  @override
  Widget build(BuildContext context) {
    // Record (số ly, tổng tiền): Selector so sánh bằng == nên chỉ build lại khi 1 trong 2 đổi
    return Selector<CartProvider, (int, int)>(
      selector: (context, cart) => (cart.itemCount, cart.totalPrice),
      builder: (context, cart, child) {
        final (count, total) = cart;
        final hidden = count == 0;
        return IgnorePointer(
          ignoring: hidden,
          child: ExcludeSemantics(
            excluding: hidden,
            child: AnimatedScale(
              scale: hidden ? 0 : 1,
              duration: motionDuration(context),
              curve: motionCurve,
              child: FloatingActionButton.extended(
                heroTag: null, // tránh trùng Hero với nút nổi của màn khác
                onPressed: () => _openCart(context),
                icon: CartBadge(
                  count: count,
                  child: const Icon(Icons.shopping_bag_outlined),
                ),
                label: Text('Xem giỏ · ${formatVnd(total)}'),
              ),
            ),
          ),
        );
      },
    );
  }
}
