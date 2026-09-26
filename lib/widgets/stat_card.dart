import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import 'mini_bars_sparkline.dart';

/// Tarjeta de indicador (KPI): ícono, valor, etiqueta y una línea de contexto.
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  /// Texto secundario bajo la etiqueta, p. ej. "últimos 7 días".
  final String? caption;
  final String? trendText;
  final bool trendUp;
  final List<int>? sparklinePoints;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.caption,
    this.trendText,
    this.trendUp = true,
    this.sparklinePoints,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: context.radii.radiusLg,
        border: Border.all(color: cs.outlineVariant),
        boxShadow: context.premiumShadows,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: context.radii.radiusMd,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const Spacer(),
              if (trendText != null) _TrendBadge(text: trendText!, up: trendUp),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: cs.onSurface,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(color: cs.onSurface),
          ),
          if (caption != null)
            Text(
              caption!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
          if (sparklinePoints != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 28,
              child: MiniBarsSparkline(
                points: sparklinePoints!,
                color: color.withValues(alpha: 0.45),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TrendBadge extends StatelessWidget {
  const _TrendBadge({required this.text, required this.up});

  final String text;
  final bool up;

  @override
  Widget build(BuildContext context) {
    final sem = context.sem;
    final color = up ? sem.success : sem.danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(up ? Icons.trending_up_rounded : Icons.trending_down_rounded, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
