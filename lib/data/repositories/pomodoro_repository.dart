// lib/data/repositories/pomodoro_repository.dart

import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../database/daos/pomodoro_dao.dart';
import '../database/daos/task_dao.dart';
import 'package:drift/drift.dart';

class PomodoroRepository {
  final PomodoroDao _pomodoroDao;
  final TaskDao _taskDao;

  PomodoroRepository(this._pomodoroDao, this._taskDao);

  Stream<List<PomodoroSession>> watchSessionsForTask(String taskId) =>
      _pomodoroDao.watchPomodoroSessionsForTask(taskId);

  Future<int> getTotalStudyMinutes() => _pomodoroDao.getTotalStudyMinutes();

  Future<void> completeSession({
    String? taskId,
    required int duration,
    required String type,
  }) async {
    await _pomodoroDao.db.transaction(() async {
      // ── BUG 1 FIX ────────────────────────────────────────────────────────
      // completedAt was previously absent from this companion, causing Drift
      // to omit the column from the INSERT SQL. SQLite has no DEFAULT for this
      // NOT NULL column, so every real session either inserted NULL (violating
      // the constraint) or threw at runtime — swallowed by the catch(_){} in
      // _onSessionComplete, meaning no real sessions ever landed in the DB.
      // ─────────────────────────────────────────────────────────────────────
      final session = PomodoroSessionsCompanion(
        id          : Value(const Uuid().v4()),
        taskId      : taskId != null ? Value(taskId) : const Value.absent(),
        duration    : Value(duration),
        type        : Value(type),
        completedAt : Value(DateTime.now()), // ← was absent before
      );
      await _pomodoroDao.insertPomodoroSession(session);

      // Only work sessions count toward a task's completedPomodoro.
      // Breaks are not attributed to any task even if taskId was provided.
      if (taskId != null && type == 'work') {
        final task = await _taskDao.getTaskById(taskId);
        if (task == null) return;

        final updated = task.copyWith(
          completedPomodoro: task.completedPomodoro + 1,
        );
        await _taskDao.updateTask(updated.toCompanion(true));
      }
    });
  }
}