import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../core/theme/app_theme.dart';
import '../models/reporte_cognitivo_model.dart';
import '../services/reporte_cognitivo_service.dart';

const _pdfAzul = PdfColor.fromInt(0xFF1E3A8A);

const _kAviso =
    'Documento de apoyo clínico. Los resultados deben interpretarse junto con la historia '
    'clínica, la entrevista y el criterio del profesional responsable; no reemplazan una '
    'valoración médica integral.';

/// Secciones de reportes antiguos cuyo contenido ya aparece en la ficha de
/// identificación, en la tabla de resultados o en el aviso legal.
const _seccionesRedundantes = {
  'DATOS DE LA EVALUACIÓN',
  'RESUMEN CUANTITATIVO',
  'NOTA ÉTICA Y ALCANCE',
};

/// Detecta líneas del tipo "Memoria: 80.0% (ALTO), ..." para separar la etiqueta.
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
    final cs = Theme.of(context).colorScheme;

    return FutureBuilder<ReporteCognitivoModel>(
      future: _reporteFuture,
      builder: (context, snapshot) {
        final terminado = snapshot.connectionState == ConnectionState.done;
        final reporte = terminado && snapshot.hasData ? snapshot.data : null;
        final ancho = MediaQuery.sizeOf(context).width;

        return Scaffold(
          backgroundColor: cs.surfaceContainer,
          appBar: AppBar(
            backgroundColor: cs.surfaceContainerLowest,
            shape: Border(bottom: BorderSide(color: cs.outlineVariant)),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              tooltip: 'Volver',
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/home');
                }
              },
            ),
            title: const Text('Informe neuropsicológico'),
            actions: [
              if (reporte != null) ...[
                if (ancho >= 700) ...[
                  OutlinedButton.icon(
                    onPressed: () => _guardarReporte(reporte),
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text('Descargar PDF'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () => _compartirReporte(reporte),
                    icon: const Icon(Icons.ios_share_rounded, size: 18),
                    label: const Text('Compartir'),
                  ),
                ] else ...[
                  IconButton(
                    tooltip: 'Descargar PDF',
                    onPressed: () => _guardarReporte(reporte),
                    icon: const Icon(Icons.download_rounded),
                  ),
                  IconButton(
                    tooltip: 'Compartir',
                    onPressed: () => _compartirReporte(reporte),
                    icon: const Icon(Icons.ios_share_rounded),
                  ),
                ],
              ],
              const SizedBox(width: 12),
            ],
          ),
          body: !terminado
              ? const _ReporteLoading()
              : snapshot.hasError
                  ? _ReporteError(mensaje: snapshot.error.toString())
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        const anchoDocumento = 880.0;
                        final margen = constraints.maxWidth > anchoDocumento + 48
                            ? (constraints.maxWidth - anchoDocumento) / 2
                            : (constraints.maxWidth < 600 ? 10.0 : 24.0);
                        return ListView(
                          padding: EdgeInsets.fromLTRB(margen, 24, margen, 40),
                          children: [
                            _Documento(reporte: reporte!, solicitud: widget.solicitud),
                          ],
                        );
                      },
                    ),
        );
      },
    );
  }

  Future<void> _guardarReporte(ReporteCognitivoModel reporte) async {
    final bytes = await _crearPdf(reporte);
    await Printing.layoutPdf(
      name: 'Informe_${reporte.pacienteId}.pdf',
      onLayout: (_) async => bytes,
    );
  }

  Future<void> _compartirReporte(ReporteCognitivoModel reporte) async {
    final bytes = await _crearPdf(reporte);
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'Informe_${reporte.pacienteId}.pdf',
    );
  }

  // ── PDF ──────────────────────────────────────────────────────────────────────

  Future<Uint8List> _crearPdf(ReporteCognitivoModel reporte) async {
    final pdf = pw.Document(theme: await _temaPdf());
    final solicitud = widget.solicitud;
    final logoSvg = await _loadLogoSvg();
    final secciones = _seccionesInforme(reporte.reporte);
    final indiceResultados = _indiceResultados(secciones);

    // Contenido numerado: la tabla de resultados va después de los instrumentos.
    final cuerpo = <pw.Widget>[];
    var numero = 0;
    void agregarResultados() {
      if (solicitud.pruebas.isEmpty) return;
      cuerpo
        ..add(pw.SizedBox(height: 16))
        ..add(_pdfSection('${++numero}. Resultados de la evaluación'))
        ..add(_pdfSummary(solicitud.pruebas))
        ..add(_pdfResultsTable(solicitud.pruebas));
    }

    if (indiceResultados < 0) agregarResultados();
    for (var i = 0; i < secciones.length; i++) {
      cuerpo
        ..add(pw.SizedBox(height: 16))
        ..add(_pdfSection('${++numero}. ${_tituloLegible(secciones[i].title)}'))
        ..add(_pdfCuerpo(secciones[i]));
      if (i == indiceResultados) agregarResultados();
    }
    if (secciones.isEmpty && reporte.reporte.trim().isNotEmpty) {
      cuerpo
        ..add(pw.SizedBox(height: 16))
        ..add(_pdfSection('${++numero}. Informe'))
        ..add(_pdfLinea(reporte.reporte));
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(48, 40, 48, 32),
        footer: _pdfPie,
        build: (context) => [
          _pdfDocumentHeader(logoSvg, reporte, solicitud),
          pw.SizedBox(height: 16),
          _pdfPatientHeader(reporte, solicitud),
          ...cuerpo,
          pw.SizedBox(height: 44),
          _pdfFirma(solicitud.profesional, _fechaLarga(reporte.createdAt)),
          pw.SizedBox(height: 20),
          _pdfAviso(),
        ],
      ),
    );
    return pdf.save();
  }

  /// Tipografía de la app en el PDF (con soporte Unicode completo).
  /// Si no hay conexión para descargarla, el PDF usa Helvetica.
  Future<pw.ThemeData?> _temaPdf() async {
    try {
      return pw.ThemeData.withFont(
        base: await PdfGoogleFonts.plusJakartaSansRegular(),
        bold: await PdfGoogleFonts.plusJakartaSansBold(),
      );
    } catch (_) {
      return null;
    }
  }

  Future<String?> _loadLogoSvg() async {
    try {
      final svg = await rootBundle.loadString('assets/svg/hospital_logo.svg');
      return svg.replaceAll('currentColor', '#1E3A8A');
    } catch (_) {
      return null;
    }
  }

  pw.Widget _pdfDocumentHeader(
    String? logoSvg,
    ReporteCognitivoModel reporte,
    SolicitudReporteCognitivoModel solicitud,
  ) {
    const gris = pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700);
    return pw.Column(
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            if (logoSvg != null) ...[
              pw.SvgImage(svg: logoSvg, width: 34, height: 34),
              pw.SizedBox(width: 10),
            ],
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    solicitud.institucion.blankFallback('NeuroApp360'),
                    style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: _pdfAzul),
                  ),
                  pw.Text('Evaluación neuropsicológica asistida - NeuroApp360', style: gris),
                ],
              ),
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'INFORME NEUROPSICOLÓGICO',
                  style: pw.TextStyle(
                    fontSize: 11.5,
                    fontWeight: pw.FontWeight.bold,
                    color: _pdfAzul,
                    letterSpacing: 0.6,
                  ),
                ),
                pw.Text('N.º ${_numeroInforme(reporte)}', style: gris),
              ],
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
    final datos = _datosIdentificacion(reporte, solicitud);

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400, width: 0.6),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        children: [
          for (var i = 0; i < datos.length; i += 2)
            pw.Container(
              decoration: i == 0
                  ? null
                  : pw.BoxDecoration(
                      border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.6)),
                    ),
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
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
            style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600, letterSpacing: 0.4),
          ),
          pw.SizedBox(height: 2),
          pw.Text(value, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  pw.Widget _pdfSection(String title) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.only(bottom: 4),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.6)),
      ),
      child: pw.Text(
        title.toUpperCase(),
        style: pw.TextStyle(
          fontSize: 10.5,
          fontWeight: pw.FontWeight.bold,
          color: _pdfAzul,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  pw.Widget _pdfCuerpo(_ReportSection seccion) {
    final lineas = pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: seccion.lines.map(_pdfLinea).toList(),
    );
    if (!seccion.title.contains('IMPRESIÓN')) return lineas;
    return pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(10, 8, 10, 4),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border(left: pw.BorderSide(color: _pdfAzul, width: 2.5)),
      ),
      child: lineas,
    );
  }

  pw.Widget _pdfLinea(String linea) {
    final texto = _textoSeguroPdf(linea);
    final match = _etiquetaLinea.firstMatch(texto);
    final estilo = pw.TextStyle(
      fontSize: 10,
      lineSpacing: 2.5,
      fontWeight: _esSeguimiento(texto) ? pw.FontWeight.bold : pw.FontWeight.normal,
    );

    if (match != null && match.group(1) == 'Categoría') {
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'CATEGORÍA DIAGNÓSTICA PRESUNTIVA',
              style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700, letterSpacing: 0.4),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              match.group(2)!,
              style: pw.TextStyle(fontSize: 11.5, fontWeight: pw.FontWeight.bold, color: _pdfAzul),
            ),
          ],
        ),
      );
    }

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: match == null
          ? pw.Text(texto, style: estilo, textAlign: pw.TextAlign.justify)
          : pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(
                  width: 130,
                  child: pw.Text(
                    match.group(1)!,
                    style: estilo.copyWith(fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.Expanded(
                  child: pw.Text(match.group(2)!, style: estilo, textAlign: pw.TextAlign.justify),
                ),
              ],
            ),
    );
  }

  pw.Widget _pdfSummary(List<PruebaCognitivaModel> pruebas) {
    final promedio = _promedioResultados(pruebas);
    final nivel = _nivelResultado(promedio);

    return pw.Row(
      children: [
        _pdfSummaryBox('Índice global', '${promedio.toStringAsFixed(1)}%'),
        pw.SizedBox(width: 8),
        _pdfSummaryBox(
          'Clasificación',
          '${_nivelLegible(nivel)} - ${_descriptorNivel(nivel)}',
          color: _pdfColorNivel(nivel),
          tamano: 11,
        ),
        pw.SizedBox(width: 8),
        _pdfSummaryBox('Pruebas aplicadas', '${pruebas.length}'),
      ],
    );
  }

  pw.Widget _pdfSummaryBox(
    String label,
    String value, {
    PdfColor color = PdfColors.black,
    double tamano = 14,
  }) {
    return pw.Expanded(
      child: pw.Container(
        height: 46,
        padding: const pw.EdgeInsets.symmetric(vertical: 7, horizontal: 10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300, width: 0.8),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Text(label.toUpperCase(), style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
            pw.SizedBox(height: 2),
            pw.Text(
              value,
              style: pw.TextStyle(fontSize: tamano, fontWeight: pw.FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _pdfResultsTable(List<PruebaCognitivaModel> pruebas) {
    const encabezado = pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700);

    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 10),
      child: pw.Column(
        children: [
          pw.Container(
            color: PdfColors.grey100,
            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            child: pw.Row(
              children: [
                pw.SizedBox(width: 132, child: pw.Text('PRUEBA', style: encabezado)),
                pw.Expanded(child: pw.Text('DESEMPEÑO', style: encabezado)),
                pw.SizedBox(
                  width: 44,
                  child: pw.Text('PUNTAJE', style: encabezado, textAlign: pw.TextAlign.right),
                ),
                pw.SizedBox(
                  width: 54,
                  child: pw.Text('NIVEL', style: encabezado, textAlign: pw.TextAlign.center),
                ),
                pw.SizedBox(
                  width: 40,
                  child: pw.Text('TIEMPO', style: encabezado, textAlign: pw.TextAlign.right),
                ),
              ],
            ),
          ),
          for (final prueba in pruebas) _pdfFilaPrueba(prueba),
          pw.SizedBox(height: 6),
          pw.Align(
            alignment: pw.Alignment.centerLeft,
            child: pw.Text(
              'Escala de referencia:  Bajo 0-40%   |   Medio 41-69%   |   Alto 70-100%',
              style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfFilaPrueba(PruebaCognitivaModel prueba) {
    final valor = prueba.porcentajeObtenido.clamp(0, 100).toDouble();
    final nivel = _nivelResultado(valor);
    final color = _pdfColorNivel(nivel);

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
      ),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 124,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(prueba.nombrePrueba, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                pw.Text(_dominio(prueba.nombrePrueba), style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
              ],
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.LayoutBuilder(
              builder: (context, constraints) {
                return pw.Container(
                  height: 6,
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.grey200,
                    borderRadius: pw.BorderRadius.all(pw.Radius.circular(3)),
                  ),
                  child: pw.Align(
                    alignment: pw.Alignment.centerLeft,
                    child: pw.Container(
                      width: constraints!.maxWidth * valor / 100,
                      height: 6,
                      decoration: pw.BoxDecoration(
                        color: color,
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
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
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(
            width: 54,
            child: pw.Text(
              _nivelLegible(nivel),
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: color),
            ),
          ),
          pw.SizedBox(
            width: 40,
            child: pw.Text(
              _formatearTiempo(prueba.tiempoSegundos),
              textAlign: pw.TextAlign.right,
              style: const pw.TextStyle(fontSize: 8.5),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfAviso() {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey400, width: 0.6)),
      ),
      child: pw.Text(
        _kAviso,
        style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700),
      ),
    );
  }

  pw.Widget _pdfFirma(String profesional, String fecha) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('FECHA DE EMISIÓN', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
            pw.Text(fecha, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
          ],
        ),
        pw.Column(
          children: [
            pw.Container(width: 190, height: 0.8, color: PdfColors.grey800),
            pw.SizedBox(height: 4),
            pw.Text(profesional, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
            pw.Text('Profesional evaluador', style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700)),
          ],
        ),
      ],
    );
  }

  pw.Widget _pdfPie(pw.Context context) {
    const estilo = pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600);
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 12),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Documento confidencial - NeuroApp360', style: estilo),
          pw.Text('Página ${context.pageNumber} de ${context.pagesCount}', style: estilo),
        ],
      ),
    );
  }
}

// ── Documento en pantalla ───────────────────────────────────────────────────────

/// Hoja del informe: membrete, ficha, secciones numeradas, firma y aviso.
class _Documento extends StatelessWidget {
  const _Documento({required this.reporte, required this.solicitud});

  final ReporteCognitivoModel reporte;
  final SolicitudReporteCognitivoModel solicitud;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final secciones = _seccionesInforme(reporte.reporte);
    final pruebas = solicitud.pruebas;
    final indiceResultados = _indiceResultados(secciones);

    // Contenido numerado: la tabla de resultados va después de los instrumentos.
    final bloques = <Widget>[];
    var numero = 0;
    void agregarResultados() {
      if (pruebas.isEmpty) return;
      bloques
        ..add(_TituloSeccion(numero: ++numero, titulo: 'Resultados de la evaluación'))
        ..add(_BloqueResultados(pruebas: pruebas));
    }

    if (indiceResultados < 0) agregarResultados();
    for (var i = 0; i < secciones.length; i++) {
      bloques
        ..add(_TituloSeccion(numero: ++numero, titulo: _tituloLegible(secciones[i].title)))
        ..add(_CuerpoSeccion(seccion: secciones[i]));
      if (i == indiceResultados) agregarResultados();
    }
    if (secciones.isEmpty && reporte.reporte.trim().isNotEmpty) {
      bloques
        ..add(_TituloSeccion(numero: ++numero, titulo: 'Informe'))
        ..add(SelectableText(reporte.reporte));
    }

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outlineVariant),
        boxShadow: context.premiumShadows,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final relleno = constraints.maxWidth >= 700 ? 44.0 : 20.0;
          return Padding(
            padding: EdgeInsets.all(relleno),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Membrete(reporte: reporte, solicitud: solicitud),
                const SizedBox(height: 28),
                const _Etiqueta('Datos de identificación'),
                const SizedBox(height: 10),
                _FichaIdentificacion(reporte: reporte, solicitud: solicitud),
                ...bloques,
                const SizedBox(height: 48),
                _Firma(profesional: solicitud.profesional, fecha: _fechaLarga(reporte.createdAt)),
                const SizedBox(height: 32),
                const _AvisoLegal(),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Membrete extends StatelessWidget {
  const _Membrete({required this.reporte, required this.solicitud});

  final ReporteCognitivoModel reporte;
  final SolicitudReporteCognitivoModel solicitud;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final institucion = Row(
      children: [
        Container(
          width: 46,
          height: 46,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: context.glass.headerGradient,
            borderRadius: BorderRadius.circular(10),
          ),
          child: SvgPicture.asset(
            'assets/svg/hospital_logo.svg',
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          ),
        ),
        const SizedBox(width: 14),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                solicitud.institucion.blankFallback('NeuroApp360'),
                style: theme.textTheme.titleMedium?.copyWith(color: cs.onSurface, fontWeight: FontWeight.w800),
              ),
              Text('Evaluación neuropsicológica asistida · NeuroApp360', style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );

    final titulo = Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'INFORME NEUROPSICOLÓGICO',
          style: theme.textTheme.labelLarge?.copyWith(color: AppColors.primaryDeep, letterSpacing: 1),
        ),
        const SizedBox(height: 2),
        Text('N.º ${_numeroInforme(reporte)}', style: theme.textTheme.bodySmall),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final angosto = constraints.maxWidth < 560;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (angosto) ...[
              institucion,
              const SizedBox(height: 14),
              Align(alignment: Alignment.centerLeft, child: titulo),
            ] else
              Row(children: [Expanded(child: institucion), const SizedBox(width: 16), titulo]),
            const SizedBox(height: 18),
            Container(height: 2, color: AppColors.primaryDeep),
          ],
        );
      },
    );
  }
}

