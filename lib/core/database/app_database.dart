import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'offline_pos.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE products (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            barcode TEXT UNIQUE,
            cost_price REAL NOT NULL DEFAULT 0,
            selling_price REAL NOT NULL DEFAULT 0,
            stock_quantity REAL NOT NULL DEFAULT 0,
            low_stock_threshold REAL NOT NULL DEFAULT 5,
            is_active INTEGER NOT NULL DEFAULT 1,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE sales (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            invoice_number INTEGER NOT NULL UNIQUE,
            subtotal REAL NOT NULL,
            discount REAL NOT NULL DEFAULT 0,
            tax REAL NOT NULL DEFAULT 0,
            total REAL NOT NULL,
            total_cost REAL NOT NULL,
            profit REAL NOT NULL,
            payment_method TEXT NOT NULL DEFAULT 'cash',
            created_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE sale_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            sale_id INTEGER NOT NULL,
            product_id INTEGER NOT NULL,
            product_name TEXT NOT NULL,
            quantity REAL NOT NULL,
            unit_price REAL NOT NULL,
            unit_cost REAL NOT NULL,
            line_total REAL NOT NULL,
            line_cost REAL NOT NULL,
            line_profit REAL NOT NULL,
            FOREIGN KEY (sale_id) REFERENCES sales(id) ON DELETE CASCADE,
            FOREIGN KEY (product_id) REFERENCES products(id)
          )
        ''');

        await db.execute('''
          CREATE TABLE stock_movements (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            product_id INTEGER NOT NULL,
            movement_type TEXT NOT NULL,
            quantity REAL NOT NULL,
            reference_id INTEGER,
            note TEXT,
            created_at TEXT NOT NULL,
            FOREIGN KEY (product_id) REFERENCES products(id)
          )
        ''');

        await db.execute(
          'CREATE INDEX idx_products_barcode ON products(barcode)',
        );
        await db.execute(
          'CREATE INDEX idx_sales_created_at ON sales(created_at)',
        );
        await db.execute(
          'CREATE INDEX idx_sale_items_product ON sale_items(product_id)',
        );

        await _seedDemoProducts(db);
      },
    );
  }

  Future<void> _seedDemoProducts(Database db) async {
    final now = DateTime.now().toIso8601String();
    final demo = [
      ['ساعة كلاسيك', '100001', 250.0, 450.0, 12.0],
      ['ساعة رياضية', '100002', 350.0, 650.0, 8.0],
      ['ساعة لؤلؤية', '100003', 500.0, 850.0, 4.0],
      ['ساعة كرونوغراف', '100004', 700.0, 1100.0, 3.0],
      ['ساعة غوص', '100005', 800.0, 1400.0, 10.0],
      ['ساعة نسائية', '100006', 300.0, 550.0, 7.0],
    ];

    for (final p in demo) {
      await db.insert('products', {
        'name': p[0],
        'barcode': p[1],
        'cost_price': p[2],
        'selling_price': p[3],
        'stock_quantity': p[4],
        'low_stock_threshold': 5,
        'is_active': 1,
        'created_at': now,
        'updated_at': now,
      });
    }
  }
}