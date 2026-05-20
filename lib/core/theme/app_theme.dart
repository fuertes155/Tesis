import 'package:flutter/material.dart';

// ... (skipping to before Helpers section)
class AppTheme {
  static ThemeData buildTheme(BuildContext context, Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;

    // ── Paleta Hospital – Azul Cobalto ────────────────────────────────────────
    const Color primaryBase = Color(0xFF2563EB); // Azul Cobalto
    const Color primaryDeep = Color(
      0xFF1D4ED8,
    ); // Azul profundo para gradientes
    const Color accentCyan = Color(0xFF3B82F6); // Azul medio vibrante

    // Superficies Dark (respaldo)
    const Color darkBg = Color(0xFF0F172A);
    const Color darkSurface = Color(0xFF1E293B);
    const Color darkSurfaceHigh = Color(0xFF334155);
    const Color darkBorder = Color(0xFF475569);

    // Superficies Light — limpio y hospitalario
    const Color lightBg = Color(0xFFF8FAFC);
    const Color lightSurface = Color(0xFFFFFFFF);
    const Color lightSurfaceHigh = Color(0xFFF1F5F9);
    const Color lightBorder = Color(0xFFE2E8F0);

    final Color surface = isDark ? darkBg : lightBg;
    final Color surfaceHigh = isDark ? darkSurfaceHigh : lightSurfaceHigh;
    final Color cardColor = isDark ? darkSurface : lightSurface;
    final Color borderColor = isDark ? darkBorder : lightBorder;
    final Color bodyColor = isDark
        ? const Color(0xFFCBD5E1)
        : const Color(0xFF334155);
    final Color displayColor = isDark
        ? const Color(0xFFF1F5F9)
        : const Color(0xFF0F172A);

    var baseTheme = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: primaryBase,
            brightness: brightness,
            surface: surface,
            surfaceContainerHighest: surfaceHigh,
            primary: primaryBase,
            secondary: const Color(0xFF64748B),
            tertiary: accentCyan,
            outlineVariant: borderColor,
          ).copyWith(
            primary: primaryBase,
            tertiary: accentCyan,
            surface: surface,
            surfaceContainerLowest: cardColor,
            outlineVariant: borderColor,
            onSurface: displayColor,
            onSurfaceVariant: isDark
                ? const Color(0xFF94A3B8)
                : const Color(0xFF64748B),
          ),
    );

    final cs = baseTheme.colorScheme;

    final textTheme = baseTheme.textTheme.apply(
      bodyColor: bodyColor,
      displayColor: displayColor,
      fontFamily: 'Arial',
    );

    // Sombras premium multicapa
    final List<BoxShadow> premiumShadow = isDark
        ? [
            BoxShadow(
              color: primaryBase.withValues(alpha: 0.12),
              blurRadius: 32,
              spreadRadius: -4,
              offset: const Offset(0, 16),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 16,
              spreadRadius: -2,
              offset: const Offset(0, 8),
            ),
          ]
        : [
            BoxShadow(
              color: primaryBase.withValues(alpha: 0.08),
              blurRadius: 24,
              spreadRadius: -4,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ];

    return baseTheme.copyWith(
      scaffoldBackgroundColor: surface,
      textTheme: textTheme.copyWith(
        displayLarge: textTheme.displayLarge?.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: -1.5,
        ),
        displayMedium: textTheme.displayMedium?.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: -1.2,
        ),
        displaySmall: textTheme.displaySmall?.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: -1.0,
        ),
        headlineLarge: textTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
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
          letterSpacing: -0.3,
        ),
        titleMedium: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.1,
        ),
        titleSmall: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        bodyLarge: textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
          height: 1.6,
        ),
        bodyMedium: textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
          height: 1.5,
        ),
        bodySmall: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
        labelLarge: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
        ),
        labelMedium: textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
        labelSmall: textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: cardColor.withValues(alpha: isDark ? 0.85 : 1.0),
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: bodyColor),
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: displayColor,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: borderColor, width: 1),
        ),
        color: cardColor,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
        clipBehavior: Clip.antiAlias,
        shadowColor: primaryBase.withValues(alpha: 0.10),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1);
            }
            return primaryBase;
          }),
          foregroundColor: const WidgetStatePropertyAll(Colors.white),
          overlayColor: WidgetStateProperty.all(
            Colors.white.withValues(alpha: 0.12),
          ),
          minimumSize: const WidgetStatePropertyAll(Size(0, 40)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          ),
          textStyle: WidgetStatePropertyAll(
            const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          elevation: const WidgetStatePropertyAll(0),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cardColor,
          foregroundColor: cs.primary,
          minimumSize: const Size(0, 40),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          elevation: 0,
          side: BorderSide(
            color: cs.primary.withValues(alpha: 0.25),
            width: 1.5,
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: cs.primary,
          side: BorderSide(
            color: cs.primary.withValues(alpha: 0.4),
            width: 1.5,
          ),
          minimumSize: const Size(0, 40),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? const Color(0xFF0A1628).withValues(alpha: 0.9)
            : Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryBase, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
        ),
        labelStyle: TextStyle(
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: TextStyle(
          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          fontSize: 14,
        ),
        prefixIconColor: isDark
            ? const Color(0xFF94A3B8)
            : const Color(0xFF64748B),
        suffixIconColor: isDark
            ? const Color(0xFF94A3B8)
            : const Color(0xFF64748B),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: cs.primary,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      dividerTheme: DividerThemeData(
        color: borderColor,
        space: 1,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark
            ? const Color(0xFF1E293B)
            : const Color(0xFF0F172A),
        contentTextStyle: TextStyle(
          color: isDark ? const Color(0xFFCCE5F5) : Colors.white,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: borderColor),
        ),
        elevation: 8,
      ),
      chipTheme: baseTheme.chipTheme.copyWith(
        labelStyle: textTheme.labelMedium,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide(color: borderColor),
        backgroundColor: cardColor,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: borderColor),
        ),
        elevation: 24,
        shadowColor: primaryDeep.withValues(alpha: 0.2),
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: displayColor,
          letterSpacing: -0.3,
        ),
        contentTextStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: bodyColor,
          height: 1.6,
        ),
      ),
      switchTheme: SwitchThemeData(
        trackOutlineColor: WidgetStatePropertyAll(borderColor),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primaryBase,
        linearTrackColor: primaryBase.withValues(alpha: 0.1),
        circularTrackColor: primaryBase.withValues(alpha: 0.1),
      ),
      extensions: <ThemeExtension<dynamic>>[
        const AppSpacing(),
        const AppRadii(),
        isDark ? AppSemanticColors.dark() : AppSemanticColors.light(),
        AppGlass.forBrightness(isDark, primaryBase, borderColor),
        AppPremiumShadows(premiumShadow: premiumShadow),
      ],
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

