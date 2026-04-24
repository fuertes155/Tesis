import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import 'mini_bars_sparkline.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? trendText;
  final bool trendUp;
  final List<int>? sparklinePoints;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.trendText,
    this.trendUp = true,
    this.sparklinePoints,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final s = context.spacing;
    final r = context.radii;
    final sem = context.sem;
    final glass = context.glass;

    return Container(
      padding: EdgeInsets.all(s.lg),
      decoration: BoxDecoration(
        gradient: glass.cardGradient,
        borderRadius: r.radiusXl,
        border: Border.all(
          color: color.withValues(alpha: 0.18),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 20,
            spreadRadius: -4,
            offset: const Offset(0, 8),
          ),
          ...context.premiumShadows,
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: ícono + trend badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Ícono con gradiente
              Container(
                padding: EdgeInsets.all(s.sm),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.18),
                      color.withValues(alpha: 0.06),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: r.radiusMd,
                  border: Border.all(color: color.withValues(alpha: 0.12)),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              if (trendText != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: (trendUp ? sem.success : sem.danger)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: (trendUp ? sem.success : sem.danger)
                          .withValues(alpha: 0.20),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        trendUp ? Icons.trending_up : Icons.trending_down,
                        size: 13,
                        color: trendUp ? sem.success : sem.danger,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        trendText!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: trendUp ? sem.success : sem.danger,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          SizedBox(height: s.md),

          // Label del título
          Text(
            title,
            style: theme.textTheme.labelMedium?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),

          const SizedBox(height: 4),

          // Valor con sparkline
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: cs.onSurface,
                  letterSpacing: -1.5,
                ),
              ),
              if (sparklinePoints != null) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: SizedBox(
                      height: 30,
                      child: MiniBarsSparkline(
                        points: sparklinePoints!,
                        color: color.withValues(alpha: 0.45),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
