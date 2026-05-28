import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/reporte_cognitivo_model.dart';
import '../services/reporte_cognitivo_service.dart';

class ReporteCognitivoScreen extends StatefulWidget {
  const ReporteCognitivoScreen({
    super.key,
    required this.solicitud,
  });

  final SolicitudReporteCognitivoModel solicitud;

  @override
  State<ReporteCognitivoScreen> createState() => _ReporteCognitivoScreenState();
}

class _ReporteCognitivoScreenState extends State<ReporteCognitivoScreen> {
  late final Future<ReporteCognitivoModel> _reporteFuture;
  final _servicio = ReporteCognitivoService();

  @override
  void initState() {
    super.initState();
    _reporteFuture = _servicio.generarReporte(widget.solicitud);
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reporte neuropsicológico'),
      ),
      body: FutureBuilder<ReporteCognitivoModel>(
        future: _reporteFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const _ReporteLoading();
          }

          if (snapshot.hasError) {
            return _ReporteError(mensaje: snapshot.error.toString());
          }

          final reporte = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reporte.nombrePaciente,
                  style: tema.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text('Fecha: ${reporte.fechaEvaluacion}'),
                const SizedBox(height: 20),
                SelectableText(
                  reporte.reporte,
                  style: tema.textTheme.bodyLarge?.copyWith(height: 1.45),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _compartirReporte(reporte),
                        icon: const Icon(Icons.ios_share_rounded),
                        label: const Text('Compartir'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _guardarReporte(reporte),
                        icon: const Icon(Icons.picture_as_pdf_rounded),
                        label: const Text('Guardar PDF'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _guardarReporte(ReporteCognitivoModel reporte) async {
    final bytes = await _crearPdf(reporte);
    await Printing.layoutPdf(
      name: 'Reporte_${reporte.pacienteId}.pdf',
      onLayout: (_) async => bytes,
    );
  }

  Future<void> _compartirReporte(ReporteCognitivoModel reporte) async {
    final bytes = await _crearPdf(reporte);
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'Reporte_${reporte.pacienteId}.pdf',
    );
  }

  Future<Uint8List> _crearPdf(ReporteCognitivoModel reporte) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text(
            'REPORTE NEUROPSICOLOGICO',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 12),
          pw.Text('Paciente: ${reporte.nombrePaciente}'),
          pw.Text('ID: ${reporte.pacienteId}'),
          pw.Text('Fecha: ${reporte.fechaEvaluacion}'),
          pw.SizedBox(height: 20),
          pw.Text(reporte.reporte),
        ],
      ),
    );
    return pdf.save();
  }
}

class _ReporteLoading extends StatelessWidget {
  const _ReporteLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text(
              'Ollama está generando el reporte neuropsicológico...',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReporteError extends StatelessWidget {
  const _ReporteError({required this.mensaje});

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48),
            const SizedBox(height: 16),
            const Text(
              'No se pudo generar el reporte',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              mensaje,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
