import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';
import '../widgets/info_row.dart';

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
    final primaryColor = const Color(0xFF1A237E);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: Text(
          patientName,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E293B),
          ),
        ),
        centerTitle: false,
        actions: [
          if (patientId != null && ApiService().currentRole == 'gestor')
            IconButton(
              tooltip: 'Eliminar Paciente',
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: Color(0xFFEF4444),
              ),
              onPressed: () async {
                int? count;
                try {
                  if (patientId != null) {
                    final api = ApiService();
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
                          backgroundColor: const Color(0xFFEF4444),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('ELIMINAR'),
                      ),
                    ],
                  ),
                );
                if (!context.mounted) return;
                if (confirmed != true) return;
                try {
                  final api = ApiService();
                  await api.deletePatient(patientId!);
                  if (!context.mounted) return;
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Paciente eliminado correctamente'),
                        behavior: SnackBarBehavior.floating,
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
                        backgroundColor: const Color(0xFFEF4444),
                      ),
                    );
                  }
                }
              },
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: primaryColor.withValues(alpha: 0.1),
                        child: Text(
                          patientName.isNotEmpty
                              ? patientName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              patientName,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Expediente del Paciente',
                              style: TextStyle(color: const Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Divider(color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 24),
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
            const SizedBox(height: 40),
            Text(
              'ACCIONES DISPONIBLES',
              style: theme.textTheme.labelSmall?.copyWith(
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 2.5,
              children: [
                _buildActionCard(
                  icon: Icons.play_circle_outline_rounded,
                  label: 'Iniciar Sesión',
                  color: primaryColor,
                  onTap: () => context.push(
                    '/new_session',
                    extra: {'patientId': patientId},
                  ),
                ),
                _buildActionCard(
                  icon: Icons.analytics_outlined,
                  label: 'Ver Historial',
                  color: const Color(0xFF0F172A),
                  onTap: () => context.push('/history'),
                ),
                _buildActionCard(
                  icon: Icons.edit_outlined,
                  label: 'Editar Perfil',
                  color: const Color(0xFF64748B),
                  onTap: () {},
                ),
                _buildActionCard(
                  icon: Icons.ios_share_rounded,
                  label: 'Exportar Datos',
                  color: const Color(0xFF64748B),
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
