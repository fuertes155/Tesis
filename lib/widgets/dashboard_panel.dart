import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Tarjeta de sección con encabezado (ícono, título, subtítulo y acciones).
///
/// Si el ancho es menor que [trailingBreakpoint], las acciones ([trailing])
/// pasan debajo del título.
class DashboardPanel extends StatelessWidget {
  const DashboardPanel({
    super.key,
    required this.title,
    required this.child,
    this.icon,
    this.iconColor,
    this.subtitle,
    this.trailing,
    this.padding = const EdgeInsets.all(20),
    this.trailingBreakpoint = 560,
  });

  final String title;
  final Widget child;
  final IconData? icon;
  final Color? iconColor;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  /// Ancho por debajo del cual [trailing] se muestra bajo el título.
  final double trailingBreakpoint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final color = iconColor ?? cs.primary;

    final titulo = Row(
      children: [
        if (icon != null) ...[
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: context.radii.radiusSm,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
        ],
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(color: cs.onSurface),
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: context.radii.radiusLg,
        border: Border.all(color: cs.outlineVariant),
        boxShadow: context.premiumShadows,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (trailing == null)
            titulo
          else
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < trailingBreakpoint) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [titulo, const SizedBox(height: 12), trailing!],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: titulo),
                    const SizedBox(width: 12),
                    trailing!,
                  ],
                );
              },
            ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}
