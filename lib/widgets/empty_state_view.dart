import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import '../core/theme/app_theme.dart';

class EmptyStateView extends StatelessWidget {
  final String title;
  final String description;
  final String? iconPath; // For SVG
  final IconData? iconData; // For fallback icon
  final String? lottiePath; // For Lottie animation
  final String? buttonLabel;
  final VoidCallback? onButtonPressed;

  const EmptyStateView({
    super.key,
    required this.title,
    required this.description,
    this.iconPath,
    this.iconData,
    this.lottiePath,
    this.buttonLabel,
    this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final spacing = context.spacing;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(spacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustration container premium
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.04),
                    shape: BoxShape.circle,
                  ),
                ).animate(onPlay: (c) => c.repeat()).scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.1, 1.1),
                  duration: 2.seconds,
                  curve: Curves.easeInOut,
                ).then().scale(
                  begin: const Offset(1.1, 1.1),
                  end: const Offset(1, 1),
                  duration: 2.seconds,
                ),
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        cs.primary.withValues(alpha: 0.08),
                        cs.tertiary.withValues(alpha: 0.04),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(spacing.lg),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: cs.primary.withValues(alpha: 0.1),
                        blurRadius: 20,
                        spreadRadius: -5,
                      ),
                    ],
                  ),
                  child: lottiePath != null
                      ? Lottie.asset(
                          lottiePath!,
                          width: 120,
                          height: 120,
                          fit: BoxFit.contain,
                        )
                      : iconPath != null
                          ? SvgPicture.asset(
                              iconPath!,
                              width: 48,
                              height: 48,
                              colorFilter: ColorFilter.mode(cs.primary, BlendMode.srcIn),
                            )
                          : Icon(
                              iconData ?? Icons.query_builder_rounded,
                              size: 48,
                              color: cs.primary,
                            ),
                ),
              ],
            ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.8, 0.8)),
            
            SizedBox(height: spacing.md),
            
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: cs.onSurface,
                letterSpacing: -0.5,
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
            
            SizedBox(height: spacing.sm),
            
            Text(
              description,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
                height: 1.5,
              ),
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
            
            if (buttonLabel != null && onButtonPressed != null) ...[
              SizedBox(height: spacing.lg),
              FilledButton.icon(
                onPressed: onButtonPressed,
                icon: const Icon(Icons.add_rounded),
                label: Text(buttonLabel!),
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: spacing.xl,
                    vertical: spacing.md,
                  ),
                ),
              ).animate().fadeIn(delay: 600.ms).scale(begin: const Offset(0.9, 0.9)),
            ],
          ],
        ),
      ),
    );
  }
}
