import 'package:drift/drift.dart';
import 'tasks.dart';

class Transactions extends Table{
  TextColumn get id => text()();
  RealColumn get amount => real()();
  TextColumn get type => text()(); // 'earn' or 'spend'
  TextColumn get relatedTaskId => text()
      .nullable()
      .references(Tasks, #id, onDelete: KeyAction.setNull)();
  TextColumn get relatedRewardId => text().nullable()(); // we'll add the reference after RewardItems
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}