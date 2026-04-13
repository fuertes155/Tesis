import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const InfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final s = context.spacing;
    final r = context.radii;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: s.xs),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(s.xs),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: r.radiusSm,
            ),
            child: Icon(icon, size: 18, color: cs.onSurfaceVariant),
          ),
          SizedBox(width: s.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: cs.onSurfaceVariant,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