class _Etiqueta extends StatelessWidget {
  const _Etiqueta(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      texto.toUpperCase(),
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        letterSpacing: 1,
      ),
    );
  }
}

class _FichaIdentificacion extends StatelessWidget {
  const _FichaIdentificacion({required this.reporte, required this.solicitud});

  final ReporteCognitivoModel reporte;
  final SolicitudReporteCognitivoModel solicitud;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final datos = _datosIdentificacion(reporte, solicitud);
    // El antecedente suele ser largo: ocupa una fila completa.
    final antecedente = datos.where((d) => d.$1 == 'Antecedente clínico').toList();
    final campos = datos.where((d) => d.$1 != 'Antecedente clínico').toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final columnas = constraints.maxWidth >= 680 ? 3 : (constraints.maxWidth >= 420 ? 2 : 1);
        final filas = <Widget>[];

        for (var i = 0; i < campos.length; i += columnas) {
          if (filas.isNotEmpty) filas.add(Divider(height: 1, color: cs.outlineVariant));
          filas.add(
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var j = 0; j < columnas; j++) ...[
                    if (j > 0) VerticalDivider(width: 1, color: cs.outlineVariant),
                    Expanded(
                      child: i + j < campos.length
                          ? _Campo(etiqueta: campos[i + j].$1, valor: campos[i + j].$2)
                          : const SizedBox(),
                    ),
                  ],
                ],
              ),
            ),
          );
        }
        for (final a in antecedente) {
          filas
            ..add(Divider(height: 1, color: cs.outlineVariant))
            ..add(_Campo(etiqueta: a.$1, valor: a.$2));
        }

        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: filas),
        );
      },
    );
  }
}

