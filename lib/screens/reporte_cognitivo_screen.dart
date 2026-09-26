import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/reporte_cognitivo_model.dart';
import '../services/reporte_cognitivo_service.dart';

const _kAzul = Color(0xFF1A3A6B);
const _pdfAzul = PdfColor.fromInt(0xFF1A3A6B);

const _kAviso =
    'Documento de apoyo clínico. No reemplaza una valoración médica integral '
    'ni el criterio del profesional responsable.';

/// Secciones de reportes antiguos cuyo contenido ya se muestra en la cabecera,
/// el resumen de resultados o el aviso legal.
const _seccionesRedundantes = {
  'DATOS DE LA EVALUACIÓN',
  'RESUMEN CUANTITATIVO',
  'NOTA ÉTICA Y ALCANCE',
};

/// Detecta líneas del tipo "Memoria: 80.0% (ALTO), ..." para resaltar la etiqueta.
final _etiquetaLinea = RegExp(r'^([^:]{2,40}):\s+(.+)$');

class ReporteCognitivoScreen extends StatefulWidget {
  const ReporteCognitivoScreen({
    super.key,
    required this.solicitud,
    this.preGeneratedReport,
  });

  final SolicitudReporteCognitivoModel solicitud;
  final ReporteCognitivoModel? preGeneratedReport;

  @override
  State<ReporteCognitivoScreen> createState() => _ReporteCognitivoScreenState();
}

class _ReporteCognitivoScreenState extends State<ReporteCognitivoScreen> {
  late final Future<ReporteCognitivoModel> _reporteFuture;
  final _servicio = ReporteCognitivoService();

