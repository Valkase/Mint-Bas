import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/transactions.dart';

part 'transaction_dao.g.dart';

@DriftAccessor(tables: [Transactions])
class TransactionDao extends DatabaseAccessor<AppDatabase> with _$TransactionDaoMixin {
  TransactionDao(super.db);

  Future<Transaction?> getTransactionById(String id) =>
      (select(transactions)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<Transaction>> getAllTransactions() =>
      (select(transactions)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();

  Stream<List<Transaction>> watchAllTransactions() =>
      (select(transactions)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();

  Future<void> insertTransaction(TransactionsCompanion transaction) =>
      into(transactions).insert(transaction);

  Future<double> getBalance() async {
    final allTransactions = await getAllTransactions();

    double earned = 0;
    double spent = 0;

    for (final t in allTransactions) {
      if (t.type == 'earn') earned += t.amount;
      if (t.type == 'spend') spent += t.amount;
    }

    return earned - spent;
  }

  Future<int> deleteAllTransactions() => delete(transactions).go();

  Stream<double> watchBalance() {
    return watchAllTransactions().map((allTransactions) {
      double earned = 0;
      double spent = 0;

      for (final t in allTransactions) {
        if (t.type == 'earn') earned += t.amount;
        if (t.type == 'spend') spent += t.amount;
      }

      return earned - spent;
    });
  }
}