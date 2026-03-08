import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/flavor/app_strings.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/database/app_database.dart';
import '../../../features/settings/widgets/settings_sheet.dart';
import '../../banking/providers/banking_notifier.dart';
import '../../rewards/providers/rewards_notifier.dart';

class RewardsScreen extends ConsumerWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(themeProvider); // rebuild instantly on theme change
    final s = AppStrings.of(ref);
    final balanceAsync = ref.watch(balanceStreamProvider);
    final rewardsAsync = ref.watch(rewardsStreamProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ──────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.rewardsScreenTitle, style: AppTheme.heading),
                          const SizedBox(height: 4),
                          Text(
                            'Celebrate your progress with small joys.',
                            style: AppTheme.caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Settings button
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        showSettingsSheet(context);
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.surfaceBorder),
                        ),
                        child: Icon(
                          Icons.tune_rounded,
                          color: AppTheme.textSecondary,
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    balanceAsync.when(
                      loading: () => const SizedBox(width: 80, height: 36),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (balance) => _BalanceChip(balance: balance),
                    ),
                  ],
                ),
              ),
            ),

            // ── Rewards Grid ─────────────────────────────────
            rewardsAsync.when(
              loading: () =>  SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 80),
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
                    'Could not load rewards.',
                    style: AppTheme.caption.copyWith(color: AppTheme.error),
                  ),
                ),
              ),
              data: (rewards) {
                if (rewards.isEmpty) {
                  return SliverToBoxAdapter(
                    child: _EmptyState(
                      onAdd: () => _showCreateRewardSheet(context, ref),
                      s: s,
                    ),
                  );
                }

                final balance = balanceAsync.value ?? 0;

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                  sliver: SliverGrid(
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.78,
                    ),
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        if (index == rewards.length) {
                          return _AddRewardCard(
                            onTap: () =>
                                _showCreateRewardSheet(context, ref),
                          );
                        }
                        final reward = rewards[index];
                        final canAfford = balance >= reward.price;
                        return _RewardCard(
                          reward: reward,
                          canAfford: canAfford,
                          onRedeem: () => _redeem(context, ref, reward, balance, s),
                          onLongPress: () => _showCardOptions(context, ref, reward),
                          s: s,
                        );
                      },
                      childCount: rewards.length + 1,
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

  Future<void> _redeem(
      BuildContext context,
      WidgetRef ref,
      RewardItem reward,
      double balance,
      AppStrings s,
      ) async {
    if (balance < reward.price) return;

    HapticFeedback.mediumImpact();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.elevated,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Redeem reward?',
          style: AppTheme.body.copyWith(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppTheme.primary.withAlpha(38),
                shape: BoxShape.circle,
              ),
              child:  Icon(
                Icons.redeem_outlined,
                color: AppTheme.primary,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              reward.name,
              style: AppTheme.body.copyWith(fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.monetization_on_outlined,
                  color: Color(0xFFEAB308),
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  '${reward.price.toStringAsFixed(0)} ${s.rewardsCost}',
                  style: AppTheme.caption.copyWith(
                    color: const Color(0xFFEAB308),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              s.cancel,
              style: AppTheme.label.copyWith(color: AppTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              s.rewardsRedeem,
              style: AppTheme.label.copyWith(
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      // matches your notifier's method name exactly
      await ref
          .read(rewardsNotifierProvider.notifier)
          .purchaseReward(reward);
      if (context.mounted) _showRedeemedOverlay(context, reward);
    }
  }

  void _showRedeemedOverlay(BuildContext context, RewardItem reward) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _RedeemedOverlay(
        reward: reward,
        onDone: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }

  void _showCreateRewardSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.elevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _CreateRewardSheet(ref: ref),
    );
  }

  void _showCardOptions(BuildContext context, WidgetRef ref, RewardItem reward) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.elevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _RewardOptionsSheet(
        reward: reward,
        onEdit: () {
          Navigator.pop(context);
          _showEditRewardSheet(context, ref, reward);
        },
        onDelete: () async {
          Navigator.pop(context);
          await ref.read(rewardsNotifierProvider.notifier).deleteReward(reward.id);
        },
      ),
    );
  }

  void _showEditRewardSheet(BuildContext context, WidgetRef ref, RewardItem reward) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.elevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _EditRewardSheet(ref: ref, reward: reward),
    );
  }
}

// ── Balance Chip ──────────────────────────────────────────────

