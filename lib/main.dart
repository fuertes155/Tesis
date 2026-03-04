import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'router.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'NeuroApp | Hospital Central',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(Brightness.light),
      routerConfig: router,
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final Color seed = const Color(0xFF0B6E99); // Azul clínico
    final Color surface = const Color(0xFFF7F9FB); // Fondo hospitalario claro
    final Color surfaceHigh = const Color(0xFFE9EEF3);

    var baseTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seed,
        brightness: brightness,
        surface: surface,
        surfaceContainerHighest: surfaceHigh,
      ),
    );

    final cs = baseTheme.colorScheme;

    return baseTheme.copyWith(
      scaffoldBackgroundColor: surface,
      textTheme: GoogleFonts.sourceSans3TextTheme(
        baseTheme.textTheme,
      ).apply(bodyColor: cs.onSurface, displayColor: cs.onSurface),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: cs.onSurface),
        titleTextStyle:
            GoogleFonts.sourceSans3(
              textStyle: baseTheme.textTheme.titleLarge,
            ).copyWith(
              color: cs.onSurface,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        color: Colors.white,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
        clipBehavior: Clip.antiAlias,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          elevation: 1,
          shadowColor: cs.primary.withValues(alpha: 0.2),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.error, width: 1),
        ),
        labelStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
        hintStyle: TextStyle(
          color: cs.onSurfaceVariant.withValues(alpha: 0.8),
          fontSize: 14,
        ),
        prefixIconColor: cs.onSurfaceVariant,
      ),
    );
  }
}
