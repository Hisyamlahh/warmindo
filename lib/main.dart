import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:warmindo_pos/core/router/app_router.dart';
import 'package:warmindo_pos/core/services/supabase_service.dart';
import 'package:warmindo_pos/core/theme/app_theme.dart';
import 'package:warmindo_pos/features/auth/providers/auth_provider.dart';
import 'package:warmindo_pos/features/cart/providers/cart_provider.dart';
import 'package:warmindo_pos/features/catalog/providers/catalog_provider.dart';
import 'package:warmindo_pos/features/checkout/providers/checkout_provider.dart';
import 'package:warmindo_pos/features/history/providers/history_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.instance.initialize();
  runApp(const WarmindoApp());
}

class WarmindoApp extends StatelessWidget {
  const WarmindoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CatalogProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => CheckoutProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final router = AppRouter.router(authProvider);
          return MaterialApp.router(
            title: 'Warmindo POS',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            routerConfig: router,
          );
        },
      ),
    );
  }
}
