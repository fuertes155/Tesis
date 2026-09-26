import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

// ── Design Tokens (ver core/theme/app_theme.dart) ────────────────────────────
// Colores:          Azul cobalto #2563EB · Verde azulado #0D9488 · Violeta #7C3AED
// Tipografía:       Plus Jakarta Sans
// Border Radius:    10 / 12 / 16 / 20
// Botones:          Altura 44px, texto 14px Bold
import 'router.dart';
import 'core/theme/app_theme.dart';
import 'providers/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');

  final container = ProviderContainer();

  runApp(UncontrolledProviderScope(container: container, child: const MyApp()));

  // Keep the first paint lean. Services that touch IndexedDB/API are initialized
  // lazily when the user actually submits login or enters authenticated routes.
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
