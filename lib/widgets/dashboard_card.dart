import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class DashboardCard extends StatelessWidget {
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
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final s = context.spacing;
    final r = context.radii;

    final cardColor = isPrimary ? cs.primary : theme.cardColor;
    final borderColor = isPrimary ? cs.primary : cs.outlineVariant;
    final shadowColor = isPrimary ? cs.primary : Colors.black;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: r.radiusXl,
        child: Container(
          padding: EdgeInsets.all(s.xl),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: r.radiusXl,
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: shadowColor.withValues(alpha: isPrimary ? 0.15 : 0.04),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(s.md),
                    decoration: BoxDecoration(
                      color: (isPrimary ? Colors.white : color).withValues(
                        alpha: isPrimary ? 0.2 : 0.1,
                      ),
                      borderRadius: r.radiusMd,
                      border: Border.all(
                        color: (isPrimary ? Colors.white : color).withValues(
                          alpha: 0.1,
                        ),
                      ),
                    ),
                    child: Icon(
                      icon,
                      size: 32,
                      color: isPrimary ? cs.onPrimary : color,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: isPrimary ? cs.onPrimary : cs.onSurface,
                      letterSpacing: -0.8,
                    ),
                  ),
                  SizedBox(height: s.xs),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isPrimary
                          ? cs.onPrimary.withValues(alpha: 0.82)
                          : cs.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
              Positioned(
                right: -4,
                bottom: -4,
                child: Container(
                  padding: EdgeInsets.all(s.sm - 2),
                  decoration: BoxDecoration(
                    color: (isPrimary ? Colors.white : cs.primary).withValues(
                      alpha: isPrimary ? 0.15 : 0.05,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: isPrimary ? cs.onPrimary : cs.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
