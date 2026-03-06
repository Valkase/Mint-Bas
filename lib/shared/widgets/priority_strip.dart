import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class PriorityStrip extends StatelessWidget {
  final int priority; // 0 = low, 1 = medium, 2 = high

  const PriorityStrip({super.key, required this.priority});

  Color get _color {
    return switch (priority) {
      2 => AppTheme.error,
      1 => AppTheme.warning,
      _ => AppTheme.primary,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      decoration: BoxDecoration(
        color: _color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}