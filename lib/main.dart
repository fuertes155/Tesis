import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'router.dart';
import 'core/di/injection.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize dependency injection (GetIt)
  await setupInjection();

  // Use a ProviderContainer to bridge GetIt and Riverpod
  final container = ProviderContainer(
    overrides: [
      // We can override providers to use instances from GetIt if needed
      // or keep them separate. For now, we use the GetIt setup.
    ],
  );

  runApp(UncontrolledProviderScope(container: container, child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'NeuroApp | Hospital Central',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    final Color seed = const Color(0xFF0B6E99); // Azul clínico principal

    // Colores de superficie adaptativos
    final Color surface = isDark
        ? const Color(0xFF0F172A)
        : const Color(0xFFF8FAFC);
    final Color surfaceHigh = isDark
        ? const Color(0xFF1E293B)
        : const Color(0xFFF1F5F9);
    final Color cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final Color borderColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);

    // Colores de texto adaptativos
    final Color bodyColor = isDark
        ? const Color(0xFFE2E8F0)
        : const Color(0xFF1E293B);
    final Color displayColor = isDark ? Colors.white : const Color(0xFF0F172A);

    var baseTheme = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seed,
        brightness: brightness,
        surface: surface,
        surfaceContainerHighest: surfaceHigh,
        primary: seed,
        secondary: const Color(0xFF64748B),
        tertiary: const Color(0xFF0EA5E9),
        outlineVariant: borderColor,
      ),
    );

    final cs = baseTheme.colorScheme;

    final textTheme = GoogleFonts.plusJakartaSansTextTheme(
      baseTheme.textTheme,
    ).apply(bodyColor: bodyColor, displayColor: displayColor);

    return baseTheme.copyWith(
      scaffoldBackgroundColor: surface,
      textTheme: textTheme.copyWith(
        displayLarge: textTheme.displayLarge?.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: -1.2,
        ),
        displayMedium: textTheme.displayMedium?.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: -1.1,
        ),
        displaySmall: textTheme.displaySmall?.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: -1.0,
        ),
        headlineLarge: textTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.7,
        ),
        headlineMedium: textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.6,
        ),
        headlineSmall: textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
        ),
        titleLarge: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
        ),
        titleMedium: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        titleSmall: textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
        bodyMedium: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
        bodySmall: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
        labelLarge: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        labelMedium: textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
        labelSmall: textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: surface.withValues(alpha: 0.8),
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: bodyColor),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: displayColor,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: borderColor, width: 1),
        ),
        color: cardColor,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
        clipBehavior: Clip.antiAlias,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
          elevation: 0,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cardColor,
          foregroundColor: cs.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          elevation: 0,
          side: BorderSide(color: cs.primary.withValues(alpha: 0.2)),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.error, width: 1.5),
        ),
        labelStyle: GoogleFonts.plusJakartaSans(
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: GoogleFonts.plusJakartaSans(
          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          fontSize: 14,
        ),
        prefixIconColor: isDark
            ? const Color(0xFF94A3B8)
            : const Color(0xFF64748B),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dividerTheme: DividerThemeData(color: cs.outlineVariant),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: cs.inverseSurface,
        contentTextStyle: TextStyle(color: cs.onInverseSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      chipTheme: baseTheme.chipTheme.copyWith(
        labelStyle: textTheme.labelLarge,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: BorderSide(color: cs.outlineVariant),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      switchTheme: SwitchThemeData(
        trackOutlineColor: WidgetStatePropertyAll(cs.outlineVariant),
      ),
      extensions: <ThemeExtension<dynamic>>[
        const AppSpacing(),
        const AppRadii(),
        isDark ? AppSemanticColors.dark() : AppSemanticColors.light(),
      ],
    );
  }
}
