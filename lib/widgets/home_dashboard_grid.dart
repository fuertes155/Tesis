import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/api_providers.dart';
import '../core/theme/app_theme.dart';
import 'dashboard_card.dart';
import 'skeleton_loader.dart';

/// Lista de accesos rápidos según el rol del usuario.
class HomeDashboardGrid extends ConsumerWidget {
  const HomeDashboardGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final sem = context.sem;
    final api = ref.watch(apiServiceProvider).value;

    if (api == null) {
      return const DashboardGridSkeleton();
    }

    final role = api.currentRole;

    final nuevaSesion = DashboardCard(
      icon: Icons.play_arrow_rounded,
      title: 'Nueva sesión',
      subtitle: 'Iniciar evaluación cognitiva',
      color: cs.primary,
      heroTag: 'hero_icon_new_session',
      onTap: () => context.push('/new_session'),
      isPrimary: true,
    );
    final pacientes = DashboardCard(
      icon: Icons.people_alt_rounded,
      title: 'Pacientes',
      subtitle: 'Ver lista, buscar y editar perfiles',
      color: cs.primary,
      heroTag: 'hero_icon_patients',
      onTap: () => context.push('/patients'),
    );
    final resultados = DashboardCard(
      icon: Icons.analytics_rounded,
      title: 'Resultados',
      subtitle: 'Historial y estadísticas',
      color: cs.tertiary,
      heroTag: 'hero_icon_history',
      onTap: () => context.push('/history'),
    );
    final reportes = DashboardCard(
      icon: Icons.picture_as_pdf_rounded,
      title: 'Reportes',
      subtitle: 'Informes neuropsicológicos',
      color: sem.danger,
      onTap: () => context.push('/report_preview'),
    );
    final panelMedico = DashboardCard(
      icon: Icons.medical_services_rounded,
      title: 'Panel médico',
      subtitle: 'Disponibilidad y pacientes asignados',
      color: cs.secondary,
      onTap: () => context.push('/doctor_panel'),
    );

    final tiles = <Widget>[
      if (role == 'gestor') ...[
        nuevaSesion,
        pacientes,
        DashboardCard(
          icon: Icons.person_add_alt_1_rounded,
          title: 'Crear paciente',
          subtitle: 'Registrar nuevo perfil clínico',
          color: cs.secondary,
          onTap: () => context.push('/create_patient'),
        ),
        DashboardCard(
          icon: Icons.admin_panel_settings_rounded,
          title: 'Usuarios y roles',
          subtitle: 'Cuentas del sistema',
          color: sem.warning,
          onTap: () => context.push('/users_admin'),
        ),
        resultados,
        reportes,
        panelMedico,
      ] else if (role == 'doctor') ...[
        nuevaSesion,
        pacientes,
        resultados,
        reportes,
        panelMedico,
      ] else if (role == 'user') ...[
        resultados,
      ],
    ];

    if (tiles.isEmpty) {
      final label = role == null ? 'sesión no iniciada' : 'rol: $role';
      return Row(
        children: [
          Icon(Icons.info_outline_rounded, color: cs.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No hay accesos rápidos para este usuario ($label).',
              style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < tiles.length; i++) ...[
          if (i > 0) SizedBox(height: i == 1 ? 10 : 2),
          tiles[i],
        ],
      ],
    );
  }
}
