
import 'package:flutter/material.dart';
import '../../../../core/database/app_database.dart';

class SalesPage extends StatefulWidget {
  const SalesPage({super.key});

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  List<Map<String, dynamic>> rows = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    final db = await AppDatabase.instance.database;
    final result = await db.query(
      'sales',
      orderBy: 'created_at DESC',
      limit: 100,
    );
    if (!mounted) return;
    setState(() {
      rows = result;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المبيعات والفواتير'),
        actions: [
          IconButton(onPressed: load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: rows.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final s = rows[i];
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.receipt_long),
                    ),
                    title: Text('فاتورة #${s['invoice_number']}'),
                    subtitle: Text(
                      '${s['created_at']}\n'
                      'ربح: ${(s['profit'] as num).toStringAsFixed(2)} ج.م',
                    ),
                    isThreeLine: true,
                    trailing: Text(
                      '${(s['total'] as num).toStringAsFixed(2)} ج.م',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
