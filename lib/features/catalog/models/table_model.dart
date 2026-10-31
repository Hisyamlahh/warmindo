class TableModel {
  final int id;
  final String tableNumber;
  final String qrCodeData;
  final String status; // 'available' or 'occupied'
  final DateTime createdAt;

  const TableModel({
    required this.id,
    required this.tableNumber,
    required this.qrCodeData,
    required this.status,
    required this.createdAt,
  });

  factory TableModel.fromJson(Map<String, dynamic> json) {
    return TableModel(
      id: json['id'] as int,
      tableNumber: json['table_number'] as String,
      qrCodeData: json['qr_code_data'] as String,
      status: json['status'] as String? ?? 'available',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'table_number': tableNumber,
      'qr_code_data': qrCodeData,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'table_number': tableNumber,
      'qr_code_data': qrCodeData,
      'status': status,
    };
  }

  TableModel copyWith({
    int? id,
    String? tableNumber,
    String? qrCodeData,
    String? status,
    DateTime? createdAt,
  }) {
    return TableModel(
      id: id ?? this.id,
      tableNumber: tableNumber ?? this.tableNumber,
      qrCodeData: qrCodeData ?? this.qrCodeData,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isAvailable => status == 'available';
  bool get isOccupied => status == 'occupied';
}
