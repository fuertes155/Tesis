import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = const Color(0xFF1A237E);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: SvgPicture.asset(
            'assets/svg/hospital_logo.svg',
            width: 20,
            height: 20,
            colorFilter: ColorFilter.mode(
              primaryColor,
              BlendMode.srcIn,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'NEUROAPP SYSTEMS',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: primaryColor.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  fontSize: 9,
                ),
              ),
              Text(
                'Panel de Control',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: const Color(0xFF1E293B),
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