@immutable
class AppSpacing extends ThemeExtension<AppSpacing> {
  const AppSpacing({
    this.xs = 8,
    this.sm = 12,
    this.md = 16,
    this.lg = 24,
    this.xl = 32,
    this.x2l = 48,
  });

  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double x2l;

  @override
  AppSpacing copyWith({
    double? xs,
    double? sm,
    double? md,
    double? lg,
    double? xl,
    double? x2l,
  }) {
    return AppSpacing(
      xs: xs ?? this.xs,
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      xl: xl ?? this.xl,
      x2l: x2l ?? this.x2l,
    );
  }

  @override
  AppSpacing lerp(ThemeExtension<AppSpacing>? other, double t) {
    if (other is! AppSpacing) return this;
    return AppSpacing(
      xs: lerpDouble(xs, other.xs, t),
      sm: lerpDouble(sm, other.sm, t),
      md: lerpDouble(md, other.md, t),
      lg: lerpDouble(lg, other.lg, t),
      xl: lerpDouble(xl, other.xl, t),
      x2l: lerpDouble(x2l, other.x2l, t),
    );
  }
}

// ── AppRadii ──────────────────────────────────────────────────────────────────

@immutable
class AppRadii extends ThemeExtension<AppRadii> {
  const AppRadii({this.sm = 8, this.md = 8, this.lg = 10, this.xl = 12});

