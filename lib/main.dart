// lib/main.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/app_config.dart';
import 'core/flavor/app_flavor.dart';
import 'core/providers/theme_provider.dart';
import 'core/router/app_router.dart';
import 'core/services/device_flavor_service.dart';
import 'core/theme/app_theme.dart';
import 'data/database/app_database.dart';
import 'data/database/database_seeder.dart';
import 'features/pomodoro/services/notification_service.dart';
import 'firebase_options.dart';
import 'shared/providers/repository_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Firebase ───────────────────────────────────────────────────────────────
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ── Flavor detection ───────────────────────────────────────────────────────
  final flavor         = await DeviceFlavorService.instance.detectFlavor();
  final onboardingDone = await DeviceFlavorService.instance.isOnboardingComplete();

  appOnboardingComplete = onboardingDone;

  // ── Theme configuration ────────────────────────────────────────────────────
  AppTheme.configure(flavor);

  // ── Notifications ──────────────────────────────────────────────────────────
  await NotificationService.instance.init();

  // ── Database ───────────────────────────────────────────────────────────────
  final db = AppDatabase();
  await DatabaseSeeder(db).seed();

  runApp(
    ProviderScope(
      overrides: [
        flavorProvider.overrideWithValue(flavor),
        databaseProvider.overrideWithValue(db),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);

    return MaterialApp.router(
      title:                      AppConfig.appName,
      theme:                      AppTheme.light,
      darkTheme:                  AppTheme.dark,
      themeMode:                  themeState.mode,
      routerConfig:               appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}