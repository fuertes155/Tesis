import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../core/theme/app_theme.dart';

class ProfessionalEmptyState extends StatelessWidget {
  const ProfessionalEmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
    this.icon,
    this.lottiePath,
  });

  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? icon;
  final String? lottiePath;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final s = context.spacing;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(s.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (lottiePath != null)
              Lottie.asset(
                lottiePath!,
                width: 200,
                height: 200,
                repeat: true,
              )
            else if (icon != null)
              Container(
                padding: EdgeInsets.all(s.xl),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 64,
                  color: cs.primary.withValues(alpha: 0.5),
                ),
              )
            else
              const SizedBox.shrink(),
            SizedBox(height: s.lg),
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: cs.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: s.xs),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: s.xl),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add_rounded),
                label: Text(actionLabel!),
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: s.xl, vertical: s.md),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