  final double sm;
  final double md;
  final double lg;
  final double xl;

  BorderRadius get radiusSm => BorderRadius.circular(sm);
  BorderRadius get radiusMd => BorderRadius.circular(md);
  BorderRadius get radiusLg => BorderRadius.circular(lg);
  BorderRadius get radiusXl => BorderRadius.circular(xl);

  @override
  AppRadii copyWith({double? sm, double? md, double? lg, double? xl}) {
    return AppRadii(
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      xl: xl ?? this.xl,
    );
  }

  @override
  AppRadii lerp(ThemeExtension<AppRadii>? other, double t) {
    if (other is! AppRadii) return this;
    return AppRadii(
      sm: lerpDouble(sm, other.sm, t),
      md: lerpDouble(md, other.md, t),
      lg: lerpDouble(lg, other.lg, t),
      xl: lerpDouble(xl, other.xl, t),
    );
  }
}

// ── AppSemanticColors ─────────────────────────────────────────────────────────

@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.success,
    required this.warning,
    required this.info,
    required this.danger,
  });

  factory AppSemanticColors.light() {
    return const AppSemanticColors(
      success: Color(0xFF10B981),
      warning: Color(0xFFF59E0B),
      info: Color(0xFF3B82F6),
      danger: Color(0xFFEF4444),
    );
  }

  factory AppSemanticColors.dark() {
    return const AppSemanticColors(
      success: Color(0xFF34D399),
      warning: Color(0xFFFBBF24),
      info: Color(0xFF60A5FA),
      danger: Color(0xFFF87171),
    );
  }

  final Color success;
  final Color warning;
  final Color info;
  final Color danger;

  @override
  AppSemanticColors copyWith({
    Color? success,
    Color? warning,
    Color? info,
    Color? danger,
  }) {
    return AppSemanticColors(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      danger: danger ?? this.danger,
    );
  }

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      success: Color.lerp(success, other.success, t) ?? success,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      info: Color.lerp(info, other.info, t) ?? info,
      danger: Color.lerp(danger, other.danger, t) ?? danger,
    );
  }
}

// ── AppGlass — Sistema Glassmorphism ──────────────────────────────────────────

@immutable
class AppGlass extends ThemeExtension<AppGlass> {
  const AppGlass({
    required this.cardGradient,
    required this.overlayColor,
    required this.borderColor,
    required this.blurSigma,
    required this.headerGradient,
    required this.accentGradient,
  });

