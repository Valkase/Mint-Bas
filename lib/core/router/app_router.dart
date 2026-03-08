// lib/core/router/app_router.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/tasks/screens/task_list_screen.dart';
import '../../features/tasks/screens/all_tasks_screen.dart';
import '../../features/tasks/screens/task_detail_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/rewards/screens/rewards_screen.dart';
import '../../features/banking/screens/banking_screen.dart';
import '../../features/pomodoro/screens/pomodoro_screen.dart';
import '../../features/projects/screens/projects_screen.dart';
import '../../features/projects/screens/project_detail_screen.dart';
import '../../features/debug/screens/debug_screen.dart';
import '../../shared/widgets/main_shell.dart';

// ── Startup flags — set by main() before runApp() ────────────────────────────
//
// Using simple top-level booleans (set once before the router is built)
// keeps the redirect logic synchronous and avoids async GoRouter complexity.

bool appOnboardingComplete = false;

// ─────────────────────────────────────────────────────────────────────────────

final appRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    // If the user hasn't seen onboarding yet, always redirect there first.
    // Once on /onboarding, don't redirect again (avoid loop).
    if (!appOnboardingComplete && state.matchedLocation != '/onboarding') {
      return '/onboarding';
    }
    return null;
  },
  routes: [

    // ── Onboarding (no shell) ──────────────────────────────────────────────
    GoRoute(
      path:    '/onboarding',
      builder: (_, __) => const OnboardingScreen(),
    ),

    // ── Shell (bottom nav) ─────────────────────────────────────────────────
    ShellRoute(
      builder: (context, state, child) {
        final location = state.matchedLocation;
        int index = 0;
        if (location.startsWith('/dashboard'))  index = 1;
        if (location.startsWith('/rewards'))    index = 2;
        if (location.startsWith('/banking'))    index = 3;
        return MainShell(child: child, currentIndex: index);
      },
      routes: [
        GoRoute(
          path:    '/',
          builder: (_, __) => const TaskListScreen(listId: '',),
        ),
        GoRoute(
          path:    '/all-tasks',
          builder: (_, __) => const AllTasksScreen(),
        ),
        GoRoute(
          path:    '/dashboard',
          builder: (_, __) => const DashboardScreen(),
        ),
        GoRoute(
          path:    '/rewards',
          builder: (_, __) => const RewardsScreen(),
        ),
        GoRoute(
          path:    '/banking',
          builder: (_, __) => const BankingScreen(),
        ),
      ],
    ),

    // ── Full-screen routes (no shell) ──────────────────────────────────────
    GoRoute(
      path:    '/pomodoro',
      builder: (_, state) => PomodoroScreen(
        initialTaskId: state.uri.queryParameters['taskId'],
      ),
    ),
    GoRoute(
      path:    '/tasks/:id',
      builder: (_, state) => TaskDetailScreen(
        taskId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path:    '/projects',
      builder: (_, __) => const ProjectsScreen(),
    ),
    GoRoute(
      path:    '/projects/:id',
      builder: (_, state) => ProjectDetailScreen(
        projectId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path:    '/debug',
      builder: (_, __) => const DebugScreen(),
    ),
  ],
);