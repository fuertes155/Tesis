import 'package:flutter/material.dart';
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
    final isCompact = MediaQuery.of(context).size.width < 600;
    return Card(
      elevation: 0,
      color: cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 12 : 16,
          vertical: isCompact ? 4 : 8,
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(isCompact ? 4 : 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: isCompact ? 18 : 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.left,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    value,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      height: 1.0,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.left,
                  ),
                  if (trendText != null) ...[
                    const SizedBox(height: 1),
                    Row(
                      children: [
                        Icon(
                          trendUp
                              ? Icons.trending_up_rounded
                              : Icons.trending_down_rounded,
                          size: 16,
                          color: trendUp ? Colors.green : Colors.redAccent,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          trendText!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: trendUp ? Colors.green : Colors.redAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (sparklinePoints != null) ...[
                    const SizedBox(height: 2),
                    SizedBox(
                      height: 8,
                      child: MiniBarsSparkline(points: sparklinePoints!),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
