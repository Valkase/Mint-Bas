import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/database/app_database.dart';
import '../providers/pomodoro_notifier.dart';
import '../../../shared/providers/repository_providers.dart';
import '../providers/pomodoro_settings_provider.dart';
import '../../settings/widgets/settings_sheet.dart';

// ── Providers ────────────────────────────────────────────────────────────────

final _attachedTaskProvider = StreamProvider.family<Task?, String>(
      (ref, taskId) => ref.watch(taskDaoProvider).watchTaskById(taskId),
);

final _quoteProvider = FutureProvider<Quote?>(
      (ref) => ref.watch(quoteDaoProvider).getRandomQuote(),
);

// ── Screen ───────────────────────────────────────────────────────────────────

class PomodoroScreen extends ConsumerStatefulWidget {
  final String? initialTaskId;
  const PomodoroScreen({super.key, this.initialTaskId});

  @override
  ConsumerState<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends ConsumerState<PomodoroScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double>   _pulse;

  late final AnimationController _completionCtrl;
  late final Animation<double>   _completionScale;
  late final Animation<double>   _completionOpacity;

  bool _showCompletion = false;
  PomodoroPhase _completedPhase = PomodoroPhase.work;
  Quote? _quote;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulse = Tween<double>(begin: 1.0, end: 1.05).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _completionCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _completionScale = Tween<double>(begin: 0.7, end: 1.0).animate(
        CurvedAnimation(parent: _completionCtrl, curve: Curves.elasticOut));
    _completionOpacity = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _completionCtrl, curve: const Interval(0, 0.3)));

    if (widget.initialTaskId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(pomodoroNotifierProvider.notifier).attachTask(widget.initialTaskId!);
      });
    }

    _loadInitialQuote();
  }

  @override
  void dispose() {
    _disposed = true;
    _pulseCtrl.dispose();
    _completionCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadInitialQuote() async {
    try {
      final q = await ref.read(_quoteProvider.future);
      if (mounted) setState(() => _quote = q);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final pom = ref.watch(pomodoroNotifierProvider);
    final isRunning = pom.status == PomodoroStatus.running;

    ref.listen<PomodoroState>(pomodoroNotifierProvider, (prev, next) {
      if (prev?.phase != next.phase && next.status == PomodoroStatus.completed) {
        _triggerCompletionOverlay(prev!.phase);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _disposed) return;
      if (isRunning && _pulseCtrl.isAnimating) {
        _pulseCtrl.stop();
      } else if (!isRunning && !_pulseCtrl.isAnimating) {
        _pulseCtrl.repeat(reverse: true);
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 32),
                        _TimerRing(pom: pom, pulse: _pulse),
                        const SizedBox(height: 28),
                        _SessionDots(pom: pom),
                        const SizedBox(height: 28),
                        _AttachedTaskCard(
                          pom   : pom,
                          onEdit: () => _showDetachSheet(context),
                        ),
                        const SizedBox(height: 40),
                        _Controls(
                          pom     : pom,
                          pulse   : _pulse,
                          onStart : _start,
                          onPause : _pause,
                          onResume: _resume,
                          onReset : _reset,
                          onSkip  : _skip,
                        ),
                        const SizedBox(height: 48),
                        _QuoteFooter(quote: _quote, pom: pom),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (_showCompletion)
            _CompletionOverlay(
              completedPhase: _completedPhase,
              scaleAnim     : _completionScale,
              opacityAnim   : _completionOpacity,
            ),
        ],
      ),
    );
  }

  void _triggerCompletionOverlay(PomodoroPhase completedPhase) async {
    HapticFeedback.heavyImpact();
    setState(() {
      _completedPhase = completedPhase;
      _showCompletion = true;
    });
    _completionCtrl.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 2200));
    if (mounted) {
      _completionCtrl.reverse().then((_) {
        if (mounted) setState(() => _showCompletion = false);
      });
    }
  }

  void _start()  => ref.read(pomodoroNotifierProvider.notifier).start();
  void _pause()  => ref.read(pomodoroNotifierProvider.notifier).pause();
  void _resume() => ref.read(pomodoroNotifierProvider.notifier).resume();
  void _reset()  => ref.read(pomodoroNotifierProvider.notifier).reset();
  void _skip()   {
    HapticFeedback.lightImpact();
    ref.read(pomodoroNotifierProvider.notifier).triggerSessionComplete();
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _CircleIconButton(
              icon: Icons.arrow_back, onTap: () => context.pop()),
          Text(
            'Focus Session',
            style: AppTheme.body.copyWith(
                fontWeight: FontWeight.w600, fontSize: 17),
          ),
          _CircleIconButton(
            icon : Icons.tune_rounded,
            onTap: () {
              HapticFeedback.lightImpact();
              showSettingsSheet(context);
            },
          ),
        ],
      ),
    );
  }

  void _showDetachSheet(BuildContext context) {
    showModalBottomSheet(
      context        : context,
      backgroundColor: AppTheme.elevated,
      shape          : const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _DetachSheet(
        onDetach: () {
          ref.read(pomodoroNotifierProvider.notifier).detachTask();
          Navigator.pop(context);
        },
      ),
    );
  }
}

