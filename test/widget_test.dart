import 'package:flutter_test/flutter_test.dart';
import 'package:warmindo_pos/core/constants/app_constants.dart';
import 'package:warmindo_pos/core/utils/format_utils.dart';

void main() {
  test('FormatUtils formats currency properly', () {
    final formatted = FormatUtils.formatCurrency(15000);
    expect(formatted.contains('15.000'), isTrue);
  });

  test('AppConstants has proper prefixes', () {
    expect(AppConstants.qrPrefix, 'WARMINDO_TABLE_');
    expect(AppConstants.paymentQrPrefix, 'WARMINDO_PAY_');
  });
}
