import 'package:drift/drift.dart';
import 'projects.dart';

class TaskLists extends Table{
  TextColumn get id => text()();
  TextColumn get projectId => text()
      .nullable()
      .references(Projects, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}