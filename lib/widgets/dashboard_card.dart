import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_theme.dart';

/// Acceso rápido del panel: fila con ícono, título, subtítulo y flecha.
/// La variante [isPrimary] usa el gradiente de marca para destacar la acción principal.
class DashboardCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color color;
  final bool isPrimary;
  final String? heroTag;

  const DashboardCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.color,
    this.isPrimary = false,
    this.heroTag,
  });

  @override
  State<DashboardCard> createState() => _DashboardCardState();
}

class _DashboardCardState extends State<DashboardCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final primario = widget.isPrimary;
    final radio = context.radii.radiusMd;

    final colorTexto = primario ? Colors.white : cs.onSurface;
    final colorSub = primario ? Colors.white.withValues(alpha: 0.8) : cs.onSurfaceVariant;

    Widget icono = Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: primario ? Colors.white.withValues(alpha: 0.18) : widget.color.withValues(alpha: 0.12),
        borderRadius: context.radii.radiusSm,
      ),
      child: Icon(widget.icon, size: 20, color: primario ? Colors.white : widget.color),
    );
    if (widget.heroTag != null) {
      icono = Hero(
        tag: widget.heroTag!,
        flightShuttleBuilder: (_, __, ___, ____, toCtx) =>
            Material(color: Colors.transparent, child: toCtx.widget),
        child: icono,
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          gradient: primario ? context.glass.headerGradient : null,
          color: primario
              ? null
              : (_hovered ? cs.primary.withValues(alpha: 0.05) : Colors.transparent),
          borderRadius: radio,
          border: primario
              ? null
              : Border.all(color: _hovered ? cs.primary.withValues(alpha: 0.25) : Colors.transparent),
          boxShadow: primario && _hovered
              ? [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.30),
                    blurRadius: 18,
                    spreadRadius: -4,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: radio,
            onTap: () {
              HapticFeedback.lightImpact();
              widget.onTap();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  icono,
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(color: colorTexto),
                        ),
                        Text(
                          widget.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(color: colorSub),
                        ),
                      ],
                    ),
                  ),
                  AnimatedSlide(
                    duration: const Duration(milliseconds: 160),
                    offset: Offset(_hovered ? 0.15 : 0, 0),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: primario ? Colors.white : cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
