import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:warmindo_pos/core/theme/app_theme.dart';
import 'package:warmindo_pos/core/utils/format_utils.dart';
import 'package:warmindo_pos/core/widgets/empty_state_widget.dart';
import 'package:warmindo_pos/core/widgets/status_badge.dart';
import 'package:warmindo_pos/features/catalog/models/order_model.dart';
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
              primary: AppTheme.primaryOrange,
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
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Container(
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
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: ReceiptWidget(order: order),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
                        label: 'Batal',
                        isSelected: history.filterStatus == 'cancelled',
                        onSelected: () => history.setStatusFilter('cancelled'),
                      ),
                      const SizedBox(width: 8),
                      _StatusFilterChip(
                        label: 'Pending',
                        isSelected: history.filterStatus == 'pending',
                        onSelected: () => history.setStatusFilter('pending'),
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
                      color: AppTheme.primaryOrange,
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
      selectedColor: AppTheme.primaryOrange.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? AppTheme.primaryOrange : AppTheme.textPrimary,
      ),
      side: BorderSide(
        color: isSelected ? AppTheme.primaryOrange : AppTheme.dividerColor,
      ),
    );
  }
}

class _OrderHistoryCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onTap;

  const _OrderHistoryCard({
    required this.order,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
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
                          color: AppTheme.primaryOrange.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          order.paymentMethod == 'cash'
                              ? Icons.payments_outlined
                              : Icons.qr_code,
                          color: AppTheme.primaryOrange,
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
                      color: AppTheme.primaryOrange,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
