class Product {
  final int? id;
  final String name;
  final String? barcode;
  final double costPrice;
  final double sellingPrice;
  final double stockQuantity;
  final double lowStockThreshold;

  const Product({
    this.id,
    required this.name,
    this.barcode,
    required this.costPrice,
    required this.sellingPrice,
    required this.stockQuantity,
    this.lowStockThreshold = 5,
  });

  bool get isLowStock => stockQuantity <= lowStockThreshold;
}