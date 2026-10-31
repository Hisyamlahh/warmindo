import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:warmindo_pos/core/theme/app_theme.dart';
import 'package:warmindo_pos/features/auth/providers/auth_provider.dart';
import 'package:warmindo_pos/features/cart/providers/cart_provider.dart';
import 'package:warmindo_pos/features/catalog/models/category_model.dart';
import 'package:warmindo_pos/features/catalog/models/product_model.dart';
import 'package:warmindo_pos/features/catalog/providers/catalog_provider.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final _searchController = TextEditingController();
  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final catalog = context.read<CatalogProvider>();
      catalog.fetchProducts();
      catalog.fetchCategories();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Show Add/Edit Product Modal Form ───────────────────────────────────────
  void _showProductFormDialog({ProductModel? product}) {
    final catalog = context.read<CatalogProvider>();
    final isEditing = product != null;

    final nameController = TextEditingController(text: product?.name ?? '');
    final priceController = TextEditingController(
      text: product != null ? product.price.toInt().toString() : '',
    );
    final stockController = TextEditingController(
      text: product != null ? product.stock.toString() : '20',
    );
    final imageController = TextEditingController(text: product?.imageUrl ?? '');

    int? selectedCategory = product?.categoryId ??
        (catalog.categories.isNotEmpty ? catalog.categories.first.id : null);
    bool isAvailable = product?.isAvailable ?? true;
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Handle bar
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppTheme.dividerColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Title
                        Text(
                          isEditing ? 'Edit Menu' : 'Tambah Menu Baru',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Nama Menu
                        TextFormField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Nama Menu *',
                            hintText: 'Misal: Indomie Goreng Rendang',
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Nama menu wajib diisi'
                              : null,
                        ),
                        const SizedBox(height: 12),

                        // Kategori Dropdown
                        DropdownButtonFormField<int>(
                          value: selectedCategory,
                          decoration: const InputDecoration(
                            labelText: 'Kategori',
                          ),
                          items: catalog.categories.map((CategoryModel cat) {
                            return DropdownMenuItem<int>(
                              value: cat.id,
                              child: Text(cat.name),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setSheetState(() => selectedCategory = val);
                          },
                        ),
                        const SizedBox(height: 12),

                        // Harga & Stok Row
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: priceController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Harga (Rp) *',
                                  prefixText: 'Rp ',
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Wajib diisi';
                                  if (double.tryParse(v) == null) return 'Angka tidak valid';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: stockController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Stok *',
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Wajib diisi';
                                  if (int.tryParse(v) == null) return 'Angka tidak valid';
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // URL Gambar (Opsional)
                        TextFormField(
                          controller: imageController,
                          decoration: const InputDecoration(
                            labelText: 'URL Gambar (Opsional)',
                            hintText: 'https://...',
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Switch Status Tersedia
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Status Tersedia'),
                          subtitle: Text(
                            isAvailable ? 'Menu dapat dipesan' : 'Menu dinonaktifkan',
                            style: const TextStyle(fontSize: 12),
                          ),
                          activeColor: AppTheme.primaryOrange,
                          value: isAvailable,
                          onChanged: (val) {
                            setSheetState(() => isAvailable = val);
                          },
                        ),
                        const SizedBox(height: 20),

                        // Tombol Simpan
                        ElevatedButton(
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  if (!formKey.currentState!.validate()) return;

                                  setSheetState(() => isSubmitting = true);

                                  try {
                                    final name = nameController.text.trim();
                                    final price = double.parse(priceController.text.trim());
                                    final stock = int.parse(stockController.text.trim());
                                    final imageUrl = imageController.text.trim().isEmpty
                                        ? null
                                        : imageController.text.trim();

                                    if (isEditing) {
                                      await catalog.updateProduct(
                                        id: product.id,
                                        name: name,
                                        price: price,
                                        stock: stock,
                                        categoryId: selectedCategory,
                                        imageUrl: imageUrl,
                                        isAvailable: isAvailable,
                                      );
                                    } else {
                                      await catalog.addProduct(
                                        name: name,
                                        price: price,
                                        stock: stock,
                                        categoryId: selectedCategory,
                                        imageUrl: imageUrl,
                                        isAvailable: isAvailable,
                                      );
                                    }

                                    if (context.mounted) {
                                      Navigator.of(ctx).pop();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(isEditing
                                              ? 'Menu berhasil diperbarui!'
                                              : 'Menu baru berhasil ditambahkan!'),
                                          backgroundColor: AppTheme.accentGreen,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    setSheetState(() => isSubmitting = false);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Gagal menyimpan menu: $e'),
                                          backgroundColor: AppTheme.accentRed,
                                        ),
                                      );
                                    }
                                  }
                                },
                          child: isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(isEditing ? 'Perbarui Menu' : 'Simpan Menu'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── Show Quick Stock Update Dialog ─────────────────────────────────────────
  void _showUpdateStockDialog(ProductModel product) {
    final catalog = context.read<CatalogProvider>();
    final controller = TextEditingController(text: product.stock.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Ubah Stok: ${product.name}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Jumlah Stok Baru',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newStock = int.tryParse(controller.text.trim());
              if (newStock == null || newStock < 0) return;

              Navigator.of(ctx).pop();
              try {
                await catalog.updateStock(product.id, newStock);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Stok ${product.name} diubah menjadi $newStock'),
                      backgroundColor: AppTheme.accentGreen,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal ubah stok: $e'),
                      backgroundColor: AppTheme.accentRed,
                    ),
                  );
                }
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  // ── Show Delete Confirmation Dialog ────────────────────────────────────────
  void _confirmDeleteProduct(ProductModel product) {
    final catalog = context.read<CatalogProvider>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Menu'),
        content: Text('Apakah Anda yakin ingin menghapus "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await catalog.deleteProduct(product.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Menu "${product.name}" berhasil dihapus'),
                      backgroundColor: AppTheme.accentRed,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal menghapus menu: $e'),
                      backgroundColor: AppTheme.accentRed,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentRed,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isAdmin = auth.userRole == 'admin';

    return Scaffold(
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _showProductFormDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Tambah Menu'),
            )
          : null,
      body: Column(
        children: [
          // ── Search bar ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) =>
                  context.read<CatalogProvider>().searchProducts(value),
              decoration: InputDecoration(
                hintText: 'Cari menu...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          context.read<CatalogProvider>().searchProducts('');
                        },
                      )
                    : null,
              ),
            ),
          ),

          // ── Category chips ────────────────────────────────────────────
          Consumer<CatalogProvider>(
            builder: (context, catalog, _) {
              return SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    _CategoryChip(
                      label: 'Semua',
                      isSelected: catalog.selectedCategoryId == null,
                      onTap: () => catalog.filterByCategory(null),
                    ),
                    ...catalog.categories.map(
                      (cat) => _CategoryChip(
                        label: cat.name,
                        isSelected: catalog.selectedCategoryId == cat.id,
                        onTap: () => catalog.filterByCategory(cat.id),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 8),

          // ── Product grid ──────────────────────────────────────────────
          Expanded(
            child: Consumer<CatalogProvider>(
              builder: (context, catalog, _) {
                if (catalog.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppTheme.primaryOrange),
                  );
                }

                if (catalog.errorMessage != null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline,
                              size: 48, color: AppTheme.accentRed),
                          const SizedBox(height: 12),
                          Text(
                            catalog.errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: AppTheme.textSecondary),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              catalog.fetchProducts();
                              catalog.fetchCategories();
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Coba Lagi'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (catalog.filteredProducts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.search_off,
                            size: 64,
                            color: AppTheme.textLight),
                        const SizedBox(height: 12),
                        const Text(
                          'Menu tidak ditemukan',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        if (isAdmin) ...[
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => _showProductFormDialog(),
                            icon: const Icon(Icons.add),
                            label: const Text('Tambah Menu Sekarang'),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.65,
                  ),
                  itemCount: catalog.filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = catalog.filteredProducts[index];
                    return _ProductCard(
                      product: product,
                      currencyFormat: _currencyFormat,
                      isAdmin: isAdmin,
                      onEdit: () => _showProductFormDialog(product: product),
                      onUpdateStock: () => _showUpdateStockDialog(product),
                      onDelete: () => _confirmDeleteProduct(product),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      // ── Floating cart summary bar ─────────────────────────────────────
      bottomNavigationBar: Consumer<CartProvider>(
        builder: (context, cart, _) {
          if (cart.isEmpty) return const SizedBox.shrink();

          return Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceWhite,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryOrange.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shopping_bag_outlined,
                      color: AppTheme.primaryOrange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${cart.totalItems} Item',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      Text(
                        _currencyFormat.format(cart.totalAmount),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () => context.push('/cart'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Lihat Pesanan'),
                        SizedBox(width: 6),
                        Icon(Icons.arrow_forward, size: 18),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// =============================================================================
// Category Chip
// =============================================================================

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: AppTheme.primaryOrange.withValues(alpha: 0.15),
        checkmarkColor: AppTheme.primaryOrange,
        labelStyle: TextStyle(
          color: isSelected ? AppTheme.primaryOrange : AppTheme.textSecondary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
        side: BorderSide(
          color: isSelected ? AppTheme.primaryOrange : AppTheme.dividerColor,
        ),
      ),
    );
  }
}

// =============================================================================
// Product Card
// =============================================================================

class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final NumberFormat currencyFormat;
  final bool isAdmin;
  final VoidCallback onEdit;
  final VoidCallback onUpdateStock;
  final VoidCallback onDelete;

  const _ProductCard({
    required this.product,
    required this.currencyFormat,
    required this.isAdmin,
    required this.onEdit,
    required this.onUpdateStock,
    required this.onDelete,
  });

  Color _stockColor() {
    if (product.stock > 5) return AppTheme.accentGreen;
    if (product.stock >= 1) return AppTheme.warningYellow;
    return AppTheme.accentRed;
  }

  String _stockLabel() {
    if (product.stock > 5) return 'Stok: ${product.stock}';
    if (product.stock >= 1) return 'Sisa ${product.stock}';
    return 'Habis';
  }

  bool get _canAdd => product.stock > 0 && product.isAvailable;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Image / placeholder ────────────────────────────────────
              Expanded(
                flex: 5,
                child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                    ? Image.network(
                        product.imageUrl!,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _imagePlaceholder(),
                      )
                    : _imagePlaceholder(),
              ),

              // ── Product info ───────────────────────────────────────────
              Expanded(
                flex: 6,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product name
                      Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),

                      // Category name
                      if (product.categoryName != null)
                        Text(
                          product.categoryName!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      const Spacer(),

                      // Price
                      Text(
                        currencyFormat.format(product.price),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryOrange,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Stock + Add button
                      Row(
                        children: [
                          // Stock indicator
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _stockColor().withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _stockLabel(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: _stockColor(),
                              ),
                            ),
                          ),
                          const Spacer(),

                          // Add to cart button
                          SizedBox(
                            height: 30,
                            child: ElevatedButton(
                              onPressed: _canAdd
                                  ? () {
                                      context
                                          .read<CartProvider>()
                                          .addToCart(product);
                                      ScaffoldMessenger.of(context)
                                        ..hideCurrentSnackBar()
                                        ..showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                '${product.name} ditambahkan'),
                                            duration:
                                                const Duration(milliseconds: 800),
                                            backgroundColor:
                                                AppTheme.accentGreen,
                                          ),
                                        );
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                textStyle: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                                disabledBackgroundColor: AppTheme.dividerColor,
                                disabledForegroundColor: AppTheme.textLight,
                              ),
                              child: Text(_canAdd ? 'Tambah' : 'Habis'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ── Admin Menu Popup Button ──────────────────────────────────────
          if (isAdmin)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  shape: BoxShape.circle,
                ),
                child: PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert,
                    size: 20,
                    color: AppTheme.secondaryDark,
                  ),
                  tooltip: 'Kelola Menu',
                  padding: EdgeInsets.zero,
                  onSelected: (action) {
                    switch (action) {
                      case 'edit':
                        onEdit();
                        break;
                      case 'stock':
                        onUpdateStock();
                        break;
                      case 'delete':
                        onDelete();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Edit Menu'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'stock',
                      child: Row(
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Ubah Stok'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline,
                              size: 18, color: AppTheme.accentRed),
                          SizedBox(width: 8),
                          Text('Hapus',
                              style: TextStyle(color: AppTheme.accentRed)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: double.infinity,
      color: AppTheme.primaryOrange.withValues(alpha: 0.08),
      child: const Center(
        child: Icon(
          Icons.restaurant,
          size: 40,
          color: AppTheme.primaryOrange,
        ),
      ),
    );
  }
}
