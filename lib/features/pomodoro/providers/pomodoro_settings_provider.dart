// lib/features/pomodoro/providers/pomodoro_settings_provider.dart
//
// Changes vs original:
//   N5 — Settings are now persisted to SharedPreferences.
//        The provider stays a synchronous NotifierProvider<..., PomodoroSettings>
//        so every existing caller (pomodoro_notifier.dart, settings_sheet.dart,
//        pomodoro_screen.dart, etc.) continues to receive a plain PomodoroSettings
//        value — zero call-site changes needed.
//
//        On build(), defaults are returned immediately (no flicker) and
//        SharedPreferences is loaded asynchronously in the background. Each
//        setter updates state synchronously and persists fire-and-forget.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────────────────────────────────────

class PomodoroSettings {
  final int workMinutes;        // default 25
  final int shortBreakMinutes;  // default 5
  final int longBreakMinutes;   // default 15

  const PomodoroSettings({
    this.workMinutes       = 25,
    this.shortBreakMinutes = 5,
    this.longBreakMinutes  = 15,
  });

  PomodoroSettings copyWith({
    int? workMinutes,
    int? shortBreakMinutes,
    int? longBreakMinutes,
  }) => PomodoroSettings(
    workMinutes       : workMinutes       ?? this.workMinutes,
    shortBreakMinutes : shortBreakMinutes ?? this.shortBreakMinutes,
    longBreakMinutes  : longBreakMinutes  ?? this.longBreakMinutes,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SharedPreferences keys
// ─────────────────────────────────────────────────────────────────────────────

const _kWork       = 'pomo_work_minutes';
const _kShortBreak = 'pomo_short_break_minutes';
const _kLongBreak  = 'pomo_long_break_minutes';

// ─────────────────────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────────────────────

// ── BUG N5 FIX ───────────────────────────────────────────────────────────────
// Provider type stays NotifierProvider<..., PomodoroSettings> — synchronous —
// so no call-sites need to change. build() fires a background load from
// SharedPreferences and updates state once available. Every setter persists
// immediately (synchronous state update + async prefs write).
// ─────────────────────────────────────────────────────────────────────────────

final pomodoroSettingsProvider =
NotifierProvider<PomodoroSettingsNotifier, PomodoroSettings>(
  PomodoroSettingsNotifier.new,
);

class PomodoroSettingsNotifier extends Notifier<PomodoroSettings> {
  @override
  PomodoroSettings build() {
    // Return defaults immediately so the UI never waits.
    // Load persisted values in the background and update state once ready.
    _loadFromPrefs();
    return const PomodoroSettings();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    state = PomodoroSettings(
      workMinutes       : prefs.getInt(_kWork)       ?? state.workMinutes,
      shortBreakMinutes : prefs.getInt(_kShortBreak) ?? state.shortBreakMinutes,
      longBreakMinutes  : prefs.getInt(_kLongBreak)  ?? state.longBreakMinutes,
    );
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kWork,       state.workMinutes);
    await prefs.setInt(_kShortBreak, state.shortBreakMinutes);
    await prefs.setInt(_kLongBreak,  state.longBreakMinutes);
  }

  void setWorkMinutes(int v) {
    state = state.copyWith(workMinutes: v.clamp(1, 60));
    _persist();
  }

  void setShortBreakMinutes(int v) {
    state = state.copyWith(shortBreakMinutes: v.clamp(1, 30));
    _persist();
  }

  void setLongBreakMinutes(int v) {
    state = state.copyWith(longBreakMinutes: v.clamp(1, 60));
    _persist();
  }
}