
import 'package:flutter/material.dart';
import '../../../../core/database/app_database.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Map<String, dynamic> stats = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final db = await AppDatabase.instance.database;
    final sales = await db.rawQuery('''
      SELECT
        COALESCE(SUM(total), 0) AS sales,
        COALESCE(SUM(total_cost), 0) AS cost,
        COALESCE(SUM(profit), 0) AS profit,
        COUNT(*) AS invoices
      FROM sales
      WHERE date(created_at) = date('now','localtime')
    ''');
    final products = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM products WHERE is_active = 1',
    );
    final low = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM products WHERE is_active = 1 AND stock_quantity <= low_stock_threshold',
    );

    if (!mounted) return;
    setState(() {
      stats = {
        ...sales.first,
        'products': products.first['count'],
        'low': low.first['count'],
      };
      loading = false;
    });
  }

  double n(dynamic v) => (v as num?)?.toDouble() ?? 0;
  int i(dynamic v) => (v as num?)?.toInt() ?? 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة التحكم'),
        actions: [
          IconButton(onPressed: load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: load,
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  const Text(
                    'ملخص اليوم',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _StatCard(
                        title: 'مبيعات اليوم',
                        value: '${n(stats['sales']).toStringAsFixed(2)} ج.م',
                        icon: Icons.payments_outlined,
                      ),
                      _StatCard(
                        title: 'تكلفة المبيعات',
                        value: '${n(stats['cost']).toStringAsFixed(2)} ج.م',
                        icon: Icons.shopping_cart_checkout,
                      ),
                      _StatCard(
                        title: 'صافي الربح',
                        value: '${n(stats['profit']).toStringAsFixed(2)} ج.م',
                        icon: Icons.trending_up,
                      ),
                      _StatCard(
                        title: 'الفواتير',
                        value: '${i(stats['invoices'])}',
                        icon: Icons.receipt_long_outlined,
                      ),
                      _StatCard(
                        title: 'المنتجات',
                        value: '${i(stats['products'])}',
                        icon: Icons.inventory_2_outlined,
                      ),
                      _StatCard(
                        title: 'مخزون منخفض',
                        value: '${i(stats['low'])}',
                        icon: Icons.warning_amber_rounded,
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(child: Icon(icon)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 5),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
