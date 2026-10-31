import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:warmindo_pos/core/theme/app_theme.dart';
import 'package:warmindo_pos/core/widgets/warmindo_logo.dart';
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
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted || _hasNavigated) return;

    final authProvider = context.read<AuthProvider>();

    try {
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
      backgroundColor: AppTheme.warmindoRed,
      body: Stack(
        children: [
          // Background decorative elements
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.warmindoYellow.withValues(alpha: 0.08),
              ),
            ),
          ),

          // Main Center Content
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo Spanduk Warmindo
                  const WarmindoLogo(width: 300),
                  const SizedBox(height: 32),

                  // Subtitle
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Sistem Kasir & Operasional Digital',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
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
                        AppTheme.warmindoYellow,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Tri-Color Bar (Kuning & Hijau)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              children: [
                Container(height: 6, color: AppTheme.warmindoYellow),
                Container(height: 10, color: AppTheme.warmindoGreen),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
