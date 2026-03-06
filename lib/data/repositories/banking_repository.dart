import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../database/daos/transaction_dao.dart';
import 'package:drift/drift.dart';

class BankingRepository {
  final TransactionDao _transactionDao;
  BankingRepository(this._transactionDao);

  Stream<List<Transaction>> watchAllTransactions() =>
      _transactionDao.watchAllTransactions();

  Stream<double> watchBalance() {
    return _transactionDao.watchBalance();
  }

  Future<double> getBalance(){
    return _transactionDao.getBalance();
  }

  Future<void> earn(double amount, {String? relatedTask, required String note}) async{
    final earn = TransactionsCompanion(
      id: Value(const Uuid().v4()),
      type: Value('earn'),
      amount: Value(amount),
      relatedTaskId: Value(relatedTask),
      note: Value(note),
    );
    await _transactionDao.insertTransaction(earn);
  }

  Future<void> spend(double amount, {String? relatedReward, required String note}) async{
    final spend = TransactionsCompanion(
      id: Value(const Uuid().v4()),
      type: Value('spend'),
      amount: Value(amount),
      relatedRewardId: Value(relatedReward),
      note: Value(note),
    );
    await _transactionDao.insertTransaction(spend);
  }
}

