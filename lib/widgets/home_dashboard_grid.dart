import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/api_providers.dart';
import '../core/theme/app_theme.dart';
import 'dashboard_card.dart';
import 'skeleton_loader.dart';

class HomeDashboardGrid extends ConsumerWidget {
  const HomeDashboardGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final s = context.spacing;
    final r = context.radii;
    final api = ref.watch(apiServiceProvider).value;

    if (api == null) {
      return const DashboardGridSkeleton();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth =
            (constraints.maxWidth.isFinite && constraints.maxWidth > 0)
                ? constraints.maxWidth
                : MediaQuery.sizeOf(context).width;
        final width = maxWidth;
        int crossAxisCount = 1;
        if (width > 900) {
          crossAxisCount = 3;
        } else if (width > 600) {
          crossAxisCount = 2;
        }
        final role = api.currentRole;
        final tiles = <Widget>[];

        if (role == 'gestor') {
          tiles.addAll([
            DashboardCard(
              icon: Icons.people_alt_outlined,
              title: 'Gestionar Pacientes',
              subtitle: 'Ver lista, buscar y editar perfiles',
              color: theme.colorScheme.secondary,
              heroTag: 'hero_icon_patients',
              onTap: () => context.push('/patients'),
            ),
            DashboardCard(
              icon: Icons.person_add_alt_1_rounded,
              title: 'Crear Paciente',
              subtitle: 'Registrar nuevo perfil clínico',
              color: theme.colorScheme.primary,
              onTap: () => context.push('/create_patient'),
            ),
            DashboardCard(
              icon: Icons.admin_panel_settings_outlined,
              title: 'Usuarios y Roles',
              subtitle: 'Listado de usuarios del sistema',
              color: theme.colorScheme.tertiary,
              onTap: () => context.push('/users_admin'),
            ),
            DashboardCard(
              icon: Icons.play_circle_outline_rounded,
              title: 'Nueva Sesión',
              subtitle: 'Iniciar evaluación cognitiva',
              color: theme.colorScheme.primary,
              heroTag: 'hero_icon_new_session',
              onTap: () => context.push('/new_session'),
              isPrimary: true,
            ),
            DashboardCard(
              icon: Icons.analytics_outlined,
              title: 'Resultados',
              subtitle: 'Ver reportes y estadísticas',
              color: theme.colorScheme.tertiary,
              heroTag: 'hero_icon_history',
              onTap: () => context.push('/history'),
            ),
            DashboardCard(
              icon: Icons.picture_as_pdf_outlined,
              title: 'Reportes',
              subtitle: 'Vista previa de informe',
              color: theme.colorScheme.secondary,
              onTap: () => context.push('/report_preview'),
            ),
            DashboardCard(
              icon: Icons.medical_services_outlined,
              title: 'Panel Médico',
              subtitle: 'Disponibilidad y pacientes asignados',
              color: theme.colorScheme.secondary,
              onTap: () => context.push('/doctor_panel'),
            ),
          ]);
        } else if (role == 'doctor') {
          tiles.addAll([
            DashboardCard(
              icon: Icons.people_alt_outlined,
              title: 'Gestionar Pacientes',
              subtitle: 'Ver lista, buscar y editar perfiles',
              color: theme.colorScheme.secondary,
              heroTag: 'hero_icon_patients',
              onTap: () => context.push('/patients'),
            ),
            DashboardCard(
              icon: Icons.play_circle_outline_rounded,
              title: 'Nueva Sesión',
              subtitle: 'Iniciar evaluación cognitiva',
              color: theme.colorScheme.primary,
              heroTag: 'hero_icon_new_session',
              onTap: () => context.push('/new_session'),
              isPrimary: true,
            ),
            DashboardCard(
              icon: Icons.analytics_outlined,
              title: 'Resultados',
              subtitle: 'Ver reportes y estadísticas',
              color: theme.colorScheme.tertiary,
              heroTag: 'hero_icon_history',
              onTap: () => context.push('/history'),
            ),
            DashboardCard(
              icon: Icons.picture_as_pdf_outlined,
              title: 'Reportes',
              subtitle: 'Vista previa de informe',
              color: theme.colorScheme.secondary,
              onTap: () => context.push('/report_preview'),
            ),
            DashboardCard(
              icon: Icons.medical_services_outlined,
              title: 'Panel Médico',
              subtitle: 'Disponibilidad y pacientes asignados',
              color: theme.colorScheme.secondary,
              onTap: () => context.push('/doctor_panel'),
            ),
          ]);
        } else if (role == 'user') {
          tiles.addAll([
            DashboardCard(
              icon: Icons.analytics_outlined,
              title: 'Resultados',
              subtitle: 'Ver reportes y estadísticas',
              color: theme.colorScheme.tertiary,
              heroTag: 'hero_icon_history',
              onTap: () => context.push('/history'),
            ),
          ]);
        }

        final spacing = s.lg;
        final itemWidth =
            ((width - (crossAxisCount - 1) * spacing) / crossAxisCount)
                .clamp(240.0, 520.0);

        if (tiles.isEmpty) {
          final label = role == null ? 'sesión no iniciada' : 'rol: $role';
          final glass = context.glass;
          return SizedBox(
            width: double.infinity,
            child: Container(
              padding: EdgeInsets.all(s.lg),
              decoration: BoxDecoration(
                gradient: glass.cardGradient,
                borderRadius: r.radiusMd,
                border: Border.all(color: glass.borderColor),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: cs.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No hay accesos rápidos para este usuario ($label).',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return SizedBox(
          width: double.infinity,
          child: Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              for (final child in tiles)
                SizedBox(
                  width: itemWidth,
                  child: AspectRatio(aspectRatio: 1.9, child: child),
                ),
            ],
          ),
        );
      },
    );
  }
}
