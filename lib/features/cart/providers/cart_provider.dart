import 'package:flutter/foundation.dart';
import 'package:warmindo_pos/features/cart/models/cart_item_model.dart';
import 'package:warmindo_pos/features/catalog/models/product_model.dart';
import 'package:warmindo_pos/features/catalog/models/table_model.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItemModel> _items = [];
  TableModel? _selectedTable;

  List<CartItemModel> get items => List.unmodifiable(_items);
  TableModel? get selectedTable => _selectedTable;

  int? get tableId => _selectedTable?.id;
  String? get tableNumber => _selectedTable?.tableNumber;

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  int get totalItems => itemCount;

  double get totalAmount => _items.fold(0.0, (sum, item) => sum + item.subtotal);

  bool get isEmpty => _items.isEmpty;
  bool get isNotEmpty => _items.isNotEmpty;

  void setTable(TableModel? table) {
    _selectedTable = table;
    notifyListeners();
  }

  void setTableData(int id, String number, String qrData) {
    _selectedTable = TableModel(
      id: id,
      tableNumber: number,
      qrCodeData: qrData,
      status: 'occupied',
      createdAt: DateTime.now(),
    );
    notifyListeners();
  }

  void addToCart(ProductModel product, {int quantity = 1, String? notes}) {
    addItem(product, quantity: quantity, notes: notes);
  }

  void addItem(ProductModel product, {int quantity = 1, String? notes}) {
    final existingIndex = _items.indexWhere((item) => item.product.id == product.id);

    if (existingIndex >= 0) {
      final existing = _items[existingIndex];
      _items[existingIndex] = existing.copyWith(
        quantity: existing.quantity + quantity,
      );
    } else {
      _items.add(CartItemModel(
        product: product,
        quantity: quantity,
        notes: notes,
      ));
    }
    notifyListeners();
  }

  void removeFromCart(int productId) {
    removeItem(productId);
  }

  void removeItem(int productId) {
    _items.removeWhere((item) => item.product.id == productId);
    notifyListeners();
  }

  void updateQuantity(int productId, int quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }

    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      _items[index] = _items[index].copyWith(quantity: quantity);
      notifyListeners();
    }
  }

  void updateNotes(int productId, String notes) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      _items[index] = _items[index].copyWith(notes: notes);
      notifyListeners();
    }
  }

  void incrementQuantity(int productId) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      _items[index] = _items[index].copyWith(
        quantity: _items[index].quantity + 1,
      );
      notifyListeners();
    }
  }

  void decrementQuantity(int productId) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      final newQuantity = _items[index].quantity - 1;
      if (newQuantity <= 0) {
        _items.removeAt(index);
      } else {
        _items[index] = _items[index].copyWith(quantity: newQuantity);
      }
      notifyListeners();
    }
  }

  void clearCart() {
    clear();
  }

  void clear() {
    _items.clear();
    _selectedTable = null;
    notifyListeners();
  }

  void clearItems() {
    _items.clear();
    notifyListeners();
  }
}
