import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/flavor/app_strings.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/database/app_database.dart';
import '../../../features/settings/widgets/settings_sheet.dart';
import '../../banking/providers/banking_notifier.dart';

// Filter state
enum _TransactionFilter { all, earned, spent }

class BankingScreen extends ConsumerStatefulWidget {
  const BankingScreen({super.key});

  @override
  ConsumerState<BankingScreen> createState() => _BankingScreenState();
}

class _BankingScreenState extends ConsumerState<BankingScreen> {
  _TransactionFilter _filter = _TransactionFilter.all;

  @override
  Widget build(BuildContext context) {
    ref.watch(themeProvider); // rebuild instantly on theme change
    final s = AppStrings.of(ref);
    final balanceAsync = ref.watch(balanceStreamProvider);
    final transactionsAsync = ref.watch(transactionsStreamProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ──────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(s.bankingScreenTitle, style: AppTheme.heading),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        showSettingsSheet(context);
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.surfaceBorder),
                        ),
                        child: Icon(
                          Icons.tune_rounded,
                          color: AppTheme.textSecondary,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Balance Hero Card ────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: balanceAsync.when(
                  loading: () => const _BalanceCardSkeleton(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (balance) {
                    return transactionsAsync.when(
                      loading: () => _BalanceCard(
                        balance: balance,
                        totalEarned: 0,
                        totalSpent: 0,
                        s: s,
                      ),
                      error: (_, __) => _BalanceCard(
                        balance: balance,
                        totalEarned: 0,
                        totalSpent: 0,
                        s: s,
                      ),
                      data: (transactions) {
                        final earned = transactions
                            .where((t) => t.type == 'earn')
                            .fold<double>(0, (sum, t) => sum + t.amount);
                        final spent = transactions
                            .where((t) => t.type == 'spend')
                            .fold<double>(0, (sum, t) => sum + t.amount);
                        return _BalanceCard(
                          balance: balance,
                          totalEarned: earned,
                          totalSpent: spent,
                          s: s,
                        );
                      },
                    );
                  },
                ),
              ),
            ),

            // ── Filter Chips ─────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'All',
                      selected: _filter == _TransactionFilter.all,
                      onTap: () =>
                          setState(() => _filter = _TransactionFilter.all),
                    ),
                    const SizedBox(width: 10),
                    _FilterChip(
                      label: 'Earned',
                      selected: _filter == _TransactionFilter.earned,
                      onTap: () =>
                          setState(() => _filter = _TransactionFilter.earned),
                    ),
                    const SizedBox(width: 10),
                    _FilterChip(
                      label: 'Spent',
                      selected: _filter == _TransactionFilter.spent,
                      onTap: () =>
                          setState(() => _filter = _TransactionFilter.spent),
                    ),
                  ],
                ),
              ),
            ),

            // ── Transaction List ─────────────────────────────
            transactionsAsync.when(
              loading: () =>  SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primary,
                      strokeWidth: 2,
                    ),
                  ),
                ),
              ),
              error: (_, __) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'Could not load transactions.',
                    style: AppTheme.caption.copyWith(color: AppTheme.error),
                  ),
                ),
              ),
              data: (transactions) {
                // Apply filter
                final filtered = transactions.where((t) {
                  if (_filter == _TransactionFilter.earned) {
                    return t.type == 'earn';
                  }
                  if (_filter == _TransactionFilter.spent) {
                    return t.type == 'spend';
                  }
                  return true;
                }).toList()
                // Sort newest first
                  ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

                if (filtered.isEmpty) {
                  return SliverToBoxAdapter(
                    child: _EmptyState(filter: _filter, s: s),
                  );
                }

                // Group by date
                final grouped = _groupByDate(filtered);
                final dateKeys = grouped.keys.toList();

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        final date = dateKeys[index];
                        final items = grouped[date]!;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Date header
                            Padding(
                              padding:
                              const EdgeInsets.only(top: 16, bottom: 8),
                              child: Text(
                                _formatDateHeader(date),
                                style: AppTheme.caption.copyWith(
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.8,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            // Transaction rows
                            ...items.map(
                                  (t) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _TransactionRow(transaction: t),
                              ),
                            ),
                          ],
                        );
                      },
                      childCount: dateKeys.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Groups transactions by calendar date (year-month-day)
  Map<DateTime, List<Transaction>> _groupByDate(
      List<Transaction> transactions) {
    final map = <DateTime, List<Transaction>>{};
    for (final t in transactions) {
      final date = DateTime(
        t.createdAt.year,
        t.createdAt.month,
        t.createdAt.day,
      );
      map.putIfAbsent(date, () => []).add(t);
    }
    return map;
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (date == today) return 'TODAY';
    if (date == yesterday) return 'YESTERDAY';
    return DateFormat('MMMM d').format(date).toUpperCase();
  }
}

