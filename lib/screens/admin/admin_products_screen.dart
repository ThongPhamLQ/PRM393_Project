import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/product_management_provider.dart';
import '../../repositories/product_management_repository.dart';
import 'admin_product_editor_screen.dart';

/// Opened from the existing AdminOrdersScreen Column; owns its provider.
class AdminProductsScreen extends StatelessWidget {
  const AdminProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final manager = ProductManagementProvider();
        Future.microtask(manager.refresh);
        return manager;
      },
      child: const _AdminProductsBody(),
    );
  }
}

class _AdminProductsBody extends StatefulWidget {
  const _AdminProductsBody();

  @override
  State<_AdminProductsBody> createState() => _AdminProductsBodyState();
}

class _AdminProductsBodyState extends State<_AdminProductsBody> {
  String _search = '';
  ProductSaleStatus? _filter;
  final TextEditingController _searchController = TextEditingController();
  final Set<int> _selectedIds = <int>{};
  bool _multiSelect = false;
  bool _showTrash = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _money(int value) {
    return '${value.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')} ₫';
  }

  Future<void> _editProduct(ManagedProduct? product) async {
    final manager = context.read<ProductManagementProvider>();
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<ProductManagementProvider>.value(
          value: manager,
          child: AdminProductEditorScreen(product: product),
        ),
      ),
    );
  }

  void _message(String text) {
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _setStatus(
    ManagedProduct product,
    ProductSaleStatus status,
  ) async {
    try {
      await context.read<ProductManagementProvider>().setStatus(
        product.id,
        status,
      );
      _message('Đã đổi trạng thái: ${product.name} → ${status.label}');
    } catch (e) {
      _message('Không cập nhật được trạng thái: $e');
    }
  }

  Future<void> _editCategory([ManagedCategory? current]) async {
    final controller = TextEditingController(text: current?.name ?? '');
    final form = GlobalKey<FormState>();
    final manager = context.read<ProductManagementProvider>();
    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(current == null ? 'Thêm danh mục' : 'Sửa danh mục'),
        content: Form(
          key: form,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            maxLength: 100,
            decoration: const InputDecoration(labelText: 'Tên danh mục'),
            validator: (value) => ProductInputRules.validateName(value ?? ''),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate())
                Navigator.pop(dialogContext, true);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    final name = controller.text.trim();
    controller.dispose();
    if (save != true) return;
    try {
      await manager.saveCategory(name, id: current?.id);
      _message('Đã lưu danh mục.');
    } catch (e) {
      _message('Không lưu được danh mục: $e');
    }
  }

  Future<void> _deleteCategory(ManagedCategory category) async {
    final allowed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa danh mục trống?'),
        content: Text(
          'Chỉ xóa "${category.name}" khi không còn sản phẩm, kể cả sản phẩm đã ẩn.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (allowed != true || !mounted) return;
    try {
      await context.read<ProductManagementProvider>().deleteCategory(
        category.id,
      );
      _message('Đã xóa danh mục trống.');
    } catch (e) {
      _message('Không thể xóa: $e');
    }
  }

  Future<void> _editTopping([ManagedTopping? current]) async {
    final name = TextEditingController(text: current?.name ?? '');
    final price = TextEditingController(text: current?.price.toString() ?? '');
    final form = GlobalKey<FormState>();
    final manager = context.read<ProductManagementProvider>();
    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(current == null ? 'Thêm topping' : 'Sửa topping'),
        content: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Tên topping'),
                validator: (v) => ProductInputRules.validateName(v ?? ''),
              ),
              TextFormField(
                controller: price,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Giá (VND)'),
                validator: (v) {
                  final amount = int.tryParse((v ?? '').trim());
                  return amount == null
                      ? 'Giá phải là số nguyên.'
                      : ProductInputRules.validatePrice(
                          amount,
                          allowZero: true,
                        );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate())
                Navigator.pop(dialogContext, true);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    final newName = name.text.trim();
    final newPrice = int.tryParse(price.text.trim());
    name.dispose();
    price.dispose();
    if (save != true || newPrice == null) return;
    try {
      await manager.saveTopping(newName, newPrice, id: current?.id);
      _message('Đã lưu topping.');
    } catch (e) {
      _message('Không lưu được topping: $e');
    }
  }

  Future<void> _deleteTopping(ManagedTopping topping) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa topping?'),
        content: Text(
          'Xóa "${topping.name}" khỏi menu? Các giỏ cũ có topping này sẽ bị từ chối khi checkout.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await context.read<ProductManagementProvider>().deleteTopping(topping.id);
      _message('Đã xóa topping.');
    } catch (e) {
      _message('Không xóa được topping: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<ProductManagementProvider>();
    final visible = (_showTrash ? manager.deletedProducts : manager.products)
        .where(
          (p) =>
              p.name.toLowerCase().contains(_search.toLowerCase()) &&
              (_filter == null || p.status == _filter),
        )
        .toList();
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Quản lý menu'),
          actions: [
            IconButton(
              tooltip: 'Làm mới',
              onPressed: manager.loading ? null : manager.refresh,
              icon: const Icon(Icons.refresh),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Đồ uống'),
              Tab(text: 'Danh mục'),
              Tab(text: 'Topping'),
            ],
          ),
        ),
        body: Column(
          children: [
            if (manager.loading) const LinearProgressIndicator(),
            if (manager.error != null)
              MaterialBanner(
                content: Text('Không thể tải dữ liệu: ${manager.error}'),
                actions: [
                  TextButton(
                    onPressed: manager.refresh,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildProducts(manager, visible),
                  _buildCategories(manager),
                  _buildToppings(manager),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteProducts(
    List<int> ids, {
    required bool allVisible,
  }) async {
    if (ids.isEmpty || !mounted) return;
    final count = ids.length;
    var acceptedRisk = false;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, update) => AlertDialog(
          title: Text(
            allVisible
                ? 'Xóa tất cả $count món đang hiển thị?'
                : 'Xóa $count đồ uống?',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bạn sẽ chuyển $count món vào Thùng rác. '
                'Nếu đang tìm kiếm/lọc, chỉ các món trong kết quả đó bị xóa.',
              ),
              const SizedBox(height: 8),
              const Text(
                'Đơn hàng cũ và doanh thu vẫn được giữ nguyên. '
                'Món đã xóa không thể đặt hàng và có thể khôi phục.',
              ),
              if (allVisible)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Tôi đã kiểm tra đúng danh sách cần xóa'),
                  value: acceptedRisk,
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (value) =>
                      update(() => acceptedRisk = value ?? false),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: allVisible && !acceptedRisk
                  ? null
                  : () => Navigator.pop(dialogContext, true),
              child: Text('Chuyển $count món vào Thùng rác'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      final deleted = await context
          .read<ProductManagementProvider>()
          .softDeleteProducts(ids);
      if (!mounted) return;
      setState(() {
        _selectedIds.clear();
        _multiSelect = false;
      });
      _message('Đã chuyển $deleted món vào Thùng rác.');
    } catch (e) {
      _message('Không xóa được sản phẩm: $e');
    }
  }

  Future<void> _restoreProduct(ManagedProduct product) async {
    try {
      await context.read<ProductManagementProvider>().restoreProduct(
        product.id,
      );
      if (!mounted) return;
      _message('Đã khôi phục ${product.name}.');
    } catch (e) {
      _message('Không khôi phục được: $e');
    }
  }

  void _toggleSelected(int id) {
    setState(() {
      if (!_selectedIds.add(id)) _selectedIds.remove(id);
    });
  }

  void _resetSelection() {
    _selectedIds.clear();
  }

  void _toggleTrash() {
    _searchController.clear();
    setState(() {
      _showTrash = !_showTrash;
      _multiSelect = false;
      _resetSelection();
      _filter = null;
      _search = '';
    });
  }

  Widget _buildProducts(
    ProductManagementProvider manager,
    List<ManagedProduct> visible,
  ) {
    final blocked = manager.saving || manager.loading;
    final visibleIds = visible.map((p) => p.id).toList(growable: false);
    final chosen = ProductDeletionRules.selectedVisibleIds(
      _selectedIds,
      visibleIds,
    );
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Tìm đồ uống...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (text) => setState(() {
              _search = text.trim();
              _resetSelection();
            }),
          ),
        ),
        if (!_showTrash)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('Tất cả'),
                  selected: _filter == null,
                  onSelected: blocked
                      ? null
                      : (_) => setState(() {
                          _filter = null;
                          _resetSelection();
                        }),
                ),
                const SizedBox(width: 8),
                for (final status in ProductSaleStatus.values) ...[
                  ChoiceChip(
                    label: Text(status.label),
                    selected: _filter == status,
                    onSelected: blocked
                        ? null
                        : (_) => setState(() {
                            _filter = status;
                            _resetSelection();
                          }),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (!_showTrash) ...[
                FilledButton.icon(
                  onPressed: blocked || manager.categories.isEmpty
                      ? null
                      : () => _editProduct(null),
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm đồ uống'),
                ),
                OutlinedButton.icon(
                  onPressed: blocked
                      ? null
                      : () => setState(() {
                          _multiSelect = !_multiSelect;
                          _resetSelection();
                        }),
                  icon: Icon(_multiSelect ? Icons.close : Icons.checklist),
                  label: Text(_multiSelect ? 'Thoát chọn' : 'Chọn nhiều'),
                ),
                TextButton.icon(
                  onPressed: blocked || visible.isEmpty
                      ? null
                      : () => _deleteProducts(visibleIds, allVisible: true),
                  icon: const Icon(Icons.delete_sweep_outlined),
                  label: Text('Xóa tất cả (${visible.length})'),
                ),
              ],
              OutlinedButton.icon(
                onPressed: blocked ? null : _toggleTrash,
                icon: Icon(
                  _showTrash
                      ? Icons.arrow_back
                      : Icons.restore_from_trash_outlined,
                ),
                label: Text(
                  _showTrash
                      ? 'Trở về menu'
                      : 'Thùng rác (${manager.deletedProducts.length})',
                ),
              ),
            ],
          ),
        ),
        if (_multiSelect && !_showTrash)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Text('Đã chọn ${chosen.length}/${visible.length}'),
                TextButton(
                  onPressed: blocked || visible.isEmpty
                      ? null
                      : () => setState(() {
                          _selectedIds.addAll(visibleIds);
                        }),
                  child: const Text('Chọn tất cả đang hiển thị'),
                ),
                TextButton(
                  onPressed: blocked || chosen.isEmpty
                      ? null
                      : () => setState(_resetSelection),
                  child: const Text('Bỏ chọn'),
                ),
                FilledButton.tonalIcon(
                  onPressed: blocked || chosen.isEmpty
                      ? null
                      : () => _deleteProducts(chosen, allVisible: false),
                  icon: const Icon(Icons.delete_outline),
                  label: Text('Xóa đã chọn (${chosen.length})'),
                ),
              ],
            ),
          ),
        if (!_showTrash && manager.categories.isEmpty)
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text('Tạo danh mục trước khi thêm đồ uống.'),
          ),
        if (_showTrash)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'Thùng rác: Có thể khôi phục từng món. '
              'Món đã xóa không xuất hiện trong menu khách hàng.',
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: manager.refresh,
            child: visible.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 96),
                      Center(
                        child: Text(
                          _showTrash
                              ? 'Thùng rác đang trống.'
                              : 'Không có đồ uống phù hợp bộ lọc.',
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: visible.length,
                    itemBuilder: (context, i) {
                      final product = visible[i];
                      final categoryName = manager.categories
                          .where((c) => c.id == product.categoryId)
                          .map((c) => c.name)
                          .join();
                      final selected = _selectedIds.contains(product.id);
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: ListTile(
                          key: ValueKey('product-row-${product.id}'),
                          leading: _multiSelect && !_showTrash
                              ? Checkbox(
                                  value: selected,
                                  onChanged: blocked
                                      ? null
                                      : (_) => _toggleSelected(product.id),
                                )
                              : _showTrash
                              ? const Icon(Icons.delete_outline)
                              : null,
                          title: Text(product.name),
                          subtitle: Text(
                            _showTrash
                                ? '$categoryName • ${_money(product.price)}'
                                : '$categoryName • ${_money(product.price)} • ${product.status.label}',
                          ),
                          onTap: blocked || _showTrash
                              ? null
                              : (_multiSelect
                                    ? () => _toggleSelected(product.id)
                                    : () => _editProduct(product)),
                          trailing: _showTrash
                              ? TextButton.icon(
                                  onPressed: blocked
                                      ? null
                                      : () => _restoreProduct(product),
                                  icon: const Icon(Icons.restore),
                                  label: const Text('Khôi phục'),
                                )
                              : _multiSelect
                              ? null
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: 'Xóa ${product.name}',
                                      onPressed: blocked
                                          ? null
                                          : () => _deleteProducts([
                                              product.id,
                                            ], allVisible: false),
                                      icon: const Icon(Icons.delete_outline),
                                    ),
                                    PopupMenuButton<ProductSaleStatus>(
                                      tooltip: 'Đổi trạng thái',
                                      enabled: !blocked,
                                      onSelected: (status) =>
                                          _setStatus(product, status),
                                      itemBuilder: (_) => [
                                        for (final s
                                            in ProductSaleStatus.values)
                                          PopupMenuItem(
                                            value: s,
                                            child: Text(s.label),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategories(ProductManagementProvider manager) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: manager.saving ? null : () => _editCategory(),
              icon: const Icon(Icons.add),
              label: const Text('Thêm danh mục'),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: manager.categories.length,
            itemBuilder: (context, i) {
              final item = manager.categories[i];
              return ListTile(
                title: Text(item.name),
                trailing: Wrap(
                  children: [
                    IconButton(
                      tooltip: 'Sửa',
                      onPressed: () => _editCategory(item),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      tooltip: 'Xóa danh mục trống',
                      onPressed: () => _deleteCategory(item),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildToppings(ProductManagementProvider manager) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: manager.saving ? null : () => _editTopping(),
              icon: const Icon(Icons.add),
              label: const Text('Thêm topping'),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: manager.toppings.length,
            itemBuilder: (context, i) {
              final item = manager.toppings[i];
              return ListTile(
                title: Text(item.name),
                subtitle: Text(_money(item.price)),
                trailing: Wrap(
                  children: [
                    IconButton(
                      tooltip: 'Sửa topping',
                      onPressed: () => _editTopping(item),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      tooltip: 'Xóa topping',
                      onPressed: () => _deleteTopping(item),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
