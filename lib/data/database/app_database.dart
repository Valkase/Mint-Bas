import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

//tables
import 'tables/projects.dart';
import 'tables/task_lists.dart';
import 'tables/tasks.dart';
import 'tables/task_steps.dart';
import 'tables/tags.dart';
import 'tables/task_tags.dart';
import 'tables/transactions.dart';
import 'tables/reward_items.dart';
import 'tables/pomodoro_sessions.dart';
import 'tables/quotes.dart';

//DAOs
import 'daos/project_dao.dart';
import 'daos/task_dao.dart';
import 'daos/transaction_dao.dart';
import 'daos/pomodoro_dao.dart';
import 'daos/reward_dao.dart';
import 'daos/quote_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Projects,
    TaskLists,
    Tasks,
    TaskSteps,
    Tags,
    TaskTags,
    Transactions,
    RewardItems,
    PomodoroSessions,
    Quotes,
  ],
  daos: [
    ProjectDao,
    TaskDao,
    TransactionDao,
    PomodoroDao,
    RewardDao,
    QuoteDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await customStatement('PRAGMA foreign_keys = ON');
    },
    onUpgrade: (m, from, to) async {
      await m.recreateAllViews();
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  @override
  ProjectDao get projectDao => ProjectDao(this);
  @override
  TaskDao get taskDao => TaskDao(this);
  @override
  TransactionDao get transactionDao => TransactionDao(this);
  @override
  PomodoroDao get pomodoroDao => PomodoroDao(this);
  @override
  RewardDao get rewardDao => RewardDao(this);
  @override
  QuoteDao get quoteDao => QuoteDao(this);

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'app_database');
  }
}
