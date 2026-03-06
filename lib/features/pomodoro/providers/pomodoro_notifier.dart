import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/repository_providers.dart';
import 'pomodoro_settings_provider.dart';

enum PomodoroStatus { idle, running, paused, completed }
enum PomodoroPhase { work, shortBreak, longBreak }

class PomodoroState {
  final PomodoroStatus status;
  final PomodoroPhase phase;
  final int secondsLeft;
  final int completedSessions;
  final String? attachedTaskId;

  const PomodoroState({
    this.status = PomodoroStatus.idle,
    this.phase = PomodoroPhase.work,
    this.secondsLeft = 25 * 60,
    this.completedSessions = 0,
    this.attachedTaskId,
  });

  PomodoroState copyWith({
    PomodoroStatus? status,
    PomodoroPhase? phase,
    int? secondsLeft,
    int? completedSessions,
    // Sentinel so callers can explicitly pass null to clear the field.
    // Without this, `null ?? this.attachedTaskId` always keeps the old value.
    Object? attachedTaskId = _keepValue,
  }) {
    return PomodoroState(
      status:            status            ?? this.status,
      phase:             phase             ?? this.phase,
      secondsLeft:       secondsLeft       ?? this.secondsLeft,
      completedSessions: completedSessions ?? this.completedSessions,
      attachedTaskId: attachedTaskId == _keepValue
          ? this.attachedTaskId
          : attachedTaskId as String?,
    );
  }
}

// Sentinel — distinguishes "argument not passed" from "explicitly null"
const Object _keepValue = Object();

// ─────────────────────────────────────────────────────────────────────────────

final pomodoroNotifierProvider =
NotifierProvider<PomodoroNotifier, PomodoroState>(PomodoroNotifier.new);

class PomodoroNotifier extends Notifier<PomodoroState> {
  Timer? _timer;

  @override
  PomodoroState build() {
    final s = ref.read(pomodoroSettingsProvider);
    return PomodoroState(secondsLeft: s.workMinutes * 60);
  }

  // ── Public controls ────────────────────────────────────────────────────────

  void start() {
    state = state.copyWith(status: PomodoroStatus.running);
    _startTicking(interval: const Duration(seconds: 1));
  }

  void pause() {
    _timer?.cancel();
    state = state.copyWith(status: PomodoroStatus.paused);
  }

  void resume() => start();

  void reset() {
    _timer?.cancel();
    final s = ref.read(pomodoroSettingsProvider);
    state = PomodoroState(
      secondsLeft:    s.workMinutes * 60,
      attachedTaskId: state.attachedTaskId, // keep task attached across resets
    );
  }

  void attachTask(String taskId) =>
      state = state.copyWith(attachedTaskId: taskId);

  // FIX: sentinel pattern so null actually clears the field
  void detachTask() =>
      state = state.copyWith(attachedTaskId: null);

  // ── Debug panel hooks ──────────────────────────────────────────────────────

  /// Immediately complete the current session (used by debug skip button).
  void triggerSessionComplete() {
    _timer?.cancel();
    _onSessionComplete();
  }

  /// Change tick speed — multiplier=60 means 60 virtual seconds per real second.
  void setSpeed(int multiplier) {
    if (state.status != PomodoroStatus.running) return;
    _startTicking(
      interval: Duration(milliseconds: (1000 / multiplier).round()),
      step: multiplier,
    );
  }

  // ── Internal ───────────────────────────────────────────────────────────────

  void _startTicking({required Duration interval, int step = 1}) {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) {
      final next = state.secondsLeft - step;
      if (next <= 0) {
        // FIX: cancel immediately so the callback never fires again while
        // _onSessionComplete is running (was the root cause of "did nothing")
        _timer?.cancel();
        _onSessionComplete();
      } else {
        state = state.copyWith(secondsLeft: next);
      }
    });
  }

  // FIX: try-catch so a DB failure never silently freezes the screen.
  // FIX: completedPhase captured BEFORE state mutation — the screen listener
  //      needs prev.phase (the phase that just finished) to show the right message.
  void _onSessionComplete() async {
    final completedPhase = state.phase; // capture NOW, before any mutation

    try {
      if (completedPhase == PomodoroPhase.work) {
        final workMins = ref.read(pomodoroSettingsProvider).workMinutes;
        await ref.read(pomodoroRepositoryProvider).completeSession(
          taskId: state.attachedTaskId,
          duration: workMins,
          type: 'work',
        );
      } else {
        // Breaks are NOT attributed to the task — taskId is intentionally null
        // so the repository does NOT increment completedPomodoro for breaks.
        await ref.read(pomodoroRepositoryProvider).completeSession(
          taskId: null,
          duration: completedPhase == PomodoroPhase.shortBreak ? 5 : 15,
          type: 'break',
        );
      }
    } catch (_) {
      // DB write failed — still proceed so the UI is never stuck
    }

    _applyCompletionTransition(completedPhase);
  }

  void _applyCompletionTransition(PomodoroPhase completedPhase) {
    if (completedPhase == PomodoroPhase.work) {
      final newCount = state.completedSessions + 1;
      final nextPhase = newCount % 4 == 0
          ? PomodoroPhase.longBreak
          : PomodoroPhase.shortBreak;
      state = state.copyWith(
        status:            PomodoroStatus.completed,
        phase:             nextPhase,
        secondsLeft:       _secondsForPhase(nextPhase),
        completedSessions: newCount,
      );
    } else {
      state = state.copyWith(
        status:      PomodoroStatus.completed,
        phase:       PomodoroPhase.work,
        secondsLeft: _secondsForPhase(PomodoroPhase.work),
      );
    }
  }

  int _secondsForPhase(PomodoroPhase phase) {
    final s = ref.read(pomodoroSettingsProvider);
    return switch (phase) {
      PomodoroPhase.work       => s.workMinutes       * 60,
      PomodoroPhase.shortBreak => s.shortBreakMinutes * 60,
      PomodoroPhase.longBreak  => s.longBreakMinutes  * 60,
    };
  }
}