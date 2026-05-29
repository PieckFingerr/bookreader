// lib/utils/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primary = Color(0xFF2D6A4F);
  static const Color primaryLight = Color(0xFF52B788);
  static const Color primaryDark = Color(0xFF1B4332);
  static const Color accent = Color(0xFFD4A373);
  static const Color accentLight = Color(0xFFF4E3C8);
  static const Color background = Color(0xFFFAF7F2);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5F0E8);
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFFADB5BD);
  static const Color divider = Color(0xFFE8E0D5);
  static const Color error = Color(0xFFDC3545);
  static const Color success = Color(0xFF28A745);
  static const Color warning = Color(0xFFFFC107);
  static const Color starColor = Color(0xFFFFC107);

  static const Map<String, Color> genreColors = {
    'Tiên hiệp': Color(0xFF7B61FF),
    'Fantasy': Color(0xFF4ECDC4),
    'Lãng mạn': Color(0xFFFF6B9D),
    'Isekai': Color(0xFF45B7D1),
    'Hành động': Color(0xFFFF6348),
    'Trinh thám': Color(0xFF2C2C54),
    'Kinh dị': Color(0xFF6C5CE7),
    'Học đường': Color(0xFFFFB347),
    'Hệ thống': Color(0xFF00B894),
    'Drama': Color(0xFFE17055),
    'Phiêu lưu': Color(0xFF0984E3),
    'Tình cảm': Color(0xFFFF7675),
    'Huyền bí': Color(0xFFA29BFE),
  };

  static Color getGenreColor(String genre) =>
      genreColors[genre] ?? const Color(0xFF6B7280);

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.light,
          surface: surface,
          primary: primary,
          secondary: accent,
          error: error,
        ),
        scaffoldBackgroundColor: background,
        textTheme: GoogleFonts.merriweatherTextTheme().copyWith(
          displayLarge: GoogleFonts.playfairDisplay(
            fontSize: 32, fontWeight: FontWeight.w700, color: textPrimary,
          ),
          displayMedium: GoogleFonts.playfairDisplay(
            fontSize: 26, fontWeight: FontWeight.w700, color: textPrimary,
          ),
          displaySmall: GoogleFonts.playfairDisplay(
            fontSize: 22, fontWeight: FontWeight.w600, color: textPrimary,
          ),
          headlineMedium: GoogleFonts.playfairDisplay(
            fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary,
          ),
          headlineSmall: GoogleFonts.nunito(
            fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary,
          ),
          titleLarge: GoogleFonts.nunito(
            fontSize: 15, fontWeight: FontWeight.w700, color: textPrimary,
          ),
          titleMedium: GoogleFonts.nunito(
            fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary,
          ),
          bodyLarge: GoogleFonts.merriweather(
            fontSize: 15, color: textPrimary, height: 1.8,
          ),
          bodyMedium: GoogleFonts.nunito(
            fontSize: 14, color: textSecondary,
          ),
          bodySmall: GoogleFonts.nunito(
            fontSize: 12, color: textSecondary,
          ),
          labelLarge: GoogleFonts.nunito(
            fontSize: 14, fontWeight: FontWeight.w600, color: surface,
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: surface,
          elevation: 0,
          centerTitle: false,
          iconTheme: const IconThemeData(color: textPrimary),
          titleTextStyle: GoogleFonts.playfairDisplay(
            fontSize: 20, fontWeight: FontWeight.w700, color: textPrimary,
          ),
          surfaceTintColor: Colors.transparent,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: primary,
            side: const BorderSide(color: primary, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surfaceVariant,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: error),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          hintStyle: GoogleFonts.nunito(color: textHint, fontSize: 14),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: surfaceVariant,
          selectedColor: primaryLight.withOpacity(0.2),
          labelStyle: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          side: const BorderSide(color: divider),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: surface,
          selectedItemColor: primary,
          unselectedItemColor: textHint,
          elevation: 8,
          type: BottomNavigationBarType.fixed,
        ),
        dividerTheme: const DividerThemeData(color: divider, thickness: 1),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: textPrimary,
          contentTextStyle: GoogleFonts.nunito(color: Colors.white, fontSize: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          behavior: SnackBarBehavior.floating,
        ),
      );
}

const List<String> kAllGenres = [
  'Tiên hiệp', 'Fantasy', 'Isekai', 'Lãng mạn', 'Hành động',
  'Trinh thám', 'Kinh dị', 'Học đường', 'Hệ thống', 'Drama',
  'Phiêu lưu', 'Tình cảm', 'Huyền bí',
];

const List<String> kAllStatuses = ['ongoing', 'completed', 'hiatus'];

String formatNumber(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
  return n.toString();
}