import 'package:drift/drift.dart';

class Quotes extends Table{
  TextColumn get id => text()();
  TextColumn get quote => text()();
  TextColumn get author => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
