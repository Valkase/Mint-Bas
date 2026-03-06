import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class PomodoroDots extends StatelessWidget {
  final int total;
  final int completed;

  const PomodoroDots({
    super.key,
    required this.total,
    required this.completed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(total, (index) {
        final isDone = index < completed;
        return Container(
          margin: const EdgeInsets.only(right: 4),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDone
                ? AppTheme.primary
                : AppTheme.primary.withOpacity(0.25),
          ),
        );
      }),
    );
  }
}