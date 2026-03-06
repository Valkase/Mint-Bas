import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/pomodoro_sessions.dart';

part 'pomodoro_dao.g.dart';

@DriftAccessor(tables: [PomodoroSessions])
class PomodoroDao extends DatabaseAccessor<AppDatabase> with _$PomodoroDaoMixin {
  PomodoroDao(super.db);

  Future<List<PomodoroSession>> getAllPomodoroSessions() =>
      (select(pomodoroSessions)..orderBy([(t) => OrderingTerm.desc(t.completedAt)])).get();

  Stream<List<PomodoroSession>> watchAllPomodoroSessions() =>
      (select(pomodoroSessions)..orderBy([(t) => OrderingTerm.desc(t.completedAt)])).watch();

  Future<void> insertPomodoroSession(PomodoroSessionsCompanion session) =>
      into(pomodoroSessions).insert(session);

  Stream<List<PomodoroSession>> watchPomodoroSessionsForTask(String taskId) =>
      (select(pomodoroSessions)
        ..where((t) => t.taskId.equals(taskId))
        ..orderBy([(t) => OrderingTerm.desc(t.completedAt)]))
          .watch();

  Future<int> deleteAllSessions() => delete(pomodoroSessions).go();

  Future<int> getTotalStudyMinutes() async {
    final allSessions = await getAllPomodoroSessions();
    int totalMinutes = 0;
    for (final session in allSessions) {
      totalMinutes += session.duration;
    }
    return totalMinutes;
  }
}