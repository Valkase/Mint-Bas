// lib/data/database/database_seeder.dart
//
// Changes vs original:
//   N8 — The seeder previously ran _seedQuotes(), then _seedRewards(), then
//        marked isSeeded=true. If _seedRewards() threw (e.g. a DB constraint
//        violation), isSeeded was never written. On the next launch both seed
//        methods ran again — re-inserting all quotes with fresh UUIDs (no
//        UNIQUE constraint on content), producing duplicate entries in the
//        quote footer.
//
//        Fix: both inserts are now wrapped in a single DB transaction.
//        Either both succeed and isSeeded is set, or both are rolled back
//        and the next launch retries from a clean state. No duplicates.

import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../../core/config/app_config.dart';

class DatabaseSeeder {
  final AppDatabase db;
  DatabaseSeeder(this.db);

  Future<void> seed() async {
    final prefs    = await SharedPreferences.getInstance();
    final isSeeded = prefs.getBool('isSeeded') ?? false;
    if (isSeeded) return;

    // ── BUG N8 FIX ─────────────────────────────────────────────────────────
    // Both seed operations now run inside a single transaction.  If either
    // batch throws, the transaction is rolled back and isSeeded is NOT written.
    // The next launch will retry from a clean slate — no duplicate rows.
    // ─────────────────────────────────────────────────────────────────────
    await db.transaction(() async {
      await _seedQuotes();
      await _seedRewards();
    });

    await prefs.setBool('isSeeded', true);
  }

  Future<void> _seedQuotes() async {
    await db.batch((batch) {
      batch.insertAll(db.quotes, [
        for (final q in AppConfig.quotes)
          QuotesCompanion(
            id    : Value(const Uuid().v4()),
            quote : Value(q.quote),
            author: Value(q.author),
          ),
      ]);
    });
  }

  Future<void> _seedRewards() async {
    await db.batch((batch) {
      batch.insertAll(db.rewardItems, [
        for (final r in AppConfig.rewards)
          RewardItemsCompanion(
            id         : Value(const Uuid().v4()),
            name       : Value(r.name),
            description: Value(r.description),
            price      : Value(r.price),
            isActive   : const Value(true),
          ),
      ]);
    });
  }
}