import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

class FormatUtils {
  FormatUtils._();

  static bool _isDateInitialized = false;

  static Future<void> init() async {
    if (!_isDateInitialized) {
      try {
        await initializeDateFormatting('id_ID', null);
        _isDateInitialized = true;
      } catch (_) {}
    }
  }

  static final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  /// Format angka ke format Rupiah (Rp 15.000)
  static String formatCurrency(double amount) {
    return _currencyFormat.format(amount);
  }

  /// Format tanggal (31 Okt 2026)
  static String formatDate(DateTime date) {
    try {
      return DateFormat('dd MMM yyyy', 'id_ID').format(date);
    } catch (_) {
      return DateFormat('dd MMM yyyy').format(date);
    }
  }

  /// Format waktu (22:30)
  static String formatTime(DateTime date) {
    try {
      return DateFormat('HH:mm', 'id_ID').format(date);
    } catch (_) {
      return DateFormat('HH:mm').format(date);
    }
  }

  /// Format tanggal dan waktu (31 Okt 2026, 22:30)
  static String formatDateTime(DateTime date) {
    try {
      return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(date);
    } catch (_) {
      return DateFormat('dd MMM yyyy, HH:mm').format(date);
    }
  }
}
