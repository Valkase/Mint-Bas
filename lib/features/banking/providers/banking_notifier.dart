import 'package:bd_project/data/database/app_database.dart';
import 'package:bd_project/shared/providers/repository_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

final balanceStreamProvider = StreamProvider<double>((ref) {
  return ref.watch(bankingRepositoryProvider).watchBalance();
});

final transactionsStreamProvider = StreamProvider<List<Transaction>>((ref) {
  return ref.watch(bankingRepositoryProvider).watchAllTransactions();
});

