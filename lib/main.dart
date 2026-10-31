import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:warmindo_pos/core/router/app_router.dart';
import 'package:warmindo_pos/core/services/supabase_service.dart';
import 'package:warmindo_pos/core/theme/app_theme.dart';
import 'package:warmindo_pos/core/utils/format_utils.dart';
import 'package:warmindo_pos/features/auth/providers/auth_provider.dart';
import 'package:warmindo_pos/features/cart/providers/cart_provider.dart';
import 'package:warmindo_pos/features/catalog/providers/catalog_provider.dart';
import 'package:warmindo_pos/features/checkout/providers/checkout_provider.dart';
import 'package:warmindo_pos/features/history/providers/history_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi locale bahasa Indonesia untuk format tanggal dan mata uang
  try {
    await initializeDateFormatting('id_ID', null);
    await FormatUtils.init();
  } catch (e) {
    debugPrint('DateFormatting initialize error: $e');
  }

  // Inisialisasi Supabase
  try {
    await SupabaseService.instance.initialize();
  } catch (e) {
    debugPrint('Supabase initialize error: $e');
  }

  runApp(const WarmindoApp());
}

class WarmindoApp extends StatefulWidget {
  const WarmindoApp({super.key});

  @override
  State<WarmindoApp> createState() => _WarmindoAppState();
}

class _WarmindoAppState extends State<WarmindoApp> {
  late final AuthProvider _authProvider;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider();
    _router = AppRouter.router(_authProvider);
  }

  @override
  void dispose() {
    _authProvider.dispose();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider(create: (_) => CatalogProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => CheckoutProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
      ],
      child: MaterialApp.router(
        title: 'Warmindo JugaJago',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: _router,
      ),
    );
  }
}
