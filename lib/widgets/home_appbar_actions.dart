import 'package:flutter/material.dart';

class HomeAppBarActions extends StatelessWidget {
  final VoidCallback onCreatePatient;
  final VoidCallback onRefresh;
  final VoidCallback onExportCsv;
  final VoidCallback onHistory;
  final VoidCallback onLogout;

  const HomeAppBarActions({
    super.key,
    required this.onCreatePatient,
    required this.onRefresh,
    required this.onExportCsv,
    required this.onHistory,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: FilledButton.icon(
            onPressed: onCreatePatient,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Crear Paciente'),
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: onRefresh,
          tooltip: 'Actualizar',
        ),
        IconButton(
          icon: const Icon(Icons.file_download_outlined),
          onPressed: onExportCsv,
          tooltip: 'Exportar CSV',
        ),
        IconButton(
          icon: const Icon(Icons.history_rounded),
          onPressed: onHistory,
          tooltip: 'Historial',
        ),
        IconButton(
          icon: const Icon(Icons.logout_rounded),
          onPressed: onLogout,
          tooltip: 'Cerrar Sesión',
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
