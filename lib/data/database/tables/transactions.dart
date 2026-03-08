// lib/data/database/tables/transactions.dart
//
// Changes vs original:
//   N10 — relatedRewardId had no FK constraint (only a TODO comment saying
//         "we'll add the reference after RewardItems"). Deleting a reward
//         left every spend transaction that referenced it with a dangling ID
//         — no integrity enforcement, no cascade, no null-out.
//
//         Fix: added .references(RewardItems, #id, onDelete: KeyAction.setNull)
//         so SQLite automatically nulls out relatedRewardId when the referenced
//         reward row is deleted.
//
//         NOTE: This is a schema change. Drift will detect a column constraint
//         change and the schema version in app_database.dart must be bumped to
//         3. Add the migration step (recreating the transactions table or using
//         a Drift migration helper) to the stepByStep map in app_database.dart.

import 'package:drift/drift.dart';
import 'tasks.dart';
import 'reward_items.dart';

class Transactions extends Table {
  TextColumn get id            => text()();
  RealColumn get amount        => real()();
  TextColumn get type          => text()();  // 'earn' or 'spend'

  TextColumn get relatedTaskId =>
      text().nullable().references(Tasks, #id, onDelete: KeyAction.setNull)();

  // ── BUG N10 FIX ──────────────────────────────────────────────────────────
  // Was: text().nullable()()   ← no FK; comment said "add later"
  // Fix: added FK reference so deleting a reward nulls out this column instead
  //      of leaving a dangling ID with no integrity check.
  // ─────────────────────────────────────────────────────────────────────────
  TextColumn get relatedRewardId =>
      text().nullable().references(RewardItems, #id, onDelete: KeyAction.setNull)();

  TextColumn   get note      => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}