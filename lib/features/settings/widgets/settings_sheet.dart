import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../pomodoro/providers/pomodoro_settings_provider.dart';
import '../../pomodoro/providers/pomodoro_notifier.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Entry point — called from header buttons
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

    final isSessionActive = pom.status != PomodoroStatus.idle;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.elevated,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20, 16, 20,
          MediaQuery.of(context).viewInsets.bottom + 40,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Drag handle ──────────────────────────────────────────────
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

            Text('Settings', style: AppTheme.heading),
            const SizedBox(height: 24),

            // ── Appearance ───────────────────────────────────────────────
            _SectionHeader(label: 'Appearance'),
            const SizedBox(height: 12),

            // Dark / Light toggle
            _SettingRow(
              icon: Icons.brightness_6_outlined,
              label: 'Dark mode',
              trailing: Switch(
                value: theme.isDark,
                onChanged: (_) {
                  HapticFeedback.lightImpact();
                  ref.read(themeProvider.notifier).toggleMode();
                },
                activeThumbColor: AppTheme.primary,
                activeTrackColor: AppTheme.primary.withAlpha(80),
                inactiveThumbColor: AppTheme.textSecondary,
                inactiveTrackColor: AppTheme.surfaceBorder,
              ),
            ),
            const SizedBox(height: 16),

            // Accent colour swatches
            _SettingRow(
              icon: Icons.palette_outlined,
              label: 'Accent colour',
              trailing: const SizedBox.shrink(),
            ),
            const SizedBox(height: 14),
            _AccentPicker(currentIndex: theme.accentIndex),
            const SizedBox(height: 28),

            // ── Pomodoro Timer ───────────────────────────────────────────
            _SectionHeader(label: 'Pomodoro Timer'),
            const SizedBox(height: 4),

            if (isSessionActive) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.warning.withAlpha(76)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        color: AppTheme.warning, size: 15),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Changes apply after you reset the timer.',
                        style: AppTheme.caption.copyWith(
                          fontSize: 12,
                          color: AppTheme.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 8),
            ],

            _DurationStepper(
              icon: Icons.self_improvement_outlined,
              label: 'Focus session',
              unit: 'min',
              value: settings.workMinutes,
              min: 1,
              max: 60,
              step: 5,
              color: AppTheme.primary,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                ref.read(pomodoroSettingsProvider.notifier).setWorkMinutes(v);
              },
            ),
            const SizedBox(height: 12),

            _DurationStepper(
              icon: Icons.coffee_outlined,
              label: 'Short break',
              unit: 'min',
              value: settings.shortBreakMinutes,
              min: 1,
              max: 30,
              step: 1,
              color: AppTheme.pomodoroBreak,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                ref.read(pomodoroSettingsProvider.notifier).setShortBreakMinutes(v);
              },
            ),
            const SizedBox(height: 12),

            _DurationStepper(
              icon: Icons.weekend_outlined,
              label: 'Long break',
              unit: 'min',
              value: settings.longBreakMinutes,
              min: 1,
              max: 60,
              step: 5,
              color: AppTheme.pomodoroBreak,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                ref.read(pomodoroSettingsProvider.notifier).setLongBreakMinutes(v);
              },
            ),
            const SizedBox(height: 28),

            _SectionHeader(label: 'About'),
            const SizedBox(height: 12),
            _SettingRow(
              icon: Icons.info_outlined,
              label: 'Version',
              trailing: Text(
                '1.0.0',
                style: AppTheme.caption.copyWith(fontSize: 12),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ), // SingleChildScrollView
    ); // Container
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Duration Stepper
// ─────────────────────────────────────────────────────────────────────────────

class _DurationStepper extends StatelessWidget {
  final IconData icon;
  final String label;
  final String unit;
  final int value;
  final int min;
  final int max;
  final int step;
  final Color color;
  final ValueChanged<int> onChanged;

  const _DurationStepper({
    required this.icon,
    required this.label,
    required this.unit,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.surfaceBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withAlpha(31),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: AppTheme.body.copyWith(fontSize: 14),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _StepBtn(
                icon: Icons.remove,
                enabled: value > min,
                color: color,
                onTap: () => onChanged((value - step).clamp(min, max)),
              ),
              SizedBox(
                width: 52,
                child: Text(
                  '$value $unit',
                  style: AppTheme.body.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              _StepBtn(
                icon: Icons.add,
                enabled: value < max,
                color: color,
                onTap: () => onChanged((value + step).clamp(min, max)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final Color color;
  final VoidCallback onTap;

  const _StepBtn({
    required this.icon,
    required this.enabled,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: enabled ? color.withAlpha(31) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 16,
          color: enabled ? color : AppTheme.textDisabled,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Accent Colour Picker
// ─────────────────────────────────────────────────────────────────────────────

class _AccentPicker extends ConsumerWidget {
  final int currentIndex;
  const _AccentPicker({required this.currentIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: List.generate(accentPresets.length, (index) {
        final preset  = accentPresets[index];
        final selected = currentIndex == index;
        final color    = preset.swatch;

        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            ref.read(themeProvider.notifier).setAccent(index);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withAlpha(selected ? 255 : 51),
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? color : AppTheme.surfaceBorder,
                width: selected ? 2.5 : 1,
              ),
            ),
            child: selected
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : Tooltip(
              message: preset.name,
              child: const SizedBox.expand(),
            ),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Micro widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: AppTheme.caption.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: AppTheme.textDisabled,
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget trailing;

  const _SettingRow({
    required this.icon,
    required this.label,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppTheme.surface,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppTheme.textSecondary, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: AppTheme.body.copyWith(fontSize: 14)),
        ),
        trailing,
      ],
    );
  }
}