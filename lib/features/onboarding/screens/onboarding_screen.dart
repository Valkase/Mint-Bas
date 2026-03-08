// lib/features/onboarding/screens/onboarding_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/flavor/app_flavor.dart';
import '../../../core/flavor/app_strings.dart';
import '../../../core/services/device_flavor_service.dart';
import '../../../core/theme/app_theme.dart';

// Onboarding accent color is flavor-aware (matches AppTheme.primary at
// the time this screen is built, which has already been configured).

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with SingleTickerProviderStateMixin {

  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await DeviceFlavorService.instance.markOnboardingComplete();
    if (mounted) context.go('/');
  }

  void _next() {
    if (_page < 2) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve:    Curves.easeInOutCubic,
      );
    } else {
      _finish();
    }
  }

  void _skip() => _finish();

  @override
  Widget build(BuildContext context) {
    final s       = AppStrings.of(ref);
    final flavor  = ref.read(flavorProvider);
    final primary = AppTheme.primary;
    final isLast  = _page == 2;

    final slides = [
      _SlideData(
        icon     : flavor == AppFlavor.basboosa
            ? Icons.favorite_rounded
            : Icons.checklist_rounded,
        title    : s.ob1Title,
        subtitle : s.ob1Subtitle,
      ),
      _SlideData(
        icon     : Icons.timer_rounded,
        title    : s.ob2Title,
        subtitle : s.ob2Subtitle,
      ),
      _SlideData(
        icon     : Icons.redeem_rounded,
        title    : s.ob3Title,
        subtitle : s.ob3Subtitle,
      ),
    ];

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [

            // ── Skip ──────────────────────────────────────────────────
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 16, 24, 0),
                child: AnimatedOpacity(
                  opacity:  isLast ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: GestureDetector(
                    onTap: isLast ? null : _skip,
                    child: Text(
                      s.obSkip,
                      style: TextStyle(
                        color:      AppTheme.textSecondary,
                        fontSize:   14,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Slides ────────────────────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller:      _controller,
                itemCount:       slides.length,
                onPageChanged:   (i) => setState(() => _page = i),
                itemBuilder: (_, i) => _Slide(
                  data:    slides[i],
                  primary: primary,
                  flavor:  flavor,
                ),
              ),
            ),

            // ── Dots ──────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                final active = i == _page;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve:    Curves.easeOut,
                  margin:   const EdgeInsets.symmetric(horizontal: 4),
                  width:    active ? 24 : 8,
                  height:   8,
                  decoration: BoxDecoration(
                    color:        active ? primary : AppTheme.surfaceBorder,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),

            const SizedBox(height: 40),

            // ── CTA button ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  _next();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width:    double.infinity,
                  height:   56,
                  decoration: BoxDecoration(
                    color:        primary,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color:      primary.withAlpha(90),
                        blurRadius: 20,
                        offset:     const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      isLast ? s.obGetStarted : s.obNext,
                      style: const TextStyle(
                        color:      Colors.white,
                        fontSize:   16,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ── Slide ─────────────────────────────────────────────────────────────────────

class _SlideData {
  final IconData icon;
  final String   title;
  final String   subtitle;
  const _SlideData({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

class _Slide extends StatelessWidget {
  final _SlideData data;
  final Color      primary;
  final AppFlavor  flavor;

  const _Slide({
    required this.data,
    required this.primary,
    required this.flavor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          // Icon circle
          Container(
            width:  120,
            height: 120,
            decoration: BoxDecoration(
              color:  primary.withAlpha(30),
              shape:  BoxShape.circle,
              border: Border.all(color: primary.withAlpha(70), width: 1.5),
            ),
            child: Icon(data.icon, size: 56, color: primary),
          ),

          const SizedBox(height: 48),

          // Title
          Text(
            data.title,
            style: TextStyle(
              fontSize:      28,
              fontWeight:    FontWeight.w700,
              color:         AppTheme.textPrimary,
              fontFamily:    'Poppins',
              height:        1.25,
              // Arabic text looks better center-aligned
              letterSpacing: flavor == AppFlavor.basboosa ? 0 : -0.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Subtitle
          Text(
            data.subtitle,
            style: TextStyle(
              fontSize:   15,
              color:      AppTheme.textSecondary,
              fontFamily: 'Poppins',
              height:     1.7,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}