// ── Balance Card ──────────────────────────────────────────────

class _BalanceCard extends StatelessWidget {
  final double balance;
  final double totalEarned;
  final double totalSpent;
  final AppStrings s;

  const _BalanceCard({
    required this.balance,
    required this.totalEarned,
    required this.totalSpent,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.surfaceBorder),
      ),
      child: Column(
        children: [
          // Icon + balance
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.coral.withAlpha(38),
              shape: BoxShape.circle,
            ),
            child:  Icon(
              Icons.monetization_on_outlined,
              color: AppTheme.coral,
              size: 26,
            ),
          ),
          const SizedBox(height: 12),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: balance),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOut,
            builder: (context, value, _) => Text(
              value.toStringAsFixed(0),
              style: AppTheme.display.copyWith(
                fontSize: 40,
                letterSpacing: -1,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(s.bankingBalance, style: AppTheme.caption),

          const SizedBox(height: 16),
          Divider(color: AppTheme.surfaceBorder, height: 1),
          const SizedBox(height: 16),

          // Earned / Spent row
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      s.bankingEarned,
                      style: AppTheme.caption.copyWith(fontSize: 11),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '+${totalEarned.toStringAsFixed(0)}',
                      style: AppTheme.body.copyWith(
                        color: AppTheme.success,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 32,
                color: AppTheme.surfaceBorder,
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      s.bankingSpent,
                      style: AppTheme.caption.copyWith(fontSize: 11),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '-${totalSpent.toStringAsFixed(0)}',
                      style: AppTheme.body.copyWith(
                        color: AppTheme.coral,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BalanceCardSkeleton extends StatelessWidget {
  const _BalanceCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.surfaceBorder),
      ),
      child:  Center(
        child: CircularProgressIndicator(
          color: AppTheme.primary,
          strokeWidth: 2,
        ),
      ),
    );
  }
}

// ── Filter Chip ───────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
        const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : AppTheme.elevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppTheme.primary : AppTheme.surfaceBorder,
          ),
        ),
        child: Text(
          label,
          style: AppTheme.label.copyWith(
            color: selected ? Colors.white : AppTheme.textSecondary,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// ── Transaction Row ───────────────────────────────────────────

class _TransactionRow extends StatelessWidget {
  final Transaction transaction;

  const _TransactionRow({required this.transaction});

  bool get _isEarn => transaction.type == 'earn';

  Color get _color => _isEarn ? AppTheme.success : AppTheme.coral;

  IconData get _icon =>
      _isEarn ? Icons.arrow_upward : Icons.arrow_downward;

  String get _formattedTime =>
      DateFormat('h:mm a').format(transaction.createdAt);

  String get _label {
    if (transaction.note != null && transaction.note!.isNotEmpty) {
      return transaction.note!;
    }
    return _isEarn ? 'Task completed' : 'Reward purchased';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.surfaceBorder),
      ),
      child: Row(
        children: [
          // Icon bubble
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _color.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: Icon(_icon, color: _color, size: 18),
          ),
          const SizedBox(width: 14),

          // Label + time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _label,
                  style: AppTheme.body.copyWith(fontSize: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _formattedTime,
                  style: AppTheme.caption.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),

          // Amount
          Text(
            '${_isEarn ? '+' : '-'}${transaction.amount.toStringAsFixed(0)}',
            style: AppTheme.body.copyWith(
              color: _color,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final _TransactionFilter filter;
  final AppStrings s;
  const _EmptyState({required this.filter, required this.s});

  String _message(AppStrings s) {
    return switch (filter) {
      _TransactionFilter.earned =>
      'No coins earned yet.\nComplete tasks to start earning.',
      _TransactionFilter.spent =>
      'Nothing spent yet.\nVisit the Rewards tab to redeem coins.',
      _ => s.bankingEmpty,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.coral.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child:  Icon(
              Icons.monetization_on_outlined,
              color: AppTheme.coral,
              size: 28,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _message(s),
            style: AppTheme.caption.copyWith(height: 1.7),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}