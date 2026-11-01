import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/product_management_provider.dart';
import '../../repositories/product_management_repository.dart';

class AdminProductEditorScreen extends StatefulWidget {
  const AdminProductEditorScreen({super.key, this.product});
  final ManagedProduct? product;

  @override
  State<AdminProductEditorScreen> createState() =>
      _AdminProductEditorScreenState();
}

class _AdminProductEditorScreenState extends State<AdminProductEditorScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _price;
  late final TextEditingController _imageUrl;
  int? _categoryId;
  ProductSaleStatus _status = ProductSaleStatus.available;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _name = TextEditingController(text: p?.name ?? '');
    _description = TextEditingController(text: p?.description ?? '');
    _price = TextEditingController(text: p?.price.toString() ?? '');
    _imageUrl = TextEditingController(text: p?.imageUrl ?? '');
    _categoryId = p?.categoryId;
    _status = p?.status ?? ProductSaleStatus.available;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _price.dispose();
    _imageUrl.dispose();
    super.dispose();
  }

  String? _validatePrice(String? text) {
    final value = int.tryParse((text ?? '').trim());
    if (value == null) return 'Nhập giá dạng số nguyên (VND).';
    return ProductInputRules.validatePrice(value);
  }

  Future<void> _submit() async {
    if (_saving || !_form.currentState!.validate()) return;
    if (_categoryId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vui lòng chọn danh mục.')));
      return;
    }
    setState(() => _saving = true);
    try {
      await context.read<ProductManagementProvider>().saveProduct(
        id: widget.product?.id,
        categoryId: _categoryId!,
        name: _name.text,
        description: _description.text,
        price: int.parse(_price.text.trim()),
        imageUrl: _imageUrl.text,
        status: _status,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Không lưu được sản phẩm: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<ProductManagementProvider>().categories;
    final validCategory = categories.any((c) => c.id == _categoryId);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'Thêm đồ uống' : 'Sửa đồ uống'),
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              maxLength: 100,
              decoration: const InputDecoration(
                labelText: 'Tên đồ uống *',
                border: OutlineInputBorder(),
              ),
              validator: (v) => ProductInputRules.validateName(v ?? ''),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: validCategory ? _categoryId : null,
              decoration: const InputDecoration(
                labelText: 'Danh mục *',
                border: OutlineInputBorder(),
              ),
              items: categories
                  .map(
                    (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _categoryId = value),
              validator: (v) => v == null ? 'Chọn danh mục.' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _price,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Giá size S (VND) *',
                border: OutlineInputBorder(),
              ),
              validator: _validatePrice,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Mô tả',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _imageUrl,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'URL ảnh (không bắt buộc)',
                border: OutlineInputBorder(),
              ),
              validator: (v) => ProductInputRules.validateImageUrl(v ?? ''),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ProductSaleStatus>(
              value: _status,
              decoration: const InputDecoration(
                labelText: 'Tình trạng kinh doanh',
                border: OutlineInputBorder(),
              ),
              items: ProductSaleStatus.values
                  .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _status = v);
              },
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _saving ? null : _submit,
              icon: const Icon(Icons.save_outlined),
              label: Text(_saving ? 'Đang lưu...' : 'Lưu sản phẩm'),
            ),
          ],
        ),
      ),
    );
  }
}
