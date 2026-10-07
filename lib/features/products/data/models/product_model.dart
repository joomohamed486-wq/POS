import '../../domain/entities/product.dart';

class ProductModel extends Product {
  const ProductModel({
    super.id,
    required super.name,
    super.barcode,
    required super.costPrice,
    required super.sellingPrice,
    required super.stockQuantity,
    super.lowStockThreshold,
  });

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      barcode: map['barcode'] as String?,
      costPrice: (map['cost_price'] as num).toDouble(),
      sellingPrice: (map['selling_price'] as num).toDouble(),
      stockQuantity: (map['stock_quantity'] as num).toDouble(),
      lowStockThreshold:
          (map['low_stock_threshold'] as num?)?.toDouble() ?? 5,
    );
  }
}