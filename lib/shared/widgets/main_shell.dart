import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:bd_project/core/providers/theme_provider.dart';
import 'package:bd_project/core/theme/app_theme.dart';
import 'package:bd_project/features/pomodoro/providers/pomodoro_notifier.dart';
import 'package:bd_project/features/pomodoro/services/overlay_service.dart';
import 'package:bd_project/features/tasks/providers/tasks_notifier.dart';
import 'package:bd_project/shared/providers/repository_providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MainShell
//
// Hosts the animated bottom nav bar and manages the floating Pomodoro overlay:
//   • Shows overlay when app goes to background while a timer is active
//   • Hides overlay when app returns to foreground
//   • Forwards play/pause and open_app actions from the overlay to the notifier
//   • Pushes live timer state to the overlay on every state change
// ─────────────────────────────────────────────────────────────────────────────

class MainShell extends ConsumerStatefulWidget {
  final int    currentIndex;
  final Widget child;

  const MainShell({
    super.key,
    required this.currentIndex,
    required this.child,
  });

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell>
    with WidgetsBindingObserver {

  StreamSubscription<Map<String, dynamic>>? _actionSub;

  // Cache of the last known attached task name — updated when taskId changes
  String? _lastTaskName;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Request "Draw over other apps" permission once on first launch.
    // The OS only shows a dialog when it's actually needed — if already
    // granted this returns immediately.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await OverlayService.instance.requestPermission();
      _listenOverlayActions();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _actionSub?.cancel();
    super.dispose();
  }

  // ── App lifecycle → overlay show / hide ───────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final pom = ref.read(pomodoroNotifierProvider);
    final timerActive = pom.status != PomodoroStatus.idle;

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      // Only show overlay when the timer is actually doing something
        if (timerActive) _showOverlay(pom);
      case AppLifecycleState.resumed:
        _hideOverlay();
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

  // ── Overlay management ─────────────────────────────────────────────────────

  Future<void> _showOverlay(PomodoroState pom) async {
    final granted = await OverlayService.instance.isPermissionGranted;
    if (!granted) return;
    await OverlayService.instance.show();
    await OverlayService.instance.pushState(
      secondsLeft: pom.secondsLeft,
      phase      : _phaseKey(pom.phase),
      isRunning  : pom.status == PomodoroStatus.running,
      taskName   : _lastTaskName,
    );
  }

  Future<void> _hideOverlay() async {
    await OverlayService.instance.hide();
  }

  // ── Listen to actions coming FROM the overlay ──────────────────────────────

  void _listenOverlayActions() {
    _actionSub = OverlayService.instance.actionStream.listen((msg) {
      final action = msg['action'] as String?;
      if (action == null) return;

      final notifier = ref.read(pomodoroNotifierProvider.notifier);
      final pom      = ref.read(pomodoroNotifierProvider);

      switch (action) {
        case 'play_pause':
          HapticFeedback.lightImpact();
          if (pom.status == PomodoroStatus.running) {
            notifier.pause();
          } else {
            notifier.resume();
          }

        case 'open_app':
        // The overlay closes itself; the OS will handle bringing the app
        // to the foreground when the user taps on it.
        // We hide the overlay from our side so state stays in sync.
          _hideOverlay();
      }
    });
  }

  // ── Push state updates to the overlay on every notifier change ─────────────
  //
  // Called by ref.listen in build(). We update task name when taskId changes
  // (requires a DB lookup), then push the full state to the overlay widget.

