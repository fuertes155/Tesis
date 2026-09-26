import 'package:flutter/material.dart';

import 'app_theme.dart';

class AppDecorations {
  /// Fondo con dos halos de color muy suaves (azul arriba a la izquierda,
  /// violeta arriba a la derecha) sobre el color base del tema.
  static BoxDecoration meshGradient(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return BoxDecoration(
      color: theme.colorScheme.surface,
      gradient: RadialGradient(
        center: const Alignment(-0.9, -1.0),
        radius: 1.2,
        colors: [
          theme.colorScheme.primary.withValues(alpha: isDark ? 0.14 : 0.07),
          theme.colorScheme.surface.withValues(alpha: 0),
        ],
      ),
    );
  }

  static Widget meshBackground({required Widget child}) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        return Stack(
          children: [
            Positioned.fill(child: DecoratedBox(decoration: meshGradient(context))),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(1.0, -1.0),
                    radius: 0.9,
                    colors: [
                      theme.colorScheme.tertiary.withValues(alpha: isDark ? 0.10 : 0.05),
                      theme.colorScheme.tertiary.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            child,
          ],
        );
      },
    );
  }

  static InputDecoration glassInput({
    required String label,
    required String hint,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(prefixIcon),
    );
  }

  static BoxDecoration premiumCard(BuildContext context, {double radius = 16}) {
    final cs = Theme.of(context).colorScheme;
    return BoxDecoration(
      color: cs.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: cs.outlineVariant),
      boxShadow: context.premiumShadows,
    );
  }
}
