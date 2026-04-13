import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';
import '../core/theme/app_theme.dart';
import 'dashboard_card.dart';

class HomeDashboardGrid extends StatelessWidget {
  const HomeDashboardGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final s = context.spacing;
    final r = context.radii;
    final api = GetIt.I<ApiService>();
    final initFuture = api.init();
    return FutureBuilder<void>(
      future: initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return SizedBox(
            width: double.infinity,
            child: Container(
              padding: EdgeInsets.all(s.lg),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: r.radiusMd,
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Cargando accesos rápidos...',
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
            final role = GetIt.I<ApiService>().currentRole;
            final tiles = <Widget>[];

            if (role == 'gestor') {
              tiles.addAll([
                DashboardCard(
                  icon: Icons.people_alt_outlined,
                  title: 'Gestionar Pacientes',
                  subtitle: 'Ver lista, buscar y editar perfiles',
                  color: theme.colorScheme.secondary,
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
                  onTap: () => context.push('/new_session'),
                  isPrimary: true,
                ),
                DashboardCard(
                  icon: Icons.analytics_outlined,
                  title: 'Resultados',
                  subtitle: 'Ver reportes y estadísticas',
                  color: theme.colorScheme.tertiary,
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
                  onTap: () => context.push('/patients'),
                ),
                DashboardCard(
                  icon: Icons.play_circle_outline_rounded,
                  title: 'Nueva Sesión',
                  subtitle: 'Iniciar evaluación cognitiva',
                  color: theme.colorScheme.primary,
                  onTap: () => context.push('/new_session'),
                  isPrimary: true,
                ),
                DashboardCard(
                  icon: Icons.analytics_outlined,
                  title: 'Resultados',
                  subtitle: 'Ver reportes y estadísticas',
                  color: theme.colorScheme.tertiary,
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
              return SizedBox(
                width: double.infinity,
                child: Container(
                  padding: EdgeInsets.all(s.lg),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: r.radiusMd,
                    border: Border.all(color: cs.outlineVariant),
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
                      child: AspectRatio(aspectRatio: 1.45, child: child),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
