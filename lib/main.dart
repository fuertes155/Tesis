import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Design Tokens ────────────────────────────────────────────────────────────
// Color primario:   Azul Cobalto  #2563EB
// Tipografía:       Inter (Sans Serif)
// Border Radius:    8px (uniforme)
// Botones:          Altura 48px, texto 14px SemiBold
// Grid:             12 columnas
import 'router.dart';
import 'core/theme/app_theme.dart';
import 'providers/api_providers.dart';
import 'core/database/local_database_service.dart';
import 'providers/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // We use a ProviderContainer to initialize async providers before starting the app
  final container = ProviderContainer();
  
  // Pre-initialize critical services
  await container.read(sharedPrefsProvider.future);
  await container.read(localDatabaseProvider.future);
  await container.read(apiServiceProvider.future);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'NeuroApp | Hospital Central',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.buildTheme(context, Brightness.light),
      darkTheme: AppTheme.buildTheme(context, Brightness.dark),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
