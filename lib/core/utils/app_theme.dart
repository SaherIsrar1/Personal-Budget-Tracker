import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Brand Colors ──────────────────────────────────────────────
  static const Color primary       = Color(0xFF1BA589);
  static const Color primaryDark   = Color(0xFF0D7A6B);
  static const Color primaryLight  = Color(0xFFE1F5EE);
  static const Color accent        = Color(0xFF00C9A7);

  static const Color income        = Color(0xFF1BA589);
  static const Color expense       = Color(0xFFE05252);

  static const Color background    = Color(0xFFF7F9FB);
  static const Color surface       = Color(0xFFFFFFFF);
  static const Color cardBorder    = Color(0xFFEEEEEE);

  static const Color textPrimary   = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF8A94A6);
  static const Color textHint      = Color(0xFFBBC4D0);

  // ── Text Styles ───────────────────────────────────────────────
  static TextStyle get displayLarge => GoogleFonts.dmSans(
    fontSize: 32, fontWeight: FontWeight.w700, color: textPrimary,
    letterSpacing: -1.0,
  );

  static TextStyle get displayMedium => GoogleFonts.dmSans(
    fontSize: 24, fontWeight: FontWeight.w600, color: textPrimary,
    letterSpacing: -0.5,
  );

  static TextStyle get titleLarge => GoogleFonts.dmSans(
    fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary,
  );

  static TextStyle get titleMedium => GoogleFonts.dmSans(
    fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary,
  );

  static TextStyle get bodyLarge => GoogleFonts.dmSans(
    fontSize: 15, fontWeight: FontWeight.w400, color: textPrimary,
  );

  static TextStyle get bodyMedium => GoogleFonts.dmSans(
    fontSize: 13, fontWeight: FontWeight.w400, color: textSecondary,
  );

  static TextStyle get labelSmall => GoogleFonts.dmSans(
    fontSize: 11, fontWeight: FontWeight.w500, color: textSecondary,
    letterSpacing: 0.4,
  );

  // ── ThemeData ─────────────────────────────────────────────────
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.light(
        primary: primary,
        secondary: accent,
        surface: surface,
        background: background,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
      ),
      textTheme: GoogleFonts.dmSansTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: textPrimary),
        titleTextStyle: titleLarge,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w600),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          side: const BorderSide(color: primary, width: 1.5),
          textStyle: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: cardBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: cardBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: expense, width: 1),
        ),
        hintStyle: GoogleFonts.dmSans(color: textHint, fontSize: 14),
        labelStyle: GoogleFonts.dmSans(color: textSecondary, fontSize: 14),
      ),
    );
  }
}
