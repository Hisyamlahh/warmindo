import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:warmindo_pos/core/theme/app_theme.dart';
import 'package:warmindo_pos/core/utils/format_utils.dart';
import 'package:warmindo_pos/core/widgets/empty_state_widget.dart';
import 'package:warmindo_pos/core/widgets/status_badge.dart';
import 'package:warmindo_pos/features/catalog/models/order_model.dart';
import 'package:warmindo_pos/features/checkout/providers/checkout_provider.dart';
import 'package:warmindo_pos/features/checkout/widgets/receipt_widget.dart';
import 'package:warmindo_pos/features/history/providers/history_provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HistoryProvider>().fetchOrders();
    });
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final history = context.read<HistoryProvider>();
    final initialRange = DateTimeRange(
      start: history.filterStartDate ??
          DateTime.now().subtract(const Duration(days: 7)),
      end: history.filterEndDate ?? DateTime.now(),
    );

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: initialRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.warmindoRed,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      history.setDateFilter(picked.start, picked.end);
    }
  }

  void _showReceiptBottomSheet(BuildContext context, OrderModel order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.88,
        minChildSize: 0.5,
        maxChildSize: 0.96,
        builder: (_, scrollController) => _ReceiptBottomSheetView(
          order: order,
          scrollController: scrollController,
        ),
      ),
    );
  }

  Future<void> _showPaymentDialog(OrderModel order) async {
    String paymentMethod = 'cash';
    final cashController = TextEditingController(
      text: order.totalAmount.toInt().toString(),
    );
    double enteredCash = order.totalAmount;

    final success = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          final diff = enteredCash - order.totalAmount;
          final change = diff > 0 ? diff : 0.0;
          final isSufficient = paymentMethod != 'cash' || enteredCash >= order.totalAmount;

          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.payment, color: AppTheme.warmindoGreen),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Bayar #${order.shortId}',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (order.tableNumber != null)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.warmindoYellow.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Meja: Meja ${order.tableNumber}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  Text(
                    'Total Tagihan: ${FormatUtils.formatCurrency(order.totalAmount)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.warmindoRed,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Metode Pembayaran:', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Tunai')),
                          selected: paymentMethod == 'cash',
                          selectedColor: AppTheme.warmindoRed.withValues(alpha: 0.15),
                          onSelected: (val) {
                            if (val) setDialogState(() => paymentMethod = 'cash');
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('QRIS')),
                          selected: paymentMethod == 'qris',
                          selectedColor: AppTheme.warmindoRed.withValues(alpha: 0.15),
                          onSelected: (val) {
                            if (val) setDialogState(() => paymentMethod = 'qris');
                          },
                        ),
                      ),
                    ],
                  ),
                  if (paymentMethod == 'cash') ...[
                    const SizedBox(height: 14),
                    TextField(
                      controller: cashController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Uang Diterima (Rp)',
                        prefixText: 'Rp ',
                      ),
                      onChanged: (val) {
                        setDialogState(() {
                          enteredCash = double.tryParse(val) ?? 0.0;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      children: [
                        ActionChip(
                          label: const Text('Uang Pas'),
                          onPressed: () {
                            setDialogState(() {
                              cashController.text = order.totalAmount.toInt().toString();
                              enteredCash = order.totalAmount;
                            });
                          },
                        ),
                        ActionChip(
                          label: const Text('+10k'),
                          onPressed: () {
                            setDialogState(() {
                              final newAmt = enteredCash + 10000;
                              cashController.text = newAmt.toInt().toString();
                              enteredCash = newAmt;
                            });
                          },
                        ),
                        ActionChip(
                          label: const Text('+50k'),
                          onPressed: () {
                            setDialogState(() {
                              final newAmt = enteredCash + 50000;
                              cashController.text = newAmt.toInt().toString();
                              enteredCash = newAmt;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Kembalian: ${FormatUtils.formatCurrency(change)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSufficient ? AppTheme.warmindoGreen : AppTheme.accentRed,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx, false),
                child: const Text('Tutup'),
              ),
              ElevatedButton(
                onPressed: !isSufficient
                    ? null
                    : () async {
                        final checkout = dialogCtx.read<CheckoutProvider>();
                        final ok = await checkout.payPendingOrder(
                          order: order,
                          cashPaid: paymentMethod == 'cash' ? enteredCash : order.totalAmount,
                          paymentMethod: paymentMethod,
                        );
                        if (dialogCtx.mounted) {
                          Navigator.pop(dialogCtx, ok);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.warmindoGreen,
                ),
                child: const Text('Konfirmasi Lunas'),
              ),
            ],
          );
        },
      ),
    );

    if (!mounted) return;
    if (success == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pembayaran Pesanan #${order.shortId} berhasil diselesaikan!'),
          backgroundColor: AppTheme.accentGreen,
        ),
      );
      context.read<HistoryProvider>().fetchOrders();
    }
  }

  Future<void> _confirmCancelOrder(OrderModel order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.accentRed),
            SizedBox(width: 8),
            Text('Batalkan Pesanan?'),
          ],
        ),
        content: Text(
          'Pesanan #${order.shortId} (Meja ${order.tableNumber ?? '-'}) akan dibatalkan.\n\n'
          'Stok menu akan dikembalikan dan meja akan otomatis diset Tersedia.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentRed,
            ),
            child: const Text('Ya, Batalkan Pesanan'),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) return;

    final checkout = context.read<CheckoutProvider>();
    final ok = await checkout.cancelOrder(order);

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pesanan #${order.shortId} berhasil dibatalkan'),
          backgroundColor: AppTheme.accentRed,
        ),
      );
      context.read<HistoryProvider>().fetchOrders();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(checkout.errorMessage ?? 'Gagal membatalkan pesanan'),
          backgroundColor: AppTheme.accentRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final history = context.watch<HistoryProvider>();

    return Scaffold(
      body: Column(
        children: [
          // Filter Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Date Range Button
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _selectDateRange(context),
                        icon: const Icon(Icons.date_range, size: 18),
                        label: Text(
                          history.filterStartDate != null &&
                                  history.filterEndDate != null
                              ? '${FormatUtils.formatDate(history.filterStartDate!)} - ${FormatUtils.formatDate(history.filterEndDate!)}'
                              : 'Semua Tanggal',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                    if (history.filterStartDate != null ||
                        history.filterStatus != null)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        tooltip: 'Reset Filter',
                        onPressed: () => history.clearFilters(),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                // Status Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _StatusFilterChip(
                        label: 'Semua',
                        isSelected: history.filterStatus == null,
                        onSelected: () => history.setStatusFilter(null),
                      ),
                      const SizedBox(width: 8),
                      _StatusFilterChip(
                        label: 'Lunas',
                        isSelected: history.filterStatus == 'paid',
                        onSelected: () => history.setStatusFilter('paid'),
                      ),
                      const SizedBox(width: 8),
                      _StatusFilterChip(
                        label: 'Pending',
                        isSelected: history.filterStatus == 'pending',
                        onSelected: () => history.setStatusFilter('pending'),
                      ),
                      const SizedBox(width: 8),
                      _StatusFilterChip(
                        label: 'Batal',
                        isSelected: history.filterStatus == 'cancelled',
                        onSelected: () => history.setStatusFilter('cancelled'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Orders List
          Expanded(
            child: history.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.warmindoRed,
                    ),
                  )
                : history.orders.isEmpty
                    ? RefreshIndicator(
                        onRefresh: history.fetchOrders,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: SizedBox(
                            height: MediaQuery.of(context).size.height * 0.6,
                            child: EmptyStateWidget(
                              icon: Icons.receipt_long,
                              title: 'Belum Ada Transaksi',
                              subtitle: history.filterStatus != null ||
                                      history.filterStartDate != null
                                  ? 'Tidak ada transaksi dengan filter ini'
                                  : 'Transaksi yang telah selesai akan muncul di sini',
                              actionText: 'Refresh',
                              onAction: history.fetchOrders,
                            ),
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: history.fetchOrders,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: history.orders.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final order = history.orders[index];
                            return _OrderHistoryCard(
                              order: order,
                              onTap: () =>
                                  _showReceiptBottomSheet(context, order),
                              onPayNow: order.isPending
                                  ? () => _showPaymentDialog(order)
                                  : null,
                              onCancel: order.isPending
                                  ? () => _confirmCancelOrder(order)
                                  : null,
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _StatusFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  const _StatusFilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: AppTheme.warmindoRed.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? AppTheme.warmindoRed : AppTheme.textPrimary,
      ),
      side: BorderSide(
        color: isSelected ? AppTheme.warmindoRed : AppTheme.dividerColor,
      ),
    );
  }
}

class _OrderHistoryCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onTap;
  final VoidCallback? onPayNow;
  final VoidCallback? onCancel;

  const _OrderHistoryCard({
    required this.order,
    required this.onTap,
    this.onPayNow,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.warmindoRed.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          order.paymentMethod == 'cash'
                              ? Icons.payments_outlined
                              : Icons.qr_code,
                          color: AppTheme.warmindoRed,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '#${order.shortId}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            FormatUtils.formatDateTime(order.createdAt),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (order.isPaid)
                    StatusBadge.paid()
                  else if (order.isCancelled)
                    StatusBadge.cancelled()
                  else
                    StatusBadge.pending(),
                ],
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    order.tableNumber != null
                        ? 'Meja ${order.tableNumber}'
                        : 'Takeaway / Umum',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    FormatUtils.formatCurrency(order.totalAmount),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.warmindoRed,
                    ),
                  ),
                ],
              ),

              // Action buttons if Pending
              if (order.isPending) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.warningYellow.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, size: 14, color: AppTheme.warningYellow),
                      SizedBox(width: 6),
                      Text(
                        'Pesanan belum dibayar',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (onCancel != null)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onCancel,
                          icon: const Icon(Icons.cancel_outlined, size: 16, color: AppTheme.accentRed),
                          label: const Text(
                            'Batal',
                            style: TextStyle(color: AppTheme.accentRed, fontSize: 13),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.accentRed),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    if (onCancel != null && onPayNow != null)
                      const SizedBox(width: 8),
                    if (onPayNow != null)
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: onPayNow,
                          icon: const Icon(Icons.check_circle_outline, size: 16, color: Colors.white),
                          label: const Text(
                            'Bayar Sekarang',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.warmindoGreen,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ReceiptBottomSheetView extends StatefulWidget {
  final OrderModel order;
  final ScrollController scrollController;

  const _ReceiptBottomSheetView({
    required this.order,
    required this.scrollController,
  });

  @override
  State<_ReceiptBottomSheetView> createState() => _ReceiptBottomSheetViewState();
}

class _ReceiptBottomSheetViewState extends State<_ReceiptBottomSheetView> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isSavingImage = false;

  Future<void> _downloadAndShareReceiptImage() async {
    setState(() => _isSavingImage = true);
    try {
      final imageBytes = await _screenshotController.capture(
        delay: const Duration(milliseconds: 60),
        pixelRatio: 3.0,
      );

      if (imageBytes == null) {
        throw Exception('Gagal membuat gambar nota');
      }

      final tempDir = await getApplicationDocumentsDirectory();
      final fileName = 'nota_warmindo_${widget.order.shortId}_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(imageBytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nota tersimpan: $fileName'),
            backgroundColor: AppTheme.accentGreen,
          ),
        );

        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Struk Nota #${widget.order.shortId} Meja ${widget.order.tableNumber ?? '-'} - Warmindo JugaJago',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengunduh nota: $e'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingImage = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.backgroundWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Detail Struk Transaksi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isSavingImage ? null : _downloadAndShareReceiptImage,
                  icon: _isSavingImage
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.download, size: 16, color: Colors.white),
                  label: Text(
                    _isSavingImage ? 'Menyiapkan...' : 'Unduh Nota (PNG)',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.warmindoGreen,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: SingleChildScrollView(
              controller: widget.scrollController,
              padding: const EdgeInsets.all(16),
              child: Screenshot(
                controller: _screenshotController,
                child: ReceiptWidget(order: widget.order),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

