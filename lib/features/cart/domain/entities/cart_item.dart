import '../../../products/domain/entities/product.dart';

class CartItem {
  final Product product;
  double quantity;

  CartItem({
    required this.product,
    this.quantity = 1,
  });

  double get total => product.sellingPrice * quantity;
  double get cost => product.costPrice * quantity;
  double get profit => total - cost;
}