import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paleta de marca NeuroApp360.
abstract final class AppColors {
  // Marca
  static const primary = Color(0xFF2563EB); // Azul cobalto
  static const primaryDeep = Color(0xFF1E3A8A); // Azul marino (gradientes)
  static const secondary = Color(0xFF0D9488); // Verde azulado clínico
  static const tertiary = Color(0xFF7C3AED); // Violeta (acento neuro)

  // Superficies claras
  static const lightBg = Color(0xFFF5F7FB);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightSubtle = Color(0xFFF8FAFC);
  static const lightHigh = Color(0xFFEEF2F7);
  static const lightBorder = Color(0xFFE4E9F2);
  static const lightText = Color(0xFF0F172A);
  static const lightBody = Color(0xFF334155);
  static const lightMuted = Color(0xFF64748B);

  // Superficies oscuras
  static const darkBg = Color(0xFF0B1220);
  static const darkCard = Color(0xFF111A2E);
  static const darkSubtle = Color(0xFF0E1628);
  static const darkHigh = Color(0xFF1A2540);
  static const darkBorder = Color(0xFF24314D);
  static const darkText = Color(0xFFF1F5F9);
  static const darkBody = Color(0xFFCBD5E1);
  static const darkMuted = Color(0xFF94A3B8);
}

