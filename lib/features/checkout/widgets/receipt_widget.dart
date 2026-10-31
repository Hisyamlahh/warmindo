import 'package:flutter/material.dart';
import 'package:warmindo_pos/core/theme/app_theme.dart';
import 'package:warmindo_pos/core/utils/format_utils.dart';
import 'package:warmindo_pos/features/catalog/models/order_model.dart';

class ReceiptWidget extends StatelessWidget {
  final OrderModel order;

  const ReceiptWidget({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          const Center(
            child: Text(
              'WARMINDO JUGAJAGO',
              style: TextStyle(
                fontFamily: 'Courier',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Center(
            child: Text(
              'Warung Makan Indomie & Minuman',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildDashedLine(),
          const SizedBox(height: 12),

          // Order Meta Info
          _buildRow('No. Transaksi', order.shortId),
          _buildRow('Tanggal', FormatUtils.formatDateTime(order.createdAt)),
          if (order.tableNumber != null)
            _buildRow('Meja', 'Meja ${order.tableNumber}'),
          if (order.cashierName != null)
            _buildRow('Kasir', order.cashierName!),
          _buildRow('Status', order.paymentStatus.toUpperCase()),

          const SizedBox(height: 12),
          _buildDashedLine(),
          const SizedBox(height: 12),

          // Items list
          ...order.items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item.productName ?? 'Menu #${item.productId}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          FormatUtils.formatCurrency(item.subtotal),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${item.quantity} x ${FormatUtils.formatCurrency(item.unitPrice)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    if (item.notes != null && item.notes!.isNotEmpty)
                      Text(
                        'Catatan: ${item.notes}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                  ],
                ),
              )),

          const SizedBox(height: 12),
          _buildDashedLine(),
          const SizedBox(height: 12),

          // Total & Payment
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TOTAL',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                FormatUtils.formatCurrency(order.totalAmount),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryOrange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildRow(
            'Metode Pembayaran',
            order.paymentMethod == 'cash' ? 'Tunai (Cash)' : 'QRIS',
          ),
          if (order.paymentMethod == 'cash') ...[
            _buildRow('Uang Diterima', FormatUtils.formatCurrency(order.cashPaid)),
            _buildRow('Kembalian', FormatUtils.formatCurrency(order.changeAmount)),
          ],

          const SizedBox(height: 16),
          _buildDashedLine(),
          const SizedBox(height: 16),

          // Footer
          const Center(
            child: Text(
              'Terima Kasih Atas Kunjungan Anda!',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Center(
            child: Text(
              'Silakan Berkunjung Kembali',
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.textLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashedLine() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 5.0;
        const dashSpace = 4.0;
        final dashCount = (boxWidth / (dashWidth + dashSpace)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return const SizedBox(
              width: dashWidth,
              height: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(color: AppTheme.dividerColor),
              ),
            );
          }),
        );
      },
    );
  }
}

