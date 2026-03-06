import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/project_repository.dart';
import '../../data/repositories/tasks_repository.dart';
import '../../data/repositories/banking_repository.dart';
import '../../data/repositories/pomodoro_repository.dart';
import '../../data/repositories/reward_repository.dart';

// Single database instance for the entire app
final databaseProvider = Provider<AppDatabase>((ref) => AppDatabase());

// DAO providers — each one pulls from the single database instance
final projectDaoProvider = Provider((ref) =>
ref.watch(databaseProvider).projectDao);

final taskDaoProvider = Provider((ref) =>
ref.watch(databaseProvider).taskDao);

final transactionDaoProvider = Provider((ref) =>
ref.watch(databaseProvider).transactionDao);

final pomodoroDaoProvider = Provider((ref) =>
ref.watch(databaseProvider).pomodoroDao);

final rewardDaoProvider = Provider((ref) =>
ref.watch(databaseProvider).rewardDao);

final quoteDaoProvider = Provider((ref) =>
ref.watch(databaseProvider).quoteDao);

// Repository providers — injected with their required DAOs
final projectRepositoryProvider = Provider((ref) =>
    ProjectRepository(ref.watch(projectDaoProvider)));

final bankingRepositoryProvider = Provider((ref) =>
    BankingRepository(ref.watch(transactionDaoProvider)));

final taskRepositoryProvider = Provider((ref) =>
    TaskRepository(
      ref.watch(taskDaoProvider),
      ref.watch(bankingRepositoryProvider),
    ));

final pomodoroRepositoryProvider = Provider((ref) =>
    PomodoroRepository(
      ref.watch(pomodoroDaoProvider),
      ref.watch(taskDaoProvider),
    ));

final rewardRepositoryProvider = Provider((ref) =>
    RewardRepository(
      ref.watch(rewardDaoProvider),
      ref.watch(bankingRepositoryProvider),
    ));