import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';

class DeadlineBadge extends StatelessWidget {
  final DateTime deadline;

  const DeadlineBadge({super.key, required this.deadline});

  bool get _isOverdue => deadline.isBefore(DateTime.now());
  bool get _isSoon =>
      deadline.difference(DateTime.now()).inDays <= 2 && !_isOverdue;

  Color get _color {
    if (_isOverdue) return AppTheme.error;
    if (_isSoon) return AppTheme.warning;
    return AppTheme.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.schedule, size: 12, color: _color),
        const SizedBox(width: 3),
        Text(
          DateFormat('MMM d').format(deadline),
          style: AppTheme.caption.copyWith(color: _color),
        ),
      ],
    );
  }
}