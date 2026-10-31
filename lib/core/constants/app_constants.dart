class AppConstants {
  AppConstants._();

  // Supabase Configuration
  static const String supabaseUrl = 'https://ymbjzwjsagkcrqwpeubf.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InltYmp6d2pzYWdrY3Jxd3BldWJmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTM0NTUwNTgsImV4cCI6MjEwOTAzMTA1OH0._uVnjaN-Pck3jmWzcb3vE-1eO-6J31cGyYKcI8QmMUU';

  // App Info
  static const String appName = 'Warmindo JugaJago';
  static const String appSubtitle = 'Warung Makan Indomie';
  static const String appVersion = '1.0.0';

  // Table QR Prefix
  static const String qrPrefix = 'WARMINDO_TABLE_';

  // Payment QR Prefix
  static const String paymentQrPrefix = 'WARMINDO_PAY_';

  // Currency
  static const String currency = 'Rp';

  // Categories
  static const List<String> defaultCategories = [
    'Indomie Kuah',
    'Indomie Goreng',
    'Minuman',
    'Topping',
    'Snack',
  ];
}
