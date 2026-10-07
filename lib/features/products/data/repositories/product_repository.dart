
import '../../../../core/database/app_database.dart';
import '../models/product_model.dart';

class ProductRepository {
  final AppDatabase database;

  ProductRepository({AppDatabase? database})
      : database = database ?? AppDatabase.instance;

  Future<List<ProductModel>> getProducts({String query = ''}) async {
    final db = await database.database;
    final q = query.trim();

    final rows = await db.query(
      'products',
      where: q.isEmpty
          ? 'is_active = 1'
          : 'is_active = 1 AND (name LIKE ? OR barcode LIKE ?)',
      whereArgs: q.isEmpty ? null : ['%$q%', '%$q%'],
      orderBy: 'name ASC',
    );

    return rows.map(ProductModel.fromMap).toList();
  }

  Future<ProductModel?> findByBarcode(String barcode) async {
    final db = await database.database;
    final rows = await db.query(
      'products',
      where: 'barcode = ? AND is_active = 1',
      whereArgs: [barcode],
      limit: 1,
    );
    return rows.isEmpty ? null : ProductModel.fromMap(rows.first);
  }

  Future<int> save({
    int? id,
    required String name,
    String? barcode,
    required double costPrice,
    required double sellingPrice,
    required double stockQuantity,
    required double lowStockThreshold,
  }) async {
    final db = await database.database;
    final now = DateTime.now().toIso8601String();

    final data = {
      'name': name.trim(),
      'barcode': barcode?.trim().isEmpty == true ? null : barcode?.trim(),
      'cost_price': costPrice,
      'selling_price': sellingPrice,
      'stock_quantity': stockQuantity,
      'low_stock_threshold': lowStockThreshold,
      'is_active': 1,
      'updated_at': now,
      'created_at': now,
    };

    if (id == null) {
      final productId = await db.insert('products', data);
      await db.insert('stock_movements', {
        'product_id': productId,
        'movement_type': 'INITIAL',
        'quantity': stockQuantity,
        'note': 'رصيد افتتاحي',
        'created_at': now,
      });
      return productId;
    }

    final oldRows = await db.query(
      'products',
      columns: ['stock_quantity'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    final oldStock = oldRows.isEmpty
        ? stockQuantity
        : (oldRows.first['stock_quantity'] as num).toDouble();

    data.remove('created_at');
    await db.update(
      'products',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );

    final difference = stockQuantity - oldStock;
    if (difference != 0) {
      await db.insert('stock_movements', {
        'product_id': id,
        'movement_type': 'ADJUSTMENT',
        'quantity': difference,
        'note': 'تعديل المخزون من شاشة المنتجات',
        'created_at': now,
      });
    }

    return id;
  }

  Future<void> delete(int id) async {
    final db = await database.database;
    await db.update(
      'products',
      {
        'is_active': 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
