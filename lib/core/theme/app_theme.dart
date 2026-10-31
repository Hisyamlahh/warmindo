import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // Authentic Warmindo Brand Colors (Merah, Kuning, Hijau, Biru Logo)
  static const Color warmindoRed = Color(0xFFE51A22); // Merah Khas Spanduk Warmindo
  static const Color warmindoYellow = Color(0xFFFFD200); // Kuning Khas Garis & Font
  static const Color warmindoGreen = Color(0xFF009B4D); // Hijau Khas Garis Bawah
  static const Color warmindoBlue = Color(0xFF00A0E9); // Biru Cyan Khas Teks "Warmindo"
  static const Color warmindoDarkRed = Color(0xFFB7151C);

  // Aliases for compatibility
  static const Color primaryOrange = warmindoRed;
  static const Color primaryDark = warmindoDarkRed;
  static const Color secondaryDark = Color(0xFF1E272E);
  static const Color accentGreen = warmindoGreen;
  static const Color accentRed = warmindoRed;
  static const Color warningYellow = warmindoYellow;

  // Backgrounds & Neutrals
  static const Color backgroundWhite = Color(0xFFF9FAFB);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF2D3436);
  static const Color textSecondary = Color(0xFF636E72);
  static const Color textLight = Color(0xFFB2BEC3);
  static const Color dividerColor = Color(0xFFDFE6E9);

  // Gradient Khas Warmindo Spanduk (Merah -> Kuning -> Hijau)
  static const LinearGradient warmindoStripGradient = LinearGradient(
    colors: [warmindoRed, warmindoYellow, warmindoGreen],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient warmindoHeaderGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFE51A22),
      Color(0xFFC71118),
    ],
  );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorSchemeSeed: warmindoRed,
      scaffoldBackgroundColor: backgroundWhite,
      appBarTheme: const AppBarTheme(
        backgroundColor: warmindoRed,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: warmindoRed,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: warmindoRed,
          side: const BorderSide(color: warmindoRed, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: warmindoRed, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: warmindoRed),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceWhite,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: warmindoRed,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceWhite,
        selectedItemColor: warmindoRed,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: backgroundWhite,
        selectedColor: warmindoRed.withValues(alpha: 0.12),
        labelStyle: const TextStyle(fontSize: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
