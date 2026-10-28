import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../providers/auth_provider.dart';
import '../../providers/menu_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/brand_block.dart';
import '../../widgets/cart_button.dart';
import '../../widgets/empty_view.dart';
import '../../widgets/product_card.dart';
import '../../widgets/product_image.dart';
import '../../widgets/section_card.dart';
import 'product_detail_screen.dart';

// Tab Menu: khối nâu (lời chào + giỏ hàng + tìm kiếm) + banner + chip danh mục
// + tiêu đề mục in hoa + lưới các món
class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final menu = context.watch<MenuProvider>();
    final products = menu.filteredProducts;
    // select: chỉ build lại khi tên người dùng đổi (sau khi sửa thông tin)
    final userName = context.select<AuthProvider, String>(
      (auth) => auth.currentUser?.name ?? '',
    );
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    // Điện thoại: khối nâu nối lên tận thanh trạng thái. Màn có thanh trái
    // (từ 600px) thì không, vì icon trạng thái nằm cả trên thanh trái màu sáng
    final phone = MediaQuery.sizeOf(context).width < 600;

    if (menu.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Tiêu đề mục: danh mục đang chọn, hoặc "Tất cả món"
    final selectedId = menu.selectedCategoryId;
    final sectionTitle = selectedId == null
        ? 'Tất cả món'
        : menu.categories.firstWhere((c) => c.id == selectedId).name;

    return Scaffold(
      // AppBar cao 0 = dải dưới thanh trạng thái, đứng yên khi cuộn; nền đậm
      // thì AppBar tự cho icon trạng thái màu sáng
      appBar: AppBar(
        toolbarHeight: 0,
        scrolledUnderElevation: 0,
        backgroundColor: phone ? colors.onPrimaryFixedVariant : null,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Responsive (Module 6): mỗi thẻ rộng tối đa 280px nên số cột tăng
          // theo bề rộng thật của vùng nội dung (ít nhất 2 cột trên điện thoại)
          final gridWidth = constraints.maxWidth - 32; // lề 16 hai bên
          final columns = max(2, (gridWidth / 280).ceil());
          final tileWidth = (gridWidth - (columns - 1) * 12) / columns;

          return CustomScrollView(
            slivers: [
              // Khối nâu: lời chào + nút giỏ hàng + ô tìm kiếm
              SliverToBoxAdapter(
                child: BrandBlock(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 8, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // textTheme của màn (ngoài khối) -> tự đặt màu sáng
                                  Text(
                                    'Xin chào, $userName',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: textTheme.bodyLarge
                                        ?.copyWith(color: colors.primaryFixedDim),
                                  ),
                                  Text(
                                    'Hôm nay bạn muốn uống gì?',
                                    style: textTheme.headlineSmall
                                        ?.copyWith(color: colors.primaryFixed),
                                  ),
                                ],
                              ),
                            ),
                            const CartButton(),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _SearchField(menu: menu),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: _MenuBanner()),

              // Danh mục: cuộn ngang, mỗi chip có icon. Mục 0 là "Tất cả"
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 64,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: menu.categories.length + 1,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 8),
                    itemBuilder: (context, index) => _buildCategoryChip(
                      menu,
                      colors,
                      index == 0 ? null : menu.categories[index - 1],
                    ),
                  ),
                ),
              ),

              // Tiêu đề mục in hoa + số món đang hiện
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: Row(
                    children: [
                      Expanded(child: SectionHeader(sectionTitle)),
                      Text(
                        '${products.length} món',
                        style: textTheme.bodyMedium
                            ?.copyWith(color: colors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),

              // Lưới các món
              if (products.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyView(
                    icon: Icons.search_off,
                    message: 'Không tìm thấy món nào',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverGrid.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      // Ảnh vuông + phần chữ cao theo cỡ chữ của máy -> không tràn
                      // (116 = lề + chữ + nút + của ProductCard)
                      mainAxisExtent: tileWidth +
                          MediaQuery.textScalerOf(context).scale(116),
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return ProductCard(
                        key: ValueKey(product.id),
                        product: product,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ProductDetailScreen(product: product),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // category = null -> chip "Tất cả"
  Widget _buildCategoryChip(
    MenuProvider menu,
    ColorScheme colors,
    MenuCategory? category,
  ) {
    final selected = menu.selectedCategoryId == category?.id;
    return ChoiceChip(
      // Icon cùng màu chữ của chip (theme chỉ đổi màu chữ theo trạng thái chọn)
      avatar: Icon(
        category == null ? Icons.apps : categoryIcon(category.id),
        size: 18,
        color: selected ? colors.onPrimary : colors.primary,
      ),
      label: Text(category?.name ?? 'Tất cả'),
      selected: selected,
      onSelected: (_) => menu.selectCategory(category?.id),
    );
  }
}

// Ô tìm kiếm sáng màu đặt trên khối nâu: tự đặt màu chữ, gợi ý, icon, con trỏ
// và viền khi đang nhập bằng cặp màu Fixed (giống nhau ở chế độ sáng và tối)
class _SearchField extends StatelessWidget {
  final MenuProvider menu;

  const _SearchField({required this.menu});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return TextFormField(
      initialValue: menu.searchText,
      onChanged: menu.search,
      textInputAction: TextInputAction.search,
      style: TextStyle(color: colors.onPrimaryFixed),
      cursorColor: colors.onPrimaryFixed,
      decoration: InputDecoration(
        hintText: 'Tìm món...',
        hintStyle: TextStyle(color: colors.onPrimaryFixedVariant),
        prefixIcon: const Icon(Icons.search),
        prefixIconColor: colors.onPrimaryFixedVariant,
        fillColor: colors.primaryFixed,
        focusedBorder: UnderlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(28)),
          borderSide: BorderSide(color: colors.onPrimaryFixedVariant, width: 2),
        ),
      ),
    );
  }
}

// Banner đầu trang. Chỉ hiện khi có file ảnh: thiếu file thì errorBuilder
// trả về khung rỗng (frameBuilder chỉ chạy khi tải được ảnh).
class _MenuBanner extends StatelessWidget {
  const _MenuBanner();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Image.asset(
      'assets/images/banner/hero.jpg',
      // Cao bằng banner, neo bên phải: 4 ly ở phải, bên trái để chữ
      fit: BoxFit.fitHeight,
      alignment: Alignment.centerRight,
      excludeFromSemantics: true,
      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
      frameBuilder: (context, image, frame, wasSynchronouslyLoaded) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            // primaryFixed / onPrimaryFixed giống nhau ở sáng và tối, hợp với
            // nền hồng đào của ảnh -> chữ luôn đủ tương phản
            child: ColoredBox(
              color: colors.primaryFixed,
              child: Stack(
                children: [
                  Positioned.fill(child: image),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            colors.primaryFixed,
                            colors.primaryFixed.withValues(alpha: 0),
                          ],
                          stops: const [0.4, 0.75],
                        ),
                      ),
                    ),
                  ),
                  Container(
                    constraints: const BoxConstraints(minHeight: 168),
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.all(20),
                    child: FractionallySizedBox(
                      widthFactor: 0.55,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mát lạnh mỗi ngày'.toUpperCase(),
                            style: textTheme.titleLarge?.copyWith(
                              color: colors.onPrimaryFixed,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Cà phê, trà sữa, trà trái cây và đá xay pha tươi tại $shopName',
                            style: textTheme.bodyMedium
                                ?.copyWith(color: colors.onPrimaryFixedVariant),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
