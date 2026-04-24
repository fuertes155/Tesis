import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_theme.dart';

/// Tarjeta del dashboard de accesos rápidos — versión premium.
class DashboardCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color color;
  final bool isPrimary;

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

  final String? heroTag;

  @override
  State<DashboardCard> createState() => _DashboardCardState();
}

class _DashboardCardState extends State<DashboardCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 130),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.975).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final s = context.spacing;
    final r = context.radii;
    final glass = context.glass;

    // Dos variantes: primaria (gradiente azul) y normal (glass)
    final decoration = widget.isPrimary
        ? BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [cs.primary, cs.tertiary],
            ),
            borderRadius: r.radiusXl,
            boxShadow: [
              BoxShadow(
                color: cs.primary.withValues(alpha: _hovered ? 0.45 : 0.28),
                blurRadius: _hovered ? 32 : 20,
                spreadRadius: -4,
                offset: Offset(0, _hovered ? 12 : 8),
              ),
            ],
          )
        : BoxDecoration(
            gradient: glass.cardGradient,
            borderRadius: r.radiusXl,
            border: Border.all(
              color: _hovered
                  ? widget.color.withValues(alpha: 0.35)
                  : glass.borderColor,
              width: 1.5,
            ),
            boxShadow: [
              if (_hovered)
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.12),
                  blurRadius: 20,
                  spreadRadius: -2,
                  offset: const Offset(0, 6),
                ),
              ...context.premiumShadows,
            ],
          );

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) => _ctrl.reverse(),
        onTapCancel: () => _ctrl.reverse(),
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onTap();
        },
        child: AnimatedBuilder(
          animation: _scale,
          builder: (_, child) =>
              Transform.scale(scale: _scale.value, child: child),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.all(s.md),
            decoration: decoration,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ícono premium con Hero opcional
                    Builder(builder: (ctx) {
                      final iconContainer = Container(
                        padding: EdgeInsets.all(s.md),
                        decoration: BoxDecoration(
                          gradient: widget.isPrimary
                              ? LinearGradient(
                                  colors: [
                                    Colors.white.withValues(alpha: 0.25),
                                    Colors.white.withValues(alpha: 0.10),
                                  ],
                                )
                              : LinearGradient(
                                  colors: [
                                    widget.color.withValues(alpha: 0.18),
                                    widget.color.withValues(alpha: 0.06),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                          borderRadius: r.radiusMd,
                          border: Border.all(
                            color: widget.isPrimary
                                ? Colors.white.withValues(alpha: 0.20)
                                : widget.color.withValues(alpha: 0.15),
                          ),
                          boxShadow: widget.isPrimary
                              ? [
                                  BoxShadow(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    blurRadius: 10,
                                  )
                                ]
                              : [],
                        ),
                        child: Icon(
                          widget.icon,
                          size: 28,
                          color: widget.isPrimary ? Colors.white : widget.color,
                        ),
                      );
                      if (widget.heroTag != null) {
                        return Hero(
                          tag: widget.heroTag!,
                          flightShuttleBuilder: (flightCtx, animation, direction, fromCtx, toCtx) {
                            return Material(color: Colors.transparent, child: toCtx.widget);
                          },
                          child: iconContainer,
                        );
                      }
                      return iconContainer;
                    }),

                    SizedBox(height: s.md),

                    // Título
                    Text(
                      widget.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: widget.isPrimary ? Colors.white : cs.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: s.xs - 2),

                    // Subtítulo
                    Text(
                      widget.subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: widget.isPrimary
                            ? Colors.white.withValues(alpha: 0.80)
                            : cs.onSurfaceVariant,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),

                // Chevron decorativo
                Positioned(
                  right: -4,
                  bottom: -4,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (widget.isPrimary ? Colors.white : widget.color)
                          .withValues(
                        alpha: widget.isPrimary
                            ? (_hovered ? 0.25 : 0.15)
                            : (_hovered ? 0.15 : 0.06),
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: widget.isPrimary ? Colors.white : widget.color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
