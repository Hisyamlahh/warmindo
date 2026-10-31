import 'package:flutter/material.dart';
import 'package:warmindo_pos/core/theme/app_theme.dart';

/// Badge status (Lunas, Batal, Pending, Available, Occupied)
class StatusBadge extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.text,
    required this.color,
    this.icon,
  });

  factory StatusBadge.paid() => const StatusBadge(
        text: 'Lunas',
        color: AppTheme.accentGreen,
        icon: Icons.check_circle,
      );

  factory StatusBadge.cancelled() => const StatusBadge(
        text: 'Batal',
        color: AppTheme.accentRed,
        icon: Icons.cancel,
      );

  factory StatusBadge.pending() => const StatusBadge(
        text: 'Pending',
        color: AppTheme.warningYellow,
        icon: Icons.access_time,
      );

  factory StatusBadge.available() => const StatusBadge(
        text: 'Tersedia',
        color: AppTheme.accentGreen,
      );

  factory StatusBadge.occupied() => const StatusBadge(
        text: 'Terisi',
        color: AppTheme.primaryOrange,
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

