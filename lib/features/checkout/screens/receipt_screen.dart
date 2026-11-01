import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:warmindo_pos/core/theme/app_theme.dart';
import 'package:warmindo_pos/core/utils/format_utils.dart';
import 'package:warmindo_pos/features/catalog/models/order_model.dart';
import 'package:warmindo_pos/features/checkout/widgets/receipt_widget.dart';

class ReceiptScreen extends StatefulWidget {
  final OrderModel order;

  const ReceiptScreen({
    super.key,
    required this.order,
  });

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isSavingImage = false;

  void _shareReceiptText() {
    final order = widget.order;
    final buffer = StringBuffer();
    buffer.writeln('=== STRUK PEMBAYARAN WARMINDO JUGAJAGO ===');
    buffer.writeln('No. Transaksi : ${order.shortId}');
    buffer.writeln('Tanggal       : ${FormatUtils.formatDateTime(order.createdAt)}');
    if (order.tableNumber != null) {
      buffer.writeln('Meja          : Meja ${order.tableNumber}');
    }
    buffer.writeln('Status        : ${order.paymentStatus.toUpperCase()}');
    buffer.writeln('----------------------------------');
    for (final item in order.items) {
      buffer.writeln(
        '${item.productName ?? 'Item'} x${item.quantity} = ${FormatUtils.formatCurrency(item.subtotal)}',
      );
    }
    buffer.writeln('----------------------------------');
    buffer.writeln('TOTAL         : ${FormatUtils.formatCurrency(order.totalAmount)}');
    buffer.writeln('Metode        : ${order.paymentMethod.toUpperCase()}');
    if (order.paymentMethod == 'cash') {
      buffer.writeln('Uang Tunai    : ${FormatUtils.formatCurrency(order.cashPaid)}');
      buffer.writeln('Kembalian     : ${FormatUtils.formatCurrency(order.changeAmount)}');
    }
    buffer.writeln('==================================');
    buffer.writeln('Terima kasih telah berkunjung ke Warmindo JugaJago!');

    Share.share(buffer.toString());
  }

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

        // Langsung buka pilihan share / kirim / cetak ke printer bluetooth
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Struk Nota Pembayaran Meja ${widget.order.tableNumber ?? '-'} - Warmindo JugaJago',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan nota: $e'),
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
    final order = widget.order;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          context.go('/dashboard');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Struk Pembayaran'),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => context.go('/dashboard'),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Screenshot(
                controller: _screenshotController,
                child: ReceiptWidget(order: order),
              ),
              const SizedBox(height: 24),
              // Download / Print Receipt Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSavingImage ? null : _downloadAndShareReceiptImage,
                  icon: _isSavingImage
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.download, color: Colors.white),
                  label: Text(
                    _isSavingImage ? 'Menyiapkan Nota...' : 'Unduh & Cetak Nota (PNG)',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.warmindoGreen,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _shareReceiptText,
                      icon: const Icon(Icons.share),
                      label: const Text('Teks Struk'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => context.go('/dashboard'),
                      icon: const Icon(Icons.add_shopping_cart),
                      label: const Text('Transaksi Baru'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
