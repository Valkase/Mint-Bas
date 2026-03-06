import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/quotes.dart';
import 'dart:math';

part 'quote_dao.g.dart';

@DriftAccessor(tables: [Quotes])
class QuoteDao extends DatabaseAccessor<AppDatabase> with _$QuoteDaoMixin {
  QuoteDao(super.db);

  Future<List<Quote>> getAllQuotes() =>
      select(quotes).get();

  Stream<List<Quote>> watchAllQuotes() =>
      select(quotes).watch();

  Future<void> insertQuote(QuotesCompanion quote) =>
      into(quotes).insert(quote);

  Future<Quote?> getRandomQuote() async {
    final allQuotes = await getAllQuotes();
    if (allQuotes.isEmpty) return null;
    return allQuotes[Random().nextInt(allQuotes.length)];
  }
}