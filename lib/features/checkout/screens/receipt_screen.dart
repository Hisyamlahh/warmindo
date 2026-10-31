import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:warmindo_pos/core/utils/format_utils.dart';
import 'package:warmindo_pos/features/catalog/models/order_model.dart';
import 'package:warmindo_pos/features/checkout/widgets/receipt_widget.dart';

class ReceiptScreen extends StatelessWidget {
  final OrderModel order;

  const ReceiptScreen({
    super.key,
    required this.order,
  });

  void _shareReceiptText() {
    final buffer = StringBuffer();
    buffer.writeln('=== STRUK PEMBAYARAN WARMINDO JUGAJAGO ===');
    buffer.writeln('No. Transaksi : ${order.shortId}');
    buffer.writeln('Tanggal       : ${FormatUtils.formatDateTime(order.createdAt)}');
    if (order.tableNumber != null) {
      buffer.writeln('Meja          : Meja ${order.tableNumber}');
    }
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
    buffer.writeln('Terima kasih telah berkunjung ke Warmindo!');

    Share.share(buffer.toString());
  }

  @override
  Widget build(BuildContext context) {
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
              ReceiptWidget(order: order),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _shareReceiptText,
                      icon: const Icon(Icons.share),
                      label: const Text('Bagikan Struk'),
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