  Future<void> _onPomodoroStateChanged(
      PomodoroState? prev,
      PomodoroState  next,
      ) async {
    // Resolve task name if the attached task changed
    if (prev?.attachedTaskId != next.attachedTaskId) {
      _lastTaskName = await _resolveTaskName(next.attachedTaskId);
      OverlayService.instance.setTaskName(_lastTaskName);
    }

    // Push live state to the overlay (no-op if overlay isn't visible)
    await OverlayService.instance.pushState(
      secondsLeft: next.secondsLeft,
      phase      : _phaseKey(next.phase),
      isRunning  : next.status == PomodoroStatus.running,
      taskName   : _lastTaskName,
    );

    // If the timer was just stopped/reset, close the overlay
    if (prev?.status != PomodoroStatus.idle &&
        next.status == PomodoroStatus.idle) {
      await _hideOverlay();
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Future<String?> _resolveTaskName(String? taskId) async {
    if (taskId == null) return null;
    try {
      final taskDao = ref.read(taskDaoProvider);
      final task    = await taskDao.watchTaskById(taskId).first;
      return task?.title;
    } catch (_) {
      return null;
    }
  }

  String _phaseKey(PomodoroPhase phase) => switch (phase) {
    PomodoroPhase.work       => 'work',
    PomodoroPhase.shortBreak => 'shortBreak',
    PomodoroPhase.longBreak  => 'longBreak',
  };

  // ── Navigation ─────────────────────────────────────────────────────────────

  void _onTap(BuildContext context, int index) {
    HapticFeedback.lightImpact();
    switch (index) {
      case 0: context.go('/');
      case 1: context.go('/dashboard');
      case 2: context.go('/rewards');
      case 3: context.go('/banking');
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    ref.watch(themeProvider); // rebuild on theme change

    // Listen to every timer state change — push to overlay & handle idle
    ref.listen<PomodoroState>(
      pomodoroNotifierProvider,
      _onPomodoroStateChanged,
    );

    return Scaffold(
      backgroundColor: AppTheme.background,
      body           : widget.child,
      bottomNavigationBar: _AnimatedNavBar(
        currentIndex: widget.currentIndex,
        onTap       : (i) => _onTap(context, i),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Animated Nav Bar
// ─────────────────────────────────────────────────────────────────────────────

class _AnimatedNavBar extends StatefulWidget {
  final int                  currentIndex;
  final ValueChanged<int>    onTap;

  const _AnimatedNavBar({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<_AnimatedNavBar> createState() => _AnimatedNavBarState();
}

class _AnimatedNavBarState extends State<_AnimatedNavBar>
    with SingleTickerProviderStateMixin {

  static const _barHeight  = 72.0;
  static const _pillSize   = 54.0;
  static const _liftAmount = -28.0;

  late final AnimationController _ctrl;
  late       Animation<double>   _pillPos;
  int _prevIndex = 0;

  static const _tabs = [
    (icon: Icons.check_circle_outline, activeIcon: Icons.check_circle,    label: 'Tasks'),
    (icon: Icons.bar_chart_outlined,   activeIcon: Icons.bar_chart,        label: 'Progress'),
    (icon: Icons.redeem_outlined,      activeIcon: Icons.redeem,           label: 'Rewards'),
    (icon: Icons.account_balance_wallet_outlined,
    activeIcon: Icons.account_balance_wallet,
    label: 'Banking'),
  ];

  @override
  void initState() {
    super.initState();
    _prevIndex = widget.currentIndex;
    _ctrl = AnimationController(
      vsync   : this,
      duration: const Duration(milliseconds: 320),
    );
    // .animate() must be called on the Tween, not on an Animation.
    _pillPos = _buildTween(widget.currentIndex, widget.currentIndex)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
  }

  @override
  void didUpdateWidget(_AnimatedNavBar old) {
    super.didUpdateWidget(old);
    if (old.currentIndex != widget.currentIndex) {
      _pillPos = _buildTween(_prevIndex, widget.currentIndex)
          .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
      _ctrl.forward(from: 0);
      _prevIndex = widget.currentIndex;
    }
  }

  // Returns a plain Tween — .animate() is always called at the use site
  Tween<double> _buildTween(int from, int to) {
    return Tween<double>(begin: from.toDouble(), end: to.toDouble());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabCount = _tabs.length;

    return Container(
      height: _barHeight + MediaQuery.of(context).padding.bottom,
      decoration: BoxDecoration(
        color : AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.surfaceBorder)),
      ),
      child: Stack(
        children: [

          // ── Sliding pill indicator ─────────────────────────
          AnimatedBuilder(
            animation: _pillPos,
            builder  : (_, __) {
              final fraction = _pillPos.value / (tabCount - 1);
              final maxOffset = MediaQuery.of(context).size.width - _pillSize;
              final pillLeft  = fraction * maxOffset;

              return Positioned(
                left  : pillLeft,
                top   : (_barHeight - _pillSize) / 2 + _liftAmount / 2,
                child : Container(
                  width : _pillSize,
                  height: _pillSize,
                  decoration: BoxDecoration(
                    color       : AppTheme.primary.withAlpha(28),
                    shape       : BoxShape.circle,
                    border      : Border.all(
                      color: AppTheme.primary.withAlpha(60),
                    ),
                  ),
                ),
              );
            },
          ),

          // ── Tab items ──────────────────────────────────────
          Row(
            children: List.generate(tabCount, (i) {
              final active = widget.currentIndex == i;
              final tab    = _tabs[i];
              return Expanded(
                child: GestureDetector(
                  onTap        : () => widget.onTap(i),
                  behavior     : HitTestBehavior.opaque,
                  child        : SizedBox(
                    height: _barHeight,
                    child : AnimatedBuilder(
                      animation: _ctrl,
                      builder  : (_, __) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [

                            // Icon with lift animation
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              curve   : Curves.easeOut,
                              transform: Matrix4.translationValues(
                                0, active ? _liftAmount : 0, 0,
                              ),
                              child: AnimatedScale(
                                scale   : active ? 1.18 : 1.0,
                                duration: const Duration(milliseconds: 220),
                                child   : Icon(
                                  active ? tab.activeIcon : tab.icon,
                                  color: active
                                      ? AppTheme.primary
                                      : AppTheme.textSecondary,
                                  size: 24,
                                ),
                              ),
                            ),

                            // Label fades in below active icon
                            AnimatedOpacity(
                              opacity : active ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 200),
                              child   : Text(
                                tab.label,
                                style: AppTheme.label.copyWith(
                                  fontSize  : 10,
                                  color     : AppTheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
