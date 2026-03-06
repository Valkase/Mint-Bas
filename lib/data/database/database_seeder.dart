import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../../core/config/app_config.dart';

class DatabaseSeeder {
  final AppDatabase db;
  DatabaseSeeder(this.db);

  Future<void> seed() async {
    final prefs = await SharedPreferences.getInstance();
    final isSeeded = prefs.getBool('isSeeded') ?? false;
    if (isSeeded) return;

    await _seedQuotes();
    await _seedRewards();

    await prefs.setBool('isSeeded', true);
  }

  Future<void> _seedQuotes() async {
    await db.batch((batch) {
      batch.insertAll(db.quotes, [
        for (final q in AppConfig.quotes)
          QuotesCompanion(
            id: Value(const Uuid().v4()),
            quote: Value(q.quote),
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
            id: Value(const Uuid().v4()),
            name: Value(r.name),
            description: Value(r.description),
            price: Value(r.price),
            isActive: const Value(true),
          ),
      ]);
    });
  }
}