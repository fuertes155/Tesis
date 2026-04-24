import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Tarjeta con efecto glassmorphism.
/// Usa [BackdropFilter] para blur real sobre el contenido detrás.
///
/// Ejemplo:
/// ```dart
/// GlassCard(
///   child: Text('Hola'),
///   radius: 24,
///   glow: true,
/// )
/// ```
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.radius = 24,
    this.glow = false,
    this.padding,
    this.margin,
    this.gradient,
    this.border,
    this.constraints,
    this.onTap,
  });

  final Widget child;
  final double radius;
  final bool glow;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Gradient? gradient;
  final Border? border;
  final BoxConstraints? constraints;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final cs = Theme.of(context).colorScheme;
    final shadows = context.premiumShadows;

    Widget content = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: glass.blurSigma,
          sigmaY: glass.blurSigma,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          constraints: constraints,
          padding: padding,
          decoration: BoxDecoration(
            gradient: gradient ?? glass.cardGradient,
            borderRadius: BorderRadius.circular(radius),
            border: border ??
                Border.all(
                  color: glass.borderColor,
                  width: 1,
                ),
            boxShadow: [
              if (glow)
                BoxShadow(
                  color: cs.primary.withValues(alpha: 0.18),
                  blurRadius: 28,
                  spreadRadius: -2,
                ),
              ...shadows,
            ],
          ),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          splashColor: cs.primary.withValues(alpha: 0.06),
          highlightColor: cs.primary.withValues(alpha: 0.03),
          child: content,
        ),
      );
    }

    if (margin != null) {
      return Padding(padding: margin!, child: content);
    }
    return content;
  }
}