class AppTheme {
  static ThemeData buildTheme(BuildContext context, Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;

    final Color bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final Color cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final Color subtle = isDark ? AppColors.darkSubtle : AppColors.lightSubtle;
    final Color surfaceHigh = isDark ? AppColors.darkHigh : AppColors.lightHigh;
    final Color borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final Color displayColor = isDark ? AppColors.darkText : AppColors.lightText;
    final Color bodyColor = isDark ? AppColors.darkBody : AppColors.lightBody;
    final Color mutedColor = isDark ? AppColors.darkMuted : AppColors.lightMuted;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
    ).copyWith(
      primary: isDark ? const Color(0xFF3B82F6) : AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: isDark ? const Color(0xFF1E3A8A) : const Color(0xFFDCE7FE),
      onPrimaryContainer: isDark ? const Color(0xFFDBEAFE) : const Color(0xFF1E3A8A),
      secondary: isDark ? const Color(0xFF2DD4BF) : AppColors.secondary,
      onSecondary: Colors.white,
      secondaryContainer: isDark ? const Color(0xFF134E4A) : const Color(0xFFCCFBF1),
      onSecondaryContainer: isDark ? const Color(0xFFCCFBF1) : const Color(0xFF134E4A),
      tertiary: isDark ? const Color(0xFFA78BFA) : AppColors.tertiary,
      onTertiary: Colors.white,
      tertiaryContainer: isDark ? const Color(0xFF3B2A6B) : const Color(0xFFEDE9FE),
      onTertiaryContainer: isDark ? const Color(0xFFEDE9FE) : const Color(0xFF4C1D95),
      error: isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
      surface: bg,
      onSurface: displayColor,
      onSurfaceVariant: mutedColor,
      surfaceContainerLowest: cardColor,
      surfaceContainerLow: isDark ? AppColors.darkSubtle : AppColors.lightBg,
      surfaceContainer: isDark ? const Color(0xFF16213A) : AppColors.lightHigh,
      surfaceContainerHigh: isDark ? AppColors.darkHigh : const Color(0xFFE8EDF4),
      surfaceContainerHighest: surfaceHigh,
      outline: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
      outlineVariant: borderColor,
      surfaceTint: Colors.transparent,
    );

    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
    );

    final baseText = GoogleFonts.plusJakartaSansTextTheme(baseTheme.textTheme).apply(
      bodyColor: bodyColor,
      displayColor: displayColor,
    );

    // Plus Jakarta Sans tiene un espacio estrecho: en títulos se compensa con
    // wordSpacing para que las palabras no se peguen al usar pesos altos.
    final textTheme = baseText.copyWith(
      displayLarge: baseText.displayLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.8, wordSpacing: 4),
      displayMedium: baseText.displayMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.6, wordSpacing: 3),
      displaySmall: baseText.displaySmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5, wordSpacing: 3),
      headlineLarge: baseText.headlineLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.4, wordSpacing: 2),
      headlineMedium: baseText.headlineMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.3, wordSpacing: 2),
      headlineSmall: baseText.headlineSmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.2, wordSpacing: 1.5),
      titleLarge: baseText.titleLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.1, wordSpacing: 1),
      titleMedium: baseText.titleMedium?.copyWith(fontWeight: FontWeight.w700, wordSpacing: 1),
      titleSmall: baseText.titleSmall?.copyWith(fontWeight: FontWeight.w700, wordSpacing: 0.5),
      bodyLarge: baseText.bodyLarge?.copyWith(fontWeight: FontWeight.w500, height: 1.55),
      bodyMedium: baseText.bodyMedium?.copyWith(fontWeight: FontWeight.w500, height: 1.5),
      bodySmall: baseText.bodySmall?.copyWith(fontWeight: FontWeight.w500, color: mutedColor),
      labelLarge: baseText.labelLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.1),
      labelMedium: baseText.labelMedium?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.2),
      labelSmall: baseText.labelSmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.4),
    );

    // Sombras suaves en dos capas: contacto + ambiente.
    final List<BoxShadow> premiumShadow = isDark
        ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 24,
              spreadRadius: -8,
              offset: const Offset(0, 12),
            ),
          ]
        : [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.04),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.06),
              blurRadius: 24,
              spreadRadius: -8,
              offset: const Offset(0, 10),
            ),
          ];

    const radius = AppRadii();
    final buttonText = textTheme.labelLarge?.copyWith(fontSize: 14, fontWeight: FontWeight.w700);
    final buttonShape = RoundedRectangleBorder(borderRadius: radius.radiusMd);

    return baseTheme.copyWith(
      scaffoldBackgroundColor: bg,
      textTheme: textTheme,
      iconTheme: IconThemeData(color: bodyColor),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: bg,
        foregroundColor: displayColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: bodyColor),
        actionsIconTheme: IconThemeData(color: mutedColor),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontSize: 18,
          color: displayColor,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: cardColor,
        surfaceTintColor: Colors.transparent,
        margin: const EdgeInsets.symmetric(vertical: 6),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: radius.radiusLg,
          side: BorderSide(color: borderColor),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          disabledBackgroundColor: surfaceHigh,
          disabledForegroundColor: mutedColor,
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          shape: buttonShape,
          textStyle: buttonText,
          elevation: 0,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cardColor,
          foregroundColor: colorScheme.primary,
          surfaceTintColor: Colors.transparent,
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          shape: buttonShape.copyWith(side: BorderSide(color: borderColor)),
          textStyle: buttonText,
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.35), width: 1.2),
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          shape: buttonShape,
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          shape: RoundedRectangleBorder(borderRadius: radius.radiusSm),
          textStyle: buttonText,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.darkSubtle : AppColors.lightSubtle,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: radius.radiusMd,
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius.radiusMd,
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius.radiusMd,
          borderSide: BorderSide(color: colorScheme.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radius.radiusMd,
          borderSide: BorderSide(color: colorScheme.error, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: radius.radiusMd,
          borderSide: BorderSide(color: colorScheme.error, width: 1.6),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(color: mutedColor),
        floatingLabelStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
        ),
        prefixIconColor: mutedColor,
        suffixIconColor: mutedColor,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 2,
        highlightElevation: 4,
        shape: RoundedRectangleBorder(borderRadius: radius.radiusLg),
      ),
      dividerTheme: DividerThemeData(color: borderColor, space: 1, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? AppColors.darkHigh : AppColors.lightText,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        actionTextColor: const Color(0xFF93C5FD),
        shape: RoundedRectangleBorder(borderRadius: radius.radiusMd),
        elevation: 6,
      ),
      chipTheme: baseTheme.chipTheme.copyWith(
        labelStyle: textTheme.labelMedium?.copyWith(color: bodyColor),
        shape: const StadiumBorder(),
        side: BorderSide(color: borderColor),
        backgroundColor: cardColor,
        selectedColor: colorScheme.primaryContainer,
        checkmarkColor: colorScheme.onPrimaryContainer,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: radius.radiusXl),
        elevation: 12,
        titleTextStyle: textTheme.titleLarge?.copyWith(color: displayColor),
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: bodyColor),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: cardColor,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: radius.radiusMd,
          side: BorderSide(color: borderColor),
        ),
        textStyle: textTheme.bodyMedium?.copyWith(color: displayColor),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(cardColor),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: radius.radiusMd,
              side: BorderSide(color: borderColor),
            ),
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: mutedColor,
        shape: RoundedRectangleBorder(borderRadius: radius.radiusMd),
        titleTextStyle: textTheme.titleSmall?.copyWith(color: displayColor),
        subtitleTextStyle: textTheme.bodySmall,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkHigh : AppColors.lightText,
          borderRadius: radius.radiusSm,
        ),
        textStyle: textTheme.labelMedium?.copyWith(color: Colors.white),
        waitDuration: const Duration(milliseconds: 400),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        side: BorderSide(color: colorScheme.outline, width: 1.5),
      ),
      switchTheme: SwitchThemeData(
        trackOutlineColor: WidgetStatePropertyAll(borderColor),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.primary.withValues(alpha: 0.12),
        circularTrackColor: colorScheme.primary.withValues(alpha: 0.12),
      ),
      extensions: <ThemeExtension<dynamic>>[
        const AppSpacing(),
        radius,
        isDark ? AppSemanticColors.dark() : AppSemanticColors.light(),
        AppGlass.forBrightness(isDark, colorScheme.primary, borderColor, cardColor, subtle),
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
  const AppRadii({this.sm = 10, this.md = 12, this.lg = 16, this.xl = 20});

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
      success: Color(0xFF059669),
      warning: Color(0xFFD97706),
      info: Color(0xFF2563EB),
      danger: Color(0xFFDC2626),
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

// ── AppGlass — superficies de tarjetas y gradientes de marca ──────────────────

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

  factory AppGlass.forBrightness(
    bool isDark,
    Color primary,
    Color border, [
    Color? card,
    Color? subtle,
  ]) {
    final cardColor = card ?? (isDark ? AppColors.darkCard : AppColors.lightCard);
    return AppGlass(
      // Superficie sólida y limpia; el "vidrio" se reserva para overlays.
      cardGradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [cardColor, cardColor],
      ),
      overlayColor: isDark
          ? Colors.white.withValues(alpha: 0.04)
          : Colors.white.withValues(alpha: 0.72),
      borderColor: border,
      blurSigma: 16.0,
      headerGradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1E3A8A), Color(0xFF2563EB), Color(0xFF0EA5E9)],
        stops: [0.0, 0.6, 1.0],
      ),
      accentGradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
      ),
    );
  }

  /// Superficie de las tarjetas.
  final LinearGradient cardGradient;

  /// Color de superposición semitransparente.
  final Color overlayColor;

  /// Borde de las tarjetas.
  final Color borderColor;

  /// Sigma del blur para overlays.
  final double blurSigma;

  /// Gradiente de headers/hero sections.
  final LinearGradient headerGradient;

  /// Gradiente de acento (íconos, badges).
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
