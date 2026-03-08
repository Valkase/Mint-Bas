// lib/features/dashboard/providers/dashboard_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../data/database/app_database.dart';

class DashboardStats {
  final int totalTasksCompleted;
  final int totalMinutesFocused;
  final List<PomodoroSession> allSessions;
  final List<int> weeklyTaskCounts;

  const DashboardStats({
    required this.totalTasksCompleted,
    required this.totalMinutesFocused,
    required this.allSessions,
    required this.weeklyTaskCounts,
  });
}

// StreamProvider so the dashboard reacts to every DB write — completing a task,
// finishing a pomodoro, or seeding data all instantly reflect on screen.
final dashboardStatsProvider = StreamProvider<DashboardStats>((ref) {
  final pomodoroDao = ref.watch(pomodoroDaoProvider);
  final taskDao     = ref.watch(taskDaoProvider);

  return pomodoroDao.watchAllPomodoroSessions().asyncMap((allSessions) async {
    final workSessions = allSessions.where((s) => s.type == 'work').toList();

    // duration is stored in minutes — do NOT divide by 60 here.
    final totalMinutes =
    workSessions.fold<int>(0, (sum, s) => sum + s.duration);

    // Sessions per day for the last 7 days (used by the bar chart).
    final now = DateTime.now();
    final weeklyFocusCounts = List.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      return workSessions
          .where((s) =>
      s.completedAt.year  == day.year  &&
          s.completedAt.month == day.month &&
          s.completedAt.day   == day.day)
          .length;
    });

    // ── BUG 4 FIX ──────────────────────────────────────────────────────────
    // totalTasksCompleted was hardwired to 0. Any future widget reading this
    // field (e.g. a "tasks completed" stat chip) would silently show 0 forever.
    //
    // Fix: take a one-shot snapshot of all tasks and count completed ones.
    // We use watchAllTasks().first here because TaskDao has no getAllTasks()
    // Future. This is safe — it subscribes, takes the first emission, and
    // cancels immediately. The value stays fresh because the outer
    // watchAllPomodoroSessions() stream re-fires whenever a session is saved,
    // which is exactly when task completion state may have changed.
    // ─────────────────────────────────────────────────────────────────────
    final allTasks          = await taskDao.watchAllTasks().first;
    final completedTaskCount = allTasks.where((t) => t.isCompleted).length;

    return DashboardStats(
      totalTasksCompleted: completedTaskCount, // ← was always 0
      totalMinutesFocused: totalMinutes,
      allSessions        : allSessions,
      weeklyTaskCounts   : weeklyFocusCounts,
    );
  });
});