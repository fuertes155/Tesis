import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final colorScheme = tema.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3A6B),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Reporte Neuropsicológico',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        centerTitle: false,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Datos del paciente ────────────────────────────────────
                _DatosPacienteCard(
                  reporte: reporte,
                  solicitud: widget.solicitud,
                ),
                const SizedBox(height: 2),
                // ── Métricas resumen ──────────────────────────────────
                if (widget.solicitud.pruebas.isNotEmpty) ...[
                  _ResumenResultadosCard(pruebas: widget.solicitud.pruebas),
                  const SizedBox(height: 2),
                  _ResultsBarsCard(pruebas: widget.solicitud.pruebas),
                  const SizedBox(height: 2),
                ],
                // ── Contenido del informe ──────────────────────────────
                _ReporteContenidoCard(reporte: reporte),
                const SizedBox(height: 2),
                // ── Pruebas aplicadas ─────────────────────────────────
                _PruebasAplicadasCard(pruebas: widget.solicitud.pruebas),
                const SizedBox(height: 16),
                // ── Botones ───────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF1A3A6B),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () => _compartirReporte(reporte),
                          icon: const Icon(Icons.ios_share_rounded),
                          label: const Text('Compartir'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: Color(0xFF1A3A6B), width: 1.5),
                            foregroundColor: const Color(0xFF1A3A6B),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () => _guardarReporte(reporte),
                          icon: const Icon(Icons.picture_as_pdf_rounded),
                          label: const Text('Guardar PDF'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
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
    final logoSvg = await _loadLogoSvg();
    final fechaGeneracion = DateTime.now();
    final fechaDocumento =
        '${fechaGeneracion.day.toString().padLeft(2, '0')}/${fechaGeneracion.month.toString().padLeft(2, '0')}/${fechaGeneracion.year}';

    if (_requierePortada(reporte, solicitud)) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(54, 54, 54, 54),
          build: (context) => _pdfCoverPage(
            reporte: reporte,
            solicitud: solicitud,
            fechaDocumento: fechaDocumento,
            logoSvg: logoSvg,
          ),
        ),
      );
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(54, 44, 54, 44),
        build: (context) => [
          _pdfDocumentHeader(logoSvg, solicitud),
          pw.SizedBox(height: 22),
          _pdfPatientHeader(reporte, solicitud),
          pw.SizedBox(height: 18),
          _pdfSection('RESUMEN CUANTITATIVO:'),
          _pdfSummary(solicitud.pruebas),
          pw.SizedBox(height: 12),
          _pdfSection('GRÁFICO DE DESEMPEÑO POR PRUEBA:'),
          _pdfBarsChart(solicitud.pruebas),
          pw.SizedBox(height: 12),
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
          ..._pdfStructuredReport(reporte.reporte),
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
          pw.SizedBox(height: 12),
          _pdfSection('NOTA ÉTICA Y ALCANCE:'),
          _pdfParagraph(
            'Este informe no reemplaza una valoración médica integral. Debe interpretarse junto con la historia clínica, la entrevista clínica, la observación funcional y el criterio del profesional responsable.',
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

  Future<String?> _loadLogoSvg() async {
    try {
      final svg = await rootBundle.loadString('assets/svg/hospital_logo.svg');
      return svg.replaceAll('currentColor', '#1565C0');
    } catch (_) {
      return null;
    }
  }

  pw.Widget _pdfDocumentHeader(
    String? logoSvg,
    SolicitudReporteCognitivoModel solicitud,
  ) {
    final institution = solicitud.institucion.blankFallback('NeuroApp360');

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        if (logoSvg != null)
          pw.SvgImage(svg: logoSvg, width: 42, height: 42)
        else
          pw.Container(
            width: 42,
            height: 42,
            alignment: pw.Alignment.center,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.blue800, width: 1.2),
              shape: pw.BoxShape.circle,
            ),
            child: pw.Text(
              '+',
              style: pw.TextStyle(
                color: PdfColors.blue800,
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        pw.SizedBox(width: 12),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                institution,
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
              pw.Text(
                'Evaluación cognitiva asistida por NeuroApp360',
                style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.grey700),
              ),
            ],
          ),
        ),
        pw.Text(
          'INFORME NEUROPSICOLÓGICO',
          style: pw.TextStyle(
            fontSize: 15,
            fontWeight: pw.FontWeight.bold,
            decoration: pw.TextDecoration.underline,
          ),
        ),
      ],
    );
  }

  pw.Widget _pdfCoverPage({
    required ReporteCognitivoModel reporte,
    required SolicitudReporteCognitivoModel solicitud,
    required String fechaDocumento,
    required String? logoSvg,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Align(
          alignment: pw.Alignment.center,
          child: logoSvg != null
              ? pw.SvgImage(svg: logoSvg, width: 76, height: 76)
              : pw.Text(
                  'NEUROAPP360',
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
        ),
        pw.SizedBox(height: 54),
        pw.Center(
          child: pw.Text(
            'INFORME NEUROPSICOLÓGICO',
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.SizedBox(height: 18),
        pw.Center(
          child: pw.Text(
            solicitud.institucion.blankFallback('NeuroApp360'),
            style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
          ),
        ),
        pw.Spacer(),
        _pdfCoverInfo('Paciente', reporte.nombrePaciente),
        _pdfCoverInfo('Documento / ID', reporte.pacienteId),
        _pdfCoverInfo('Edad', '${solicitud.edadPaciente} años'),
        _pdfCoverInfo('Profesional', solicitud.profesional),
        _pdfCoverInfo('Fecha de evaluación', reporte.fechaEvaluacion),
        _pdfCoverInfo('Fecha de expedición', fechaDocumento),
        pw.Spacer(),
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey500, width: 0.7),
          ),
          child: pw.Text(
            'Documento clínico de apoyo. No reemplaza una valoración médica integral.',
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
        ),
      ],
    );
  }

  pw.Widget _pdfCoverInfo(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 5),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 130,
            child: pw.Text(
              label.toUpperCase(),
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(
            child: pw.Text(value.blankFallback('No registrado'), style: const pw.TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
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
            _pdfInfoCell(
              'DOCUMENTO / ID',
              solicitud.documentoPaciente.blankFallback(reporte.pacienteId),
            ),
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
        pw.SizedBox(height: 6),
        pw.Row(
          children: [
            _pdfInfoCell('TELÉFONO', solicitud.telefonoPaciente.blankFallback('No registrado')),
            _pdfInfoCell('INSTITUCIÓN', solicitud.institucion.blankFallback('NeuroApp360')),
          ],
        ),
        pw.SizedBox(height: 6),
        pw.Row(
          children: [
            _pdfInfoCell(
              'ANTECEDENTE',
              solicitud.diagnosticoPaciente.blankFallback('No registrado'),
            ),
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
          3: const pw.FlexColumnWidth(1),
        },
        data: [
          ['Prueba', 'Resultado', 'Nivel', 'Tiempo'],
          ...pruebas.map(
            (prueba) => [
              prueba.nombrePrueba,
              '${prueba.porcentajeObtenido.toStringAsFixed(1)}%',
              _nivelResultado(prueba.porcentajeObtenido),
              '${prueba.tiempoSegundos}s',
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfBarsChart(List<PruebaCognitivaModel> pruebas) {
    if (pruebas.isEmpty) {
      return _pdfParagraph('No hay resultados suficientes para graficar.');
    }

    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 8),
      child: pw.Column(
        children: pruebas.map((prueba) {
          final value = prueba.porcentajeObtenido.clamp(0, 100).toDouble();
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 7),
            child: pw.Row(
              children: [
                pw.SizedBox(
                  width: 120,
                  child: pw.Text(prueba.nombrePrueba, style: const pw.TextStyle(fontSize: 8.5)),
                ),
                pw.Expanded(
                  child: pw.LayoutBuilder(
                    builder: (context, constraints) {
                      final barWidth = constraints!.maxWidth * value / 100;
                      return pw.Container(
                        height: 9,
                        decoration: pw.BoxDecoration(
                          color: PdfColors.grey200,
                          border: pw.Border.all(
                            color: PdfColors.grey400,
                            width: 0.3,
                          ),
                        ),
                        child: pw.Align(
                          alignment: pw.Alignment.centerLeft,
                          child: pw.Container(
                            width: barWidth,
                            color: _pdfLevelColor(value),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.SizedBox(
                  width: 42,
                  child: pw.Text(
                    '${value.toStringAsFixed(1)}%',
                    textAlign: pw.TextAlign.right,
                    style: const pw.TextStyle(fontSize: 8.5),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  pw.Widget _pdfSummary(List<PruebaCognitivaModel> pruebas) {
    if (pruebas.isEmpty) {
      return _pdfParagraph('No hay resultados cuantitativos para resumir.');
    }

    final promedio = _promedioResultados(pruebas);

    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 8),
      child: pw.Row(
        children: [
          _pdfSummaryBox('Pruebas', '${pruebas.length}'),
          pw.SizedBox(width: 8),
          _pdfSummaryBox('Promedio', '${promedio.toStringAsFixed(1)}%'),
          pw.SizedBox(width: 8),
          _pdfSummaryBox('Alto', '${_contarNivel(pruebas, 'ALTO')}'),
          pw.SizedBox(width: 8),
          _pdfSummaryBox('Medio', '${_contarNivel(pruebas, 'MEDIO')}'),
          pw.SizedBox(width: 8),
          _pdfSummaryBox('Bajo', '${_contarNivel(pruebas, 'BAJO')}'),
        ],
      ),
    );
  }

  pw.Widget _pdfSummaryBox(String label, String value) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey500, width: 0.6),
          color: PdfColors.grey100,
        ),
        child: pw.Column(
          children: [
            pw.Text(
              label,
              style: const pw.TextStyle(
                fontSize: 8.5,
                color: PdfColors.grey700,
              ),
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              value,
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  List<pw.Widget> _pdfStructuredReport(String text) {
    final sections = _splitReportSections(text);
    if (sections.isEmpty) {
      return [_pdfParagraph(text)];
    }

    final widgets = <pw.Widget>[];
    for (final section in sections) {
      widgets
        ..add(_pdfSubsection(section.title))
        ..add(_pdfParagraph(section.body));
    }
    return widgets;
  }

  pw.Widget _pdfSubsection(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 8),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.blue900,
        ),
      ),
    );
  }
}

class _ResumenResultadosCard extends StatelessWidget {
  const _ResumenResultadosCard({required this.pruebas});

  final List<PruebaCognitivaModel> pruebas;

  @override
  Widget build(BuildContext context) {
    if (pruebas.isEmpty) {
      return const SizedBox.shrink();
    }

    final promedio = _promedioResultados(pruebas);

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _MetricChip(label: 'Pruebas', value: '${pruebas.length}'),
        _MetricChip(
          label: 'Promedio',
          value: '${promedio.toStringAsFixed(1)}%',
        ),
        _MetricChip(label: 'Alto', value: '${_contarNivel(pruebas, 'ALTO')}'),
        _MetricChip(label: 'Medio', value: '${_contarNivel(pruebas, 'MEDIO')}'),
        _MetricChip(label: 'Bajo', value: '${_contarNivel(pruebas, 'BAJO')}'),
      ],
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 112,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultsBarsCard extends StatelessWidget {
  const _ResultsBarsCard({required this.pruebas});

  final List<PruebaCognitivaModel> pruebas;

  @override
  Widget build(BuildContext context) {
    if (pruebas.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('GRÁFICO DE DESEMPEÑO:'),
        const SizedBox(height: 10),
        ...pruebas.map((prueba) {
          final value = prueba.porcentajeObtenido.clamp(0, 100).toDouble();
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 118,
                  child: Text(
                    prueba.nombrePrueba,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: value / 100,
                      minHeight: 10,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      color: _levelColor(context, value),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 48,
                  child: Text(
                    '${value.toStringAsFixed(1)}%',
                    textAlign: TextAlign.right,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _StructuredReportView extends StatelessWidget {
  const _StructuredReportView({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sections = _splitReportSections(text);

    if (sections.isEmpty) {
      return SelectableText(
        text,
        style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sections.map((section) {
        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                section.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 6),
              SelectableText(
                section.body,
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
              ),
            ],
          ),
        );
      }).toList(),
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
            _InfoLine(
              label: 'Documento / ID',
              value: solicitud.documentoPaciente.blankFallback(
                reporte.pacienteId,
              ),
            ),
            _InfoLine(label: 'Edad', value: '${solicitud.edadPaciente} años'),
            _InfoLine(
              label: 'Teléfono',
              value: solicitud.telefonoPaciente.blankFallback('No registrado'),
            ),
            _InfoLine(
              label: 'Institución',
              value: solicitud.institucion.blankFallback('NeuroApp360'),
            ),
            _InfoLine(
              label: 'Antecedente',
              value: solicitud.diagnosticoPaciente.blankFallback(
                'No registrado',
              ),
            ),
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

// ────────────────────────────────────────────────────────────────────────────────────

/// Muestra el texto del informe generado, dividido en secciones con títulos.
class _ReporteContenidoCard extends StatelessWidget {
  const _ReporteContenidoCard({required this.reporte});

  final ReporteCognitivoModel reporte;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionTitle('INFORME NEUROPSICOLÓGICO:'),
              const SizedBox(height: 12),
              _StructuredReportView(text: reporte.reporte),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tabla de pruebas aplicadas con puntajes y niveles.
class _PruebasAplicadasCard extends StatelessWidget {
  const _PruebasAplicadasCard({required this.pruebas});

  final List<PruebaCognitivaModel> pruebas;

  @override
  Widget build(BuildContext context) {
    if (pruebas.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle('PRUEBAS APLICADAS:'),
            const SizedBox(height: 10),
            // Encabezado de tabla
            Row(
              children: [
                const Expanded(
                  flex: 4,
                  child: Text('Prueba', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                ),
                const SizedBox(
                  width: 60,
                  child: Text('Result.', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                ),
                const SizedBox(
                  width: 60,
                  child: Text('Nivel', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                ),
                const SizedBox(
                  width: 52,
                  child: Text('Tiempo', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                ),
              ],
            ),
            const Divider(height: 8),
            ...pruebas.map((prueba) {
              final nivel = _nivelResultado(prueba.porcentajeObtenido);
              final color = _levelColor(context, prueba.porcentajeObtenido);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Text(
                        prueba.nombrePrueba,
                        style: theme.textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(
                      width: 60,
                      child: Text(
                        '${prueba.porcentajeObtenido.toStringAsFixed(1)}%',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    SizedBox(
                      width: 60,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          nivel,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: color,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 52,
                      child: Text(
                        '${prueba.tiempoSegundos}s',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              );
            }),
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

extension on String? {
  String blankFallback(String fallback) {
    final value = this?.trim();
    return value == null || value.isEmpty ? fallback : value;
  }
}

class _ReportSection {
  const _ReportSection({required this.title, required this.body});

  final String title;
  final String body;
}

List<_ReportSection> _splitReportSections(String text) {
  final lines = text
      .split(RegExp(r'\r?\n'))
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();
  final sections = <_ReportSection>[];
  String? currentTitle;
  final buffer = <String>[];

  for (final line in lines) {
    final isHeading =
        line.endsWith(':') &&
        line.length <= 80 &&
        line.toUpperCase() == line;
    if (isHeading) {
      if (currentTitle != null && buffer.isNotEmpty) {
        sections.add(
          _ReportSection(title: currentTitle, body: buffer.join('\n')),
        );
      }
      currentTitle = line;
      buffer.clear();
    } else {
      buffer.add(line);
    }
  }

  if (currentTitle != null && buffer.isNotEmpty) {
    sections.add(_ReportSection(title: currentTitle, body: buffer.join('\n')));
  }

  return sections;
}

bool _requierePortada(
  ReporteCognitivoModel reporte,
  SolicitudReporteCognitivoModel solicitud,
) {
  return reporte.reporte.length > 1800 || solicitud.pruebas.length > 6;
}

PdfColor _pdfLevelColor(double value) {
  if (value <= 40) return PdfColors.red600;
  if (value <= 69) return PdfColors.amber700;
  return PdfColors.green700;
}

Color _levelColor(BuildContext context, double value) {
  if (value <= 40) return Colors.red.shade700;
  if (value <= 69) return Colors.amber.shade800;
  return Colors.green.shade700;
}

String _nivelResultado(double porcentaje) {
  if (porcentaje <= 40) return 'BAJO';
  if (porcentaje <= 69) return 'MEDIO';
  return 'ALTO';
}

double _promedioResultados(List<PruebaCognitivaModel> pruebas) {
  if (pruebas.isEmpty) return 0;
  final total = pruebas.fold<double>(
    0,
    (sum, prueba) => sum + prueba.porcentajeObtenido,
  );
  return total / pruebas.length;
}

int _contarNivel(List<PruebaCognitivaModel> pruebas, String nivel) {
  return pruebas
      .where((prueba) => _nivelResultado(prueba.porcentajeObtenido) == nivel)
      .length;
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
