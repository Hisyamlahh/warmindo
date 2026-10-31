import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:warmindo_pos/features/catalog/models/category_model.dart';
import 'package:warmindo_pos/features/catalog/models/product_model.dart';

class CatalogProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  List<ProductModel> _products = [];
  List<ProductModel> _filteredProducts = [];
  List<CategoryModel> _categories = [];
  int? _selectedCategoryId;
  String _searchQuery = '';
  bool _isLoading = false;
  String? _errorMessage;

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  List<ProductModel> get products => _products;
  List<ProductModel> get filteredProducts => _filteredProducts;
  List<CategoryModel> get categories => _categories;
  int? get selectedCategoryId => _selectedCategoryId;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ---------------------------------------------------------------------------
  // Fetch products from Supabase with category join
  // ---------------------------------------------------------------------------

  Future<void> fetchProducts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _supabase
          .from('products')
          .select('*, categories(name)')
          .order('name', ascending: true);

      _products = (response as List<dynamic>)
          .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
          .toList();

      _applyFilters();
    } catch (e) {
      _errorMessage = 'Gagal memuat produk: $e';
      debugPrint(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Fetch categories from Supabase
  // ---------------------------------------------------------------------------

  Future<void> fetchCategories() async {
    try {
      final response = await _supabase
          .from('categories')
          .select()
          .order('name', ascending: true);

      _categories = (response as List<dynamic>)
          .map((json) => CategoryModel.fromJson(json as Map<String, dynamic>))
          .toList();

      notifyListeners();
    } catch (e) {
      debugPrint('Gagal memuat kategori: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Filtering
  // ---------------------------------------------------------------------------

  void filterByCategory(int? categoryId) {
    _selectedCategoryId = categoryId;
    _applyFilters();
    notifyListeners();
  }

  void searchProducts(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    _filteredProducts = _products.where((product) {
      final matchesCategory = _selectedCategoryId == null ||
          product.categoryId == _selectedCategoryId;

      final matchesSearch = _searchQuery.isEmpty ||
          product.name.toLowerCase().contains(_searchQuery.toLowerCase());

      return matchesCategory && matchesSearch;
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // ADMIN ONLY – CRUD operations
  // ---------------------------------------------------------------------------

  Future<void> addProduct({
    required String name,
    required double price,
    required int stock,
    int? categoryId,
    String? imageUrl,
    bool isAvailable = true,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _supabase.from('products').insert({
        'name': name,
        'price': price,
        'stock': stock,
        'category_id': categoryId,
        'image_url': imageUrl,
        'is_available': isAvailable,
      });

      await fetchProducts();
    } catch (e) {
      _errorMessage = 'Gagal menambah produk: $e';
      debugPrint(_errorMessage);
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateProduct({
    required int id,
    required String name,
    required double price,
    required int stock,
    int? categoryId,
    String? imageUrl,
    bool isAvailable = true,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _supabase.from('products').update({
        'name': name,
        'price': price,
        'stock': stock,
        'category_id': categoryId,
        'image_url': imageUrl,
        'is_available': isAvailable,
      }).eq('id', id);

      await fetchProducts();
    } catch (e) {
      _errorMessage = 'Gagal mengupdate produk: $e';
      debugPrint(_errorMessage);
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteProduct(int id) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _supabase.from('products').delete().eq('id', id);
      await fetchProducts();
    } catch (e) {
      _errorMessage = 'Gagal menghapus produk: $e';
      debugPrint(_errorMessage);
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateStock(int productId, int newStock) async {
    try {
      await _supabase
          .from('products')
          .update({'stock': newStock}).eq('id', productId);

      // Update local state immediately for responsiveness
      final index = _products.indexWhere((p) => p.id == productId);
      if (index != -1) {
        _products[index] = _products[index].copyWith(stock: newStock);
        _applyFilters();
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Gagal mengupdate stok: $e';
      debugPrint(_errorMessage);
      rethrow;
    }
  }
}
