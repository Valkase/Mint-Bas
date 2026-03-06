import 'package:bd_project/data/database/app_database.dart';
import 'package:bd_project/shared/providers/repository_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../banking/providers/banking_notifier.dart';

final rewardsStreamProvider = StreamProvider<List<RewardItem>>((ref) {
  return ref.watch(rewardRepositoryProvider).watchActiveRewards();
});

final rewardsNotifierProvider = AsyncNotifierProvider<RewardsNotifier, void>(RewardsNotifier.new);

class RewardsNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> purchaseReward(RewardItem reward) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final balance = ref.read(balanceStreamProvider).value ?? 0.0;
      await ref.read(rewardRepositoryProvider).purchaseReward(
        reward: reward,
        currentBalance: balance,
      );
    });
  }

  Future<void> createReward({
    required String name,
    String? description,
    required double price,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() =>
        ref.read(rewardRepositoryProvider).createReward(
          name: name,
          description: description,
          price: price,
        ));
  }

  Future<void> updateReward({
    required String id,
    required String name,
    required double price,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() =>
        ref.read(rewardRepositoryProvider).updateReward(
          id: id,
          name: name,
          price: price,
        ));
  }

  Future<void> deleteReward(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() =>
        ref.read(rewardRepositoryProvider).deleteReward(id));
  }
}