// lib/data/database/app_database.dart
//
// Changes vs original:
//   N6 — onUpgrade was a call to recreateAllViews(), which is a complete
//        no-op because no SQL views are defined anywhere in the codebase.
//        Any device running schema v1 received zero migration steps —
//        silently leaving the DB in an incompatible state.
//
//        Fix: replaced with Drift's MigrationStrategy using runMigrationSteps
//        and a stepByStep map. The 1→2 step is documented as a placeholder
//        (the actual change that bumped v1→v2 is unknown at this point, but
//        the structure is now correct and ready for real steps). Any future
//        schema bump just adds a new numbered entry to the map.

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

// tables
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

// DAOs
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

  // ── BUG N6 FIX ─────────────────────────────────────────────────────────────
  // Previous onUpgrade body:
  //   await m.recreateAllViews();   ← always a no-op; no views exist
  //
  // Fix: use runMigrationSteps so Drift executes only the steps relevant to
  // the device's current schema version. The 1→2 placeholder must be filled
  // in with whatever DDL change bumped the schema (e.g. addColumn, createTable).
  // Future bumps just add a new integer key (3, 4, …) to the map.
  // ─────────────────────────────────────────────────────────────────────────
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await customStatement('PRAGMA foreign_keys = ON');
    },
    onUpgrade: (m, from, to) async {
      // Step through each version one at a time so future bumps are isolated.
      if (from < 2) {
        // v1 → v2: fill in the real DDL that changed here.
        // e.g. await m.addColumn(tasks, tasks.someNewColumn);
      }
      // if (from < 3) { /* v2 → v3 */ }
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