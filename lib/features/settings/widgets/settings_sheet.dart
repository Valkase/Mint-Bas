// lib/features/settings/widgets/settings_sheet.dart
//
// Changes vs original:
//   • Added a "Your name" section visible only for the Mint flavor.
//   • Uses userNameProvider to read and update the stored first name.
//   • Accent colour picker: Mint sees only Sage (green) + Slate (blue).
//     Basboosa gets all five presets — she deserves the full palette.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/flavor/app_flavor.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/providers/user_name_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../pomodoro/providers/pomodoro_settings_provider.dart';
import '../../pomodoro/providers/pomodoro_notifier.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Entry point
// ─────────────────────────────────────────────────────────────────────────────

void showSettingsSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const _SettingsSheet(),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _SettingsSheet extends ConsumerWidget {
  const _SettingsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme    = ref.watch(themeProvider);
    final settings = ref.watch(pomodoroSettingsProvider);
    final pom      = ref.watch(pomodoroNotifierProvider);
    final flavor   = ref.read(flavorProvider);

    final isSessionActive = pom.status != PomodoroStatus.idle;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.elevated,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            // ── Handle ──────────────────────────────────────────────────────
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Container(
                  width : 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color       : AppTheme.surfaceBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),

            // ── Title ───────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Text('Settings', style: AppTheme.heading),
            ),

            // ── Name section (Mint only) ─────────────────────────────────────
            if (flavor == AppFlavor.mint) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'DISPLAY NAME',
                  style: AppTheme.caption.copyWith(
                    fontWeight   : FontWeight.w700,
                    letterSpacing: 1.2,
                    fontSize     : 11,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: _NameField(),
              ),
              const SizedBox(height: 8),
              Divider(color: AppTheme.surfaceBorder, height: 1),
            ],

            // ── Appearance ──────────────────────────────────────────────────
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'APPEARANCE',
                style: AppTheme.caption.copyWith(
                  fontWeight   : FontWeight.w700,
                  letterSpacing: 1.2,
                  fontSize     : 11,
                ),
              ),
            ),
            SwitchListTile(
              value      : theme.isDark,
              onChanged  : (_) => ref.read(themeProvider.notifier).toggleMode(),
              title      : Text('Dark mode', style: AppTheme.body),
              secondary  : Icon(
                theme.isDark
                    ? Icons.dark_mode_rounded
                    : Icons.light_mode_rounded,
                color: AppTheme.primary,
              ),
              activeColor: AppTheme.primary,
            ),
            // Accent swatches — Mint gets green + blue only (indices 0 & 1).
            // Basboosa gets all five because she gets the full experience.
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: _AccentPicker(
                currentIndex: theme.accentIndex,
                visibleCount: flavor == AppFlavor.mint ? 2 : accentPresets.length,
              ),
            ),

            // ── Pomodoro ────────────────────────────────────────────────────
            Divider(color: AppTheme.surfaceBorder, height: 1),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'POMODORO',
                style: AppTheme.caption.copyWith(
                  fontWeight   : FontWeight.w700,
                  letterSpacing: 1.2,
                  fontSize     : 11,
                ),
              ),
            ),
            _DurationTile(
              label    : 'Focus duration',
              value    : settings.workMinutes,
              min      : 5,
              max      : 60,
              step     : 5,
              unit     : 'min',
              icon     : Icons.timer_rounded,
              disabled : isSessionActive,
              onChanged: (v) => ref
                  .read(pomodoroSettingsProvider.notifier)
                  .setWorkMinutes(v),
            ),
            _DurationTile(
              label    : 'Short break',
              value    : settings.shortBreakMinutes,
              min      : 1,
              max      : 30,
              step     : 1,
              unit     : 'min',
              icon     : Icons.coffee_rounded,
              disabled : isSessionActive,
              onChanged: (v) => ref
                  .read(pomodoroSettingsProvider.notifier)
                  .setShortBreakMinutes(v),
            ),
            _DurationTile(
              label    : 'Long break',
              value    : settings.longBreakMinutes,
              min      : 5,
              max      : 60,
              step     : 5,
              unit     : 'min',
              icon     : Icons.self_improvement_rounded,
              disabled : isSessionActive,
              onChanged: (v) => ref
                  .read(pomodoroSettingsProvider.notifier)
                  .setLongBreakMinutes(v),
            ),

            if (isSessionActive)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: Text(
                  'Stop the current session to change Pomodoro settings.',
                  style: AppTheme.caption.copyWith(
                    color   : AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Name field (Mint only)
// ─────────────────────────────────────────────────────────────────────────────

class _NameField extends ConsumerStatefulWidget {
  const _NameField();

  @override
  ConsumerState<_NameField> createState() => _NameFieldState();
}

class _NameFieldState extends ConsumerState<_NameField> {
  late final TextEditingController _ctrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final current = ref.read(userNameProvider).valueOrNull ?? '';
    _ctrl = TextEditingController(text: current);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _ctrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    HapticFeedback.selectionClick();
    await ref.read(userNameProvider.notifier).setName(name);
    if (mounted) {
      setState(() => _saving = false);
      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content        : const Text('Name updated'),
          duration       : const Duration(seconds: 2),
          backgroundColor: AppTheme.surface,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(userNameProvider, (_, next) {
      final name = next.valueOrNull ?? '';
      if (_ctrl.text != name) _ctrl.text = name;
    });

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller        : _ctrl,
            textCapitalization: TextCapitalization.words,
            style: TextStyle(
              color     : AppTheme.textPrimary,
              fontFamily: 'Poppins',
              fontSize  : 15,
            ),
            decoration: InputDecoration(
              hintText: 'Enter your name',
              hintStyle: TextStyle(
                color     : AppTheme.textSecondary.withAlpha(120),
                fontFamily: 'Poppins',
              ),
              filled     : true,
              fillColor  : AppTheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide  : BorderSide(color: AppTheme.surfaceBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide  : BorderSide(color: AppTheme.surfaceBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide  : BorderSide(color: AppTheme.primary, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical  : 12,
              ),
              isDense: true,
            ),
            onChanged      : (_) => setState(() {}),
            onSubmitted    : (_) => _save(),
            textInputAction: TextInputAction.done,
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: _ctrl.text.trim().isNotEmpty && !_saving ? _save : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width : 44,
            height: 44,
            decoration: BoxDecoration(
              color       : _ctrl.text.trim().isNotEmpty
                  ? AppTheme.primary
                  : AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border      : Border.all(
                color: _ctrl.text.trim().isNotEmpty
                    ? AppTheme.primary
                    : AppTheme.surfaceBorder,
              ),
            ),
            child: _saving
                ? const Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(
                color      : Colors.white,
                strokeWidth: 2,
              ),
            )
                : Icon(
              Icons.check_rounded,
              color: _ctrl.text.trim().isNotEmpty
                  ? Colors.white
                  : AppTheme.textSecondary,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Accent colour picker
// visibleCount: how many presets to show, always starting from index 0.
//   Mint     → 2 (Sage = green, Slate = blue)
//   Basboosa → 5 (all presets)
// ─────────────────────────────────────────────────────────────────────────────

class _AccentPicker extends ConsumerWidget {
  final int currentIndex;
  final int visibleCount;

  const _AccentPicker({
    required this.currentIndex,
    required this.visibleCount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Wrap(
      spacing   : 12,
      runSpacing: 12,
      children  : List.generate(visibleCount, (index) {
        final preset   = accentPresets[index];
        final selected = currentIndex == index;
        final color    = preset.swatch;

        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            ref.read(themeProvider.notifier).setAccent(index);
          },
          child: Tooltip(
            message: preset.name,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width : 44,
              height: 44,
              decoration: BoxDecoration(
                color : color.withAlpha(selected ? 255 : 51),
                shape : BoxShape.circle,
                border: Border.all(
                  color: selected ? color : AppTheme.surfaceBorder,
                  width: selected ? 2.5 : 1,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : const SizedBox.shrink(),
            ),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Duration stepper tile
// ─────────────────────────────────────────────────────────────────────────────

class _DurationTile extends StatelessWidget {
  final String   label;
  final int      value;
  final int      min;
  final int      max;
  final int      step;
  final String   unit;
  final IconData icon;
  final bool     disabled;
  final void Function(int) onChanged;

  const _DurationTile({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.unit,
    required this.icon,
    required this.disabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.4 : 1.0,
      child: ListTile(
        leading : Icon(icon, color: AppTheme.primary, size: 22),
        title   : Text(label, style: AppTheme.body),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children    : [
            _StepButton(
              icon : Icons.remove,
              onTap: disabled || value <= min
                  ? null
                  : () => onChanged(value - step),
            ),
            SizedBox(
              width: 48,
              child: Text(
                unit.isEmpty ? '$value' : '$value $unit',
                textAlign: TextAlign.center,
                style    : AppTheme.body.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            _StepButton(
              icon : Icons.add,
              onTap: disabled || value >= max
                  ? null
                  : () => onChanged(value + step),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData      icon;
  final VoidCallback? onTap;

  const _StepButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width : 32,
        height: 32,
        decoration: BoxDecoration(
          color       : AppTheme.surface,
          borderRadius: BorderRadius.circular(8),
          border      : Border.all(color: AppTheme.surfaceBorder),
        ),
        child: Icon(
          icon,
          size : 16,
          color: onTap != null
              ? AppTheme.textPrimary
              : AppTheme.textSecondary,
        ),
      ),
    );
  }
}