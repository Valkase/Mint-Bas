// lib/core/router/app_router.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/app_config.dart';
import '../../core/flavor/app_flavor.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/unlock/screens/unlock_screen.dart';
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

bool appOnboardingComplete = false;
bool appUnlocked           = false; // set in main.dart before runApp

final appRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final loc = state.matchedLocation;

    // ── Unlock gate (Basboosa only) ────────────────────────────────────────
    // If the APK is the Basboosa flavor and the user hasn't entered the code
    // yet, force them to /unlock. No other route is reachable until unlocked.
    if (AppConfig.flavor == AppFlavor.basboosa && !appUnlocked) {
      if (loc != '/unlock') return '/unlock';
      return null;
    }

    // ── Onboarding gate ───────────────────────────────────────────────────
    if (!appOnboardingComplete && loc != '/onboarding') {
      return '/onboarding';
    }

    return null;
  },
  routes: [

    // ── Unlock (no shell, Basboosa only) ──────────────────────────────────
    GoRoute(
      path   : '/unlock',
      builder: (_, __) => const UnlockScreen(),
    ),

    // ── Onboarding (no shell) ─────────────────────────────────────────────
    GoRoute(
      path   : '/onboarding',
      builder: (_, __) => const OnboardingScreen(),
    ),

    // ── Shell (bottom nav) ────────────────────────────────────────────────
    ShellRoute(
      builder: (context, state, child) {
        final location = state.matchedLocation;
        int index = 0;
        if (location.startsWith('/dashboard')) index = 1;
        if (location.startsWith('/rewards'))   index = 2;
        if (location.startsWith('/banking'))   index = 3;
        return MainShell(child: child, currentIndex: index);
      },
      routes: [
        GoRoute(path: '/',          builder: (_, __) => const AllTasksScreen()),
        GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
        GoRoute(path: '/rewards',   builder: (_, __) => const RewardsScreen()),
        GoRoute(path: '/banking',   builder: (_, __) => const BankingScreen()),
      ],
    ),

    // ── Full-screen routes (no shell) ─────────────────────────────────────
    GoRoute(
      path   : '/list/:id',
      builder: (_, state) =>
          TaskListScreen(listId: state.pathParameters['id']!),
    ),
    GoRoute(
      path   : '/task/:id',
      builder: (_, state) =>
          TaskDetailScreen(taskId: state.pathParameters['id']!),
    ),
    GoRoute(
      path   : '/pomodoro',
      builder: (_, state) => PomodoroScreen(
        initialTaskId: state.uri.queryParameters['taskId'],
      ),
    ),
    GoRoute(path: '/projects', builder: (_, __) => const ProjectsScreen()),
    GoRoute(
      path   : '/project/:id',
      builder: (_, state) =>
          ProjectDetailScreen(projectId: state.pathParameters['id']!),
    ),
    GoRoute(path: '/debug', builder: (_, __) => const DebugScreen()),
  ],
);