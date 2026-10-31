import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:warmindo_pos/core/theme/app_theme.dart';
import 'package:warmindo_pos/features/cart/models/cart_item_model.dart';
import 'package:warmindo_pos/features/cart/providers/cart_provider.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cart, _) {
        return Scaffold(
          appBar: AppBar(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Keranjang'),
                if (cart.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${cart.totalItems}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              if (cart.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_sweep_outlined),
                  tooltip: 'Kosongkan keranjang',
                  onPressed: () => _confirmClearCart(context, cart),
                ),
            ],
          ),
          body: cart.isEmpty ? _buildEmptyState(context) : _buildCartList(cart),
          bottomNavigationBar:
              cart.isEmpty ? null : _buildBottomBar(context, cart),
        );
      },
    );
  }

  // ===========================================================================
  // Empty state
  // ===========================================================================

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: AppTheme.textLight,
            ),
            const SizedBox(height: 16),
            const Text(
              'Keranjang kosong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Belum ada menu yang dipilih.\nYuk mulai pesan!',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.restaurant_menu),
              label: const Text('Mulai Pesan'),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // Cart item list
  // ===========================================================================

  Widget _buildCartList(CartProvider cart) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 140),
      children: [
        // Table banner
        if (cart.tableNumber != null) _buildTableBanner(cart.tableNumber!),

        // Cart items
        ...cart.items.map(
          (item) => _CartItemTile(
            item: item,
            currencyFormat: _currencyFormat,
          ),
        ),
      ],
    );
  }

  Widget _buildTableBanner(String tableNumber) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppTheme.primaryOrange.withValues(alpha: 0.12),
      child: Row(
        children: [
          const Icon(Icons.table_bar, color: AppTheme.primaryOrange, size: 20),
          const SizedBox(width: 8),
          Text(
            'Meja: $tableNumber',
            style: const TextStyle(
              color: AppTheme.primaryOrange,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Bottom checkout bar
  // ===========================================================================

  Widget _buildBottomBar(BuildContext context, CartProvider cart) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Divider
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Total row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.textSecondary,
                  ),
                ),
                Text(
                  _currencyFormat.format(cart.totalAmount),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Checkout button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.push('/checkout'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Proses Pembayaran',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // Confirm clear cart dialog
  // ===========================================================================

  void _confirmClearCart(BuildContext context, CartProvider cart) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kosongkan Keranjang?'),
        content:
            const Text('Semua item dalam keranjang akan dihapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              cart.clearCart();
              Navigator.of(ctx).pop();
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.accentRed),
            child: const Text('Hapus Semua'),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Cart Item Tile
// =============================================================================

class _CartItemTile extends StatefulWidget {
  final CartItemModel item;
  final NumberFormat currencyFormat;

  const _CartItemTile({
    required this.item,
    required this.currencyFormat,
  });

  @override
  State<_CartItemTile> createState() => _CartItemTileState();
}

class _CartItemTileState extends State<_CartItemTile> {
  bool _showNotes = false;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.item.notes ?? '');
    _showNotes = widget.item.notes != null && widget.item.notes!.isNotEmpty;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();
    final product = widget.item.product;
    final item = widget.item;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row: name + delete ────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.currencyFormat.format(product.price),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: AppTheme.accentRed, size: 20),
                  tooltip: 'Hapus',
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                  onPressed: () => cart.removeFromCart(product.id),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // ── Quantity controls + subtotal ─────────────────────────
            Row(
              children: [
                // Quantity controls
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.dividerColor),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _QtyButton(
                        icon: Icons.remove,
                        onTap: () => cart.updateQuantity(
                            product.id, item.quantity - 1),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text(
                          '${item.quantity}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      _QtyButton(
                        icon: Icons.add,
                        onTap: () => cart.updateQuantity(
                            product.id, item.quantity + 1),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Subtotal
                Text(
                  widget.currencyFormat.format(item.subtotal),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppTheme.primaryOrange,
                  ),
                ),
              ],
            ),

            // ── Notes (collapsible) ─────────────────────────────────
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () => setState(() => _showNotes = !_showNotes),
              child: Row(
                children: [
                  Icon(
                    _showNotes
                        ? Icons.sticky_note_2
                        : Icons.sticky_note_2_outlined,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _showNotes ? 'Sembunyikan catatan' : 'Tambah catatan',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (_showNotes) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _notesController,
                onChanged: (value) => cart.updateNotes(product.id, value),
                decoration: const InputDecoration(
                  hintText: 'Contoh: tidak pedas, tanpa sayur...',
                  hintStyle: TextStyle(fontSize: 13),
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                style: const TextStyle(fontSize: 13),
                maxLines: 2,
                textInputAction: TextInputAction.done,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Quantity Button
// =============================================================================

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 18, color: AppTheme.primaryOrange),
      ),
    );
  }
}
