import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../../../cart/presentation/providers/cart_provider.dart';

class SaleRepository {
  final AppDatabase database;

  SaleRepository({AppDatabase? database})
      : database = database ?? AppDatabase.instance;

  Future<int> completeSale(CartProvider cart) async {
    if (cart.items.isEmpty) {
      throw Exception('السلة فارغة');
    }

    final db = await database.database;

    return db.transaction<int>((txn) async {
      final maxResult = await txn.rawQuery(
        'SELECT MAX(invoice_number) AS max_number FROM sales',
      );

      final maxNumber =
          (maxResult.first['max_number'] as int?) ?? 0;
      final invoiceNumber = maxNumber + 1;
      final now = DateTime.now().toIso8601String();

      final saleId = await txn.insert('sales', {
        'invoice_number': invoiceNumber,
        'subtotal': cart.subtotal,
        'discount': cart.discount,
        'tax': cart.tax,
        'total': cart.total,
        'total_cost': cart.totalCost,
        'profit': cart.profit,
        'payment_method': 'cash',
        'created_at': now,
      });

      for (final item in cart.items) {
        final productId = item.product.id!;

        final rows = await txn.query(
          'products',
          columns: ['stock_quantity'],
          where: 'id = ?',
          whereArgs: [productId],
          limit: 1,
        );

        if (rows.isEmpty) {
          throw Exception('المنتج غير موجود: ${item.product.name}');
        }

        final stock =
            (rows.first['stock_quantity'] as num).toDouble();

        if (stock < item.quantity) {
          throw Exception(
            'الكمية غير كافية للمنتج: ${item.product.name}',
          );
        }

        await txn.insert('sale_items', {
          'sale_id': saleId,
          'product_id': productId,
          'product_name': item.product.name,
          'quantity': item.quantity,
          'unit_price': item.product.sellingPrice,
          'unit_cost': item.product.costPrice,
          'line_total': item.total,
          'line_cost': item.cost,
          'line_profit': item.profit,
        });

        final updated = await txn.rawUpdate(
          '''
          UPDATE products
          SET stock_quantity = stock_quantity - ?,
              updated_at = ?
          WHERE id = ?
            AND stock_quantity >= ?
          ''',
          [item.quantity, now, productId, item.quantity],
        );

        if (updated != 1) {
          throw Exception(
            'تعذر تحديث مخزون: ${item.product.name}',
          );
        }

        await txn.insert('stock_movements', {
          'product_id': productId,
          'movement_type': 'SALE',
          'quantity': -item.quantity,
          'reference_id': saleId,
          'note': 'بيع فاتورة #$invoiceNumber',
          'created_at': now,
        });
      }

      return saleId;
    });
  }
}