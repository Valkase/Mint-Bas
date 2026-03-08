// lib/core/flavor/app_flavor.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppFlavor { mint, basboosa }

/// Seeded before runApp() via ProviderScope override.
/// Read anywhere with ref.read(flavorProvider) — never changes at runtime.
final flavorProvider = Provider<AppFlavor>(
      (_) => AppFlavor.mint, // default; always overridden at startup
);