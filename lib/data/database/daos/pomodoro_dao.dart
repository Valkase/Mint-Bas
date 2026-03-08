// lib/data/database/daos/pomodoro_dao.dart
//
// Changes vs original:
//   N9 — getTotalStudyMinutes() summed ALL session rows regardless of type.
//        Since break sessions also store a non-zero duration, the total was
//        inflated. The method has no live callers (dead code), but fixing
//        it now prevents a wrong number being displayed if it is ever wired
//        to a stats widget.
//
//        Fix: add a WHERE type = 'work' filter before summing.

import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/pomodoro_sessions.dart';

part 'pomodoro_dao.g.dart';

@DriftAccessor(tables: [PomodoroSessions])
class PomodoroDao extends DatabaseAccessor<AppDatabase>
    with _$PomodoroDaoMixin {
  PomodoroDao(super.db);

  Future<List<PomodoroSession>> getAllPomodoroSessions() =>
      (select(pomodoroSessions)
        ..orderBy([(t) => OrderingTerm.desc(t.completedAt)]))
          .get();

  Stream<List<PomodoroSession>> watchAllPomodoroSessions() =>
      (select(pomodoroSessions)
        ..orderBy([(t) => OrderingTerm.desc(t.completedAt)]))
          .watch();

  Future<void> insertPomodoroSession(PomodoroSessionsCompanion session) =>
      into(pomodoroSessions).insert(session);

  Stream<List<PomodoroSession>> watchPomodoroSessionsForTask(String taskId) =>
      (select(pomodoroSessions)
        ..where((t) => t.taskId.equals(taskId))
        ..orderBy([(t) => OrderingTerm.desc(t.completedAt)]))
          .watch();

  Future<int> deleteAllSessions() => delete(pomodoroSessions).go();

  // ── BUG N9 FIX ─────────────────────────────────────────────────────────────
  // Previously summed duration for ALL session types, including shortBreak and
  // longBreak, inflating the "study" total by every break minute ever logged.
  //
  // Fix: filter to type = 'work' only before summing.
  // ─────────────────────────────────────────────────────────────────────────
  Future<int> getTotalStudyMinutes() async {
    final workSessions = await (select(pomodoroSessions)
      ..where((t) => t.type.equals('work')))
        .get();
    return workSessions.fold<int>(0, (sum, s) => sum + s.duration);
  }
}