  @override
  void initState() {
    super.initState();
    if (widget.preGeneratedReport != null) {
      _reporteFuture = Future.value(widget.preGeneratedReport);
    } else {
      _reporteFuture = _servicio.generarReporte(widget.solicitud);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: _kAzul,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: const Text(
          'Reporte Neuropsicológico',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: Colors.white),
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
          final pruebas = widget.solicitud.pruebas;

          return LayoutBuilder(
            builder: (context, constraints) {
              // Contenido centrado con ancho máximo en pantallas grandes.
              final margen = constraints.maxWidth > 792
                  ? (constraints.maxWidth - 760) / 2
                  : 16.0;

              return ListView(
                padding: EdgeInsets.fromLTRB(margen, 16, margen, 32),
                children: [
                  _EncabezadoPaciente(reporte: reporte, solicitud: widget.solicitud),
                  if (pruebas.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _ResultadosCard(pruebas: pruebas),
                  ],
                  const SizedBox(height: 12),
                  _InformeCard(texto: reporte.reporte),
                  const SizedBox(height: 12),
                  const _AvisoLegal(),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () => _guardarReporte(reporte),
                          icon: const Icon(Icons.download_rounded),
                          label: const Text('Guardar'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: _kAzul,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () => _compartirReporte(reporte),
                          icon: const Icon(Icons.share_rounded),
                          label: const Text('Compartir'),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
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

  // ── PDF ──────────────────────────────────────────────────────────────────────

  Future<Uint8List> _crearPdf(ReporteCognitivoModel reporte) async {
    final pdf = pw.Document();
    final solicitud = widget.solicitud;
    final logoSvg = await _loadLogoSvg();
    final hoy = DateTime.now();
    final fechaDocumento =
        '${hoy.day.toString().padLeft(2, '0')}/${hoy.month.toString().padLeft(2, '0')}/${hoy.year}';
    final secciones = _seccionesInforme(reporte.reporte);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(48, 40, 48, 32),
        footer: _pdfPie,
        build: (context) => [
          _pdfDocumentHeader(logoSvg, solicitud),
          pw.SizedBox(height: 16),
          _pdfPatientHeader(reporte, solicitud),
          if (solicitud.pruebas.isNotEmpty) ...[
            pw.SizedBox(height: 18),
            _pdfSection('Resultados'),
            _pdfSummary(solicitud.pruebas),
            _pdfResultsTable(solicitud.pruebas),
          ],
          if (secciones.isEmpty) ...[
            pw.SizedBox(height: 18),
            _pdfLinea(reporte.reporte),
          ] else
            for (final seccion in secciones) ...[
              pw.SizedBox(height: 16),
              _pdfSection(_tituloLegible(seccion.title)),
              for (final linea in seccion.lines) _pdfLinea(linea),
            ],
          pw.SizedBox(height: 18),
          _pdfAviso(),
          pw.SizedBox(height: 44),
          _pdfFirma(solicitud.profesional, fechaDocumento),
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
    return pw.Column(
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            if (logoSvg != null) ...[
              pw.SvgImage(svg: logoSvg, width: 36, height: 36),
              pw.SizedBox(width: 10),
            ],
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    solicitud.institucion.blankFallback('NeuroApp360'),
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: _pdfAzul,
                    ),
                  ),
                  pw.Text(
                    'Evaluación cognitiva asistida por NeuroApp360',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                  ),
                ],
              ),
            ),
            pw.Text(
              'INFORME NEUROPSICOLÓGICO',
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: _pdfAzul,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Container(height: 1.5, color: _pdfAzul),
      ],
    );
  }

  pw.Widget _pdfPatientHeader(
    ReporteCognitivoModel reporte,
    SolicitudReporteCognitivoModel solicitud,
  ) {
    final telefono = solicitud.telefonoPaciente.blankFallback('');
    final antecedente = solicitud.diagnosticoPaciente.blankFallback('');
    final datos = <(String, String)>[
      ('Paciente', reporte.nombrePaciente),
      ('Documento / ID', solicitud.documentoPaciente.blankFallback(reporte.pacienteId)),
      ('Edad', '${solicitud.edadPaciente} años'),
      ('Fecha de evaluación', reporte.fechaEvaluacion),
      ('Profesional', solicitud.profesional),
      ('Institución', solicitud.institucion.blankFallback('NeuroApp360')),
      if (telefono.isNotEmpty) ('Teléfono', telefono),
      if (antecedente.isNotEmpty) ('Antecedente', antecedente),
    ];

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: const pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        children: [
          for (var i = 0; i < datos.length; i += 2)
            pw.Padding(
              padding: pw.EdgeInsets.only(top: i == 0 ? 0 : 8),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _pdfInfoCell(datos[i].$1, datos[i].$2),
                  if (i + 1 < datos.length)
                    _pdfInfoCell(datos[i + 1].$1, datos[i + 1].$2)
                  else
                    pw.Expanded(child: pw.SizedBox()),
                ],
              ),
            ),
        ],
      ),
    );
  }

  pw.Widget _pdfInfoCell(String label, String value) {
    return pw.Expanded(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label.toUpperCase(),
            style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600, letterSpacing: 0.4),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            value.isBlank ? 'No registrado' : value,
            style: const pw.TextStyle(fontSize: 10.5),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfSection(String title) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 6),
      padding: const pw.EdgeInsets.only(left: 6),
      decoration: pw.BoxDecoration(
        border: pw.Border(left: pw.BorderSide(color: _pdfAzul, width: 2.5)),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 11.5,
          fontWeight: pw.FontWeight.bold,
          color: _pdfAzul,
        ),
      ),
    );
  }

  pw.Widget _pdfLinea(String linea) {
    final texto = linea.replaceAll('—', '-').replaceAll('–', '-');
    final match = _etiquetaLinea.firstMatch(texto);
    const estilo = pw.TextStyle(fontSize: 10.5, lineSpacing: 2);

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: match == null
          ? pw.Text(texto, style: estilo, textAlign: pw.TextAlign.justify)
          : pw.RichText(
              textAlign: pw.TextAlign.justify,
              text: pw.TextSpan(
                style: estilo,
                children: [
                  pw.TextSpan(
                    text: '${match.group(1)}: ',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.TextSpan(text: match.group(2)),
                ],
              ),
            ),
    );
  }

  pw.Widget _pdfSummary(List<PruebaCognitivaModel> pruebas) {
    final promedio = _promedioResultados(pruebas);
    final nivel = _nivelResultado(promedio);

    return pw.Row(
      children: [
        _pdfSummaryBox('Promedio global', '${promedio.toStringAsFixed(1)}%'),
        pw.SizedBox(width: 8),
        _pdfSummaryBox('Nivel global', nivel, color: _pdfColorNivel(nivel)),
        pw.SizedBox(width: 8),
        _pdfSummaryBox('Pruebas aplicadas', '${pruebas.length}'),
      ],
    );
  }

  pw.Widget _pdfSummaryBox(
    String label,
    String value, {
    PdfColor color = PdfColors.black,
  }) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300, width: 0.8),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
            pw.SizedBox(height: 2),
            pw.Text(
              value,
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _pdfResultsTable(List<PruebaCognitivaModel> pruebas) {
    const encabezado = pw.TextStyle(fontSize: 8, color: PdfColors.grey700);

    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 10),
      child: pw.Column(
        children: [
          pw.Row(
            children: [
              pw.SizedBox(width: 138, child: pw.Text('Prueba', style: encabezado)),
              pw.Expanded(child: pw.SizedBox()),
              pw.SizedBox(
                width: 44,
                child: pw.Text('Puntaje', style: encabezado, textAlign: pw.TextAlign.right),
              ),
              pw.SizedBox(
                width: 50,
                child: pw.Text('Nivel', style: encabezado, textAlign: pw.TextAlign.center),
              ),
              pw.SizedBox(
                width: 40,
                child: pw.Text('Tiempo', style: encabezado, textAlign: pw.TextAlign.right),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Container(height: 0.5, color: PdfColors.grey400),
          for (final prueba in pruebas) _pdfFilaPrueba(prueba),
        ],
      ),
    );
  }

  pw.Widget _pdfFilaPrueba(PruebaCognitivaModel prueba) {
    final valor = prueba.porcentajeObtenido.clamp(0, 100).toDouble();
    final nivel = _nivelResultado(valor);
    final color = _pdfColorNivel(nivel);

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 6),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5)),
      ),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 130,
            child: pw.Text(prueba.nombrePrueba, style: const pw.TextStyle(fontSize: 9.5)),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.LayoutBuilder(
              builder: (context, constraints) {
                return pw.Container(
                  height: 7,
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.grey200,
                    borderRadius: pw.BorderRadius.all(pw.Radius.circular(3.5)),
                  ),
                  child: pw.Align(
                    alignment: pw.Alignment.centerLeft,
                    child: pw.Container(
                      width: constraints!.maxWidth * valor / 100,
                      height: 7,
                      decoration: pw.BoxDecoration(
                        color: color,
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3.5)),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          pw.SizedBox(
            width: 44,
            child: pw.Text(
              '${valor.toStringAsFixed(1)}%',
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(
            width: 50,
            child: pw.Text(
              nivel,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: color),
            ),
          ),
          pw.SizedBox(
            width: 40,
            child: pw.Text(
              _formatearTiempo(prueba.tiempoSegundos),
              textAlign: pw.TextAlign.right,
              style: const pw.TextStyle(fontSize: 9),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfAviso() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400, width: 0.6),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Text(
        _kAviso,
        style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700),
      ),
    );
  }

  pw.Widget _pdfFirma(String profesional, String fecha) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Text('Fecha de expedición: $fecha', style: const pw.TextStyle(fontSize: 9.5)),
        pw.Column(
          children: [
            pw.Container(width: 180, height: 0.8, color: PdfColors.black),
            pw.SizedBox(height: 4),
            pw.Text(
              profesional,
              style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              'Profesional evaluador',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _pdfPie(pw.Context context) {
    const estilo = pw.TextStyle(fontSize: 8, color: PdfColors.grey600);
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 12),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('NeuroApp360', style: estilo),
          pw.Text('Página ${context.pageNumber} de ${context.pagesCount}', style: estilo),
        ],
      ),
    );
  }
}