  factory AppGlass.forBrightness(bool isDark, Color primary, Color border) {
    return AppGlass(
      cardGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [
                const Color(0xFF1E293B).withValues(alpha: 0.9),
                const Color(0xFF0F172A).withValues(alpha: 0.8),
              ]
            : [Colors.white, const Color(0xFFF8FAFC)],
      ),
      overlayColor: isDark
          ? Colors.white.withValues(alpha: 0.04)
          : Colors.white.withValues(alpha: 0.7),
      borderColor: isDark
          ? Colors.white.withValues(alpha: 0.08)
          : const Color(0xFFE2E8F0),
      blurSigma: 16.0,
      headerGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [
                const Color(0xFF2563EB),
                const Color(0xFF1D4ED8),
                const Color(0xFF1E40AF),
              ]
            : [const Color(0xFF2563EB), const Color(0xFF3B82F6)],
        stops: isDark ? const [0.0, 0.55, 1.0] : null,
      ),
      accentGradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
      ),
    );
  }

  /// Gradiente de la superficie glass de cards
  final LinearGradient cardGradient;

  /// Color de superposición semitransparente
  final Color overlayColor;

  /// Borde del efecto glass
  final Color borderColor;

  /// Sigma del blur backdrop
  final double blurSigma;

  /// Gradiente de headers/hero sections
  final LinearGradient headerGradient;

  /// Gradiente de acento (íconos, badges)
  final LinearGradient accentGradient;

  @override
  AppGlass copyWith({
    LinearGradient? cardGradient,
    Color? overlayColor,
    Color? borderColor,
    double? blurSigma,
    LinearGradient? headerGradient,
    LinearGradient? accentGradient,
  }) {
    return AppGlass(
      cardGradient: cardGradient ?? this.cardGradient,
      overlayColor: overlayColor ?? this.overlayColor,
      borderColor: borderColor ?? this.borderColor,
      blurSigma: blurSigma ?? this.blurSigma,
      headerGradient: headerGradient ?? this.headerGradient,
      accentGradient: accentGradient ?? this.accentGradient,
    );
  }

  @override
  AppGlass lerp(ThemeExtension<AppGlass>? other, double t) {
    if (other is! AppGlass) return this;
    return AppGlass(
      cardGradient:
          LinearGradient.lerp(cardGradient, other.cardGradient, t) ??
          cardGradient,
      overlayColor:
          Color.lerp(overlayColor, other.overlayColor, t) ?? overlayColor,
      borderColor: Color.lerp(borderColor, other.borderColor, t) ?? borderColor,
      blurSigma: lerpDouble(blurSigma, other.blurSigma, t),
      headerGradient:
          LinearGradient.lerp(headerGradient, other.headerGradient, t) ??
          headerGradient,
      accentGradient:
          LinearGradient.lerp(accentGradient, other.accentGradient, t) ??
          accentGradient,
    );
  }
}

// ── AppPremiumShadows ─────────────────────────────────────────────────────────

@immutable
class AppPremiumShadows extends ThemeExtension<AppPremiumShadows> {
  const AppPremiumShadows({required this.premiumShadow});

  final List<BoxShadow> premiumShadow;

  @override
  AppPremiumShadows copyWith({List<BoxShadow>? premiumShadow}) {
    return AppPremiumShadows(
      premiumShadow: premiumShadow ?? this.premiumShadow,
    );
  }

  @override
  AppPremiumShadows lerp(ThemeExtension<AppPremiumShadows>? other, double t) {
    if (other is! AppPremiumShadows) return this;
    return AppPremiumShadows(
      premiumShadow:
          BoxShadow.lerpList(premiumShadow, other.premiumShadow, t) ??
          premiumShadow,
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

double lerpDouble(double a, double b, double t) => a + (b - a) * t;

extension AppThemeX on BuildContext {
  AppSpacing get spacing =>
      Theme.of(this).extension<AppSpacing>() ?? const AppSpacing();

  AppRadii get radii =>
      Theme.of(this).extension<AppRadii>() ?? const AppRadii();

  AppSemanticColors get sem {
    final theme = Theme.of(this);
    return theme.extension<AppSemanticColors>() ??
        (theme.brightness == Brightness.dark
            ? AppSemanticColors.dark()
            : AppSemanticColors.light());
  }

  AppGlass get glass {
    final theme = Theme.of(this);
    return theme.extension<AppGlass>() ??
        AppGlass.forBrightness(
          theme.brightness == Brightness.dark,
          theme.colorScheme.primary,
          theme.colorScheme.outlineVariant,
        );
  }

  List<BoxShadow> get premiumShadows =>
      Theme.of(this).extension<AppPremiumShadows>()?.premiumShadow ?? [];

  bool get isMobile => MediaQuery.sizeOf(this).width < 600;
  bool get isTablet =>
      MediaQuery.sizeOf(this).width >= 600 &&
      MediaQuery.sizeOf(this).width < 1024;
  bool get isDesktop => MediaQuery.sizeOf(this).width >= 1024;
}
