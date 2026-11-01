import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:warmindo_pos/core/theme/app_theme.dart';
import 'package:warmindo_pos/features/auth/providers/auth_provider.dart';
import 'package:warmindo_pos/features/catalog/screens/catalog_screen.dart';
import 'package:warmindo_pos/features/history/screens/history_screen.dart';
import 'package:warmindo_pos/features/qr_generator/screens/qr_generator_screen.dart';
import 'package:warmindo_pos/features/qr_scanner/screens/qr_scanner_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  static const List<_TabItem> _allTabs = [
    _TabItem(
      label: 'Katalog',
      icon: Icons.restaurant_menu,
      role: null,
    ),
    _TabItem(
      label: 'Scan QR',
      icon: Icons.qr_code_scanner,
      role: null,
    ),
    _TabItem(
      label: 'Meja',
      icon: Icons.table_restaurant,
      role: null, // Kasir dan Admin sama-sama bisa melihat status meja
    ),
    _TabItem(
      label: 'Riwayat',
      icon: Icons.history,
      role: null,
    ),
  ];

  List<_TabItem> _visibleTabs(String role) {
    if (role == 'admin') return _allTabs;
    return _allTabs.where((t) => t.role == null).toList();
  }

  Widget _buildBody(_TabItem tab) {
    switch (tab.label) {
      case 'Katalog':
        return const CatalogScreen();
      case 'Scan QR':
        return QrScannerScreen(
          onTableBound: () {
            setState(() {
              _currentIndex = 0; // Pindah otomatis ke Katalog Menu
            });
          },
        );
      case 'Meja':
      case 'Generate QR':
        return const QrGeneratorScreen();
      case 'Riwayat':
        return const HistoryScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final tabs = _visibleTabs(auth.userRole);

        if (_currentIndex >= tabs.length) {
          _currentIndex = 0;
        }

        return Scaffold(
          appBar: AppBar(
            backgroundColor: AppTheme.warmindoRed,
            elevation: 2,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: 'Warmindo ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text: 'JugaJago',
                        style: TextStyle(
                          color: AppTheme.warmindoYellow,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _RoleBadge(role: auth.userRole),
              ],
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(4),
              child: Column(
                children: [
                  Container(height: 2, color: AppTheme.warmindoYellow),
                  Container(height: 2, color: AppTheme.warmindoGreen),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                tooltip: 'Keluar',
                onPressed: () => _confirmLogout(context, auth),
              ),
            ],
          ),
          body: IndexedStack(
            index: _currentIndex,
            children: tabs.map((tab) => _buildBody(tab)).toList(),
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            items: tabs
                .map(
                  (tab) => BottomNavigationBarItem(
                    icon: Icon(tab.icon),
                    label: tab.label,
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }

  Future<void> _confirmLogout(BuildContext context, AuthProvider auth) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentRed,
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (shouldLogout == true && context.mounted) {
      await auth.logout();
      if (context.mounted) {
        context.go('/login');
      }
    }
  }
}

class _TabItem {
  final String label;
  final IconData icon;
  final String? role;

  const _TabItem({
    required this.label,
    required this.icon,
    required this.role,
  });
}

class _RoleBadge extends StatelessWidget {
  final String role;

  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final isAdmin = role == 'admin';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isAdmin
            ? Colors.white.withValues(alpha: 0.25)
            : Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isAdmin ? 'Admin' : 'Kasir',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}