// ── Widgets de pantalla ─────────────────────────────────────────────────────────

class _Tarjeta extends StatelessWidget {
  const _Tarjeta({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: child,
    );
  }
}

class _EncabezadoPaciente extends StatelessWidget {
  const _EncabezadoPaciente({required this.reporte, required this.solicitud});

  final ReporteCognitivoModel reporte;
  final SolicitudReporteCognitivoModel solicitud;

  @override
  Widget build(BuildContext context) {
    final documento = solicitud.documentoPaciente.blankFallback(reporte.pacienteId);
    final institucion = solicitud.institucion.blankFallback('');
    final antecedente = solicitud.diagnosticoPaciente.blankFallback('');
    final detalles = <(IconData, String)>[
      (Icons.event_outlined, reporte.fechaEvaluacion),
      (Icons.person_outline_rounded, solicitud.profesional),
      if (institucion.isNotEmpty) (Icons.local_hospital_outlined, institucion),
      if (antecedente.isNotEmpty) (Icons.medical_information_outlined, antecedente),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [_kAzul, Color(0xFF2B5C9E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: Colors.white.withValues(alpha: 0.18),
                child: Text(
                  _iniciales(reporte.nombrePaciente),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reporte.nombrePaciente,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${solicitud.edadPaciente} años  ·  ID $documento',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              for (final (icono, texto) in detalles)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icono, size: 16, color: Colors.white70),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        texto,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResultadosCard extends StatelessWidget {
  const _ResultadosCard({required this.pruebas});

  final List<PruebaCognitivaModel> pruebas;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final promedio = _promedioResultados(pruebas);
    final nivel = _nivelResultado(promedio);
    final color = _colorNivel(nivel);
    final secundario = theme.colorScheme.onSurfaceVariant;

    return _Tarjeta(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SizedBox(
                width: 78,
                height: 78,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: promedio.clamp(0, 100) / 100,
                      strokeWidth: 8,
                      strokeCap: StrokeCap.round,
                      backgroundColor: color.withValues(alpha: 0.15),
                      color: color,
                    ),
                    Center(
                      child: Text(
                        '${promedio.round()}%',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rendimiento global',
                      style: theme.textTheme.labelLarge?.copyWith(color: secundario),
                    ),
                    const SizedBox(height: 6),
                    _NivelBadge(nivel: nivel),
                    const SizedBox(height: 8),
                    Text(
                      '${pruebas.length} ${pruebas.length == 1 ? 'prueba' : 'pruebas'}  ·  '
                      '${_contarNivel(pruebas, 'ALTO')} alto  ·  '
                      '${_contarNivel(pruebas, 'MEDIO')} medio  ·  '
                      '${_contarNivel(pruebas, 'BAJO')} bajo',
                      style: theme.textTheme.bodySmall?.copyWith(color: secundario),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: theme.colorScheme.outlineVariant),
          const SizedBox(height: 4),
          for (final prueba in pruebas) _FilaPrueba(prueba: prueba),
        ],
      ),
    );
  }
}

class _FilaPrueba extends StatelessWidget {
  const _FilaPrueba({required this.prueba});

  final PruebaCognitivaModel prueba;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final valor = prueba.porcentajeObtenido.clamp(0, 100).toDouble();
    final nivel = _nivelResultado(valor);
    final color = _colorNivel(nivel);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prueba.nombrePrueba,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      _formatearTiempo(prueba.tiempoSegundos),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${valor.toStringAsFixed(1)}%',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(width: 10),
              _NivelBadge(nivel: nivel),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: valor / 100,
              minHeight: 8,
              backgroundColor: color.withValues(alpha: 0.15),
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _NivelBadge extends StatelessWidget {
  const _NivelBadge({required this.nivel});

  final String nivel;

  @override
  Widget build(BuildContext context) {
    final color = _colorNivel(nivel);
    return Container(
      width: 64,
      padding: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        nivel,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

/// Texto del informe dividido en secciones con icono y título.
class _InformeCard extends StatelessWidget {
  const _InformeCard({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secciones = _seccionesInforme(texto);

    return _Tarjeta(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informe clínico',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          if (secciones.isEmpty) ...[
            const SizedBox(height: 12),
            SelectableText(texto, style: theme.textTheme.bodyMedium?.copyWith(height: 1.5)),
          ] else
            for (final seccion in secciones) _SeccionInforme(seccion: seccion),
        ],
      ),
    );
  }
}

class _SeccionInforme extends StatelessWidget {
  const _SeccionInforme({required this.seccion});

  final _ReportSection seccion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final acento = theme.colorScheme.primary;
    final estilo = theme.textTheme.bodyMedium?.copyWith(height: 1.5);

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: acento.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_iconoSeccion(seccion.title), size: 18, color: acento),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _tituloLegible(seccion.title),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: acento,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final linea in seccion.lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: SelectableText.rich(_lineaConEtiqueta(linea, estilo)),
            ),
        ],
      ),
    );
  }
}