class _Campo extends StatelessWidget {
  const _Campo({required this.etiqueta, required this.valor});

  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            etiqueta.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 10,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 3),
          SelectableText(
            valor,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TituloSeccion extends StatelessWidget {
  const _TituloSeccion({required this.numero, required this.titulo});

  final int numero;
  final String titulo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 34, bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                '$numero.',
                style: theme.textTheme.titleSmall?.copyWith(color: AppColors.primaryDeep),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  titulo.toUpperCase(),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: cs.onSurface,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Divider(height: 1, color: cs.outlineVariant),
        ],
      ),
    );
  }
}

class _CuerpoSeccion extends StatelessWidget {
  const _CuerpoSeccion({required this.seccion});

  final _ReportSection seccion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final estilo = theme.textTheme.bodyMedium?.copyWith(
      color: cs.onSurface.withValues(alpha: 0.88),
      height: 1.65,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final ancho = constraints.maxWidth >= 600;
        final lineas = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final linea in seccion.lines)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _linea(context, linea, estilo, ancho),
              ),
          ],
        );
        if (!seccion.title.contains('IMPRESIÓN')) return lineas;
        // La impresión clínica es la conclusión principal: se destaca.
        return Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 6),
          decoration: BoxDecoration(
            color: AppColors.primaryDeep.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(8),
            border: const Border(left: BorderSide(color: AppColors.primaryDeep, width: 3)),
          ),
          child: lineas,
        );
      },
    );
  }

  Widget _linea(BuildContext context, String linea, TextStyle? estilo, bool ancho) {
    if (_esSeguimiento(linea)) return _NotaSeguimiento(texto: linea);

    final match = _etiquetaLinea.firstMatch(linea);
    if (match == null) return SelectableText(linea, style: estilo);

    final etiqueta = match.group(1)!;
    final resto = match.group(2)!;

    if (etiqueta == 'Categoría') {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Etiqueta('Categoría diagnóstica presuntiva'),
            const SizedBox(height: 4),
            SelectableText(
              resto,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.primaryDeep,
                    fontWeight: FontWeight.w800,
                    height: 1.4,
                  ),
            ),
          ],
        ),
      );
    }
    final estiloEtiqueta = estilo?.copyWith(fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface);

    if (!ancho) {
      return SelectableText.rich(
        TextSpan(
          style: estilo,
          children: [
            TextSpan(text: '$etiqueta: ', style: estiloEtiqueta),
            TextSpan(text: resto),
          ],
        ),
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 180, child: Text(etiqueta, style: estiloEtiqueta)),
        Expanded(child: SelectableText(resto, style: estilo)),
      ],
    );
  }
}

