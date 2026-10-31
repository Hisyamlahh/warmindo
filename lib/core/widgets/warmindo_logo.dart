import 'package:flutter/material.dart';
import 'package:warmindo_pos/core/theme/app_theme.dart';

class WarmindoLogo extends StatelessWidget {
  final double width;
  final bool compact;

  const WarmindoLogo({
    super.key,
    this.width = 280,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: AppTheme.warmindoRed,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              vertical: compact ? 10 : 16,
              horizontal: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tagline atas: "Warung Makan Indomie"
                Text(
                  'Warung Makan Indomie',
                  style: TextStyle(
                    color: AppTheme.warmindoYellow,
                    fontSize: compact ? 11 : 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                SizedBox(height: compact ? 2 : 4),

                // Logo Warmindo (Biru Cyan dengan outline putih)
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer outline putih
                    Text(
                      'Warmindo',
                      style: TextStyle(
                        fontSize: compact ? 26 : 34,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        letterSpacing: 1.2,
                        foreground: Paint()
                          ..style = PaintingStyle.stroke
                          ..strokeWidth = compact ? 3.5 : 4.5
                          ..color = Colors.white,
                      ),
                    ),
                    // Teks biru di tengah
                    Text(
                      'Warmindo',
                      style: TextStyle(
                        color: AppTheme.warmindoBlue,
                        fontSize: compact ? 26 : 34,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: compact ? 2 : 4),

                // Nama Toko: "JUGAJAGO" (Kuning Emas Bold)
                Text(
                  'JUGAJAGO',
                  style: TextStyle(
                    color: AppTheme.warmindoYellow,
                    fontSize: compact ? 16 : 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                  ),
                ),
              ],
            ),
          ),

          // Strip Warna Khas Bawah: Kuning & Hijau
          Column(
            children: [
              Container(
                height: compact ? 5 : 7,
                color: AppTheme.warmindoYellow,
              ),
              Container(
                height: compact ? 7 : 9,
                color: AppTheme.warmindoGreen,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
