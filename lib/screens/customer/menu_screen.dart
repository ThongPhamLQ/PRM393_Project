import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/menu_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/cart_button.dart';
import '../../widgets/empty_view.dart';
import '../../widgets/product_card.dart';
import 'product_detail_screen.dart';

// Tab Menu: tìm kiếm + lọc theo danh mục + lưới các món
class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final menu = context.watch<MenuProvider>();
    final products = menu.filteredProducts;

    // Responsive (Module 6): điện thoại 2 cột, màn hình rộng 4 cột
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width < 600 ? 2 : 4;

    return Scaffold(
      appBar: AppBar(
        title: const Text(shopName),
        actions: const [CartButton()],
      ),
      body: menu.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Ô tìm kiếm
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: TextFormField(
                    initialValue: menu.searchText,
                    onChanged: menu.search,
                    decoration: InputDecoration(
                      hintText: 'Tìm món...',
                      prefixIcon: const Icon(Icons.search),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),

                // Danh mục: cuộn ngang
                SizedBox(
                  height: 56,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    children: [
                      _buildCategoryChip(menu, 'Tất cả', null),
                      ...menu.categories.map(
                        (c) => _buildCategoryChip(menu, c.name, c.id),
                      ),
                    ],
                  ),
                ),

                // Lưới các món
                Expanded(
                  child: products.isEmpty
                      ? const EmptyView(
                          icon: Icons.search_off,
                          message: 'Không tìm thấy món nào',
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(12),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                childAspectRatio: 0.75,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
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
            ),
    );
  }

  Widget _buildCategoryChip(MenuProvider menu, String label, int? categoryId) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: menu.selectedCategoryId == categoryId,
        onSelected: (_) => menu.selectCategory(categoryId),
      ),
    );
  }
}
