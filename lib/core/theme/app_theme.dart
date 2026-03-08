// lib/core/theme/app_theme.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../flavor/app_flavor.dart';

class AppTheme {
  // ── Flavor ────────────────────────────────────────────────────────────────
  static AppFlavor _flavor = AppFlavor.mint;

  /// Call this once in main() after detecting the flavor, before runApp().
  /// FIX: no longer hardcodes basboosa colors — apply() handles everything.
  static void configure(AppFlavor flavor) {
    _flavor = flavor;
  }

  // ── Mutable static fields ─────────────────────────────────────────────────

  static Color background    = const Color(0xFF1E1C1A);
  static Color surface       = const Color(0xFF262320);
  static Color surfaceBorder = const Color(0xFF3A352F);
  static Color elevated      = const Color(0xFF2E2A26);

  static Color primary       = const Color(0xFF7FAF8E);
  static Color primaryLight  = const Color(0xFF93C3A3);
  static Color primaryMuted  = const Color(0xFF2F3A34);

  static Color gold          = const Color(0xFFCFAF6E);
  static Color goldLight     = const Color(0xFFDFC98A);

  static Color get coral      => gold;
  static Color get coralLight => goldLight;

  static Color textPrimary   = const Color(0xFFF1EDE6);
  static Color textSecondary = const Color(0xFFB7B0A6);
  static Color textDisabled  = const Color(0xFF6B6560);

  static Color success       = const Color(0xFF7FAF8E);
  static Color warning       = const Color(0xFFCFAF6E);
  static Color error         = const Color(0xFFD17C6C);

  static Color pomodoroWork  = const Color(0xFF7FAF8E);
  static Color pomodoroBreak = const Color(0xFF8FA8B8);

  // ── Apply — called by ThemeNotifier on every mode/accent change ───────────

  static void apply(dynamic themeState) {
    final isDark = themeState.isDark as bool;
    final accent = themeState.accent;

    if (isDark) {
      background    = const Color(0xFF1E1C1A);
      surface       = const Color(0xFF262320);
      surfaceBorder = const Color(0xFF3A352F);
      elevated      = const Color(0xFF2E2A26);
      textPrimary   = const Color(0xFFF1EDE6);
      textSecondary = const Color(0xFFB7B0A6);
      textDisabled  = const Color(0xFF6B6560);
      error         = const Color(0xFFD17C6C);
      pomodoroBreak = const Color(0xFF8FA8B8);
      primary       = accent.darkPrimary       as Color;
      primaryLight  = accent.darkPrimaryLight  as Color;
      primaryMuted  = accent.darkPrimaryMuted  as Color;
    } else {
      background    = const Color(0xFFF6F1E8);
      surface       = const Color(0xFFFFFFFF);
      surfaceBorder = const Color(0xFFE4DDD3);
      elevated      = const Color(0xFFEFE7DC);
      textPrimary   = const Color(0xFF2E2A26);
      textSecondary = const Color(0xFF6F6A64);
      textDisabled  = const Color(0xFFB0AA9F);
      error         = const Color(0xFFC26A5A);
      pomodoroBreak = const Color(0xFF6A8FA8);
      primary       = accent.lightPrimary       as Color;
      primaryLight  = accent.lightPrimaryLight  as Color;
      primaryMuted  = accent.lightPrimaryMuted  as Color;
    }

    // FIX: removed basboosa hardcoded override — both flavors now use
    // the full accent + dark/light system identically.

    // Semantic colors follow primary
    success      = primary;
    warning      = isDark ? const Color(0xFFCFAF6E) : const Color(0xFFAF8E4A);
    gold         = isDark ? const Color(0xFFCFAF6E) : const Color(0xFFAF8E4A);
    goldLight    = isDark ? const Color(0xFFDFC98A) : const Color(0xFF9C7C3C);
    pomodoroWork = primary;
  }

  // ── Text Styles ────────────────────────────────────────────────────────────

  static TextStyle get display => GoogleFonts.poppins(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: -0.2,
  );

  static TextStyle get heading => GoogleFonts.poppins(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static TextStyle get body => GoogleFonts.poppins(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: textPrimary,
  );

  static TextStyle get caption => GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: textSecondary,
    letterSpacing: 0.3,
  );

  static TextStyle get label => GoogleFonts.poppins(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: textSecondary,
  );

  // ── ThemeData generators ───────────────────────────────────────────────────

  static ThemeData get dark  => _buildTheme(Brightness.dark);
  static ThemeData get light => _buildTheme(Brightness.light);

  static ThemeData _buildTheme(Brightness brightness) => ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: background,
    colorScheme: ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: brightness == Brightness.dark
          ? const Color(0xFF1E1C1A)
          : const Color(0xFFFFFFFF),
      secondary: gold,
      onSecondary: brightness == Brightness.dark
          ? const Color(0xFF1E1C1A)
          : const Color(0xFFFFFFFF),
      error: error,
      onError: Colors.white,
      surface: surface,
      onSurface: textPrimary,
    ),
  );
}