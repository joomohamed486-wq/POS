
import 'package:flutter/material.dart';
import '../../../../core/database/app_database.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  bool monthly = false;
  bool loading = true;
  Map<String, dynamic> summary = {};
  List<Map<String, dynamic>> top = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    final db = await AppDatabase.instance.database;

    final filter = monthly
        ? "strftime('%Y-%m', created_at) = strftime('%Y-%m', 'now', 'localtime')"
        : "date(created_at) = date('now','localtime')";

    final result = await db.rawQuery('''
      SELECT
        COALESCE(SUM(total),0) AS sales,
        COALESCE(SUM(total_cost),0) AS cost,
        COALESCE(SUM(profit),0) AS profit,
        COUNT(*) AS invoices
      FROM sales
      WHERE $filter
    ''');

    final items = await db.rawQuery('''
      SELECT
        si.product_name AS product_name,
        SUM(si.quantity) AS quantity,
        SUM(si.line_total) AS sales,
        SUM(si.line_profit) AS profit
      FROM sale_items si
      INNER JOIN sales s ON s.id = si.sale_id
      WHERE $filter
      GROUP BY si.product_id, si.product_name
      ORDER BY quantity DESC
      LIMIT 10
    ''');

    if (!mounted) return;
    setState(() {
      summary = result.first;
      top = items;
      loading = false;
    });
  }

  double n(dynamic v) => (v as num?)?.toDouble() ?? 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('التقارير'),
        actions: [
          IconButton(onPressed: load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('اليوم')),
                    ButtonSegment(value: true, label: Text('هذا الشهر')),
                  ],
                  selected: {monthly},
                  onSelectionChanged: (s) {
                    setState(() => monthly = s.first);
                    load();
                  },
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _Metric('المبيعات', n(summary['sales'])),
                    _Metric('التكلفة', n(summary['cost'])),
                    _Metric('صافي الربح', n(summary['profit'])),
                    _Metric(
                      'الفواتير',
                      (summary['invoices'] as num?)?.toDouble() ?? 0,
                      money: false,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'الأكثر مبيعاً',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...top.asMap().entries.map(
                  (entry) {
                    final row = entry.value;
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(child: Text('${entry.key + 1}')),
                        title: Text(row['product_name'] as String),
                        subtitle: Text(
                          'الكمية: ${(row['quantity'] as num).toStringAsFixed(0)}',
                        ),
                        trailing: Text(
                          '${n(row['sales']).toStringAsFixed(2)} ج.م',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  },
                ),
                if (top.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(30),
                    child: Center(child: Text('لا توجد مبيعات في الفترة المحددة')),
                  ),
              ],
            ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String title;
  final double value;
  final bool money;

  const _Metric(this.title, this.value, {this.money = true});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SizedBox(
        width: 220,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 8),
              Text(
                money
                    ? '${value.toStringAsFixed(2)} ج.م'
                    : value.toStringAsFixed(0),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
