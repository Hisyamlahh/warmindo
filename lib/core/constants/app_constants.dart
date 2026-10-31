class AppConstants {
  AppConstants._();

  // Supabase Configuration
  // Ganti dengan kredensial Supabase Anda
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';

  // App Info
  static const String appName = 'Warmindo POS';
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

