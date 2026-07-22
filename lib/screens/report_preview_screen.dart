import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/api_providers.dart';
import '../models/reporte_cognitivo_model.dart';
import 'package:intl/intl.dart';

class ReportPreviewScreen extends ConsumerWidget {
  const ReportPreviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final api = ref.watch(apiServiceProvider).value;

    if (api == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final patientId = api.currentPatientId.toString();

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      appBar: AppBar(
        title: const Text('Historial de Reportes'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<ReporteCognitivoModel>>(
        future: api.getReportesByPatient(patientId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error al cargar reportes: ${snapshot.error}',
                  style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final reportes = snapshot.data ?? [];

          if (reportes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open_outlined, size: 64, color: theme.colorScheme.outline),
                  const SizedBox(height: 16),
                  Text(
                    'No hay reportes generados aún',
                    style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reportes.length,
            itemBuilder: (context, index) {
              final reporte = reportes[index];
              final fechaFormateada = DateFormat('dd/MM/yyyy - HH:mm').format(reporte.createdAt.toLocal());

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    foregroundColor: theme.colorScheme.onPrimaryContainer,
                    child: const Icon(Icons.picture_as_pdf_rounded),
                  ),
                  title: Text(
                    'Reporte Cognitivo',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Paciente: ${reporte.nombrePaciente}'),
                        Text('Fecha: $fechaFormateada', style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: () {
                    context.push('/reporte_cognitivo', extra: {
                      'solicitud': reporte.toSolicitud().toJson(),
                      'preGeneratedReport': reporte.toJson(),
                    });
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
