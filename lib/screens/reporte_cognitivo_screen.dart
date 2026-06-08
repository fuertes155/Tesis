import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
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
                Center(
                  child: Column(
                    children: [
                      Text(
                        'INFORME NEUROPSICOLÓGICO',
                        textAlign: TextAlign.center,
                        style: tema.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        reporte.nombrePaciente,
                        style: tema.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _DatosPacienteCard(
                  reporte: reporte,
                  solicitud: widget.solicitud,
                ),
                const SizedBox(height: 20),
                _SectionTitle('RESULTADOS E INTERPRETACIÓN:'),
                SelectableText(
                  reporte.reporte,
                  style: tema.textTheme.bodyLarge?.copyWith(height: 1.45),
                ),
                const SizedBox(height: 20),
                _SectionTitle('PRUEBAS APLICADAS:'),
                const SizedBox(height: 8),
                ...widget.solicitud.pruebas.map(
                  (prueba) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '${prueba.nombrePrueba}: ${prueba.porcentajeObtenido.toStringAsFixed(1)}% - ${prueba.tiempoSegundos}s',
                    ),
                  ),
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
    final solicitud = widget.solicitud;
    final fechaGeneracion = DateTime.now();
    final fechaDocumento =
        '${fechaGeneracion.day.toString().padLeft(2, '0')}/${fechaGeneracion.month.toString().padLeft(2, '0')}/${fechaGeneracion.year}';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(54, 44, 54, 44),
        build: (context) => [
          pw.Center(
            child: pw.Text(
              'INFORME NEUROPSICOLÓGICO',
              style: pw.TextStyle(
                fontSize: 17,
                fontWeight: pw.FontWeight.bold,
                decoration: pw.TextDecoration.underline,
              ),
            ),
          ),
          pw.SizedBox(height: 22),
          _pdfPatientHeader(reporte, solicitud),
          pw.SizedBox(height: 18),
          _pdfSection('ANTECEDENTES Y CONTEXTO DE EVALUACIÓN:'),
          _pdfParagraph(
            'Evaluación neuropsicológica realizada a solicitud del profesional tratante. '
            'El presente documento resume los resultados obtenidos en las pruebas cognitivas disponibles y debe interpretarse como apoyo clínico, no como diagnóstico definitivo aislado.',
          ),
          pw.SizedBox(height: 12),
          _pdfSection('PRUEBAS APLICADAS:'),
          _pdfTestsTable(solicitud.pruebas),
          pw.SizedBox(height: 12),
          _pdfSection('RESULTADOS E INTERPRETACIÓN:'),
          _pdfParagraph(reporte.reporte),
          pw.SizedBox(height: 12),
          _pdfSection('RECOMENDACIONES Y SEGUIMIENTO:'),
          _pdfParagraph(
            'Correlacionar estos hallazgos con entrevista clínica, historia médica y observación funcional. '
            'Se sugiere seguimiento profesional si persisten dificultades cognitivas, cambios conductuales o impacto en actividades diarias.',
          ),
          pw.SizedBox(height: 12),
          _pdfSection('PRONOSTICO:'),
          _pdfParagraph(
            'Reservado a la evolución clínica y a la respuesta al plan de intervención definido por el profesional responsable.',
          ),
          pw.SizedBox(height: 22),
          _pdfParagraph(
            'Se expide el presente informe a solicitud del interesado(a).',
          ),
          pw.SizedBox(height: 34),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Fecha de expedición: $fechaDocumento',
              style: const pw.TextStyle(fontSize: 10),
            ),
          ),
          pw.SizedBox(height: 42),
          pw.Align(
            alignment: pw.Alignment.center,
            child: pw.Column(
              children: [
                pw.Container(width: 190, height: 1, color: PdfColors.black),
                pw.SizedBox(height: 6),
                pw.Text(
                  solicitud.profesional,
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'Profesional evaluador',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    return pdf.save();
  }

  pw.Widget _pdfPatientHeader(
    ReporteCognitivoModel reporte,
    SolicitudReporteCognitivoModel solicitud,
  ) {
    return pw.Column(
      children: [
        pw.Row(
          children: [
            _pdfInfoCell('PROFESIONAL', solicitud.profesional),
            _pdfInfoCell('PACIENTE', reporte.nombrePaciente),
          ],
        ),
        pw.SizedBox(height: 6),
        pw.Row(
          children: [
            _pdfInfoCell('DOCUMENTO / ID', reporte.pacienteId),
            _pdfInfoCell('EDAD', '${solicitud.edadPaciente} años'),
          ],
        ),
        pw.SizedBox(height: 6),
        pw.Row(
          children: [
            _pdfInfoCell('FECHA EVALUACIÓN', reporte.fechaEvaluacion),
            _pdfInfoCell('TIPO DE INFORME', 'Neuropsicológico'),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Divider(thickness: 0.8),
      ],
    );
  }

  pw.Widget _pdfInfoCell(String label, String value) {
    return pw.Expanded(
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 92,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Text(
            ':  ',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value.isBlank ? 'No registrado' : value,
              style: const pw.TextStyle(fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfSection(String title) {
    return pw.Container(
      color: PdfColors.yellow200,
      padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 1),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 10.5,
          fontWeight: pw.FontWeight.bold,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  pw.Widget _pdfParagraph(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 8),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.justify,
        style: const pw.TextStyle(fontSize: 10.5, height: 1.35),
      ),
    );
  }

  pw.Widget _pdfTestsTable(List<PruebaCognitivaModel> pruebas) {
    if (pruebas.isEmpty) {
      return _pdfParagraph(
        'No se registraron pruebas cognitivas en esta evaluación.',
      );
    }

    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 8),
      child: pw.TableHelper.fromTextArray(
        headerDecoration: const pw.BoxDecoration(color: PdfColors.grey800),
        headerStyle: pw.TextStyle(
          color: PdfColors.white,
          fontWeight: pw.FontWeight.bold,
          fontSize: 9.5,
        ),
        cellStyle: const pw.TextStyle(fontSize: 9),
        cellAlignment: pw.Alignment.centerLeft,
        cellHeight: 24,
        columnWidths: {
          0: const pw.FlexColumnWidth(2.3),
          1: const pw.FlexColumnWidth(1),
          2: const pw.FlexColumnWidth(1),
        },
        data: [
          ['Prueba', 'Resultado', 'Tiempo'],
          ...pruebas.map(
            (prueba) => [
              prueba.nombrePrueba,
              '${prueba.porcentajeObtenido.toStringAsFixed(1)}%',
              '${prueba.tiempoSegundos}s',
            ],
          ),
        ],
      ),
    );
  }
}

class _DatosPacienteCard extends StatelessWidget {
  const _DatosPacienteCard({
    required this.reporte,
    required this.solicitud,
  });

  final ReporteCognitivoModel reporte;
  final SolicitudReporteCognitivoModel solicitud;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            _InfoLine(label: 'Profesional', value: solicitud.profesional),
            _InfoLine(label: 'Paciente', value: reporte.nombrePaciente),
            _InfoLine(label: 'Documento / ID', value: reporte.pacienteId),
            _InfoLine(label: 'Edad', value: '${solicitud.edadPaciente} años'),
            _InfoLine(
              label: 'Fecha evaluación',
              value: reporte.fechaEvaluacion,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          const Text(':  '),
          Expanded(child: Text(value.isBlank ? 'No registrado' : value)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.yellow.shade200,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w900,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

extension on String {
  bool get isBlank => trim().isEmpty;
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