class _AvisoLegal extends StatelessWidget {
  const _AvisoLegal();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline_rounded, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(_kAviso, style: theme.textTheme.bodySmall?.copyWith(color: color)),
        ),
      ],
    );
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
              'Generando el reporte neuropsicológico...',
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

// ── Utilidades ─────────────────────────────────────────────────────────────────

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
  const _ReportSection({required this.title, required this.lines});

  /// Título en MAYÚSCULAS, sin los dos puntos finales.
  final String title;
  final List<String> lines;
}

List<_ReportSection> _splitReportSections(String text) {
  final lines = text
      .split(RegExp(r'\r?\n'))
      // Limpia marcas de formato que a veces devuelve el modelo (**, ##, viñetas).
      .map(
        (line) => line
            .replaceAll('**', '')
            .replaceFirst(RegExp(r'^\s*#+\s*'), '')
            .replaceFirst(RegExp(r'^\s*[-*•]\s+'), '')
            .trim(),
      )
      .where((line) => line.isNotEmpty)
      .toList();
  final sections = <_ReportSection>[];
  String? currentTitle;
  var buffer = <String>[];

  for (final line in lines) {
    final isHeading =
        line.endsWith(':') &&
        line.length <= 80 &&
        line.toUpperCase() == line;
    if (isHeading) {
      if (currentTitle != null && buffer.isNotEmpty) {
        sections.add(_ReportSection(title: currentTitle, lines: buffer));
      }
      currentTitle = line.substring(0, line.length - 1).trim();
      buffer = <String>[];
    } else {
      buffer.add(line);
    }
  }

  if (currentTitle != null && buffer.isNotEmpty) {
    sections.add(_ReportSection(title: currentTitle, lines: buffer));
  }

  return sections;
}

