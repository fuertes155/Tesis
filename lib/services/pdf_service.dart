import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class PdfService {
  static Future<void> generateResultsPdf({
    required String patientName,
    required String title,
    required double score,
    required Map<String, dynamic> details,
    String? patientId,
  }) async {
    final pdf = pw.Document();

    // Cargar logo si existe (opcional, fallback a texto si falla)
    pw.Widget logo;
    try {
      final svgData = await rootBundle.loadString('assets/svg/hospital_logo.svg');
      logo = pw.SvgImage(svg: svgData, width: 60, height: 60);
    } catch (e) {
      logo = pw.Text('NEUROAPP 360', 
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 24, color: PdfColors.blue900));
    }

    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) => [
          // Header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              logo,
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('INFORME NEUROPSICOLÓGICO', 
                      style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.Text(dateStr, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Divider(thickness: 1, color: PdfColors.blue900),
          pw.SizedBox(height: 20),

          // Datos del Paciente
          pw.Text('DATOS DEL PACIENTE', 
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue700)),
          pw.SizedBox(height: 10),
          pw.Row(children: [
            pw.Expanded(child: pw.Text('Nombre: $patientName', style: const pw.TextStyle(fontSize: 12))),
            if (patientId != null) 
              pw.Expanded(child: pw.Text('ID: $patientId', style: const pw.TextStyle(fontSize: 12))),
          ]),
          pw.SizedBox(height: 30),

          // Resultados Globales
          pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
              border: pw.Border.all(color: PdfColors.grey300),
            ),
            child: pw.Column(
              children: [
                pw.Text('RESULTADO GLOBAL', 
                    style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                pw.SizedBox(height: 10),
                pw.Text('${score.toInt()} / 100', 
                    style: pw.TextStyle(fontSize: 32, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                pw.SizedBox(height: 5),
                pw.Text(title, style: const pw.TextStyle(fontSize: 14, color: PdfColors.blue600)),
              ],
            ),
          ),
          pw.SizedBox(height: 30),

          // Detalle por Dominios
          pw.Text('DESGLOSE POR DOMINIOS COGNITIVOS', 
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue700)),
          pw.SizedBox(height: 15),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue900),
            cellHeight: 30,
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.center,
            },
            data: <List<String>>[
              <String>['Dominio', 'Puntuación'],
              ...details.entries.map((e) => [e.key, '${(e.value as num).toInt()} pts']),
            ],
          ),

          // Footer / Firma
          pw.Spacer(),
          pw.Divider(thickness: 0.5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Generado por NeuroApp 360', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
              pw.Column(
                children: [
                  pw.SizedBox(height: 40, width: 120, child: pw.Divider(thickness: 1)),
                  pw.Text('Firma del Profesional', style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    // Compartir/Imprimir el PDF
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Informe_${patientName.replaceAll(' ', '_')}.pdf',
    );
  }
}
