import 'package:go_router/go_router.dart';
import '../../features/tasks/screens/all_tasks_screen.dart';
import '../../features/projects/screens/projects_screen.dart';
import '../../features/projects/screens/project_detail_screen.dart';
import '../../features/tasks/screens/task_list_screen.dart';
import '../../features/tasks/screens/task_detail_screen.dart';
import '../../features/pomodoro/screens/pomodoro_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/rewards/screens/rewards_screen.dart';
import '../../features/banking/screens/banking_screen.dart';
import '../../shared/widgets/main_shell.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    // ── Shell: 4 persistent tabs ──────────────────────────────────
    ShellRoute(
      builder: (context, state, child) {
        final path = state.uri.path;
        int index = 0;
        if (path.startsWith('/dashboard')) index = 1;
        else if (path.startsWith('/rewards'))   index = 2;
        else if (path.startsWith('/banking'))   index = 3;
        return MainShell(currentIndex: index, child: child);
      },
      routes: [
        GoRoute(path: '/',          builder: (c, s) => const AllTasksScreen()),
        GoRoute(path: '/dashboard', builder: (c, s) => const DashboardScreen()),
        GoRoute(path: '/rewards',   builder: (c, s) => const RewardsScreen()),
        GoRoute(path: '/banking',   builder: (c, s) => const BankingScreen()),
      ],
    ),

    // ── Sub-pages: no bottom nav ──────────────────────────────────
    GoRoute(
      path: '/projects',
      builder: (c, s) => const ProjectsScreen(),
    ),
    GoRoute(
      path: '/project/:id',
      builder: (c, s) =>
          ProjectDetailScreen(projectId: s.pathParameters['id']!),
    ),
    GoRoute(
      path: '/list/:id',
      builder: (c, s) => TaskListScreen(listId: s.pathParameters['id']!),
    ),
    GoRoute(
      path: '/task/:id',
      builder: (c, s) => TaskDetailScreen(taskId: s.pathParameters['id']!),
    ),

    // ── Pomodoro ──────────────────────────────────────────────────
    GoRoute(
      path: '/pomodoro',
      builder: (c, s) {
        final taskId = s.uri.queryParameters['taskId'];
        return PomodoroScreen(initialTaskId: taskId);
      },
    ),
  ],
);