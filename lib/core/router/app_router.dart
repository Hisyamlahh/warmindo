import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:warmindo_pos/features/auth/providers/auth_provider.dart';
import 'package:warmindo_pos/features/auth/screens/login_screen.dart';
import 'package:warmindo_pos/features/cart/screens/cart_screen.dart';
import 'package:warmindo_pos/features/catalog/models/order_model.dart';
import 'package:warmindo_pos/features/checkout/screens/checkout_screen.dart';
import 'package:warmindo_pos/features/checkout/screens/receipt_screen.dart';
import 'package:warmindo_pos/features/dashboard/screens/dashboard_screen.dart';
import 'package:warmindo_pos/features/splash/screens/splash_screen.dart';

class AppRouter {
  AppRouter._();

  static GoRouter router(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: '/splash',
      refreshListenable: authProvider,
      routes: [
        GoRoute(
          path: '/splash',
          name: 'splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/dashboard',
          name: 'dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/cart',
          name: 'cart',
          builder: (context, state) => const CartScreen(),
        ),
        GoRoute(
          path: '/checkout',
          name: 'checkout',
          builder: (context, state) => const CheckoutScreen(),
        ),
        GoRoute(
          path: '/receipt',
          name: 'receipt',
          builder: (context, state) {
            final order = state.extra as OrderModel?;
            if (order == null) {
              return const DashboardScreen();
            }
            return ReceiptScreen(order: order);
          },
        ),
      ],
      redirect: (BuildContext context, GoRouterState state) {
        final isOnSplash = state.matchedLocation == '/splash';

        // Never redirect away from splash – let it handle navigation itself.
        if (isOnSplash) return null;

        final isAuthenticated = authProvider.isAuthenticated;
        final isOnLogin = state.matchedLocation == '/login';

        // Not authenticated -> force to login
        if (!isAuthenticated) {
          return isOnLogin ? null : '/login';
        }

        // Authenticated but on login -> send to dashboard
        if (isOnLogin) {
          return '/dashboard';
        }

        return null;
      },
    );
  }
}
