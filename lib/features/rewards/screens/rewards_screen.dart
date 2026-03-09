// lib/features/rewards/screens/rewards_screen.dart
//
// Changes vs original:
//   N2 — _EditRewardSheet quick-preset chips: '\$amount' → '$amount'
//        The backslash caused every chip to render the literal text "$amount"
//        instead of the numeric value. One character fix; slider was unaffected.

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
    ref.watch(themeProvider);
    final s             = AppStrings.of(ref);
    final balanceAsync  = ref.watch(balanceStreamProvider);
    final rewardsAsync  = ref.watch(rewardsStreamProvider);

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
                            s.rewardsSubtitle,
                            style: AppTheme.caption),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Balance badge
                    balanceAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error  : (_, __) => const SizedBox.shrink(),
                      data   : (bal) => GestureDetector(
                        onTap: () => showSettingsSheet(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color       : const Color(0xFFEAB308).withAlpha(20),
                            borderRadius: BorderRadius.circular(12),
                            border      : Border.all(
                                color: const Color(0xFFEAB308).withAlpha(60)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.monetization_on,
                                  color: Color(0xFFEAB308), size: 16),
                              const SizedBox(width: 6),
                              Text(
                                bal.toStringAsFixed(0),
                                style: AppTheme.body.copyWith(
                                  color     : const Color(0xFFEAB308),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Rewards grid ─────────────────────────────────
            rewardsAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => SliverFillRemaining(
                child: Center(
                  child: Text('Error: $e', style: AppTheme.caption),
                ),
              ),
              data: (rewards) => SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                        (ctx, i) {
                      if (i == rewards.length) {
                        return _AddRewardCard(
                          onTap: () =>
                              _showCreateRewardSheet(context, ref),
                        );
                      }
                      final reward = rewards[i];
                      return _RewardCard(
                        reward : reward,
                        balance: balanceAsync.value ?? 0,
                        onTap  : () => _confirmRedeem(context, ref, reward),
                        onLongPress: () =>
                            _showCardOptions(context, ref, reward),
                      );
                    },
                    childCount: rewards.length + 1,
                  ),
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount     : 2,
                    crossAxisSpacing   : 12,
                    mainAxisSpacing    : 12,
                    childAspectRatio   : 0.85,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmRedeem(
      BuildContext context, WidgetRef ref, RewardItem reward) async {
    final s       = AppStrings.of(ref);
    final balance = ref.read(balanceStreamProvider).value ?? 0.0;

    if (balance < reward.price) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Not enough coins. You need ${reward.price.toInt()} but have ${balance.toInt()}.',
            style: AppTheme.caption.copyWith(color: AppTheme.textPrimary),
          ),
          backgroundColor: AppTheme.surface,
          behavior       : SnackBarBehavior.floating,
          shape          : RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.elevated,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title  : Text('Redeem reward?',
            style: AppTheme.heading.copyWith(fontSize: 18)),
        content: Text(
          'Spend ${reward.price.toInt()} coins on "${reward.name}"?',
          style: AppTheme.body.copyWith(
              fontSize: 14, color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel,
                style: AppTheme.label
                    .copyWith(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              s.rewardsRedeem,
              style: AppTheme.label.copyWith(
                color     : AppTheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
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
      context           : context,
      isScrollControlled: true,
      backgroundColor   : AppTheme.elevated,
      shape             : const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _CreateRewardSheet(ref: ref),
    );
  }

  void _showCardOptions(BuildContext context, WidgetRef ref, RewardItem reward) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context        : context,
      backgroundColor: AppTheme.elevated,
      shape          : const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _RewardOptionsSheet(
        reward  : reward,
        onEdit  : () {
          Navigator.pop(context);
          _showEditRewardSheet(context, ref, reward);
        },
        onDelete: () {
          Navigator.pop(context);
          ref.read(rewardsNotifierProvider.notifier).deleteReward(reward.id);
        },
      ),
    );
  }

  void _showEditRewardSheet(
      BuildContext context, WidgetRef ref, RewardItem reward) {
    showModalBottomSheet(
      context           : context,
      isScrollControlled: true,
      backgroundColor   : AppTheme.elevated,
      shape             : const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _EditRewardSheet(ref: ref, reward: reward),
    );
  }
}

// ── Reward Card ───────────────────────────────────────────────

class _RewardCard extends StatelessWidget {
  final RewardItem   reward;
  final double       balance;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _RewardCard({
    required this.reward,
    required this.balance,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final canAfford = balance >= reward.price;

    return GestureDetector(
      onTap      : onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color       : AppTheme.surface,
          borderRadius: BorderRadius.circular(18),
          border      : Border.all(color: AppTheme.surfaceBorder),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width : 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color : AppTheme.primary.withAlpha(20),
                      shape : BoxShape.circle,
                    ),
                    child: Icon(Icons.redeem_rounded,
                        color: AppTheme.primary, size: 20),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color       : canAfford
                          ? const Color(0xFFEAB308).withAlpha(20)
                          : AppTheme.surfaceBorder.withAlpha(60),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.monetization_on,
                          color: canAfford
                              ? const Color(0xFFEAB308)
                              : AppTheme.textDisabled,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          reward.price.toInt().toString(),
                          style: AppTheme.caption.copyWith(
                            color     : canAfford
                                ? const Color(0xFFEAB308)
                                : AppTheme.textDisabled,
                            fontWeight: FontWeight.w700,
                            fontSize  : 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                reward.name,
                style  : AppTheme.body.copyWith(fontWeight: FontWeight.w600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (reward.description != null &&
                  reward.description!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  reward.description!,
                  style   : AppTheme.caption.copyWith(fontSize: 11),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Container(
                width     : double.infinity,
                padding   : const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color       : canAfford
                      ? AppTheme.primary
                      : AppTheme.surfaceBorder.withAlpha(80),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    canAfford ? 'Redeem' : 'Need more coins',
                    style: AppTheme.caption.copyWith(
                      color     : canAfford
                          ? Colors.white
                          : AppTheme.textDisabled,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
          color       : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          border      : Border.all(color: AppTheme.surfaceBorder),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width : 44,
              height: 44,
              decoration: BoxDecoration(
                color : AppTheme.primary.withAlpha(20),
                shape : BoxShape.circle,
              ),
              child: Icon(Icons.add, color: AppTheme.primary, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              'New Reward',
              style: AppTheme.caption.copyWith(
                color     : AppTheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Redeemed Overlay ──────────────────────────────────────────

class _RedeemedOverlay extends StatefulWidget {
  final RewardItem   reward;
  final VoidCallback onDone;

  const _RedeemedOverlay({required this.reward, required this.onDone});

  @override
  State<_RedeemedOverlay> createState() => _RedeemedOverlayState();
}

class _RedeemedOverlayState extends State<_RedeemedOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _scale;
  late Animation<double>   _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _scale   = Tween<double>(begin: 0.7, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _opacity = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
            parent: _ctrl, curve: const Interval(0, 0.4)));
    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) _ctrl.reverse().then((_) => widget.onDone());
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Material(
        color: Colors.black54,
        child: Center(
          child: ScaleTransition(
            scale: _scale,
            child: Container(
              margin   : const EdgeInsets.all(40),
              padding  : const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color       : AppTheme.surface,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children    : [
                  Icon(Icons.celebration_rounded,
                      color: AppTheme.primary, size: 52),
                  const SizedBox(height: 16),
                  Text('Enjoy it!', style: AppTheme.heading),
                  const SizedBox(height: 8),
                  Text(
                    widget.reward.name,
                    style    : AppTheme.body.copyWith(
                        color: AppTheme.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Reward Options Sheet ──────────────────────────────────────

class _RewardOptionsSheet extends StatelessWidget {
  final RewardItem   reward;
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
        mainAxisSize      : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width : 40,
              height: 4,
              decoration: BoxDecoration(
                color       : AppTheme.surfaceBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(reward.name,
              style: AppTheme.heading.copyWith(fontSize: 18)),
          const SizedBox(height: 20),
          _OptionRow(
            icon : Icons.edit_outlined,
            label: 'Edit reward',
            color: AppTheme.primary,
            onTap: onEdit,
          ),
          const SizedBox(height: 8),
          _OptionRow(
            icon : Icons.delete_outline_rounded,
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
  final String   label;
  final Color    color;
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
        padding   : const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color       : color.withAlpha(15),
          borderRadius: BorderRadius.circular(12),
          border      : Border.all(color: color.withAlpha(40)),
        ),
        child: Row(children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 12),
          Text(label,
              style: AppTheme.body.copyWith(color: color, fontSize: 14)),
        ]),
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
        mainAxisSize      : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width : 40,
              height: 4,
              decoration: BoxDecoration(
                color       : AppTheme.surfaceBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('New Reward',
              style: AppTheme.heading.copyWith(fontSize: 20)),
          const SizedBox(height: 6),
          Text('What will you treat yourself to?',
              style: AppTheme.caption),
          const SizedBox(height: 20),
          TextField(
            controller: _nameController,
            autofocus : true,
            style     : AppTheme.body,
            decoration: InputDecoration(
              hintText      : 'e.g. Coffee break, Movie night…',
              hintStyle     : AppTheme.body
                  .copyWith(color: AppTheme.textDisabled),
              filled        : true,
              fillColor     : AppTheme.surface,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
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
                borderSide  : BorderSide(color: AppTheme.primary),
              ),
            ),
          ),
          const SizedBox(height: 24),
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
                    color     : const Color(0xFFEAB308),
                  ),
                ),
              ]),
            ],
          ),
          const SizedBox(height: 10),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor  : AppTheme.primary,
              inactiveTrackColor: AppTheme.surfaceBorder,
              thumbColor        : AppTheme.primary,
              overlayColor      : AppTheme.primary.withAlpha(30),
              trackHeight       : 4,
              thumbShape:
              const RoundSliderThumbShape(enabledThumbRadius: 10),
            ),
            child: Slider(
              value    : _price,
              min      : 10,
              max      : 500,
              divisions: 49,
              onChanged: (v) => setState(() => _price = v),
            ),
          ),
          // Quick presets — _CreateRewardSheet (correct, no backslash)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [25, 50, 100, 200, 500].map((amount) {
              final selected = _price == amount.toDouble();
              return GestureDetector(
                onTap: () => setState(() => _price = amount.toDouble()),
                child: AnimatedContainer(
                  duration : const Duration(milliseconds: 120),
                  padding  : const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color : selected
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
                    '$amount', // ← correct
                    style: AppTheme.caption.copyWith(
                      color     : selected
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
              onPressed: _create,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding        : const EdgeInsets.symmetric(vertical: 16),
                elevation      : 0,
                shape          : RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'Add Reward',
                style: AppTheme.label.copyWith(
                  color     : Colors.white,
                  fontSize  : 15,
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

// ── Edit Reward Sheet ─────────────────────────────────────────

class _EditRewardSheet extends StatefulWidget {
  final WidgetRef  ref;
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
        mainAxisSize      : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width : 40,
              height: 4,
              decoration: BoxDecoration(
                color       : AppTheme.surfaceBorder,
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
          TextField(
            controller: _nameController,
            autofocus : true,
            style     : AppTheme.body,
            decoration: InputDecoration(
              hintText      : 'Reward name',
              hintStyle     : AppTheme.body
                  .copyWith(color: AppTheme.textDisabled),
              filled        : true,
              fillColor     : AppTheme.surface,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
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
                borderSide  : BorderSide(color: AppTheme.primary),
              ),
            ),
          ),
          const SizedBox(height: 24),
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
                    color     : const Color(0xFFEAB308),
                  ),
                ),
              ]),
            ],
          ),
          const SizedBox(height: 10),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor  : AppTheme.primary,
              inactiveTrackColor: AppTheme.surfaceBorder,
              thumbColor        : AppTheme.primary,
              overlayColor      : AppTheme.primary.withAlpha(30),
              trackHeight       : 4,
              thumbShape:
              const RoundSliderThumbShape(enabledThumbRadius: 10),
            ),
            child: Slider(
              value    : _price,
              min      : 10,
              max      : 500,
              divisions: 49,
              onChanged: (v) => setState(() => _price = v),
            ),
          ),
          // ── BUG N2 FIX ─────────────────────────────────────────────────────
          // Was: child: Text('\$amount')  → rendered literal "$amount" on all chips
          // Fix: child: Text('$amount')   → interpolates the int value correctly
          // ─────────────────────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [25, 50, 100, 200, 500].map((amount) {
              final selected = _price == amount.toDouble();
              return GestureDetector(
                onTap: () => setState(() => _price = amount.toDouble()),
                child: AnimatedContainer(
                  duration : const Duration(milliseconds: 120),
                  padding  : const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color : selected
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
                    '$amount', // ← N2 FIX: was '\$amount'
                    style: AppTheme.caption.copyWith(
                      color     : selected
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
                padding        : const EdgeInsets.symmetric(vertical: 16),
                elevation      : 0,
                shape          : RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'Save changes',
                style: AppTheme.label.copyWith(
                  color     : Colors.white,
                  fontSize  : 15,
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
      id   : widget.reward.id,
      name : name,
      price: _price,
    );
    if (mounted) Navigator.pop(context);
  }
}