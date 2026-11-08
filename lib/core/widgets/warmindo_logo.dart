import 'package:flutter/material.dart';

/// Logo utama aplikasi Warmindo JugaJago
///
/// Menggunakan aset logo PNG transparan dari kreasi resmi Warmindo JugaJago.
class WarmindoLogo extends StatelessWidget {
  final double width;
  final double? height;
  final bool compact;

  const WarmindoLogo({
    super.key,
    this.width = 240,
    this.height,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveWidth = compact ? width * 0.75 : width;
    return Image.asset(
      'assets/images/logo.png',
      width: effectiveWidth,
      height: height,
      fit: BoxFit.contain,
      semanticLabel: 'Logo Warmindo JugaJago',
    );
  }
}
