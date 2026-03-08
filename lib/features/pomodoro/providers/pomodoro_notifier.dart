// lib/features/pomodoro/providers/pomodoro_notifier.dart

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/repository_providers.dart';
import 'package:bd_project/features/pomodoro/providers/pomodoro_settings_provider.dart';
import '../services/notification_service.dart';

enum PomodoroStatus { idle, running, paused, completed }
enum PomodoroPhase  { work, shortBreak, longBreak }

class PomodoroState {
  final PomodoroStatus status;
  final PomodoroPhase  phase;
  final int            secondsLeft;
  final int            completedSessions;
  final String?        attachedTaskId;

  const PomodoroState({
    this.status            = PomodoroStatus.idle,
    this.phase             = PomodoroPhase.work,
    this.secondsLeft       = 25 * 60,
    this.completedSessions = 0,
    this.attachedTaskId,
  });

  PomodoroState copyWith({
    PomodoroStatus? status,
    PomodoroPhase?  phase,
    int?            secondsLeft,
    int?            completedSessions,
    Object?         attachedTaskId = _keepValue,
  }) {
    return PomodoroState(
      status            : status            ?? this.status,
      phase             : phase             ?? this.phase,
      secondsLeft       : secondsLeft       ?? this.secondsLeft,
      completedSessions : completedSessions ?? this.completedSessions,
      attachedTaskId    : attachedTaskId == _keepValue
          ? this.attachedTaskId
          : attachedTaskId as String?,
    );
  }
}

const Object _keepValue = Object();

// ─────────────────────────────────────────────────────────────────────────────

final pomodoroNotifierProvider =
NotifierProvider<PomodoroNotifier, PomodoroState>(PomodoroNotifier.new);

class PomodoroNotifier extends Notifier<PomodoroState> {
  Timer?  _timer;

  // Task name is cached here so the notification can show it without DB access.
  String? _cachedTaskName;

  @override
  PomodoroState build() {
    ref.onDispose(() => _timer?.cancel());
    final s = ref.read(pomodoroSettingsProvider);
    return PomodoroState(secondsLeft: s.workMinutes * 60);
  }

  // ── Public controls ────────────────────────────────────────────────────────

  void start() {
    _safeSetState(state.copyWith(status: PomodoroStatus.running));
    _startTicking(interval: const Duration(seconds: 1));
    _pushNotification();
  }

  void pause() {
    _timer?.cancel();
    _safeSetState(state.copyWith(status: PomodoroStatus.paused));
    _pushNotification();
  }

  void resume() => start();

  void reset() {
    _timer?.cancel();
    final s = ref.read(pomodoroSettingsProvider);
    _safeSetState(PomodoroState(
      secondsLeft   : s.workMinutes * 60,
      attachedTaskId: state.attachedTaskId,
    ));
    NotificationService.instance.cancel();
  }

  void attachTask(String taskId) =>
      _safeSetState(state.copyWith(attachedTaskId: taskId));

  void detachTask() {
    _cachedTaskName = null;
    _safeSetState(state.copyWith(attachedTaskId: null));
    _pushNotification();
  }

  /// Called by the UI when the attached task name is resolved.
  /// Keeps the notification in sync without the notifier touching the DB.
  void setTaskName(String? name) {
    _cachedTaskName = name;
    _pushNotification();
  }

  // ── Debug panel hooks ──────────────────────────────────────────────────────

  void triggerSessionComplete() {
    _timer?.cancel();
    _onSessionComplete();
  }

  void setSpeed(int multiplier) {
    if (state.status != PomodoroStatus.running) return;
    _startTicking(
      interval: Duration(milliseconds: (1000 / multiplier).round()),
      step    : multiplier,
    );
  }

  // ── Internal timer ─────────────────────────────────────────────────────────

