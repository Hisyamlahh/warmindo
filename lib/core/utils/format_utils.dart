import 'package:intl/intl.dart';

class FormatUtils {
  FormatUtils._();

  static final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static final _dateFormat = DateFormat('dd MMM yyyy', 'id_ID');
  static final _timeFormat = DateFormat('HH:mm', 'id_ID');
  static final _dateTimeFormat = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');

  /// Format angka ke format Rupiah (Rp 15.000)
  static String formatCurrency(double amount) {
    return _currencyFormat.format(amount);
  }

  /// Format tanggal (31 Okt 2026)
  static String formatDate(DateTime date) {
    return _dateFormat.format(date);
  }

  /// Format waktu (22:30)
  static String formatTime(DateTime date) {
    return _timeFormat.format(date);
  }

  /// Format tanggal dan waktu (31 Okt 2026, 22:30)
  static String formatDateTime(DateTime date) {
    return _dateTimeFormat.format(date);
  }
}

