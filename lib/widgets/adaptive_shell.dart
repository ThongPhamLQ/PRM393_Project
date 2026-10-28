import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'max_width_box.dart';

// Khung điều hướng responsive, dùng chung cho khách hàng và chủ quán (Module 6):
// - Dưới 600px (điện thoại): NavigationBar ở đáy
// - 600 - 1024px (tablet, cửa sổ hẹp): NavigationRail bên trái
// - Từ 1024px (Chrome màn hình rộng): NavigationRail mở rộng có chữ,
//   nội dung căn giữa, rộng tối đa 1200px
class AdaptiveShell extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final List<NavigationDestination> destinations;
  final Widget body;
  final PreferredSizeWidget? appBar;

  const AdaptiveShell({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    required this.destinations,
    required this.body,
    this.appBar,
  });

  @override
  Widget build(BuildContext context) {
    // LayoutBuilder thay vì MediaQuery: chọn bố cục theo đúng bề rộng được cấp.
    // Màn này bị route khác che mà cửa sổ Chrome đổi cỡ thì vẫn khớp, không bị bóp.
    return LayoutBuilder(
      builder: (context, constraints) => _buildLayout(context, constraints.maxWidth),
    );
  }

  Widget _buildLayout(BuildContext context, double width) {
    final useRail = width >= 600;
    final extended = width >= 1024;
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: appBar,
      bottomNavigationBar: useRail
          ? null
          : NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: onSelected,
              destinations: destinations,
            ),
      body: Row(
        children: [
          if (useRail)
            NavigationRail(
              extended: extended,
              // Rail mở rộng có chữ cạnh icon; rail thu gọn hiện chữ dưới icon
              labelType: extended
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.all,
              scrollable: true, // màn hình thấp (điện thoại xoay ngang) vẫn cuộn được
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_cafe, color: colors.primary),
                    if (extended) ...[
                      const SizedBox(width: 12),
                      // Flexible: lúc rail đang giãn ra, chữ thu lại thay vì tràn
                      Flexible(
                        child: Text(
                          shopName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: colors.primary),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              selectedIndex: selectedIndex,
              onDestinationSelected: onSelected,
              destinations: [
                for (final d in destinations)
                  NavigationRailDestination(
                    icon: d.icon,
                    selectedIcon: d.selectedIcon,
                    label: Text(d.label),
                  ),
              ],
            ),
          // key: chuyển qua lại thanh dưới / thanh trái vẫn giữ nguyên trạng thái tab
          Expanded(
            key: const ValueKey('content'),
            child: MaxWidthBox(child: body),
          ),
        ],
      ),
    );
  }
}
