import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/app_config.dart';
import 'core/providers/theme_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/database/app_database.dart';
import 'data/database/database_seeder.dart';
import 'shared/providers/repository_providers.dart';
import 'features/pomodoro/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise the notification channel before the widget tree is built.
  await NotificationService.instance.init();

  final db = AppDatabase();
  await DatabaseSeeder(db).seed();

  runApp(
    ProviderScope(
      overrides: [
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
      title:                    AppConfig.appName,
      theme:                    AppTheme.light,
      darkTheme:                AppTheme.dark,
      themeMode:                themeState.mode,
      routerConfig:             appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}