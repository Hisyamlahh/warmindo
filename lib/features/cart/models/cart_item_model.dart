import 'package:warmindo_pos/features/catalog/models/product_model.dart';

class CartItemModel {
  final ProductModel product;
  final int quantity;
  final String? notes;

  const CartItemModel({
    required this.product,
    required this.quantity,
    this.notes,
  });

  double get subtotal => product.price * quantity;

  CartItemModel copyWith({
    ProductModel? product,
    int? quantity,
    String? notes,
  }) {
    return CartItemModel(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
    );
  }
}
