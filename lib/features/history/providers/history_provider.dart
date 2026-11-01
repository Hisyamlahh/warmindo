import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:warmindo_pos/features/catalog/models/order_model.dart';

class HistoryProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<OrderModel> _orders = [];
  bool _isLoading = false;
  String? _errorMessage;

  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  String? _filterStatus; // null (all), 'paid', 'cancelled', 'pending'

  List<OrderModel> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime? get filterStartDate => _filterStartDate;
  DateTime? get filterEndDate => _filterEndDate;
  String? get filterStatus => _filterStatus;

  Future<void> fetchOrders() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      var query = _supabase.from('orders').select('''
        *,
        tables (table_number),
        profiles (full_name),
        order_items (
          *,
          products (name)
        )
      ''');

      if (_filterStatus != null && _filterStatus!.isNotEmpty) {
        query = query.eq('payment_status', _filterStatus!);
      }

      if (_filterStartDate != null) {
        query = query.gte(
          'created_at',
          _filterStartDate!.toIso8601String(),
        );
      }

      if (_filterEndDate != null) {
        // Set to end of the day
        final endOfDay = DateTime(
          _filterEndDate!.year,
          _filterEndDate!.month,
          _filterEndDate!.day,
          23,
          59,
          59,
        );
        query = query.lte('created_at', endOfDay.toIso8601String());
      }

      final response = await query.order('created_at', ascending: false);

      _orders = (response as List<dynamic>)
          .map((json) => OrderModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _errorMessage = 'Gagal memuat riwayat transaksi: $e';
      debugPrint(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setDateFilter(DateTime? start, DateTime? end) {
    _filterStartDate = start;
    _filterEndDate = end;
    fetchOrders();
  }

  void setStatusFilter(String? status) {
    _filterStatus = status;
    fetchOrders();
  }

  void clearFilters() {
    _filterStartDate = null;
    _filterEndDate = null;
    _filterStatus = null;
    fetchOrders();
  }
}

