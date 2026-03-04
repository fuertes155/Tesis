import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/info_row.dart';
import '../widgets/action_button.dart';
import 'package:go_router/go_router.dart';

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

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(patientName),
        centerTitle: true,
        actions: [
          if (patientId != null)
            IconButton(
              tooltip: 'Eliminar Paciente',
              icon: const Icon(Icons.delete_outline_rounded),
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
                        child: const Text('Cancelar'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.error,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Eliminar'),
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
                        backgroundColor: theme.colorScheme.error,
                      ),
                    );
                  }
                }
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      patientName.isNotEmpty ? patientName[0] : '?',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    patientName,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Activo',
                      style: TextStyle(
                        color: theme.colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Información Personal',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(height: 32),
                    InfoRow(
                      icon: Icons.cake_outlined,
                      label: 'Edad',
                      value: '30 años',
                    ),
                    const SizedBox(height: 16),
                    InfoRow(
                      icon: Icons.badge_outlined,
                      label: 'ID',
                      value: '12345',
                    ),
                    const SizedBox(height: 16),
                    InfoRow(
                      icon: Icons.phone_outlined,
                      label: 'Teléfono',
                      value: '+51 987 654 321',
                    ),
                    const SizedBox(height: 16),
                    InfoRow(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: 'correo@ejemplo.com',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Acciones Rápidas',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ActionButton(
                    icon: Icons.play_circle_fill_rounded,
                    label: 'Nueva\nSesión',
                    color: theme.colorScheme.primary,
                    onTap: () => context.push('/new_session'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ActionButton(
                    icon: Icons.history_rounded,
                    label: 'Ver\nHistorial',
                    color: theme.colorScheme.secondary,
                    onTap: () => context.push('/history'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ActionButton(
                    icon: Icons.assignment_rounded,
                    label: 'Ver\nConsentimiento',
                    color: Colors.orange,
                    onTap: () => context.push('/consent'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
