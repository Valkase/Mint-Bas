// lib/features/onboarding/screens/name_entry_screen.dart
//
// Shown once, right after the Mint onboarding completes.
// Asks the user what to call them, saves it via userNameProvider,
// then navigates to the main app.
//
// Design mirrors the onboarding aesthetic (same background, same button style)
// so it feels like a seamless 4th onboarding step.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/user_name_provider.dart';
import '../../../core/theme/app_theme.dart';

class NameEntryScreen extends ConsumerStatefulWidget {
  const NameEntryScreen({super.key});

  @override
  ConsumerState<NameEntryScreen> createState() => _NameEntryScreenState();
}

class _NameEntryScreenState extends ConsumerState<NameEntryScreen>
    with SingleTickerProviderStateMixin {

  final _controller = TextEditingController();
  final _focusNode  = FocusNode();
  bool  _saving     = false;
  late final AnimationController _fadeCtrl;
  late final Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync   : this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

    // Auto-focus keyboard with a tiny delay so the animation isn't janky.
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _controller.text.trim();
    if (name.isEmpty) return;

    setState(() => _saving = true);
    HapticFeedback.mediumImpact();

    await ref.read(userNameProvider.notifier).setName(name);

    if (mounted) context.go('/');
  }

  void _skip() {
    HapticFeedback.selectionClick();
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final primary    = AppTheme.primary;
    final nameValue  = _controller.text.trim();
    final canSave    = nameValue.isNotEmpty && !_saving;

    return Scaffold(
      backgroundColor: AppTheme.background,
      // Resize when keyboard opens so content is never hidden.
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Skip ────────────────────────────────────────────────────
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: GestureDetector(
                      onTap: _skip,
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          color     : AppTheme.textSecondary,
                          fontSize  : 14,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),
                ),

                const Spacer(flex: 3),

                // ── Icon ────────────────────────────────────────────────────
                Container(
                  width : 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color : primary.withAlpha(30),
                    shape : BoxShape.circle,
                    border: Border.all(color: primary.withAlpha(70), width: 1.5),
                  ),
                  child: Icon(Icons.waving_hand_rounded, size: 40, color: primary),
                ),

                const SizedBox(height: 36),

                // ── Heading ─────────────────────────────────────────────────
                Text(
                  'What can I call you?',
                  style: TextStyle(
                    fontSize     : 28,
                    fontWeight   : FontWeight.w700,
                    color        : AppTheme.textPrimary,
                    fontFamily   : 'Poppins',
                    height       : 1.25,
                    letterSpacing: -0.5,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  'Just a name — so your greeting feels a little more personal.',
                  style: TextStyle(
                    fontSize  : 15,
                    color     : AppTheme.textSecondary,
                    fontFamily: 'Poppins',
                    height    : 1.7,
                  ),
                ),

                const SizedBox(height: 40),

                // ── Text field ──────────────────────────────────────────────
                TextField(
                  controller       : _controller,
                  focusNode        : _focusNode,
                  textCapitalization: TextCapitalization.words,
                  style: TextStyle(
                    color     : AppTheme.textPrimary,
                    fontFamily: 'Poppins',
                    fontSize  : 16,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Your name',
                    hintStyle: TextStyle(
                      color     : AppTheme.textSecondary.withAlpha(120),
                      fontFamily: 'Poppins',
                    ),
                    filled     : true,
                    fillColor  : AppTheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide  : BorderSide(color: AppTheme.surfaceBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide  : BorderSide(color: AppTheme.surfaceBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide  : BorderSide(color: primary, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical  : 16,
                    ),
                  ),
                  onChanged    : (_) => setState(() {}),
                  onSubmitted  : (_) => _save(),
                  textInputAction: TextInputAction.done,
                ),

                const Spacer(flex: 2),

                // ── CTA button ──────────────────────────────────────────────
                GestureDetector(
                  onTap: canSave ? _save : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width : double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      color        : canSave ? primary : primary.withAlpha(80),
                      borderRadius : BorderRadius.circular(18),
                      boxShadow    : canSave
                          ? [
                        BoxShadow(
                          color     : primary.withAlpha(90),
                          blurRadius: 20,
                          offset    : const Offset(0, 6),
                        ),
                      ]
                          : [],
                    ),
                    child: Center(
                      child: _saving
                          ? SizedBox(
                        width : 22,
                        height: 22,
                        child : CircularProgressIndicator(
                          color      : Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                          : Text(
                        "Let's go",
                        style: const TextStyle(
                          color     : Colors.white,
                          fontSize  : 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}