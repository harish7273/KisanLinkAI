import '../models/product_model.dart';

class CartItem {
  final ProductModel product;
  double quantity;

  CartItem({
    required this.product,
    this.quantity = 1,
  });

  double get total {
    return product.price * quantity;
  }
}

class CartService {
  CartService._privateConstructor();

  static final CartService instance =
      CartService._privateConstructor();

  final List<CartItem> _items = [];

  // ============================================================
  // GET ITEMS
  // ============================================================

  List<CartItem> get items {
    return List.unmodifiable(_items);
  }

  // ============================================================
  // CART COUNT
  // ============================================================

  int get itemCount {
    return _items.length;
  }

  // ============================================================
  // TOTAL WEIGHT
  // ============================================================

  double get totalQuantity {
    double total = 0;

    for (final item in _items) {
      total += item.quantity;
    }

    return total;
  }

  // ============================================================
  // SUBTOTAL
  // ============================================================

  double get subtotal {
    double total = 0;

    for (final item in _items) {
      total += item.total;
    }

    return total;
  }

  // ============================================================
  // ADD PRODUCT
  // ============================================================

  void addProduct(ProductModel product) {
    final existingIndex = _items.indexWhere(
      (item) => item.product.id == product.id,
    );

    if (existingIndex != -1) {
      _items[existingIndex].quantity += 1;
    } else {
      _items.add(
        CartItem(
          product: product,
          quantity: 1,
        ),
      );
    }
  }

  // ============================================================
  // INCREASE
  // ============================================================

  void increase(CartItem item) {
    final index = _items.indexOf(item);

    if (index == -1) return;

    // Do not exceed available stock.
    if (_items[index].quantity <
        _items[index].product.quantity) {
      _items[index].quantity += 1;
    }
  }

  // ============================================================
  // DECREASE
  // ============================================================

  void decrease(CartItem item) {
    final index = _items.indexOf(item);

    if (index == -1) return;

    if (_items[index].quantity > 1) {
      _items[index].quantity -= 1;
    }
  }

  // ============================================================
  // REMOVE
  // ============================================================

  void remove(CartItem item) {
    _items.remove(item);
  }

  // ============================================================
  // CLEAR
  // ============================================================

  void clear() {
    _items.clear();
  }

  // ============================================================
  // CHECK PRODUCT EXISTS
  // ============================================================

  bool contains(ProductModel product) {
    return _items.any(
      (item) => item.product.id == product.id,
    );
  }
}