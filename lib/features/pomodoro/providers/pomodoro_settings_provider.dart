import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    workMinutes:       workMinutes       ?? this.workMinutes,
    shortBreakMinutes: shortBreakMinutes ?? this.shortBreakMinutes,
    longBreakMinutes:  longBreakMinutes  ?? this.longBreakMinutes,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────────────────────

final pomodoroSettingsProvider =
NotifierProvider<PomodoroSettingsNotifier, PomodoroSettings>(
  PomodoroSettingsNotifier.new,
);

class PomodoroSettingsNotifier extends Notifier<PomodoroSettings> {
  @override
  PomodoroSettings build() => const PomodoroSettings();

  void setWorkMinutes(int v) =>
      state = state.copyWith(workMinutes: v.clamp(1, 60));

  void setShortBreakMinutes(int v) =>
      state = state.copyWith(shortBreakMinutes: v.clamp(1, 30));

  void setLongBreakMinutes(int v) =>
      state = state.copyWith(longBreakMinutes: v.clamp(1, 60));
}