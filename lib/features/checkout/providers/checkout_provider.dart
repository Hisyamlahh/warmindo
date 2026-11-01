import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:warmindo_pos/core/constants/app_constants.dart';
import 'package:warmindo_pos/features/cart/providers/cart_provider.dart';
import 'package:warmindo_pos/features/catalog/models/order_model.dart';

class CheckoutProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  String _paymentMethod = 'cash'; // 'cash' or 'qris'
  double _cashPaid = 0.0;
  bool _isProcessing = false;
  String? _errorMessage;
  String? _generatedQrData;
  OrderModel? _lastCompletedOrder;

  // Getters
  String get paymentMethod => _paymentMethod;
  double get cashPaid => _cashPaid;
  bool get isProcessing => _isProcessing;
  String? get errorMessage => _errorMessage;
  String? get generatedQrData => _generatedQrData;
  OrderModel? get lastCompletedOrder => _lastCompletedOrder;

  double getChangeAmount(double totalAmount) {
    if (_paymentMethod != 'cash') return 0.0;
    final diff = _cashPaid - totalAmount;
    return diff > 0 ? diff : 0.0;
  }

  bool isCashSufficient(double totalAmount) {
    if (_paymentMethod != 'cash') return true;
    return _cashPaid >= totalAmount;
  }

  void setPaymentMethod(String method) {
    _paymentMethod = method;
    _errorMessage = null;
    notifyListeners();
  }

  void setCashPaid(double amount) {
    _cashPaid = amount;
    _errorMessage = null;
    notifyListeners();
  }

  String generatePaymentQr(String orderId, double amount) {
    final qrData = '${AppConstants.paymentQrPrefix}${orderId}_${amount.toInt()}';
    _generatedQrData = qrData;
    notifyListeners();
    return qrData;
  }

  /// Process the payment, create order in Supabase, insert order items,
  /// decrement stock, update table status to 'available', and clear cart.
  Future<OrderModel?> processPayment({
    required CartProvider cart,
    required String? cashierId,
    String? cashierName,
  }) async {
    if (cart.items.isEmpty) {
      _errorMessage = 'Keranjang belanja kosong';
      notifyListeners();
      return null;
    }

    final totalAmount = cart.totalAmount;
    if (_paymentMethod == 'cash' && !isCashSufficient(totalAmount)) {
      _errorMessage = 'Jumlah pembayaran tunai kurang dari total tagihan';
      notifyListeners();
      return null;
    }

    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final orderId = const Uuid().v4();
      final changeAmount = getChangeAmount(totalAmount);
      final finalCashPaid = _paymentMethod == 'cash' ? _cashPaid : totalAmount;

      // 1. Create order
      final orderData = {
        'id': orderId,
        'table_id': cart.tableId,
        'cashier_id': cashierId,
        'total_amount': totalAmount,
        'cash_paid': finalCashPaid,
        'change_amount': changeAmount,
        'payment_method': _paymentMethod,
        'payment_status': 'paid',
      };

      await _supabase.from('orders').insert(orderData);

      // 2. Create order items & 3. Decrement stock
      final List<OrderItemModel> createdItems = [];
      for (final item in cart.items) {
        final itemData = {
          'order_id': orderId,
          'product_id': item.product.id,
          'quantity': item.quantity,
          'unit_price': item.product.price,
          'notes': item.notes,
        };

        final itemRes = await _supabase
            .from('order_items')
            .insert(itemData)
            .select()
            .single();

        createdItems.add(OrderItemModel(
          id: (itemRes['id'] as num).toInt(),
          orderId: orderId,
          productId: item.product.id,
          quantity: item.quantity,
          unitPrice: item.product.price,
          subtotal: item.subtotal,
          notes: item.notes,
          productName: item.product.name,
        ));

        // Decrement product stock in products table
        try {
          final newStock = (item.product.stock - item.quantity);
          await _supabase.from('products').update({
            'stock': newStock >= 0 ? newStock : 0,
            'is_available': newStock > 0,
          }).eq('id', item.product.id);
        } catch (e) {
          debugPrint('Warning: stock update failed: $e');
        }
      }

      // 4. Update table status if set
      if (cart.tableId != null) {
        try {
          await _supabase.from('tables').update({
            'status': 'available',
          }).eq('id', cart.tableId!);
        } catch (e) {
          debugPrint('Warning: table status update failed: $e');
        }
      }

      final completedOrder = OrderModel(
        id: orderId,
        tableId: cart.tableId,
        cashierId: cashierId,
        totalAmount: totalAmount,
        cashPaid: finalCashPaid,
        changeAmount: changeAmount,
        paymentMethod: _paymentMethod,
        paymentStatus: 'paid',
        createdAt: DateTime.now(),
        items: createdItems,
        tableNumber: cart.tableNumber,
        cashierName: cashierName,
      );

      _lastCompletedOrder = completedOrder;

      // 5. Clear cart
      cart.clear();

      _isProcessing = false;
      notifyListeners();
      return completedOrder;
    } catch (e) {
      _errorMessage = 'Gagal memproses pembayaran: $e';
      _isProcessing = false;
      notifyListeners();
      return null;
    }
  }

  /// Save order as 'pending' (Bayar Nanti).
  /// Decrements stock, leaves table as 'occupied', and clears cart.
  Future<OrderModel?> createPendingOrder({
    required CartProvider cart,
    required String? cashierId,
    String? cashierName,
  }) async {
    if (cart.items.isEmpty) {
      _errorMessage = 'Keranjang belanja kosong';
      notifyListeners();
      return null;
    }

    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final orderId = const Uuid().v4();
      final totalAmount = cart.totalAmount;

      // 1. Create order with status 'pending'
      final orderData = {
        'id': orderId,
        'table_id': cart.tableId,
        'cashier_id': cashierId,
        'total_amount': totalAmount,
        'cash_paid': 0.0,
        'change_amount': 0.0,
        'payment_method': _paymentMethod,
        'payment_status': 'pending',
      };

      await _supabase.from('orders').insert(orderData);

      // 2. Insert items & decrement stock
      final List<OrderItemModel> createdItems = [];
      for (final item in cart.items) {
        final itemData = {
          'order_id': orderId,
          'product_id': item.product.id,
          'quantity': item.quantity,
          'unit_price': item.product.price,
          'notes': item.notes,
        };

        final itemRes = await _supabase
            .from('order_items')
            .insert(itemData)
            .select()
            .single();

        createdItems.add(OrderItemModel(
          id: (itemRes['id'] as num).toInt(),
          orderId: orderId,
          productId: item.product.id,
          quantity: item.quantity,
          unitPrice: item.product.price,
          subtotal: item.subtotal,
          notes: item.notes,
          productName: item.product.name,
        ));

        // Decrement product stock
        try {
          final newStock = (item.product.stock - item.quantity);
          await _supabase.from('products').update({
            'stock': newStock >= 0 ? newStock : 0,
            'is_available': newStock > 0,
          }).eq('id', item.product.id);
        } catch (e) {
          debugPrint('Warning: stock decrement failed: $e');
        }
      }

      // 3. Keep table status as 'occupied'
      if (cart.tableId != null) {
        try {
          await _supabase.from('tables').update({
            'status': 'occupied',
          }).eq('id', cart.tableId!);
        } catch (e) {
          debugPrint('Warning: table occupied update failed: $e');
        }
      }

      final pendingOrder = OrderModel(
        id: orderId,
        tableId: cart.tableId,
        cashierId: cashierId,
        totalAmount: totalAmount,
        cashPaid: 0.0,
        changeAmount: 0.0,
        paymentMethod: _paymentMethod,
        paymentStatus: 'pending',
        createdAt: DateTime.now(),
        items: createdItems,
        tableNumber: cart.tableNumber,
        cashierName: cashierName,
      );

      _lastCompletedOrder = pendingOrder;

      // 4. Clear cart
      cart.clear();

      _isProcessing = false;
      notifyListeners();
      return pendingOrder;
    } catch (e) {
      _errorMessage = 'Gagal menyimpan pesanan pending: $e';
      _isProcessing = false;
      notifyListeners();
      return null;
    }
  }

  /// Complete payment for an existing pending order
  Future<bool> payPendingOrder({
    required OrderModel order,
    required double cashPaid,
    required String paymentMethod,
  }) async {
    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final changeAmount = paymentMethod == 'cash' && cashPaid > order.totalAmount
          ? (cashPaid - order.totalAmount)
          : 0.0;

      await _supabase.from('orders').update({
        'payment_status': 'paid',
        'cash_paid': paymentMethod == 'cash' ? cashPaid : order.totalAmount,
        'change_amount': changeAmount,
        'payment_method': paymentMethod,
      }).eq('id', order.id);

      // Make table available
      if (order.tableId != null) {
        try {
          await _supabase.from('tables').update({
            'status': 'available',
          }).eq('id', order.tableId!);
        } catch (e) {
          debugPrint('Warning: table available update failed: $e');
        }
      }

      _isProcessing = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal menyelesaikan pembayaran: $e';
      _isProcessing = false;
      notifyListeners();
      return false;
    }
  }

  /// Cancel an order: mark as 'cancelled', restore stock, and release table
  Future<bool> cancelOrder(OrderModel order) async {
    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Update order status
      await _supabase.from('orders').update({
        'payment_status': 'cancelled',
      }).eq('id', order.id);

      // 2. Restore stock
      for (final item in order.items) {
        if (item.productId != null) {
          try {
            final prodRes = await _supabase
                .from('products')
                .select('stock')
                .eq('id', item.productId!)
                .maybeSingle();

            if (prodRes != null) {
              final currentStock = (prodRes['stock'] as num).toInt();
              final restoredStock = currentStock + item.quantity;
              await _supabase.from('products').update({
                'stock': restoredStock,
                'is_available': restoredStock > 0,
              }).eq('id', item.productId!);
            }
          } catch (e) {
            debugPrint('Warning: stock restore failed: $e');
          }
        }
      }

      // 3. Make table available
      if (order.tableId != null) {
        try {
          await _supabase.from('tables').update({
            'status': 'available',
          }).eq('id', order.tableId!);
        } catch (e) {
          debugPrint('Warning: table available update failed: $e');
        }
      }

      _isProcessing = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal membatalkan pesanan: $e';
      _isProcessing = false;
      notifyListeners();
      return false;
    }
  }

  void reset() {
    _paymentMethod = 'cash';
    _cashPaid = 0.0;
    _isProcessing = false;
    _errorMessage = null;
    _generatedQrData = null;
    _lastCompletedOrder = null;
    notifyListeners();
  }
}

