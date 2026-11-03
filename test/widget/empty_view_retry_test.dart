import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shop_app/utils/motion.dart';
import 'package:shop_app/widgets/empty_view.dart';

void main() {
  testWidgets('Màn lỗi có nút "Thử lại", bấm thì gọi lại hàm tải', (
    tester,
  ) async {
    var retried = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmptyView(
            icon: Icons.cloud_off,
            message: 'Không tải được menu.',
            onRetry: () => retried++,
          ),
        ),
      ),
    );

    expect(find.text('Không tải được menu.'), findsOneWidget);
    await tester.tap(find.text('Thử lại'));
    expect(retried, 1);
  });

  testWidgets('Màn trống bình thường không có nút "Thử lại"', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EmptyView(
            icon: Icons.receipt_long,
            message: 'Bạn chưa có đơn hàng nào',
          ),
        ),
      ),
    );

    expect(find.text('Bạn chưa có đơn hàng nào'), findsOneWidget);
    expect(find.text('Thử lại'), findsNothing);
  });

  testWidgets('Bật "Tắt hiệu ứng" thì thời lượng hiệu ứng = 0', (tester) async {
    late Duration normal;
    late Duration reduced;
    Widget probe(bool disable, void Function(Duration) save) => MediaQuery(
      data: MediaQueryData(disableAnimations: disable),
      child: Builder(
        builder: (context) {
          save(motionDuration(context));
          return const SizedBox();
        },
      ),
    );

    await tester.pumpWidget(probe(false, (d) => normal = d));
    await tester.pumpWidget(probe(true, (d) => reduced = d));

    expect(normal, const Duration(milliseconds: 200));
    expect(reduced, Duration.zero);
  });

  testWidgets('Màn lọc rỗng có thể đổi nhãn nút hành động', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: EmptyView(
          icon: Icons.search_off,
          message: 'Không tìm thấy đơn phù hợp',
          onRetry: () {},
          retryLabel: 'Xóa bộ lọc',
        ),
      ),
    );

    expect(find.text('Xóa bộ lọc'), findsOneWidget);
    expect(find.text('Thử lại'), findsNothing);
  });
}
