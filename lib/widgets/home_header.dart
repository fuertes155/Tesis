import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../core/theme/app_theme.dart';

/// Marca de la app para barras superiores: logo con gradiente + nombre.
class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key, this.subtitle = 'Panel de control'});

  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 38,
          height: 38,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: context.glass.headerGradient,
            borderRadius: context.radii.radiusMd,
            boxShadow: [
              BoxShadow(
                color: cs.primary.withValues(alpha: 0.30),
                blurRadius: 12,
                spreadRadius: -4,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: SvgPicture.asset(
            'assets/svg/hospital_logo.svg',
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(text: 'NeuroApp'),
                      TextSpan(text: '360', style: TextStyle(color: cs.primary)),
                    ],
                  ),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(height: 1.2),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
