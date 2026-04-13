import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';
import '../widgets/info_row.dart';
import '../core/theme/app_theme.dart';

class PatientDetailScreen extends StatelessWidget {
  final String patientName;
  final int? patientId;

  const PatientDetailScreen({
    super.key,
    required this.patientName,
    this.patientId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final r = context.radii;
    final spacing = context.spacing;
    final sem = context.sem;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surfaceContainerLowest,
        surfaceTintColor: cs.surfaceContainerLowest,
        elevation: 0,
        title: Text(
          patientName,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: cs.onSurface,
          ),
        ),
        centerTitle: false,
        actions: [
          if (patientId != null &&
              GetIt.I<ApiService>().currentRole == 'gestor')
            IconButton(
              tooltip: 'Eliminar Paciente',
              icon: Icon(
                Icons.delete_outline_rounded,
                color: sem.danger,
              ),
              onPressed: () async {
                int? count;
                try {
                  if (patientId != null) {
                    final api = GetIt.I<ApiService>();
                    count = await api.getSessionsCountForPatient(patientId!);
                  }
                } catch (_) {
                  count = null;
                }
                if (!context.mounted) return;
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Eliminar paciente'),
                    content: Text(
                      count == null
                          ? '¿Seguro que deseas eliminar a "$patientName"? Esta acción es permanente.'
                          : 'Vas a eliminar a "$patientName" y $count sesión(es) asociada(s). Esta acción es permanente.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('CANCELAR'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        style: FilledButton.styleFrom(
                          backgroundColor: sem.danger,
                          foregroundColor: cs.onError,
                        ),
                        child: const Text('ELIMINAR'),
                      ),
                    ],
                  ),
                );
                if (!context.mounted) return;
                if (confirmed != true) return;
                try {
                  final api = GetIt.I<ApiService>();
                  await api.deletePatient(patientId!);
                  if (!context.mounted) return;
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Paciente eliminado correctamente'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: sem.success,
                      ),
                    );
                    Navigator.of(context).pop(true);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('No se pudo eliminar: $e'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: sem.danger,
                      ),
                    );
                  }
                }
              },
            ),
          SizedBox(width: spacing.xs),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(spacing.lg),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLowest,
                borderRadius: r.radiusXl,
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: cs.primary.withValues(alpha: 0.1),
                        child: Text(
                          patientName.isNotEmpty
                              ? patientName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: cs.primary,
                          ),
                        ),
                      ),
                      SizedBox(width: spacing.lg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              patientName,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: cs.onSurface,
                              ),
                            ),
                            SizedBox(height: spacing.xs - 4), // ~4
                            Text(
                              'Expediente del Paciente',
                              style: TextStyle(color: cs.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: spacing.xl),
                  Divider(color: cs.outlineVariant),
                  SizedBox(height: spacing.lg),
                  InfoRow(
                    icon: Icons.badge_outlined,
                    label: 'ID Único',
                    value: patientId?.toString() ?? 'No asignado',
                  ),
                  InfoRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Edad',
                    value: '45 años', // En un caso real vendría del API
                  ),
                  InfoRow(
                    icon: Icons.history_outlined,
                    label: 'Última Sesión',
                    value: '12 de Octubre, 2023',
                  ),
                ],
              ),
            ),
            SizedBox(height: spacing.x2l),
            Text(
              'ACCIONES DISPONIBLES',
              style: theme.textTheme.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
            SizedBox(height: spacing.lg),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: spacing.md,
              crossAxisSpacing: spacing.md,
              childAspectRatio: 2.5,
              children: [
                _buildActionCard(
                  context,
                  icon: Icons.play_circle_outline_rounded,
                  label: 'Iniciar Sesión',
                  color: cs.primary,
                  onTap: () => context.push(
                    '/new_session',
                    extra: {'patientId': patientId},
                  ),
                ),
                _buildActionCard(
                  context,
                  icon: Icons.analytics_outlined,
                  label: 'Ver Historial',
                  color: cs.onSurface,
                  onTap: () => context.push('/history'),
                ),
                _buildActionCard(
                  context,
                  icon: Icons.edit_outlined,
                  label: 'Editar Perfil',
                  color: cs.onSurfaceVariant,
                  onTap: () {},
                ),
                _buildActionCard(
                  context,
                  icon: Icons.ios_share_rounded,
                  label: 'Exportar Datos',
                  color: cs.onSurfaceVariant,
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    final r = context.radii;
    final spacing = context.spacing;
    
    return InkWell(
      onTap: onTap,
      borderRadius: r.radiusMd,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: spacing.md, vertical: spacing.sm),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
          borderRadius: r.radiusMd,
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(spacing.xs),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: r.radiusSm,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            SizedBox(width: spacing.sm),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: cs.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
