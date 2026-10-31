class OrderModel {
  final String id;
  final int? tableId;
  final String? cashierId;
  final double totalAmount;
  final double cashPaid;
  final double changeAmount;
  final String paymentMethod; // 'cash' or 'qris'
  final String paymentStatus; // 'pending', 'paid', 'cancelled'
  final DateTime createdAt;
  final List<OrderItemModel> items;
  // Optional joined fields
  final String? tableNumber;
  final String? cashierName;

  const OrderModel({
    required this.id,
    this.tableId,
    this.cashierId,
    required this.totalAmount,
    required this.cashPaid,
    required this.changeAmount,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.createdAt,
    this.items = const [],
    this.tableNumber,
    this.cashierName,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    // Parse joined table data
    String? tableNumber;
    if (json['tables'] != null && json['tables'] is Map) {
      tableNumber = json['tables']['table_number'] as String?;
    }

    // Parse joined profile/cashier data
    String? cashierName;
    if (json['profiles'] != null && json['profiles'] is Map) {
      cashierName = json['profiles']['full_name'] as String?;
    }

    // Parse order items
    List<OrderItemModel> items = [];
    if (json['order_items'] != null && json['order_items'] is List) {
      items = (json['order_items'] as List)
          .map((item) => OrderItemModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return OrderModel(
      id: json['id'] as String,
      tableId: json['table_id'] as int?,
      cashierId: json['cashier_id'] as String?,
      totalAmount: (json['total_amount'] as num).toDouble(),
      cashPaid: (json['cash_paid'] as num?)?.toDouble() ?? 0,
      changeAmount: (json['change_amount'] as num?)?.toDouble() ?? 0,
      paymentMethod: json['payment_method'] as String? ?? 'cash',
      paymentStatus: json['payment_status'] as String? ?? 'pending',
      createdAt: DateTime.parse(json['created_at'] as String),
      items: items,
      tableNumber: tableNumber ?? json['table_number'] as String?,
      cashierName: cashierName ?? json['cashier_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'table_id': tableId,
      'cashier_id': cashierId,
      'total_amount': totalAmount,
      'cash_paid': cashPaid,
      'change_amount': changeAmount,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'id': id,
      'table_id': tableId,
      'cashier_id': cashierId,
      'total_amount': totalAmount,
      'cash_paid': cashPaid,
      'change_amount': changeAmount,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
    };
  }

  OrderModel copyWith({
    String? id,
    int? tableId,
    String? cashierId,
    double? totalAmount,
    double? cashPaid,
    double? changeAmount,
    String? paymentMethod,
    String? paymentStatus,
    DateTime? createdAt,
    List<OrderItemModel>? items,
    String? tableNumber,
    String? cashierName,
  }) {
    return OrderModel(
      id: id ?? this.id,
      tableId: tableId ?? this.tableId,
      cashierId: cashierId ?? this.cashierId,
      totalAmount: totalAmount ?? this.totalAmount,
      cashPaid: cashPaid ?? this.cashPaid,
      changeAmount: changeAmount ?? this.changeAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
      tableNumber: tableNumber ?? this.tableNumber,
      cashierName: cashierName ?? this.cashierName,
    );
  }

  bool get isPaid => paymentStatus == 'paid';
  bool get isCancelled => paymentStatus == 'cancelled';
  bool get isPending => paymentStatus == 'pending';
  bool get isCash => paymentMethod == 'cash';
  bool get isQris => paymentMethod == 'qris';

  String get shortId => id.length >= 8 ? id.substring(0, 8).toUpperCase() : id.toUpperCase();
}

class OrderItemModel {
  final int id;
  final String orderId;
  final int? productId;
  final int quantity;
  final double unitPrice;
  final double subtotal;
  final String? notes;
  final String? productName; // from join

  const OrderItemModel({
    required this.id,
    required this.orderId,
    this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    this.notes,
    this.productName,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    // Parse joined product name
    String? productName;
    if (json['products'] != null && json['products'] is Map) {
      productName = json['products']['name'] as String?;
    }

    return OrderItemModel(
      id: json['id'] as int? ?? 0,
      orderId: json['order_id'] as String,
      productId: json['product_id'] as int?,
      quantity: json['quantity'] as int,
      unitPrice: (json['unit_price'] as num).toDouble(),
      subtotal: (json['subtotal'] as num).toDouble(),
      notes: json['notes'] as String?,
      productName: productName ?? json['product_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'product_id': productId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'subtotal': subtotal,
      'notes': notes,
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'order_id': orderId,
      'product_id': productId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'subtotal': subtotal,
      'notes': notes,
    };
  }
}
