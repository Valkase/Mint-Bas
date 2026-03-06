import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class CoinBadge extends StatelessWidget {
  final double amount;
  final bool small;

  const CoinBadge({super.key, required this.amount, this.small = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 10,
        vertical: small ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: AppTheme.coral.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.coral.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.monetization_on_outlined,
            color: AppTheme.coral,
            size: small ? 12 : 14,
          ),
          const SizedBox(width: 4),
          Text(
            amount.toStringAsFixed(0),
            style: AppTheme.label.copyWith(
              color: AppTheme.coral,
              fontSize: small ? 11 : 13,
            ),
          ),
        ],
      ),
    );
  }
}