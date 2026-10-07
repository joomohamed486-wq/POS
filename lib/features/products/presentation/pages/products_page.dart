
import 'package:flutter/material.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/product_repository.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final repo = ProductRepository();
  final search = TextEditingController();
  List<ProductModel> products = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    final result = await repo.getProducts(query: search.text);
    if (!mounted) return;
    setState(() {
      products = result;
      loading = false;
    });
  }

  Future<void> edit([ProductModel? product]) async {
    await showDialog(
      context: context,
      builder: (_) => ProductDialog(product: product, repo: repo),
    );
    await load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المنتجات'),
        actions: [
          IconButton(onPressed: load, icon: const Icon(Icons.refresh)),
          IconButton(
            onPressed: () => edit(),
            icon: const Icon(Icons.add),
            tooltip: 'إضافة منتج',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => edit(),
        icon: const Icon(Icons.add),
        label: const Text('منتج جديد'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: search,
              onChanged: (_) => load(),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'بحث باسم المنتج أو الباركود',
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : products.isEmpty
                      ? const Center(child: Text('لا توجد منتجات'))
                      : ListView.separated(
                          itemCount: products.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, i) {
                            final p = products[i];
                            return Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  child: Icon(
                                    p.isLowStock
                                        ? Icons.warning_amber_rounded
                                        : Icons.inventory_2_outlined,
                                  ),
                                ),
                                title: Text(
                                  p.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  'باركود: ${p.barcode ?? '-'}\n'
                                  'تكلفة: ${p.costPrice.toStringAsFixed(2)} ج.م  •  '
                                  'بيع: ${p.sellingPrice.toStringAsFixed(2)} ج.م',
                                ),
                                isThreeLine: true,
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${p.stockQuantity.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: p.isLowStock ? Colors.orange : Colors.indigo,
                                      ),
                                    ),
                                    const Text('المخزون'),
                                  ],
                                ),
                                onTap: () => edit(p),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProductDialog extends StatefulWidget {
  final ProductModel? product;
  final ProductRepository repo;

  const ProductDialog({
    super.key,
    required this.product,
    required this.repo,
  });

  @override
  State<ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<ProductDialog> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController name;
  late final TextEditingController barcode;
  late final TextEditingController cost;
  late final TextEditingController price;
  late final TextEditingController stock;
  late final TextEditingController threshold;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    name = TextEditingController(text: p?.name ?? '');
    barcode = TextEditingController(text: p?.barcode ?? '');
    cost = TextEditingController(text: p?.costPrice.toString() ?? '');
    price = TextEditingController(text: p?.sellingPrice.toString() ?? '');
    stock = TextEditingController(text: p?.stockQuantity.toString() ?? '0');
    threshold = TextEditingController(
      text: p?.lowStockThreshold.toString() ?? '5',
    );
  }

  double number(TextEditingController c) =>
      double.tryParse(c.text.replaceAll(',', '.')) ?? 0;

  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => saving = true);

    try {
      await widget.repo.save(
        id: widget.product?.id,
        name: name.text,
        barcode: barcode.text,
        costPrice: number(cost),
        sellingPrice: number(price),
        stockQuantity: number(stock),
        lowStockThreshold: number(threshold),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر الحفظ: $e')),
      );
      setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.product != null;

    return AlertDialog(
      title: Text(editing ? 'تعديل المنتج' : 'إضافة منتج'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'اسم المنتج'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'اكتب اسم المنتج' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: barcode,
                  decoration: const InputDecoration(labelText: 'الباركود'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: cost,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'سعر التكلفة'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: price,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'سعر البيع'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: stock,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'الكمية'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: threshold,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'حد التنبيه'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: saving ? null : () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton.icon(
          onPressed: saving ? null : save,
          icon: saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save),
          label: const Text('حفظ'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    name.dispose();
    barcode.dispose();
    cost.dispose();
    price.dispose();
    stock.dispose();
    threshold.dispose();
    super.dispose();
  }
}
