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

// FIX: StreamProvider instead of FutureProvider.
// The old FutureProvider fetched once at app start and never updated.
// This stream reacts to every DB write — completing a task, finishing a
// pomodoro, or seeding data all instantly reflect on the dashboard.
final dashboardStatsProvider = StreamProvider<DashboardStats>((ref) {
  final pomodoroDao = ref.watch(pomodoroDaoProvider);

  return pomodoroDao.watchAllPomodoroSessions().map((allSessions) {
    final workSessions = allSessions.where((s) => s.type == 'work').toList();

    // FIX: duration is stored in minutes, not seconds.
    // The old code did `s.duration ~/ 60` which always returned 0
    // for any session shorter than 60 minutes (i.e. every session).
    final totalMinutes =
    workSessions.fold<int>(0, (sum, s) => sum + s.duration);

    // Sessions per day for the last 7 days
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

    return DashboardStats(
      totalTasksCompleted: 0,
      totalMinutesFocused: totalMinutes,
      allSessions:         allSessions,
      weeklyTaskCounts:    weeklyFocusCounts,
    );
  });
});