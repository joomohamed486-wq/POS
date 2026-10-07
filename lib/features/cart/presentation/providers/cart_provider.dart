import 'package:flutter/foundation.dart';

import '../../domain/entities/cart_item.dart';
import '../../../products/domain/entities/product.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  double discount = 0;
  double tax = 0;

  List<CartItem> get items => List.unmodifiable(_items);

  double get subtotal =>
      _items.fold(0, (sum, item) => sum + item.total);

  double get totalCost =>
      _items.fold(0, (sum, item) => sum + item.cost);

  double get total => subtotal - discount + tax;

  double get profit => total - totalCost;

  void addProduct(Product product) {
    if (product.stockQuantity <= 0) return;

    final index = _items.indexWhere(
      (item) => item.product.id == product.id,
    );

    if (index == -1) {
      _items.add(CartItem(product: product));
    } else if (_items[index].quantity < product.stockQuantity) {
      _items[index].quantity++;
    }

    notifyListeners();
  }

  void increase(int productId) {
    final index = _items.indexWhere(
      (item) => item.product.id == productId,
    );
    if (index == -1) return;

    final item = _items[index];
    if (item.quantity < item.product.stockQuantity) {
      item.quantity++;
      notifyListeners();
    }
  }

  void decrease(int productId) {
    final index = _items.indexWhere(
      (item) => item.product.id == productId,
    );
    if (index == -1) return;

    if (_items[index].quantity > 1) {
      _items[index].quantity--;
    } else {
      _items.removeAt(index);
    }
    notifyListeners();
  }

  void remove(int productId) {
    _items.removeWhere((item) => item.product.id == productId);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    discount = 0;
    tax = 0;
    notifyListeners();
  }
}