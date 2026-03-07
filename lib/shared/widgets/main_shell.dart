// lib/shared/widgets/main_shell.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/theme/app_theme.dart';

// ── Nav item model ────────────────────────────────────────────────────────────

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String   label;
  final String   route;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
  });
}

const _navItems = [
  _NavItem(
    icon:       Icons.check_circle_outline,
    activeIcon: Icons.check_circle,
    label:      'Tasks',
    route:      '/',
  ),
  _NavItem(
    icon:       Icons.bar_chart_outlined,
    activeIcon: Icons.bar_chart_rounded,
    label:      'Progress',
    route:      '/dashboard',
  ),
  _NavItem(
    icon:       Icons.redeem_outlined,
    activeIcon: Icons.redeem_rounded,
    label:      'Rewards',
    route:      '/rewards',
  ),
  _NavItem(
    icon:       Icons.account_balance_wallet_outlined,
    activeIcon: Icons.account_balance_wallet_rounded,
    label:      'Banking',
    route:      '/banking',
  ),
];

// ── Shell ─────────────────────────────────────────────────────────────────────

class MainShell extends ConsumerWidget {
  final Widget child;
  final int    currentIndex;

  const MainShell({
    super.key,
    required this.child,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(themeProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: child,
      bottomNavigationBar: _AnimatedNavBar(
        currentIndex: currentIndex,
        onTap: (index) {
          HapticFeedback.selectionClick();
          context.go(_navItems[index].route);
        },
      ),
    );
  }
}

// ── Animated Nav Bar ──────────────────────────────────────────────────────────

class _AnimatedNavBar extends StatefulWidget {
  final int               currentIndex;
  final ValueChanged<int> onTap;

  const _AnimatedNavBar({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<_AnimatedNavBar> createState() => _AnimatedNavBarState();
}

class _AnimatedNavBarState extends State<_AnimatedNavBar>
    with TickerProviderStateMixin {
  late final List<AnimationController> _iconCtrl;
  late final List<Animation<double>>   _liftAnim;
  late final List<Animation<double>>   _scaleAnim;

  late final List<AnimationController> _labelCtrl;
  late final List<Animation<double>>   _labelAnim;

  late final AnimationController _pillCtrl;
  late       Animation<double>   _pillAnim;

  static const double _pillSize   = 54;
  static const double _barHeight  = 72;
  static const double _liftAmount = -28;

  @override
  void initState() {
    super.initState();

    _iconCtrl = List.generate(
      _navItems.length,
          (_) => AnimationController(
          vsync: this, duration: const Duration(milliseconds: 300)),
    );
    _liftAnim = _iconCtrl.map((c) =>
        Tween<double>(begin: 0, end: _liftAmount).animate(
          CurvedAnimation(parent: c, curve: Curves.easeOutBack),
        ),
    ).toList();
    _scaleAnim = _iconCtrl.map((c) =>
        Tween<double>(begin: 1.0, end: 1.15).animate(
          CurvedAnimation(parent: c, curve: Curves.easeOutBack),
        ),
    ).toList();

    _labelCtrl = List.generate(
      _navItems.length,
          (_) => AnimationController(
          vsync: this, duration: const Duration(milliseconds: 350)),
    );
    _labelAnim = _labelCtrl.map((c) =>
        CurvedAnimation(parent: c, curve: Curves.easeInOut),
    ).toList();

    _pillCtrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 380),
    );
    _pillAnim = Tween<double>(
      begin: widget.currentIndex.toDouble(),
      end:   widget.currentIndex.toDouble(),
    ).animate(CurvedAnimation(parent: _pillCtrl, curve: Curves.easeInOutCubic));

    _iconCtrl[widget.currentIndex].value  = 1.0;
    _labelCtrl[widget.currentIndex].value = 1.0;
  }

  @override
  void didUpdateWidget(_AnimatedNavBar old) {
    super.didUpdateWidget(old);
    if (old.currentIndex != widget.currentIndex) {
      _animateTo(widget.currentIndex, from: old.currentIndex);
    }
  }

  void _animateTo(int newIndex, {required int from}) {
    _iconCtrl[from].reverse();
    _labelCtrl[from].reverse();
    _iconCtrl[newIndex].forward();
    _labelCtrl[newIndex].forward();
    _pillAnim = Tween<double>(
      begin: from.toDouble(),
      end:   newIndex.toDouble(),
    ).animate(CurvedAnimation(parent: _pillCtrl, curve: Curves.easeInOutCubic));
    _pillCtrl
      ..reset()
      ..forward();
  }

  @override
  void dispose() {
    for (final c in _iconCtrl)  c.dispose();
    for (final c in _labelCtrl) c.dispose();
    _pillCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      height: _barHeight + bottomPadding,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(
          top: BorderSide(color: AppTheme.surfaceBorder, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withAlpha(60),
            blurRadius: 20,
            offset:     const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final totalWidth = constraints.maxWidth;
            final tabWidth   = totalWidth / _navItems.length;

            return Stack(
              clipBehavior: Clip.none,
              children: [

                // ── Sliding pill ───────────────────────────────────
                AnimatedBuilder(
                  animation: _pillAnim,
                  builder: (_, __) {
                    final pillX   =
                        _pillAnim.value * tabWidth + (tabWidth - _pillSize) / 2;
                    final pillTop =
                        (_barHeight / 2 + _liftAmount) - (_pillSize / 2);
                    return Positioned(
                      top:  pillTop,
                      left: pillX,
                      child: Container(
                        width:  _pillSize,
                        height: _pillSize,
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color:        AppTheme.primary.withAlpha(100),
                              blurRadius:   16,
                              spreadRadius: 2,
                              offset:       const Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // ── Tab items ──────────────────────────────────────
                Row(
                  children: List.generate(_navItems.length, (i) {
                    final item = _navItems[i];
                    return Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap:    () => widget.onTap(i),
                        child: SizedBox(
                          height: _barHeight,
                          child: AnimatedBuilder(
                            animation: Listenable.merge(
                                [_liftAnim[i], _scaleAnim[i], _labelAnim[i]]),
                            builder: (context, __) {
                              final isActive = widget.currentIndex == i;
                              return Stack(
                                alignment: Alignment.center,
                                children: [
                                  Transform.translate(
                                    offset: Offset(0, _liftAnim[i].value),
                                    child: Transform.scale(
                                      scale: _scaleAnim[i].value,
                                      child: Icon(
                                        isActive ? item.activeIcon : item.icon,
                                        size:  24,
                                        color: isActive
                                            ? Colors.white
                                            : AppTheme.textSecondary,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 10,
                                    child: Opacity(
                                      opacity: _labelAnim[i].value,
                                      child: Transform.translate(
                                        offset: Offset(
                                            0, (1 - _labelAnim[i].value) * 4),
                                        child: Text(
                                          item.label,
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize:   10,
                                            fontWeight: FontWeight.w600,
                                            color:      AppTheme.primary,
                                            shadows: [
                                              Shadow(
                                                color: AppTheme.primary
                                                    .withAlpha(140),
                                                blurRadius: 10,
                                              ),
                                            ],
                                          ),
                                        ),
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
            );
          },
        ),
      ),
    );
  }
}