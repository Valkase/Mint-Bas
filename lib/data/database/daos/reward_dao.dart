import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/reward_items.dart';

part 'reward_dao.g.dart';

@DriftAccessor(tables: [RewardItems])
class RewardDao extends DatabaseAccessor<AppDatabase> with _$RewardDaoMixin {
  RewardDao(super.db);

  Future<List<RewardItem>> getAllRewardItems() =>
      select(rewardItems).get();

  Stream<List<RewardItem>> watchAllRewardItems() =>
      (select(rewardItems)..where((t) => t.isActive.equals(true))).watch();

  Future<void> insertReward(RewardItemsCompanion reward) =>
      into(rewardItems).insert(reward);

  Future<void> updateReward(RewardItemsCompanion reward) =>
      update(rewardItems).replace(reward);

  Future<int> deleteReward(String id) =>
      (delete(rewardItems)..where((t) => t.id.equals(id))).go();
}