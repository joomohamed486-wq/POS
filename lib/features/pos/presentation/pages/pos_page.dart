import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../cart/presentation/providers/cart_provider.dart';
import '../../../products/data/repositories/product_repository.dart';
import '../../../products/data/models/product_model.dart';
import '../../../sales/data/repositories/sale_repository.dart';

class PosPage extends StatefulWidget {
  const PosPage({super.key});

  @override
  State<PosPage> createState() => _PosPageState();
}

class _PosPageState extends State<PosPage> {
  final _searchController = TextEditingController();
  final _productRepository = ProductRepository();
  final _saleRepository = SaleRepository();

  List<ProductModel> products = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => loading = true);
    final result = await _productRepository.getProducts(
      query: _searchController.text,
    );
    if (!mounted) return;
    setState(() {
      products = result;
      loading = false;
    });
  }

  Future<void> _scanBarcode() async {
    final barcode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerPage()),
    );

    if (barcode == null || barcode.isEmpty) return;

    final product = await _productRepository.findByBarcode(barcode);
    if (!mounted) return;

    if (product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('لا يوجد منتج بالباركود $barcode')),
      );
      return;
    }

    context.read<CartProvider>().addProduct(product);
  }

  Future<void> _checkout() async {
    final cart = context.read<CartProvider>();
    if (cart.items.isEmpty) return;

    try {
      final saleId = await _saleRepository.completeSale(cart);
      cart.clear();
      await _loadProducts();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم إتمام البيع بنجاح — رقم العملية $saleId'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('نظام الكاشير POS'),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 800;

          return Padding(
            padding: const EdgeInsets.all(12),
            child: wide
                ? Row(
                    children: [
                      Expanded(flex: 3, child: _productsPanel()),
                      const SizedBox(width: 12),
                      Expanded(flex: 2, child: _cartPanel()),
                    ],
                  )
                : Column(
                    children: [
                      Expanded(child: _productsPanel()),
                      const SizedBox(height: 12),
                      SizedBox(height: 330, child: _cartPanel()),
                    ],
                  ),
          );
        },
      ),
    );
  }

  Widget _productsPanel() {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              onChanged: (_) => _loadProducts(),
              decoration: InputDecoration(
                hintText: 'ابحث بالاسم أو الباركود',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: _scanBarcode,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : products.isEmpty
                      ? const Center(child: Text('لا توجد منتجات'))
                      : GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 230,
                            mainAxisExtent: 150,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemCount: products.length,
                          itemBuilder: (_, index) {
                            final product = products[index];
                            return _ProductCard(product: product);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cartPanel() {
    return Consumer<CartProvider>(
      builder: (context, cart, _) {
        return Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'الفاتورة الحالية',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text('${cart.items.length} أصناف'),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: cart.items.isEmpty
                      ? const Center(
                          child: Text('أضف المنتجات إلى الفاتورة'),
                        )
                      : ListView.builder(
                          itemCount: cart.items.length,
                          itemBuilder: (_, index) {
                            final item = cart.items[index];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(item.product.name),
                              subtitle: Text(
                                '${item.product.sellingPrice.toStringAsFixed(2)} ج.م',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: () =>
                                        cart.decrease(item.product.id!),
                                    icon: const Icon(Icons.remove_circle_outline),
                                  ),
                                  Text(item.quantity.toStringAsFixed(0)),
                                  IconButton(
                                    onPressed: () =>
                                        cart.increase(item.product.id!),
                                    icon: const Icon(Icons.add_circle_outline),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                const Divider(),
                _SummaryRow('الإجمالي', cart.subtotal),
                _SummaryRow('التكلفة', cart.totalCost),
                _SummaryRow('صافي الربح', cart.profit),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: cart.items.isEmpty ? null : _checkout,
                    icon: const Icon(Icons.point_of_sale),
                    label: Text(
                      'إتمام البيع — ${cart.total.toStringAsFixed(2)} ج.م',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductModel product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: product.stockQuantity <= 0
          ? null
          : () => context.read<CartProvider>().addProduct(product),
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: product.isLowStock
                ? Colors.orange.shade300
                : Colors.transparent,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Center(
                  child: Icon(
                    Icons.watch_outlined,
                    size: 48,
                    color: product.stockQuantity <= 0
                        ? Colors.grey
                        : Colors.indigo,
                  ),
                ),
              ),
              Text(
                product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${product.sellingPrice.toStringAsFixed(0)} ج.م',
                    ),
                  ),
                  Text(
                    'مخزون ${product.stockQuantity.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: product.isLowStock
                          ? Colors.orange.shade800
                          : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String title;
  final double value;

  const _SummaryRow(this.title, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(title)),
          Text(
            '${value.toStringAsFixed(2)} ج.م',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage({super.key});

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  bool handled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مسح الباركود')),
      body: MobileScanner(
        onDetect: (capture) {
          if (handled) return;
          final code = capture.barcodes.isEmpty ? null : capture.barcodes.first.rawValue;
          if (code == null || code.isEmpty) return;

          handled = true;
          Navigator.pop(context, code);
        },
      ),
    );
  }
}
