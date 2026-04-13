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

    return Container(
      padding: EdgeInsets.all(s.lg),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: r.radiusXl,
        border: Border.all(color: cs.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(s.sm),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: r.radiusMd,
                  border: Border.all(color: color.withValues(alpha: 0.05)),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              if (trendText != null)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: s.sm - 2,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: (trendUp ? sem.success : sem.danger).withValues(
                      alpha: 0.1,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        trendUp ? Icons.trending_up : Icons.trending_down,
                        size: 14,
                        color: trendUp ? sem.success : sem.danger,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        trendText!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: trendUp ? sem.success : sem.danger,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          SizedBox(height: s.md),
          Text(
            title,
            style: theme.textTheme.labelMedium?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                  letterSpacing: -1,
                ),
              ),
              if (sparklinePoints != null) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 32,
                    child: MiniBarsSparkline(
                      points: sparklinePoints!,
                      color: color.withValues(alpha: 0.4),
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
