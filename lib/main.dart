import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/app_config.dart';
import 'core/providers/theme_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/database/app_database.dart';
import 'data/database/database_seeder.dart';
import 'shared/providers/repository_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
    // Watching themeProvider causes the entire app to rebuild whenever
    // the mode or accent changes — all AppTheme static fields are already
    // updated by the time this build runs, so every screen gets new colors.
    final themeState = ref.watch(themeProvider);

    return MaterialApp.router(
      title: AppConfig.appName,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeState.mode,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}