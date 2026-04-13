import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../core/theme/app_theme.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final s = context.spacing;
    final r = context.radii;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.all(s.xs),
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.1),
            borderRadius: r.radiusSm,
            border: Border.all(
              color: cs.primary.withValues(alpha: 0.1),
            ),
          ),
          child: SvgPicture.asset(
            'assets/svg/hospital_logo.svg',
            width: 22,
            height: 22,
            colorFilter: ColorFilter.mode(
              cs.primary,
              BlendMode.srcIn,
            ),
          ),
        ),
        SizedBox(width: s.sm),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'NEUROAPP SYSTEMS',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.primary.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    fontSize: 10,
                    height: 1.0,
                  ),
                ),
                Text(
                  'Panel de Control',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
