import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

// ── Accent presets ────────────────────────────────────────────────────────────

class AccentPreset {
  final String name;
  final Color darkPrimary;
  final Color darkPrimaryLight;
  final Color darkPrimaryMuted;
  final Color lightPrimary;
  final Color lightPrimaryLight;
  final Color lightPrimaryMuted;
  // The swatch color shown in the picker (always visible regardless of mode)
  final Color swatch;

  const AccentPreset({
    required this.name,
    required this.darkPrimary,
    required this.darkPrimaryLight,
    required this.darkPrimaryMuted,
    required this.lightPrimary,
    required this.lightPrimaryLight,
    required this.lightPrimaryMuted,
    required this.swatch,
  });
}

const List<AccentPreset> accentPresets = [
  AccentPreset(
    name: 'Sage',
    darkPrimary:       Color(0xFF7FAF8E),
    darkPrimaryLight:  Color(0xFF93C3A3),
    darkPrimaryMuted:  Color(0xFF2F3A34),
    lightPrimary:      Color(0xFF6B8F7A),
    lightPrimaryLight: Color(0xFF5E7D6B),
    lightPrimaryMuted: Color(0xFFDCE8E1),
    swatch:            Color(0xFF7FAF8E),
  ),
  AccentPreset(
    name: 'Slate',
    darkPrimary:       Color(0xFF7A9EBF),
    darkPrimaryLight:  Color(0xFF93B4CF),
    darkPrimaryMuted:  Color(0xFF2A3540),
    lightPrimary:      Color(0xFF5C7FA0),
    lightPrimaryLight: Color(0xFF4E6E8C),
    lightPrimaryMuted: Color(0xFFD8E4EF),
    swatch:            Color(0xFF7A9EBF),
  ),
  AccentPreset(
    name: 'Lavender',
    darkPrimary:       Color(0xFF9E8FBF),
    darkPrimaryLight:  Color(0xFFB3A5CF),
    darkPrimaryMuted:  Color(0xFF352E40),
    lightPrimary:      Color(0xFF7D6EA0),
    lightPrimaryLight: Color(0xFF6C5E8C),
    lightPrimaryMuted: Color(0xFFEAE4F0),
    swatch:            Color(0xFF9E8FBF),
  ),
  AccentPreset(
    name: 'Rose',
    darkPrimary:       Color(0xFFBF8F9E),
    darkPrimaryLight:  Color(0xFFCFA5B0),
    darkPrimaryMuted:  Color(0xFF3F2E35),
    lightPrimary:      Color(0xFF9E6B7A),
    lightPrimaryLight: Color(0xFF8C5C6A),
    lightPrimaryMuted: Color(0xFFF0E2E6),
    swatch:            Color(0xFFBF8F9E),
  ),
  AccentPreset(
    name: 'Amber',
    darkPrimary:       Color(0xFFCFAF6E),
    darkPrimaryLight:  Color(0xFFDFC98A),
    darkPrimaryMuted:  Color(0xFF3A3020),
    lightPrimary:      Color(0xFFAF8E4A),
    lightPrimaryLight: Color(0xFF9C7C3C),
    lightPrimaryMuted: Color(0xFFF0E8D4),
    swatch:            Color(0xFFCFAF6E),
  ),
];

// ── Theme State ───────────────────────────────────────────────────────────────

class ThemeState {
  final ThemeMode mode;
  final int accentIndex;

  const ThemeState({
    this.mode = ThemeMode.dark,
    this.accentIndex = 0,
  });

  ThemeState copyWith({ThemeMode? mode, int? accentIndex}) => ThemeState(
    mode: mode ?? this.mode,
    accentIndex: accentIndex ?? this.accentIndex,
  );

  bool get isDark => mode == ThemeMode.dark;
  AccentPreset get accent => accentPresets[accentIndex];
}

// ── Provider ──────────────────────────────────────────────────────────────────

final themeProvider =
NotifierProvider<ThemeNotifier, ThemeState>(ThemeNotifier.new);

class ThemeNotifier extends Notifier<ThemeState> {
  static const _modeKey   = 'theme_mode';
  static const _accentKey = 'theme_accent';

  @override
  ThemeState build() {
    _load();
    return const ThemeState();
  }

  Future<void> _load() async {
    final prefs  = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_modeKey) ?? true;
    final accent = (prefs.getInt(_accentKey) ?? 0)
        .clamp(0, accentPresets.length - 1);
    final loaded = ThemeState(
      mode: isDark ? ThemeMode.dark : ThemeMode.light,
      accentIndex: accent,
    );
    AppTheme.apply(loaded);
    state = loaded;
  }

  Future<void> setMode(ThemeMode mode) async {
    final next = state.copyWith(mode: mode);
    AppTheme.apply(next);
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_modeKey, mode == ThemeMode.dark);
  }

  Future<void> setAccent(int index) async {
    final next = state.copyWith(accentIndex: index);
    AppTheme.apply(next);
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_accentKey, index);
  }

  void toggleMode() =>
      setMode(state.isDark ? ThemeMode.light : ThemeMode.dark);
}