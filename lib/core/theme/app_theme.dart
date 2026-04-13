import 'package:flutter/material.dart';

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

@immutable
class AppRadii extends ThemeExtension<AppRadii> {
  const AppRadii({this.sm = 12, this.md = 16, this.lg = 20, this.xl = 24});

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
}
