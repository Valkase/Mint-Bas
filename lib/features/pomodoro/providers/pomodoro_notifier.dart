import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/repository_providers.dart';
import 'package:bd_project/features/pomodoro/providers/pomodoro_settings_provider.dart';
import '../services/overlay_service.dart';

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

final pomodoroNotifierProvider =
NotifierProvider<PomodoroNotifier, PomodoroState>(PomodoroNotifier.new);

class PomodoroNotifier extends Notifier<PomodoroState> {
  Timer? _timer;

  @override
  PomodoroState build() {
    final s = ref.read(pomodoroSettingsProvider);
    return PomodoroState(secondsLeft: s.workMinutes * 60);
  }

  void start() {
    state = state.copyWith(status: PomodoroStatus.running);
    _startTicking(interval: const Duration(seconds: 1));
    _pushOverlay();
  }

  void pause() {
    _timer?.cancel();
    state = state.copyWith(status: PomodoroStatus.paused);
    _pushOverlay();
  }

  void resume() => start();

  void reset() {
    _timer?.cancel();
    final s = ref.read(pomodoroSettingsProvider);
    state = PomodoroState(
      secondsLeft   : s.workMinutes * 60,
      attachedTaskId: state.attachedTaskId,
    );
    _pushOverlay();
  }

  void attachTask(String taskId) {
    state = state.copyWith(attachedTaskId: taskId);
    _pushOverlay();
  }

  void detachTask() {
    state = state.copyWith(attachedTaskId: null);
    _pushOverlay();
  }

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

  void _startTicking({required Duration interval, int step = 1}) {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) {
      final next = state.secondsLeft - step;
      if (next <= 0) {
        _timer?.cancel();
        _onSessionComplete();
      } else {
        state = state.copyWith(secondsLeft: next);
        _pushOverlay();
      }
    });
  }

  void _onSessionComplete() async {
    final completedPhase = state.phase;
    try {
      if (completedPhase == PomodoroPhase.work) {
        await ref.read(pomodoroRepositoryProvider).completeSession(
          taskId  : state.attachedTaskId,
          duration: ref.read(pomodoroSettingsProvider).workMinutes,
          type    : 'work',
        );
      } else {
        await ref.read(pomodoroRepositoryProvider).completeSession(
          taskId  : null,
          duration: completedPhase == PomodoroPhase.shortBreak
              ? ref.read(pomodoroSettingsProvider).shortBreakMinutes
              : ref.read(pomodoroSettingsProvider).longBreakMinutes,
          type    : 'break',
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

    state = state.copyWith(
      status           : PomodoroStatus.completed,
      phase            : nextPhase,
      secondsLeft      : nextSeconds,
      completedSessions: newSessions,
    );
    _pushOverlay();
  }

  void _pushOverlay() {
    OverlayService.instance.pushState(
      secondsLeft: state.secondsLeft,
      phase      : _phaseKey(state.phase),
      isRunning  : state.status == PomodoroStatus.running,
    );
  }

  String _phaseKey(PomodoroPhase phase) => switch (phase) {
    PomodoroPhase.work       => 'work',
    PomodoroPhase.shortBreak => 'shortBreak',
    PomodoroPhase.longBreak  => 'longBreak',
  };
}
