import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:warmindo_pos/core/constants/app_constants.dart';
import 'package:warmindo_pos/core/theme/app_theme.dart';
import 'package:warmindo_pos/core/utils/format_utils.dart';
import 'package:warmindo_pos/core/widgets/loading_button.dart';
import 'package:warmindo_pos/features/auth/providers/auth_provider.dart';
import 'package:warmindo_pos/features/cart/providers/cart_provider.dart';
import 'package:warmindo_pos/features/checkout/providers/checkout_provider.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final TextEditingController _cashController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cart = context.read<CartProvider>();
      final checkout = context.read<CheckoutProvider>();
      checkout.reset();
      // Default cash is exact amount
      _cashController.text = cart.totalAmount.toInt().toString();
      checkout.setCashPaid(cart.totalAmount);
    });
  }

  @override
  void dispose() {
    _cashController.dispose();
    super.dispose();
  }

  void _setQuickCash(double amount) {
    _cashController.text = amount.toInt().toString();
    context.read<CheckoutProvider>().setCashPaid(amount);
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final checkout = context.watch<CheckoutProvider>();
    final auth = context.watch<AuthProvider>();

    final total = cart.totalAmount;
    final change = checkout.getChangeAmount(total);
    final isSufficient = checkout.isCashSufficient(total);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pembayaran'),
      ),
      body: cart.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.remove_shopping_cart,
                      size: 64, color: AppTheme.textLight),
                  const SizedBox(height: 16),
                  const Text('Keranjang Belanja Kosong'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.go('/dashboard'),
                    child: const Text('Kembali ke Menu'),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Order Summary Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Ringkasan Pesanan',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              if (cart.tableNumber != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryOrange
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Meja ${cart.tableNumber}',
                                    style: const TextStyle(
                                      color: AppTheme.primaryOrange,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const Divider(height: 24),
                          ...cart.items.map((item) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${item.quantity}x ${item.product.name}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      FormatUtils.formatCurrency(item.subtotal),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Tagihan',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                FormatUtils.formatCurrency(total),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryOrange,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Payment Method Selector
                  const Text(
                    'Pilih Metode Pembayaran',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _PaymentMethodOption(
                          title: 'Tunai (Cash)',
                          icon: Icons.payments_outlined,
                          isSelected: checkout.paymentMethod == 'cash',
                          onTap: () => checkout.setPaymentMethod('cash'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _PaymentMethodOption(
                          title: 'QRIS',
                          icon: Icons.qr_code_2,
                          isSelected: checkout.paymentMethod == 'qris',
                          onTap: () => checkout.setPaymentMethod('qris'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Content based on payment method
                  if (checkout.paymentMethod == 'cash') ...[
                    // Cash Input Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Nominal Uang Tunai',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _cashController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                              decoration: const InputDecoration(
                                prefixText: 'Rp ',
                                prefixStyle: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryOrange,
                                ),
                              ),
                              onChanged: (val) {
                                final amount = double.tryParse(val) ?? 0.0;
                                checkout.setCashPaid(amount);
                              },
                            ),
                            const SizedBox(height: 12),
                            // Quick Cash Buttons
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _QuickCashChip(
                                  label: 'Uang Pas',
                                  onTap: () => _setQuickCash(total),
                                ),
                                _QuickCashChip(
                                  label: 'Rp 20.000',
                                  onTap: () => _setQuickCash(20000),
                                ),
                                _QuickCashChip(
                                  label: 'Rp 50.000',
                                  onTap: () => _setQuickCash(50000),
                                ),
                                _QuickCashChip(
                                  label: 'Rp 100.000',
                                  onTap: () => _setQuickCash(100000),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            // Kembalian Display
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Kembalian',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  FormatUtils.formatCurrency(change),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isSufficient
                                        ? AppTheme.accentGreen
                                        : AppTheme.accentRed,
                                  ),
                                ),
                              ],
                            ),
                            if (!isSufficient) ...[
                              const SizedBox(height: 4),
                              const Text(
                                'Nominal yang dibayar masih kurang',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.accentRed,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    // QRIS Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            const Text(
                              'Pindai QRIS untuk Bayar',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              FormatUtils.formatCurrency(total),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryOrange,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppTheme.dividerColor,
                                ),
                              ),
                              child: QrImageView(
                                data:
                                    '${AppConstants.paymentQrPrefix}TRX_${total.toInt()}_${DateTime.now().millisecondsSinceEpoch}',
                                version: QrVersions.auto,
                                size: 200,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Mendukung Gopay, OVO, Dana, ShopeePay, BCA, dll.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  if (checkout.errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.accentRed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        checkout.errorMessage!,
                        style: const TextStyle(color: AppTheme.accentRed),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Submit Payment Button
                  LoadingButton(
                    text: checkout.paymentMethod == 'cash'
                        ? 'Konfirmasi Pembayaran'
                        : 'Selesai & Cetak Struk',
                    isLoading: checkout.isProcessing,
                    icon: Icons.check_circle_outline,
                    onPressed: (!isSufficient && checkout.paymentMethod == 'cash')
                        ? null
                        : () async {
                            final completedOrder = await checkout.processPayment(
                              cart: cart,
                              cashierId: auth.currentUser?.id,
                              cashierName:
                                  auth.currentUser?.email?.split('@').first ??
                                      'Kasir',
                            );

                            if (completedOrder != null && context.mounted) {
                              context.push('/receipt', extra: completedOrder);
                            }
                          },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}

class _PaymentMethodOption extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentMethodOption({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryOrange.withValues(alpha: 0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryOrange : AppTheme.dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected
                  ? AppTheme.primaryOrange
                  : AppTheme.textSecondary,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? AppTheme.primaryOrange
                    : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickCashChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickCashChip({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: Colors.white,
      side: const BorderSide(color: AppTheme.dividerColor),
      labelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
      ),
    );
  }
}