class _BalanceChip extends StatelessWidget {
  final double balance;
  const _BalanceChip({required this.balance});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.surfaceBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.monetization_on,
              color: Color(0xFFEAB308), size: 16),
          const SizedBox(width: 5),
          Text(
            balance.toStringAsFixed(0),
            style: AppTheme.label.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reward Card ───────────────────────────────────────────────

class _RewardCard extends StatelessWidget {
  final RewardItem reward;
  final bool canAfford;
  final VoidCallback onRedeem;
  final VoidCallback onLongPress;
  final AppStrings s;

  const _RewardCard({
    required this.reward,
    required this.canAfford,
    required this.onRedeem,
    required this.onLongPress,
    required this.s,
  });

  IconData get _icon {
    final n = reward.name.toLowerCase();
    if (n.contains('coffee') || n.contains('drink')) return Icons.coffee_outlined;
    if (n.contains('walk') || n.contains('outside')) return Icons.directions_walk_outlined;
    if (n.contains('music') || n.contains('listen')) return Icons.headphones_outlined;
    if (n.contains('read') || n.contains('book')) return Icons.menu_book_outlined;
    if (n.contains('game') || n.contains('play')) return Icons.sports_esports_outlined;
    if (n.contains('food') || n.contains('eat') || n.contains('snack')) return Icons.restaurant_outlined;
    if (n.contains('sleep') || n.contains('nap') || n.contains('rest')) return Icons.bed_outlined;
    if (n.contains('movie') || n.contains('watch') || n.contains('netflix')) return Icons.movie_outlined;
    if (n.contains('plant') || n.contains('garden')) return Icons.eco_outlined;
    return Icons.redeem_outlined;
  }

  Color get _accentColor {
    final n = reward.name.toLowerCase();
    if (n.contains('coffee') || n.contains('drink')) return const Color(0xFFC4965A);
    if (n.contains('walk') || n.contains('outside') || n.contains('plant')) return AppTheme.primary;
    if (n.contains('music') || n.contains('listen')) return const Color(0xFF5A7A9E);
    if (n.contains('movie') || n.contains('watch') || n.contains('netflix')) return AppTheme.coral;
    return AppTheme.primaryLight;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: canAfford ? 1.0 : 0.65,
      child: GestureDetector(
        onTap: canAfford ? onRedeem : null,
        onLongPress: onLongPress,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.surfaceBorder),
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon area — Stack so the ⋮ button can sit in the top-right corner
              Stack(
                children: [
                  Container(
                    height: 100,
                    width: double.infinity,
                    color: _accentColor.withAlpha(canAfford ? 20 : 12),
                    child: Center(
                      child: Icon(
                        _icon,
                        size: 44,
                        color: canAfford ? _accentColor : AppTheme.textDisabled,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: onLongPress,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppTheme.surface.withAlpha(200),
                          shape: BoxShape.circle,
                        ),
                        child:  Icon(
                          Icons.more_vert,
                          size: 15,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reward.name,
                        style: AppTheme.body.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: canAfford
                              ? AppTheme.textPrimary
                              : AppTheme.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (!canAfford) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Need ${reward.price.toStringAsFixed(0)} coins',
                          style: AppTheme.caption.copyWith(fontSize: 10),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const Spacer(),
                      // Discovery hint — only shown when affordable to avoid overflow
                      // (the ⋮ button in the corner is always visible for management)
                      if (canAfford)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Icon(Icons.touch_app_outlined,
                                  size: 10, color: AppTheme.textDisabled),
                              const SizedBox(width: 3),
                              Text(
                                'hold to manage',
                                style: AppTheme.caption.copyWith(
                                  fontSize: 9,
                                  color: AppTheme.textDisabled,
                                ),
                              ),
                            ],
                          ),
                        ),
                      Row(
                        children: [
                          // Price badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: canAfford
                                  ? const Color(0xFFEAB308).withAlpha(20)
                                  : AppTheme.elevated,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.monetization_on,
                                  size: 11,
                                  color: canAfford
                                      ? const Color(0xFFEAB308)
                                      : AppTheme.textDisabled,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  reward.price.toStringAsFixed(0),
                                  style: AppTheme.caption.copyWith(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: canAfford
                                        ? const Color(0xFFEAB308)
                                        : AppTheme.textDisabled,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Redeem button
                          Expanded(
                            child: GestureDetector(
                              onTap: canAfford ? onRedeem : null,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                height: 30,
                                decoration: BoxDecoration(
                                  color: canAfford
                                      ? AppTheme.primary
                                      : AppTheme.elevated,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    s.rewardsRedeem,
                                    style: AppTheme.caption.copyWith(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: canAfford
                                          ? Colors.white
                                          : AppTheme.textDisabled,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ), // GestureDetector
    );
  }
}

// ── Add Reward Card ───────────────────────────────────────────

class _AddRewardCard extends StatelessWidget {
  final VoidCallback onTap;
  const _AddRewardCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.surfaceBorder),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.primary.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child:  Icon(Icons.add, color: AppTheme.primary, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              'New Reward',
              style: AppTheme.caption.copyWith(
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Add something\nyou love',
              style: AppTheme.caption.copyWith(fontSize: 10, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Redeemed Overlay ──────────────────────────────────────────

class _RedeemedOverlay extends StatefulWidget {
  final RewardItem reward;
  final VoidCallback onDone;

  const _RedeemedOverlay({required this.reward, required this.onDone});

  @override
  State<_RedeemedOverlay> createState() => _RedeemedOverlayState();
}

class _RedeemedOverlayState extends State<_RedeemedOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    );

    _scale = TweenSequence([
      TweenSequenceItem(
        tween: Tween(begin: 0.7, end: 1.05)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.05, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 10,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 40),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.9)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 25,
      ),
    ]).animate(_ctrl);

    _opacity = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 15),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 25),
    ]).animate(_ctrl);

    _ctrl.forward().then((_) => widget.onDone());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withAlpha(140),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (ctx, _) => Opacity(
          opacity: _opacity.value,
          child: Center(
            child: ScaleTransition(
              scale: _scale,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 40, vertical: 36),
                margin: const EdgeInsets.symmetric(horizontal: 40),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.surfaceBorder),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withAlpha(30),
                        shape: BoxShape.circle,
                      ),
                      child:  Icon(
                        Icons.spa_outlined,
                        color: AppTheme.primary,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Enjoy your reward.',
                      style: AppTheme.body.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.reward.name,
                      style: AppTheme.caption.copyWith(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'You earned this.',
                      style: AppTheme.caption.copyWith(
                        fontStyle: FontStyle.italic,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  final AppStrings s;
  const _EmptyState({required this.onAdd, required this.s});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 80, 40, 0),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.primary.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child:  Icon(Icons.redeem_outlined,
                color: AppTheme.primary, size: 28),
          ),
          const SizedBox(height: 20),
          Text(s.rewardsEmptyTitle,
              style: AppTheme.body.copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text(
            s.rewardsEmptyBody,
            style: AppTheme.caption.copyWith(height: 1.6),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: onAdd,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primary.withAlpha(60)),
              ),
              child: Text(
                s.rewardsAddButton,
                style: AppTheme.label.copyWith(color: AppTheme.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Create Reward Sheet ───────────────────────────────────────

class _CreateRewardSheet extends StatefulWidget {
  final WidgetRef ref;
  const _CreateRewardSheet({required this.ref});

  @override
  State<_CreateRewardSheet> createState() => _CreateRewardSheetState();
}

class _CreateRewardSheetState extends State<_CreateRewardSheet> {
  final _nameController = TextEditingController();
  double _price = 50;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20, 20, 20,
        MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppTheme.surfaceBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('New Reward', style: AppTheme.heading.copyWith(fontSize: 20)),
          const SizedBox(height: 6),
          Text('What will you treat yourself to?', style: AppTheme.caption),
          const SizedBox(height: 20),

          // Name field
          TextField(
            controller: _nameController,
            autofocus: true,
            style: AppTheme.body,
            decoration: InputDecoration(
              hintText: 'e.g. Coffee break, 30 min walk…',
              hintStyle: AppTheme.body.copyWith(color: AppTheme.textDisabled),
              filled: true,
              fillColor: AppTheme.surface,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:  BorderSide(color: AppTheme.surfaceBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:  BorderSide(color: AppTheme.surfaceBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:  BorderSide(color: AppTheme.primary),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Price label + value
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Coin cost', style: AppTheme.label),
              Row(
                children: [
                  const Icon(Icons.monetization_on,
                      color: Color(0xFFEAB308), size: 16),
                  const SizedBox(width: 4),
                  Text(
                    _price.toStringAsFixed(0),
                    style: AppTheme.body.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFEAB308),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Slider
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppTheme.primary,
              inactiveTrackColor: AppTheme.surfaceBorder,
              thumbColor: AppTheme.primary,
              overlayColor: AppTheme.primary.withAlpha(30),
              trackHeight: 4,
              thumbShape:
              const RoundSliderThumbShape(enabledThumbRadius: 10),
            ),
            child: Slider(
              value: _price,
              min: 10,
              max: 500,
              divisions: 49,
              onChanged: (v) => setState(() => _price = v),
            ),
          ),

          // Quick presets
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [25, 50, 100, 200, 500].map((amount) {
              final selected = _price == amount.toDouble();
              return GestureDetector(
                onTap: () => setState(() => _price = amount.toDouble()),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppTheme.primary.withAlpha(30)
                        : AppTheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selected
                          ? AppTheme.primary
                          : AppTheme.surfaceBorder,
                    ),
                  ),
                  child: Text(
                    '$amount',
                    style: AppTheme.caption.copyWith(
                      color: selected
                          ? AppTheme.primary
                          : AppTheme.textSecondary,
                      fontWeight:
                      selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _create,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'Add Reward',
                style: AppTheme.label.copyWith(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _create() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    await widget.ref
        .read(rewardsNotifierProvider.notifier)
        .createReward(name: name, price: _price);
    if (mounted) Navigator.pop(context);
  }
}
// ── Reward Options Sheet ──────────────────────────────────────

class _RewardOptionsSheet extends StatelessWidget {
  final RewardItem reward;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RewardOptionsSheet({
    required this.reward,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppTheme.surfaceBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(reward.name,
              style: AppTheme.body.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.monetization_on,
                color: Color(0xFFEAB308), size: 13),
            const SizedBox(width: 4),
            Text('${reward.price.toStringAsFixed(0)} coins',
                style: AppTheme.caption),
          ]),
          const SizedBox(height: 20),
          // Edit
          _OptionRow(
            icon: Icons.edit_outlined,
            label: 'Edit reward',
            color: AppTheme.textPrimary,
            onTap: onEdit,
          ),
          const SizedBox(height: 4),
          // Delete
          _OptionRow(
            icon: Icons.delete_outline,
            label: 'Delete reward',
            color: AppTheme.error,
            onTap: onDelete,
          ),
        ],
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _OptionRow({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(40)),
        ),
        child: Row(children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 12),
          Text(label, style: AppTheme.body.copyWith(color: color, fontSize: 14)),
        ]),
      ),
    );
  }
}

// ── Edit Reward Sheet ─────────────────────────────────────────

class _EditRewardSheet extends StatefulWidget {
  final WidgetRef ref;
  final RewardItem reward;
  const _EditRewardSheet({required this.ref, required this.reward});

  @override
  State<_EditRewardSheet> createState() => _EditRewardSheetState();
}

class _EditRewardSheetState extends State<_EditRewardSheet> {
  late final TextEditingController _nameController;
  late double _price;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.reward.name);
    _price = widget.reward.price.clamp(10, 500);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20, 20, 20,
        MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppTheme.surfaceBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Edit Reward',
              style: AppTheme.heading.copyWith(fontSize: 20)),
          const SizedBox(height: 6),
          Text('Update the name or coin cost.',
              style: AppTheme.caption),
          const SizedBox(height: 20),

          // Name field
          TextField(
            controller: _nameController,
            autofocus: true,
            style: AppTheme.body,
            decoration: InputDecoration(
              hintText: 'Reward name',
              hintStyle:
              AppTheme.body.copyWith(color: AppTheme.textDisabled),
              filled: true,
              fillColor: AppTheme.surface,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                BorderSide(color: AppTheme.surfaceBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                BorderSide(color: AppTheme.surfaceBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:  BorderSide(color: AppTheme.primary),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Price label
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Coin cost', style: AppTheme.label),
              Row(children: [
                const Icon(Icons.monetization_on,
                    color: Color(0xFFEAB308), size: 16),
                const SizedBox(width: 4),
                Text(
                  _price.toStringAsFixed(0),
                  style: AppTheme.body.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFEAB308),
                  ),
                ),
              ]),
            ],
          ),
          const SizedBox(height: 10),

          // Slider
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppTheme.primary,
              inactiveTrackColor: AppTheme.surfaceBorder,
              thumbColor: AppTheme.primary,
              overlayColor: AppTheme.primary.withAlpha(30),
              trackHeight: 4,
              thumbShape:
              const RoundSliderThumbShape(enabledThumbRadius: 10),
            ),
            child: Slider(
              value: _price,
              min: 10,
              max: 500,
              divisions: 49,
              onChanged: (v) => setState(() => _price = v),
            ),
          ),

          // Quick presets
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [25, 50, 100, 200, 500].map((amount) {
              final selected = _price == amount.toDouble();
              return GestureDetector(
                onTap: () => setState(() => _price = amount.toDouble()),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppTheme.primary.withAlpha(30)
                        : AppTheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selected
                          ? AppTheme.primary
                          : AppTheme.surfaceBorder,
                    ),
                  ),
                  child: Text(
                    '\$amount',
                    style: AppTheme.caption.copyWith(
                      color: selected
                          ? AppTheme.primary
                          : AppTheme.textSecondary,
                      fontWeight: selected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'Save Changes',
                style: AppTheme.label.copyWith(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    await widget.ref.read(rewardsNotifierProvider.notifier).updateReward(
      id: widget.reward.id,
      name: name,
      price: _price,
    );
    if (mounted) Navigator.pop(context);
  }
}