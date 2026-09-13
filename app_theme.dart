// THEME LOCK: dark — source: fintech domain signal (premium, used at home/night)
// Scaffold.backgroundColor = AppTheme.backgroundDark — ALL screens

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Brand colors ──────────────────────────────────────────────────
  static const Color primary = Color(0xFF00E5A0);
  static const Color primaryContainer = Color(0xff00e5a026);
  static const Color secondary = Color(0xFF6C5CE7);
  static const Color secondaryContainer = Color(0xff6c5ce726);

  // ── Semantic colors ───────────────────────────────────────────────
  static const Color success = Color(0xFF00C97A);
  static const Color successContainer = Color(0xff00c97a1a);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningContainer = Color(0xfff59e0b1a);
  static const Color error = Color(0xFFEF4444);
  static const Color errorContainer = Color(0xffef44441a);

  // ── Dark surfaces ─────────────────────────────────────────────────
  static const Color backgroundDark = Color(0xFF0A0A0F);
  static const Color surfaceDark = Color(0xFF111118);
  static const Color surfaceVariantDark = Color(0xFF1A1A24);
  static const Color surfaceGlassDark = Color(0xFF1E1E2A);

  // ── Light surfaces (required by framework) ────────────────────────
  static const Color backgroundLight = Color(0xFFF4F6FA);
  static const Color surfaceLight = Color(0xFFFFFFFF);

  // ── Text colors ───────────────────────────────────────────────────
  static const Color textPrimaryDark = Color(0xFFEEEEF5);
  static const Color textSecondaryDark = Color(0xFF8888A0);
  static const Color textMutedDark = Color(0xFF4A4A5A);

  // ── Card gradient ─────────────────────────────────────────────────
  static const List<Color> cardGradient = [
    Color(0xFF1A3A2A),
    Color(0xFF0D2E40),
  ];
  static const List<Color> cardGradientViolet = [
    Color(0xFF2A1A3A),
    Color(0xFF1A0D2E),
  ];

  // ─────────────────────────────────────────────────────────────────
  // DARK THEME
  // ─────────────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      colorScheme: const ColorScheme.dark(
        primary: primary,
        onPrimary: Color(0xFF003322),
        primaryContainer: primaryContainer,
        onPrimaryContainer: primary,
        secondary: secondary,
        onSecondary: Colors.white,
        secondaryContainer: secondaryContainer,
        onSecondaryContainer: secondary,
        surface: surfaceDark,
        onSurface: textPrimaryDark,
        surfaceContainerHighest: surfaceVariantDark,
        onSurfaceVariant: textSecondaryDark,
        error: error,
        onError: Colors.white,
        outline: Color(0xFF2A2A3A),
        outlineVariant: Color(0xFF1E1E2A),
      ),
      scaffoldBackgroundColor: backgroundDark,
      textTheme: GoogleFonts.manropeTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.manrope(
          fontSize: 36,
          fontWeight: FontWeight.w700,
          color: textPrimaryDark,
        ),
        displayMedium: GoogleFonts.manrope(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: textPrimaryDark,
        ),
        headlineLarge: GoogleFonts.manrope(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: textPrimaryDark,
        ),
        headlineMedium: GoogleFonts.manrope(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimaryDark,
        ),
        titleLarge: GoogleFonts.manrope(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimaryDark,
        ),
        titleMedium: GoogleFonts.manrope(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimaryDark,
        ),
        titleSmall: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textPrimaryDark,
        ),
        bodyLarge: GoogleFonts.manrope(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: textPrimaryDark,
        ),
        bodyMedium: GoogleFonts.manrope(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: textSecondaryDark,
        ),
        bodySmall: GoogleFonts.manrope(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: textMutedDark,
        ),
        labelLarge: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textPrimaryDark,
        ),
        labelMedium: GoogleFonts.manrope(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textSecondaryDark,
          letterSpacing: 0.3,
        ),
        labelSmall: GoogleFonts.manrope(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: textMutedDark,
          letterSpacing: 0.3,
        ),
      ),
      appBarTheme: AppBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: GoogleFonts.manrope(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textPrimaryDark,
        ),
        iconTheme: const IconThemeData(color: textPrimaryDark),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: surfaceVariantDark,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF2A2A3A)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF2A2A3A)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: error, width: 1.5),
        ),
        labelStyle: GoogleFonts.manrope(color: textSecondaryDark, fontSize: 14),
        hintStyle: GoogleFonts.manrope(color: textMutedDark, fontSize: 14),
        errorStyle: GoogleFonts.manrope(color: error, fontSize: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: const Color(0xFF003322),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.manrope(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: const Color(0xFF003322),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.manrope(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.manrope(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceVariantDark,
        selectedColor: primaryContainer,
        labelStyle: GoogleFonts.manrope(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        side: const BorderSide(color: Color(0xFF2A2A3A)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF1E1E2A),
        thickness: 1,
        space: 1,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // LIGHT THEME (required — mirrors dark structure)
  // ─────────────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      colorScheme: ColorScheme.light(
        primary: primary,
        onPrimary: const Color(0xFF003322),
        secondary: secondary,
        onSecondary: Colors.white,
        surface: surfaceLight,
        onSurface: const Color(0xFF1A1A2E),
        error: error,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: backgroundLight,
      textTheme: GoogleFonts.manropeTextTheme(base.textTheme),
    );
  }
}
