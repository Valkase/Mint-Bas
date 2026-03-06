import 'package:drift/drift.dart';
import 'tasks.dart';

class TaskSteps extends Table {
  TextColumn get id => text()();
  TextColumn get taskId => text()
      .references(Tasks, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  IntColumn get order => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}