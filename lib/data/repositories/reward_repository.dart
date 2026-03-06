import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../database/daos/reward_dao.dart';
import '../../core/exceptions/app_exceptions.dart';
import 'banking_repository.dart';

class RewardRepository {
  final RewardDao _rewardDao;
  final BankingRepository _bankingRepository;

  RewardRepository(this._rewardDao, this._bankingRepository);

  Stream<List<RewardItem>> watchActiveRewards() =>
      _rewardDao.watchAllRewardItems();

  Future<void> createReward({
    required String name,
    String? description,
    required double price,
  }) async {
    final reward = RewardItemsCompanion(
      id: Value(const Uuid().v4()),
      name: Value(name),
      description: Value(description),
      price: Value(price),
      isActive: const Value(true),
    );
    await _rewardDao.insertReward(reward);
  }

  Future<void> updateReward({
    required String id,
    required String name,
    required double price,
  }) async {
    final reward = RewardItemsCompanion(
      id: Value(id),
      name: Value(name),
      price: Value(price),
      isActive: const Value(true),
    );
    await _rewardDao.updateReward(reward);
  }

  Future<void> deleteReward(String id) =>
      _rewardDao.deleteReward(id);

  Future<void> purchaseReward({
    required RewardItem reward,
    required double currentBalance,
  }) async {
    // Business rule: you cannot spend what you don't have
    if (currentBalance < reward.price) {
      throw InsufficientFundsException(
        'Not enough coins. Need ${reward.price} but have $currentBalance',
      );
    }

    await _bankingRepository.spend(
      reward.price,
      relatedReward: reward.id,
      note: 'Purchased: ${reward.name}',
    );
  }
}