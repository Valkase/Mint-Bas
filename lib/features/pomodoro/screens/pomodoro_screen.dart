import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/database/app_database.dart';
import '../../pomodoro/providers/pomodoro_notifier.dart';
import '../../pomodoro/providers/pomodoro_settings_provider.dart';
import '../../../features/settings/widgets/settings_sheet.dart';
import '../../../shared/providers/repository_providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────────────────────

final _attachedTaskProvider = StreamProvider.family<Task?, String>(
      (ref, taskId) => ref.watch(taskDaoProvider).watchTaskById(taskId),
);

final _quoteProvider = FutureProvider<Quote?>(
      (ref) => ref.watch(quoteDaoProvider).getRandomQuote(),
);

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class PomodoroScreen extends ConsumerStatefulWidget {
  final String? initialTaskId;
  const PomodoroScreen({super.key, this.initialTaskId});

  @override
  ConsumerState<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends ConsumerState<PomodoroScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulse;

  late final AnimationController _completionCtrl;
  late final Animation<double> _completionScale;
  late final Animation<double> _completionOpacity;

  bool _showCompletion = false;
  PomodoroPhase _completedPhase = PomodoroPhase.work;

  Timer? _quoteTimer;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulse = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _completionCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _completionScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _completionCtrl, curve: Curves.elasticOut),
    );
    _completionOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _completionCtrl, curve: const Interval(0.0, 0.4)),
    );

    _quoteTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (mounted) ref.invalidate(_quoteProvider);
    });

    if (widget.initialTaskId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(pomodoroNotifierProvider.notifier)
            .attachTask(widget.initialTaskId!);
      });
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _completionCtrl.dispose();
    _quoteTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeProvider); // rebuild instantly on theme change

    final pom   = ref.watch(pomodoroNotifierProvider);
    final quote = ref.watch(_quoteProvider);

    final isRunning = pom.status == PomodoroStatus.running;

    // FIX: Pass prev.phase (the phase that FINISHED) not next.phase (the
    // new phase). The notifier already updates phase to the next one before
    // we get here, so next.phase always shows the wrong message.
    ref.listen<PomodoroState>(pomodoroNotifierProvider, (prev, next) {
      if (prev?.status != PomodoroStatus.completed &&
          next.status == PomodoroStatus.completed) {
        _triggerCompletionOverlay(prev!.phase);
      }
    });

    // FIX: Never mutate animation controllers inside build().
    // Use a post-frame callback so it runs after the current frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
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
                          pom: pom,
                          onEdit: () => _showDetachSheet(context),
                        ),
                        const SizedBox(height: 40),
                        _Controls(
                          pom: pom,
                          pulse: _pulse,
                          onStart:  _start,
                          onPause:  _pause,
                          onResume: _resume,
                          onReset:  _reset,
                          onSkip:   _skip,
                        ),
                        const SizedBox(height: 48),
                        _QuoteFooter(quoteAsync: quote, pom: pom),
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
              scaleAnim:      _completionScale,
              opacityAnim:    _completionOpacity,
            ),
        ],
      ),
    );
  }

  // ── Completion overlay ───────────────────────────────────────────────────

  void _triggerCompletionOverlay(PomodoroPhase completedPhase) async {
    HapticFeedback.heavyImpact();
    setState(() {
      _showCompletion  = true;
      _completedPhase  = completedPhase;
    });
    _completionCtrl.forward(from: 0);
    ref.invalidate(_quoteProvider);
    await Future.delayed(const Duration(milliseconds: 2500));
    if (mounted) {
      _completionCtrl.reverse().then((_) {
        if (mounted) setState(() => _showCompletion = false);
      });
    }
  }

  // ── Control callbacks ────────────────────────────────────────────────────

  void _start()  {
    HapticFeedback.mediumImpact();
    ref.read(pomodoroNotifierProvider.notifier).start();
  }

  void _pause()  {
    HapticFeedback.lightImpact();
    ref.read(pomodoroNotifierProvider.notifier).pause();
  }

  void _resume() {
    HapticFeedback.mediumImpact();
    ref.read(pomodoroNotifierProvider.notifier).resume();
  }

  void _reset()  {
    HapticFeedback.lightImpact();
    ref.read(pomodoroNotifierProvider.notifier).reset();
  }

  void _skip()   {
    HapticFeedback.mediumImpact();
    ref.read(pomodoroNotifierProvider.notifier).triggerSessionComplete();
  }

  // ── Header ───────────────────────────────────────────────────────────────
  // FIX: Removed dead more_vert button. Right side is now a settings button.

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _CircleIconButton(
            icon: Icons.arrow_back,
            onTap: () => context.pop(),
          ),
          Text(
            'Focus Session',
            style: AppTheme.body.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 17,
            ),
          ),
          _CircleIconButton(
            icon: Icons.tune_rounded,
            onTap: () {
              HapticFeedback.lightImpact();
              showSettingsSheet(context);
            },
          ),
        ],
      ),
    );
  }

  // ── Detach sheet ─────────────────────────────────────────────────────────

  void _showDetachSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.elevated,
      shape: const RoundedRectangleBorder(
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

// ─────────────────────────────────────────────────────────────────────────────
// Timer Ring
// ─────────────────────────────────────────────────────────────────────────────

class _TimerRing extends ConsumerWidget {
  final PomodoroState pom;
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
    // Read custom durations from settings — live update when settings change
    final settings = ref.watch(pomodoroSettingsProvider);
    final totalSeconds = switch (pom.phase) {
      PomodoroPhase.work       => settings.workMinutes       * 60,
      PomodoroPhase.shortBreak => settings.shortBreakMinutes * 60,
      PomodoroPhase.longBreak  => settings.longBreakMinutes  * 60,
    };
    final progress  = totalSeconds == 0 ? 0.0 : pom.secondsLeft / totalSeconds;
    final isRunning = pom.status == PomodoroStatus.running;

    return AnimatedBuilder(
      animation: pulse,
      builder: (_, __) => Transform.scale(
        scale: isRunning ? 1.0 : pulse.value,
        child: SizedBox(
          width: 288,
          height: 288,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(288, 288),
                painter: _RingPainter(progress: progress, color: _color),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _phaseLabel,
                    style: AppTheme.label.copyWith(
                      color: _color,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _fmt(pom.secondsLeft),
                    style: AppTheme.display.copyWith(
                      fontSize: 56,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'minutes remaining',
                    style: AppTheme.caption.copyWith(fontSize: 12),
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

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  const _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final c  = Offset(size.width / 2, size.height / 2);
    final r  = size.width / 2 - 16;
    const sw = 10.0;

    // FIX: AppTheme.surfaceBorder — adapts to light/dark mode
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color       = AppTheme.surfaceBorder
        ..style       = PaintingStyle.stroke
        ..strokeWidth = sw,
    );

    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..color       = color
          ..style       = PaintingStyle.stroke
          ..strokeWidth = sw
          ..strokeCap   = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}

// ─────────────────────────────────────────────────────────────────────────────
// Session Dots
// ─────────────────────────────────────────────────────────────────────────────

class _SessionDots extends StatelessWidget {
  final PomodoroState pom;
  const _SessionDots({required this.pom});

  @override
  Widget build(BuildContext context) {
    final doneInCycle = pom.completedSessions % 4;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (i) {
            final filled = i < doneInCycle;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOut,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // FIX: AppTheme.surfaceBorder — adapts to light/dark mode
                color: filled ? AppTheme.primary : AppTheme.surfaceBorder,
              ),
            );
          }),
        ),
        const SizedBox(height: 10),
        Text(
          'Session ${doneInCycle + 1} of 4',
          style: AppTheme.caption.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Attached Task Card
// ─────────────────────────────────────────────────────────────────────────────

class _AttachedTaskCard extends ConsumerWidget {
  final PomodoroState pom;
  final VoidCallback onEdit;
  const _AttachedTaskCard({required this.pom, required this.onEdit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskId = pom.attachedTaskId;

    if (taskId == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            _taskIcon(Icons.link_outlined),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('No task attached',
                      style: AppTheme.caption.copyWith(fontSize: 12)),
                  const SizedBox(height: 2),
                  Text('Free focus session',
                      style: AppTheme.body.copyWith(fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final taskAsync = ref.watch(_attachedTaskProvider(taskId));
    return taskAsync.when(
      loading: () => const SizedBox(height: 72),
      error:   (_, __) => const SizedBox.shrink(),
      data:    (task) {
        if (task == null) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              _taskIcon(Icons.school_outlined),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Current Task',
                        style: AppTheme.caption.copyWith(fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(
                      task.title,
                      style: AppTheme.body.copyWith(fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onEdit,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.edit_outlined,
                      color: AppTheme.textSecondary, size: 20),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _taskIcon(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppTheme.primary.withAlpha(51),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: AppTheme.primary, size: 20),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Controls
// FIX: Removed the duplicate pause button on the right.
//      Replaced with a skip-forward button that completes the session cleanly.
// ─────────────────────────────────────────────────────────────────────────────

class _Controls extends StatelessWidget {
  final PomodoroState pom;
  final Animation<double> pulse;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onReset;
  final VoidCallback onSkip;

  const _Controls({
    required this.pom,
    required this.pulse,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onReset,
    required this.onSkip,
  });

  bool get _isRunning => pom.status == PomodoroStatus.running;
  bool get _isIdle    => pom.status == PomodoroStatus.idle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Reset — disabled when idle (nothing to reset)
        _SideBtn(
          icon:    Icons.restart_alt_rounded,
          enabled: !_isIdle,
          onTap:   onReset,
        ),

        const SizedBox(width: 32),

        // Main play/pause button
        AnimatedBuilder(
          animation: pulse,
          builder: (_, __) => GestureDetector(
            onTap: _isRunning ? onPause : (_isIdle ? onStart : onResume),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withAlpha(_isRunning ? 128 : 76),
                    blurRadius: _isRunning ? 28 : 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                _isRunning
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
        ),

        const SizedBox(width: 32),

        // Skip forward — completes the current session immediately.
        // Enabled only while running or paused (not idle — nothing to skip).
        _SideBtn(
          icon:    Icons.skip_next_rounded,
          enabled: !_isIdle,
          onTap:   onSkip,
        ),
      ],
    );
  }
}

class _SideBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _SideBtn({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: enabled ? AppTheme.textSecondary : AppTheme.textDisabled,
          size: 26,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quote Footer
// ─────────────────────────────────────────────────────────────────────────────

class _QuoteFooter extends StatelessWidget {
  final AsyncValue<Quote?> quoteAsync;
  final PomodoroState pom;
  const _QuoteFooter({required this.quoteAsync, required this.pom});

  String get _fallback => switch (pom.phase) {
    PomodoroPhase.work       => "Let's focus. 25 minutes to grow a little more.",
    PomodoroPhase.shortBreak => 'Rest now. You did the work.',
    PomodoroPhase.longBreak  => 'Take a real break. You earned this one.',
  };

  @override
  Widget build(BuildContext context) {
    final text   = quoteAsync.value?.quote ?? _fallback;
    final author = quoteAsync.value?.author;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Text(
            '"$text"',
            style: AppTheme.caption.copyWith(
              fontStyle: FontStyle.italic,
              fontSize: 12,
              height: 1.8,
            ),
            textAlign: TextAlign.center,
          ),
          if (author != null) ...[
            const SizedBox(height: 6),
            Text(
              '— $author',
              style: AppTheme.caption.copyWith(
                fontSize: 11,
                color: AppTheme.textDisabled,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Detach Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _DetachSheet extends StatelessWidget {
  final VoidCallback onDetach;
  const _DetachSheet({required this.onDetach});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.surfaceBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Task Options', style: AppTheme.heading),
          const SizedBox(height: 6),
          Text(
            'To focus on a different task, go back and tap the focus button on any task card.',
            style: AppTheme.caption.copyWith(height: 1.6),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: onDetach,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppTheme.error.withAlpha(20),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.error.withAlpha(51)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.link_off_outlined,
                      color: AppTheme.error, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Detach from task',
                    style: AppTheme.label.copyWith(color: AppTheme.error),
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

// ─────────────────────────────────────────────────────────────────────────────
// Reusable circle icon button
// ─────────────────────────────────────────────────────────────────────────────

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppTheme.textSecondary, size: 20),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Completion Overlay
// ─────────────────────────────────────────────────────────────────────────────

class _CompletionOverlay extends StatelessWidget {
  final PomodoroPhase completedPhase;
  final Animation<double> scaleAnim;
  final Animation<double> opacityAnim;

  const _CompletionOverlay({
    required this.completedPhase,
    required this.scaleAnim,
    required this.opacityAnim,
  });

  String get _headline => completedPhase == PomodoroPhase.work
      ? 'Session complete.'
      : 'Break over.';

  String get _subline => completedPhase == PomodoroPhase.work
      ? 'Take a breath. You earned it.'
      : "Back to it. Let's go.";

  Color get _color => completedPhase == PomodoroPhase.work
      ? AppTheme.primary
      : const Color(0xFF5A9E8A);

  IconData get _icon => completedPhase == PomodoroPhase.work
      ? Icons.self_improvement_outlined
      : Icons.bolt_outlined;

  String get _nextLabel => completedPhase == PomodoroPhase.work
      ? 'Starting break...'
      : 'Starting focus...';

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.background.withAlpha(230),
      child: Center(
        child: FadeTransition(
          opacity: opacityAnim,
          child: ScaleTransition(
            scale: scaleAnim,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: _color.withAlpha(30),
                    shape: BoxShape.circle,
                    border:
                    Border.all(color: _color.withAlpha(80), width: 2),
                  ),
                  child: Icon(_icon, color: _color, size: 42),
                ),
                const SizedBox(height: 24),
                Text(_headline,
                    style: AppTheme.heading.copyWith(fontSize: 22)),
                const SizedBox(height: 8),
                Text(
                  _subline,
                  style: AppTheme.caption.copyWith(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _color.withAlpha(20),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _nextLabel,
                    style: AppTheme.label.copyWith(
                      color: _color,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}