// ── Timer Ring ───────────────────────────────────────────────────────────────

class _TimerRing extends ConsumerWidget {
  final PomodoroState     pom;
  final Animation<double> pulse;
  const _TimerRing({required this.pom, required this.pulse});

  String get _phaseLabel => switch (pom.phase) {
    PomodoroPhase.work       => 'Focus',
    PomodoroPhase.shortBreak => 'Short Break',
    PomodoroPhase.longBreak  => 'Long Break',
  };

  Color get _color => pom.phase == PomodoroPhase.work
      ? AppTheme.primary
      : const Color(0xFF5A9E8A);

  String _fmt(int s) {
    final m   = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // FIX: pomodoroSettingsProvider returns the object directly, not an AsyncValue.
    final settings     = ref.watch(pomodoroSettingsProvider);
    final totalSeconds = switch (pom.phase) {
      PomodoroPhase.work       => settings.workMinutes       * 60,
      PomodoroPhase.shortBreak => settings.shortBreakMinutes * 60,
      PomodoroPhase.longBreak  => settings.longBreakMinutes  * 60,
    };
    final progress  = totalSeconds == 0 ? 0.0 : pom.secondsLeft / totalSeconds;
    final isRunning = pom.status == PomodoroStatus.running;

    return AnimatedBuilder(
      animation: pulse,
      builder  : (_, __) => Transform.scale(
        scale: isRunning ? pulse.value : 1.0,
        child: SizedBox(
          width : 240,
          height: 240,
          child : Stack(
            alignment: Alignment.center,
            children  : [
              SizedBox(
                width : 240,
                height: 240,
                child : CircularProgressIndicator(
                  value      : progress,
                  strokeWidth: 6,
                  color      : _color,
                  backgroundColor: AppTheme.surfaceBorder,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children    : [
                  Text(
                    _phaseLabel,
                    style: AppTheme.caption.copyWith(
                      color   : _color,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _fmt(pom.secondsLeft),
                    style: AppTheme.heading.copyWith(
                      fontSize  : 52,
                      fontWeight: FontWeight.w300,
                      letterSpacing: -2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Session dots ─────────────────────────────────────────────────────────────

class _SessionDots extends StatelessWidget {
  final PomodoroState pom;
  const _SessionDots({required this.pom});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (i) {
        final filled = i < (pom.completedSessions % 4);
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin  : const EdgeInsets.symmetric(horizontal: 4),
          width   : filled ? 10 : 8,
          height  : filled ? 10 : 8,
          decoration: BoxDecoration(
            color: filled ? AppTheme.primary : AppTheme.surfaceBorder,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}

// ── Attached task card ───────────────────────────────────────────────────────

class _AttachedTaskCard extends ConsumerWidget {
  final PomodoroState pom;
  final VoidCallback  onEdit;

  const _AttachedTaskCard({required this.pom, required this.onEdit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (pom.attachedTaskId == null) return const SizedBox.shrink();

    final taskAsync = ref.watch(_attachedTaskProvider(pom.attachedTaskId!));

    return taskAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (task) {
        if (task == null) return const SizedBox.shrink();
        return GestureDetector(
          onTap: onEdit,
          child: Container(
            width     : double.infinity,
            padding   : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color       : AppTheme.surface,
              borderRadius: BorderRadius.circular(14),
              border      : Border.all(color: AppTheme.surfaceBorder),
            ),
            child: Row(
              children: [
                Icon(Icons.task_alt_rounded,
                    color: AppTheme.primary, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    task.title,
                    style: AppTheme.body.copyWith(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.close, color: AppTheme.textSecondary, size: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Controls ─────────────────────────────────────────────────────────────────

class _Controls extends StatelessWidget {
  final PomodoroState     pom;
  final Animation<double> pulse;
  final VoidCallback      onStart;
  final VoidCallback      onPause;
  final VoidCallback      onResume;
  final VoidCallback      onReset;
  final VoidCallback      onSkip;

  const _Controls({
    required this.pom,
    required this.pulse,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onReset,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final isRunning = pom.status == PomodoroStatus.running;
    final isPaused  = pom.status == PomodoroStatus.paused;
    final isIdle    = pom.status == PomodoroStatus.idle ||
        pom.status == PomodoroStatus.completed;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (!isIdle) ...[
          _CircleIconButton(icon: Icons.replay_rounded, onTap: onReset),
          const SizedBox(width: 20),
        ],
        GestureDetector(
          onTap: isRunning ? onPause : (isPaused ? onResume : onStart),
          child: AnimatedBuilder(
            animation: pulse,
            builder  : (_, __) => Transform.scale(
              scale: isRunning ? pulse.value : 1.0,
              child: Container(
                width : 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color      : AppTheme.primary.withAlpha(80),
                      blurRadius : isRunning ? 0 : 20 * pulse.value,
                      spreadRadius: isRunning ? 0 : 4 * pulse.value,
                    ),
                  ],
                ),
                child: Icon(
                  isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size : 36,
                ),
              ),
            ),
          ),
        ),
        if (!isIdle) ...[
          const SizedBox(width: 20),
          _CircleIconButton(icon: Icons.skip_next_rounded, onTap: onSkip),
        ],
      ],
    );
  }
}

// ── Completion Overlay ───────────────────────────────────────────────────────

class _CompletionOverlay extends StatelessWidget {
  final PomodoroPhase completedPhase;
  final Animation<double> scaleAnim;
  final Animation<double> opacityAnim;

  const _CompletionOverlay({
    required this.completedPhase,
    required this.scaleAnim,
    required this.opacityAnim,
  });

  @override
  Widget build(BuildContext context) {
    final isWork = completedPhase == PomodoroPhase.work;
    return Container(
      color: AppTheme.background.withAlpha(235),
      child: Center(
        child: FadeTransition(
          opacity: opacityAnim,
          child: ScaleTransition(
            scale: scaleAnim,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withAlpha(38),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isWork ? Icons.check : Icons.wb_sunny_rounded,
                    color: AppTheme.primary,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  isWork ? 'Session Complete!' : 'Break Over!',
                  style: AppTheme.heading.copyWith(fontSize: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  isWork ? 'Time for a well-earned break.' : 'Ready to focus again?',
                  style: AppTheme.body.copyWith(color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Quote Footer ─────────────────────────────────────────────────────────────

class _QuoteFooter extends StatelessWidget {
  final Quote? quote;
  final PomodoroState pom;
  const _QuoteFooter({required this.quote, required this.pom});

  @override
  Widget build(BuildContext context) {
    if (quote == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.surfaceBorder),
      ),
      child: Column(
        children: [
          Text(
            '"${quote!.quote}"',
            textAlign: TextAlign.center,
            style: AppTheme.body.copyWith(
              fontStyle: FontStyle.italic,
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          if (quote!.author != null) ...[
            const SizedBox(height: 8),
            Text(
              '— ${quote!.author}',
              style: AppTheme.caption.copyWith(fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.surfaceBorder),
        ),
        child: Icon(icon, color: AppTheme.textSecondary, size: 20),
      ),
    );
  }
}

class _DetachSheet extends StatelessWidget {
  final VoidCallback onDetach;
  const _DetachSheet({required this.onDetach});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.surfaceBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Session Options',
            style: AppTheme.heading.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: onDetach,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.error.withAlpha(20),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.error.withAlpha(51)),
              ),
              child: Row(
                children: [
                  Icon(Icons.link_off_rounded, color: AppTheme.error),
                  const SizedBox(width: 16),
                  Text(
                    'Detach current task',
                    style: AppTheme.body.copyWith(
                      color: AppTheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
