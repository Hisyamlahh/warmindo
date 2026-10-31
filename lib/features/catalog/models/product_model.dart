class ProductModel {
  final int id;
  final int? categoryId;
  final String name;
  final double price;
  final int stock;
  final String? imageUrl;
  final bool isAvailable;
  final DateTime createdAt;
  final String? categoryName;

  const ProductModel({
    required this.id,
    this.categoryId,
    required this.name,
    required this.price,
    required this.stock,
    this.imageUrl,
    this.isAvailable = true,
    required this.createdAt,
    this.categoryName,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    String? catName;
    if (json['categories'] != null && json['categories'] is Map) {
      catName = json['categories']['name'] as String?;
    } else if (json['category_name'] != null) {
      catName = json['category_name'] as String?;
    } else if (json['category'] != null && json['category'] is String) {
      catName = json['category'] as String?;
    }

    return ProductModel(
      id: json['id'] as int,
      categoryId: json['category_id'] as int?,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      stock: json['stock'] as int? ?? 0,
      imageUrl: json['image_url'] as String?,
      isAvailable: json['is_available'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      categoryName: catName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_id': categoryId,
      'name': name,
      'price': price,
      'stock': stock,
      'image_url': imageUrl,
      'is_available': isAvailable,
      'created_at': createdAt.toIso8601String(),
    };
  }

  ProductModel copyWith({
    int? id,
    int? categoryId,
    String? name,
    double? price,
    int? stock,
    String? imageUrl,
    bool? isAvailable,
    DateTime? createdAt,
    String? categoryName,
  }) {
    return ProductModel(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      imageUrl: imageUrl ?? this.imageUrl,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt ?? this.createdAt,
      categoryName: categoryName ?? this.categoryName,
    );
  }
}