class _NotaSeguimiento extends StatelessWidget {
  const _NotaSeguimiento({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: cs.primary, width: 3)),
      ),
      child: Row(
        children: [
          Icon(Icons.event_repeat_rounded, size: 18, color: cs.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurface, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _BloqueResultados extends StatelessWidget {
  const _BloqueResultados({required this.pruebas});

  final List<PruebaCognitivaModel> pruebas;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final promedio = _promedioResultados(pruebas);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final indice = _IndiceGlobal(valor: promedio);
            final escala = _EscalaReferencia(valor: promedio);
            if (constraints.maxWidth < 600) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [indice, const SizedBox(height: 20), escala],
              );
            }
            return Row(
              children: [
                SizedBox(width: 230, child: indice),
                const SizedBox(width: 28),
                Expanded(child: escala),
              ],
            );
          },
        ),
        const SizedBox(height: 22),
        _TablaResultados(pruebas: pruebas),
        const SizedBox(height: 8),
        Text(
          'Escala de referencia:  Bajo 0–40%  ·  Medio 41–69%  ·  Alto 70–100%',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _IndiceGlobal extends StatelessWidget {
  const _IndiceGlobal({required this.valor});

  final double valor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final nivel = _nivelResultado(valor);
    final color = _colorNivel(nivel);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Etiqueta('Índice global'),
          const SizedBox(height: 4),
          Text(
            '${valor.toStringAsFixed(1)}%',
            style: theme.textTheme.headlineMedium?.copyWith(color: cs.onSurface, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            '${_nivelLegible(nivel)} · ${_descriptorNivel(nivel)}',
            style: theme.textTheme.labelLarge?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

/// Barra con las tres zonas de clasificación y un marcador en el valor obtenido.
class _EscalaReferencia extends StatelessWidget {
  const _EscalaReferencia({required this.valor});

  final double valor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final color = _colorNivel(_nivelResultado(valor));
    const zonas = [(40, 'BAJO'), (29, 'MEDIO'), (31, 'ALTO')];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Etiqueta('Posición en la escala de referencia'),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final ancho = constraints.maxWidth;
            const marcador = 18.0;
            final x = (ancho * valor.clamp(0, 100) / 100 - marcador / 2).clamp(0.0, ancho - marcador);
            return SizedBox(
              height: marcador,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: (marcador - 10) / 2,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: Row(
                        children: [
                          for (final (flex, nivel) in zonas)
                            Expanded(
                              flex: flex,
                              child: Container(
                                height: 10,
                                margin: EdgeInsets.only(right: nivel == 'ALTO' ? 0 : 2),
                                color: _colorNivel(nivel).withValues(alpha: 0.28),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: x),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    builder: (context, posicion, _) => Positioned(
                      left: posicion,
                      child: Container(
                        width: marcador,
                        height: marcador,
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerLowest,
                          shape: BoxShape.circle,
                          border: Border.all(color: color, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final (flex, nivel) in zonas)
              Expanded(
                flex: flex,
                child: Text(
                  _nivelLegible(nivel),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(color: _colorNivel(nivel)),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _TablaResultados extends StatelessWidget {
  const _TablaResultados({required this.pruebas});

  final List<PruebaCognitivaModel> pruebas;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    Widget celda(Widget child, {TextAlign? alinear}) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: alinear == TextAlign.right ? Align(alignment: Alignment.centerRight, child: child) : child,
        );
    Widget encabezado(String texto, {TextAlign alinear = TextAlign.left}) => celda(
          Text(
            texto.toUpperCase(),
            textAlign: alinear,
            style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant, letterSpacing: 0.6),
          ),
          alinear: alinear,
        );

    return LayoutBuilder(
      builder: (context, constraints) {
        final completa = constraints.maxWidth >= 560;

        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Table(
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            border: TableBorder(horizontalInside: BorderSide(color: cs.outlineVariant)),
            columnWidths: completa
                ? const {
                    0: FlexColumnWidth(3),
                    1: FlexColumnWidth(2.2),
                    2: FixedColumnWidth(92),
                    3: FixedColumnWidth(118),
                    4: FixedColumnWidth(84),
                  }
                : const {
                    0: FlexColumnWidth(),
                    1: FixedColumnWidth(84),
                    2: FixedColumnWidth(100),
                  },
            children: [
              TableRow(
                decoration: BoxDecoration(color: cs.surfaceContainer),
                children: [
                  encabezado('Prueba'),
                  if (completa) encabezado('Dominio'),
                  encabezado('Puntaje', alinear: TextAlign.right),
                  encabezado('Clasificación'),
                  if (completa) encabezado('Tiempo', alinear: TextAlign.right),
                ],
              ),
              for (final p in pruebas)
                TableRow(
                  children: [
                    celda(Text(
                      p.nombrePrueba,
                      style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurface, fontWeight: FontWeight.w600),
                    )),
                    if (completa) celda(Text(_dominio(p.nombrePrueba), style: theme.textTheme.bodyMedium)),
                    celda(
                      Text(
                        '${p.porcentajeObtenido.toStringAsFixed(1)}%',
                        style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurface, fontWeight: FontWeight.w700),
                      ),
                      alinear: TextAlign.right,
                    ),
                    celda(_Clasificacion(nivel: _nivelResultado(p.porcentajeObtenido))),
                    if (completa)
                      celda(
                        Text(_formatearTiempo(p.tiempoSegundos), style: theme.textTheme.bodyMedium),
                        alinear: TextAlign.right,
                      ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Clasificacion extends StatelessWidget {
  const _Clasificacion({required this.nivel});

  final String nivel;

  @override
  Widget build(BuildContext context) {
    final color = _colorNivel(nivel);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(
          _nivelLegible(nivel),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(color: color),
        ),
      ],
    );
  }
}

class _Firma extends StatelessWidget {
  const _Firma({required this.profesional, required this.fecha});

  final String profesional;
  final String fecha;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final bloqueFecha = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Etiqueta('Fecha de emisión'),
        const SizedBox(height: 3),
        Text(fecha, style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurface, fontWeight: FontWeight.w600)),
      ],
    );
    final bloqueFirma = SizedBox(
      width: 240,
      child: Column(
        children: [
          Divider(height: 1, thickness: 1, color: cs.onSurface.withValues(alpha: 0.6)),
          const SizedBox(height: 8),
          Text(profesional, textAlign: TextAlign.center, style: theme.textTheme.titleSmall?.copyWith(color: cs.onSurface)),
          Text('Profesional evaluador', style: theme.textTheme.bodySmall),
        ],
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 520) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [bloqueFecha, const SizedBox(height: 40), bloqueFirma],
          );
        }
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [bloqueFecha, bloqueFirma],
        );
      },
    );
  }
}

class _AvisoLegal extends StatelessWidget {
  const _AvisoLegal();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.only(top: 14),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: cs.outlineVariant))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 16, color: cs.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(child: Text(_kAviso, style: theme.textTheme.bodySmall)),
        ],
      ),
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
              'Generando el informe neuropsicológico...',
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
              'No se pudo generar el informe',
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

/// Sección tras la cual va la tabla de resultados: los instrumentos en los
/// informes actuales o el resumen en los antiguos; -1 la pone al inicio.
int _indiceResultados(List<_ReportSection> secciones) {
  final instrumentos = secciones.indexWhere((s) => s.title.contains('INSTRUMENTOS'));
  if (instrumentos >= 0) return instrumentos;
  return secciones.indexWhere((s) => s.title.contains('RESUMEN'));
}

/// Línea con el plazo de reevaluación o control.
bool _esSeguimiento(String linea) => linea.startsWith('Reevaluación') || linea.startsWith('Control');

/// Datos de la ficha de identificación, en el orden en que se muestran.
List<(String, String)> _datosIdentificacion(
  ReporteCognitivoModel reporte,
  SolicitudReporteCognitivoModel solicitud,
) {
  final telefono = solicitud.telefonoPaciente.blankFallback('');
  final antecedente = solicitud.diagnosticoPaciente.blankFallback('');
  return [
    ('Paciente', reporte.nombrePaciente),
    ('Documento / ID', solicitud.documentoPaciente.blankFallback(reporte.pacienteId)),
    ('Edad', solicitud.edadPaciente > 0 ? '${solicitud.edadPaciente} años' : 'No registrada'),
    ('Fecha de evaluación', _fechaEvaluacion(reporte.fechaEvaluacion)),
    ('Tipo de evaluación', 'Tamizaje neuropsicológico computarizado'),
    ('Profesional evaluador', solicitud.profesional),
    ('Institución', solicitud.institucion.blankFallback('NeuroApp360')),
    if (telefono.isNotEmpty) ('Teléfono', telefono),
    if (antecedente.isNotEmpty) ('Antecedente clínico', antecedente),
  ];
}

/// "RESULTADOS POR DOMINIO" -> "Resultados por dominio".
String _tituloLegible(String titulo) {
  final t = titulo.toLowerCase();
  return t.isEmpty ? t : t[0].toUpperCase() + t.substring(1);
}

String _numeroInforme(ReporteCognitivoModel reporte) => reporte.id.toString().padLeft(5, '0');

String _fechaLarga(DateTime fecha) => DateFormat("d 'de' MMMM 'de' y", 'es').format(fecha);

String _fechaEvaluacion(String iso) {
  final fecha = DateTime.tryParse(iso);
  return fecha == null ? iso : _fechaLarga(fecha);
}

/// Reemplaza caracteres que la fuente de respaldo del PDF (Helvetica) no soporta.
String _textoSeguroPdf(String texto) => texto
    .replaceAll('—', '-')
    .replaceAll('–', '-')
    .replaceAll('…', '...')
    .replaceAll('“', '"')
    .replaceAll('”', '"')
    .replaceAll('’', "'");

String _dominio(String prueba) {
  final n = prueba.toLowerCase();
  if (n.contains('memoria')) return 'Memoria';
  if (n.contains('atenci')) return 'Atención';
  if (n.contains('fluidez') || n.contains('lenguaje')) return 'Lenguaje';
  if (n.contains('stroop') || n.contains('ejecutiv')) return 'Funciones ejecutivas';
  return 'No especificado';
}

String _formatearTiempo(int segundos) {
  if (segundos < 60) return '$segundos s';
  final resto = (segundos % 60).toString().padLeft(2, '0');
  return '${segundos ~/ 60} min $resto s';
}

String _nivelResultado(double porcentaje) {
  if (porcentaje <= 40) return 'BAJO';
  if (porcentaje <= 69) return 'MEDIO';
  return 'ALTO';
}

String _nivelLegible(String nivel) => switch (nivel) {
      'BAJO' => 'Bajo',
      'MEDIO' => 'Medio',
      _ => 'Alto',
    };

String _descriptorNivel(String nivel) => switch (nivel) {
      'BAJO' => 'Por debajo de lo esperado',
      'MEDIO' => 'Rango limítrofe',
      _ => 'Dentro de lo esperado',
    };

Color _colorNivel(String nivel) {
  return switch (nivel) {
    'BAJO' => const Color(0xFFDC2626),
    'MEDIO' => const Color(0xFFD97706),
    _ => const Color(0xFF059669),
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
