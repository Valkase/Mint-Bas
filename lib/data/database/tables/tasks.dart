import 'package:bd_project/data/database/tables/task_lists.dart';
import 'package:drift/drift.dart';

class Tasks extends Table{
  TextColumn get id => text()();
  TextColumn get listId => text()
      .references(TaskLists, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  IntColumn get priority => integer().nullable()();
  DateTimeColumn get deadline => dateTime().nullable()();
  RealColumn get price => real().withDefault(const Constant(10.0))();
  IntColumn get estimatedPomodoro => integer().withDefault(const Constant(1))();
  IntColumn get completedPomodoro => integer().withDefault(const Constant(0))();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}