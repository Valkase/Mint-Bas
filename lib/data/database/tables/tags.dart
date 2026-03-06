import 'package:drift/drift.dart';

class Tags extends Table{
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get color => text().withDefault(const Constant("#888888"))();

  @override
  Set<Column> get primaryKey => {id};
}