/// Secciones a mostrar, omitiendo las que duplican información ya visible.
List<_ReportSection> _seccionesInforme(String texto) {
  return _splitReportSections(texto)
      .where((s) => !_seccionesRedundantes.contains(s.title))
      .toList();
}

/// "RESULTADOS POR DOMINIO" -> "Resultados por dominio".
String _tituloLegible(String titulo) {
  final t = titulo.toLowerCase();
  return t.isEmpty ? t : t[0].toUpperCase() + t.substring(1);
}

IconData _iconoSeccion(String titulo) {
  if (titulo.contains('RESUMEN')) return Icons.summarize_outlined;
  if (titulo.contains('RESULTADO')) return Icons.insights_rounded;
  if (titulo.contains('INTERPRETACI')) return Icons.psychology_outlined;
  if (titulo.contains('RECOMENDACI')) return Icons.checklist_rounded;
  if (titulo.contains('CONCLUSI')) return Icons.flag_outlined;
  if (titulo.contains('ANTECEDENTE')) return Icons.history_edu_outlined;
  return Icons.article_outlined;
}

TextSpan _lineaConEtiqueta(String linea, TextStyle? estilo) {
  final match = _etiquetaLinea.firstMatch(linea);
  if (match == null) return TextSpan(text: linea, style: estilo);
  return TextSpan(
    style: estilo,
    children: [
      TextSpan(
        text: '${match.group(1)}: ',
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      TextSpan(text: match.group(2)),
    ],
  );
}

String _iniciales(String nombre) {
  final partes = nombre.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
  return partes.take(2).map((p) => p[0].toUpperCase()).join();
}

String _formatearTiempo(int segundos) {
  if (segundos < 60) return '${segundos}s';
  final resto = (segundos % 60).toString().padLeft(2, '0');
  return '${segundos ~/ 60}m ${resto}s';
}

String _nivelResultado(double porcentaje) {
  if (porcentaje <= 40) return 'BAJO';
  if (porcentaje <= 69) return 'MEDIO';
  return 'ALTO';
}

Color _colorNivel(String nivel) {
  return switch (nivel) {
    'BAJO' => Colors.red.shade700,
    'MEDIO' => Colors.amber.shade800,
    _ => Colors.green.shade700,
  };
}

PdfColor _pdfColorNivel(String nivel) {
  return switch (nivel) {
    'BAJO' => PdfColors.red700,
    'MEDIO' => PdfColors.amber800,
    _ => PdfColors.green700,
  };
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
