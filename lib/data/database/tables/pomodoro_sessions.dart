import 'package:drift/drift.dart';
import 'tasks.dart';
class PomodoroSessions extends Table{
  TextColumn get id => text()();
  TextColumn get taskId => text()
      .nullable()
      .references(Tasks, #id, onDelete: KeyAction.cascade)();
  IntColumn get duration => integer()();
  TextColumn get type => text()(); // 'work' or 'short-break' or 'long-break'
  DateTimeColumn get completedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

}