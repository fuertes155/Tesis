import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'dashboard_card.dart';

class HomeDashboardGrid extends StatelessWidget {
  const HomeDashboardGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int crossAxisCount = 1;
        if (width > 900) {
          crossAxisCount = 3;
        } else if (width > 600) {
          crossAxisCount = 2;
        }
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          childAspectRatio: 1.45,
          children: [
            DashboardCard(
                  icon: Icons.people_alt_outlined,
                  title: 'Gestionar Pacientes',
                  subtitle: 'Ver lista, buscar y editar perfiles',
                  color: theme.colorScheme.secondary,
                  onTap: () => context.push('/patients'),
                )
                .animate()
                .fadeIn(duration: 260.ms, curve: Curves.easeOut)
                .moveY(begin: 8, end: 0, duration: 260.ms),
            DashboardCard(
                  icon: Icons.play_circle_outline_rounded,
                  title: 'Nueva Sesión',
                  subtitle: 'Iniciar evaluación cognitiva',
                  color: theme.colorScheme.primary,
                  onTap: () => context.push('/new_session'),
                  isPrimary: true,
                )
                .animate()
                .fadeIn(
                  duration: 260.ms,
                  delay: 90.ms,
                  curve: Curves.easeOut,
                )
                .moveY(
                  begin: 8,
                  end: 0,
                  duration: 260.ms,
                  delay: 90.ms,
                ),
            DashboardCard(
                  icon: Icons.analytics_outlined,
                  title: 'Resultados',
                  subtitle: 'Ver reportes y estadísticas',
                  color: theme.colorScheme.tertiary,
                  onTap: () => context.push('/history'),
                )
                .animate()
                .fadeIn(
                  duration: 260.ms,
                  delay: 180.ms,
                  curve: Curves.easeOut,
                )
                .moveY(
                  begin: 8,
                  end: 0,
                  duration: 260.ms,
                  delay: 180.ms,
                ),
          ],
        );
      },
    );
  }
}