  void _startTicking({required Duration interval, int step = 1}) {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) {
      final next = state.secondsLeft - step;
      if (next <= 0) {
        _timer?.cancel();
        _onSessionComplete();
      } else {
        _safeSetState(state.copyWith(secondsLeft: next));
        _pushNotification();
      }
    });
  }

  Future<void> _onSessionComplete() async {
    final completedPhase = state.phase;
    try {
      if (completedPhase == PomodoroPhase.work) {
        await ref.read(pomodoroRepositoryProvider).completeSession(
          taskId  : state.attachedTaskId,
          duration: ref.read(pomodoroSettingsProvider).workMinutes,
          type    : 'work',
        );
      } else {
        // ── BUG 3 FIX ──────────────────────────────────────────────────────
        // Previously, both break types were stored as the generic 'break'
        // string, which conflicts with the debug panel's 'shortBreak' /
        // 'longBreak' convention AND the table comment ('work' | 'short-break'
        // | 'long-break'). We now derive the type string from the actual phase
        // using _phaseKey(), which returns the same canonical strings used
        // everywhere else (overlay, notification service, debug inject form).
        // ──────────────────────────────────────────────────────────────────
        await ref.read(pomodoroRepositoryProvider).completeSession(
          taskId  : null,
          duration: completedPhase == PomodoroPhase.shortBreak
              ? ref.read(pomodoroSettingsProvider).shortBreakMinutes
              : ref.read(pomodoroSettingsProvider).longBreakMinutes,
          type    : _phaseKey(completedPhase), // ← was hardcoded 'break'
        );
      }
    } catch (_) {}
    _applyCompletionTransition(completedPhase);
  }

  void _applyCompletionTransition(PomodoroPhase completedPhase) {
    final settings    = ref.read(pomodoroSettingsProvider);
    final newSessions = completedPhase == PomodoroPhase.work
        ? state.completedSessions + 1
        : state.completedSessions;

    final nextPhase = switch (completedPhase) {
      PomodoroPhase.work => newSessions % 4 == 0
          ? PomodoroPhase.longBreak
          : PomodoroPhase.shortBreak,
      _ => PomodoroPhase.work,
    };

    final nextSeconds = switch (nextPhase) {
      PomodoroPhase.work       => settings.workMinutes       * 60,
      PomodoroPhase.shortBreak => settings.shortBreakMinutes * 60,
      PomodoroPhase.longBreak  => settings.longBreakMinutes  * 60,
    };

    _safeSetState(state.copyWith(
      status           : PomodoroStatus.completed,
      phase            : nextPhase,
      secondsLeft      : nextSeconds,
      completedSessions: newSessions,
    ));
    NotificationService.instance.cancel();
  }

  // ── Notification helper ────────────────────────────────────────────────────

  void _pushNotification() {
    if (state.status == PomodoroStatus.idle ||
        state.status == PomodoroStatus.completed) {
      NotificationService.instance.cancel();
      return;
    }
    NotificationService.instance.showTimer(
      secondsLeft: state.secondsLeft,
      phase      : _phaseKey(state.phase),
      isRunning  : state.status == PomodoroStatus.running,
      taskName   : _cachedTaskName,
    );
  }

  // ── Safe state setter ──────────────────────────────────────────────────────
  //
  // Wraps `state =` in a try/catch to absorb the brief window where a disposed
  // ConsumerStatefulElement is still in Riverpod's listener list, which would
  // otherwise throw "_lifecycleState != _ElementLifecycle.defunct".
  void _safeSetState(PomodoroState newState) {
    try {
      state = newState;
    } catch (_) {}
  }

  // ── Phase key ──────────────────────────────────────────────────────────────
  //
  // Single source of truth for the string representation of each phase.
  // Used by: notification service, break session type storage, overlay.
  String _phaseKey(PomodoroPhase phase) => switch (phase) {
    PomodoroPhase.work       => 'work',
    PomodoroPhase.shortBreak => 'shortBreak',
    PomodoroPhase.longBreak  => 'longBreak',
  };
}