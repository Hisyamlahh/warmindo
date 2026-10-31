import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:warmindo_pos/core/theme/app_theme.dart';
import 'package:warmindo_pos/features/auth/providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _animationController.forward();
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    // Tunggu animasi splash 1.5 detik
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted || _hasNavigated) return;

    final authProvider = context.read<AuthProvider>();

    try {
      // Timeout maksimal 3 detik agar aplikasi tidak pernah hang/stuck
      await authProvider.checkAuthStatus().timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          debugPrint('Auth check timeout, proceeding to login screen');
        },
      );
    } catch (e) {
      debugPrint('Auth check error: $e');
    }

    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;

    if (authProvider.isAuthenticated) {
      context.go('/dashboard');
    } else {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryOrange,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.restaurant_menu,
                  size: 64,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 28),

              // App name
              const Text(
                'Warmindo POS',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),

              // Subtitle
              Text(
                'Sistem Kasir Digital',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.85),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 48),

              // Loading indicator
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
