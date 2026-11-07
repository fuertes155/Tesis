// Informe neuropsicológico: secciones, tabla de resultados, diseño en
// teléfono, generación con IA, errores y exportación a PDF.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_de_prueba.dart';
import '../helpers/plugins_simulados.dart';
import '../helpers/servidor_simulado.dart';

const _textoCompleto = '''
## MOTIVO DE EVALUACIÓN:
Evaluación de tamizaje — paciente “Jorge” remitido por olvidos…
DATOS DE LA EVALUACIÓN:
Esta sección repite la ficha y no se muestra.
INSTRUMENTOS APLICADOS:
- Memoria Visual
* **Test Stroop**
RESULTADOS POR DOMINIO:
Memoria: 40.0% (BAJO), por debajo de lo esperado
Atención: 75.0% (ALTO)
IMPRESIÓN DIAGNÓSTICA:
Categoría: Deterioro cognitivo leve probable.
Perfil compatible con alteración de memoria episódica.
RECOMENDACIONES:
Reevaluación neuropsicológica en 6 meses.
Control con neurología.
''';

Map<String, dynamic> solicitud({List<Map<String, dynamic>>? pruebas, bool completa = true}) => {
      'paciente_id': '10234587',
      'nombre_paciente': 'Jorge Enrique Salazar Mejía',
      'edad_paciente': completa ? 80 : 0,
      'fecha_evaluacion': '2026-09-16',
      'profesional': 'Samuel Vanegas',
      if (completa) ...{
        'documento_paciente': '10234587',
        'telefono_paciente': '3157784412',
        'diagnostico_paciente': 'Diabetes tipo 2.',
        'institucion': 'Remisión EPS',
      },
      'pruebas': pruebas ??
          [
            {'nombre_prueba': 'Memoria Visual', 'porcentaje_obtenido': 40, 'tiempo_segundos': 31},
            {'nombre_prueba': 'Atención Sostenida', 'porcentaje_obtenido': 60, 'tiempo_segundos': 45},
            {'nombre_prueba': 'Fluidez Verbal', 'porcentaje_obtenido': 80, 'tiempo_segundos': 60},
            {'nombre_prueba': 'Funciones Ejecutivas (Stroop)', 'porcentaje_obtenido': 50, 'tiempo_segundos': 75},
            {'nombre_prueba': 'Prueba piloto', 'porcentaje_obtenido': 120, 'tiempo_segundos': 5},
          ],
    };

Map<String, dynamic> informe(String texto) => {...reporteEjemplo(), 'reporte': texto};

Future<ProviderContainer> abrirInforme(
  WidgetTester tester, {
  String texto = _textoCompleto,
  Map<String, dynamic>? datos,
  Size pantalla = const Size(1440, 1000),
  bool empujar = true,
}) async {
  final c = await montarApp(tester, ServidorSimulado(), rolConSesion: 'doctor', pantalla: pantalla);
  await irA(tester, c, '/home');
  final extra = {'solicitud': datos ?? solicitud(), 'preGeneratedReport': informe(texto)};
  if (empujar) {
    c.read(routerProvider).push('/reporte_cognitivo', extra: extra);
  } else {
    c.read(routerProvider).go('/reporte_cognitivo', extra: extra);
  }
  await esperar(tester, pasos: 30);
  return c;
}

/// El PDF se arma con trabajo real (recursos, fuentes) y con el reloj simulado.
Future<void> esperarPdf(WidgetTester tester, ImpresionSimulada impresion, {int cuantos = 1}) async {
  for (var i = 0; i < 100 && impresion.documentos.length < cuantos; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump(const Duration(milliseconds: 50));
  }
  await esperar(tester, pasos: 5);
}

void main() {
  testWidgets('muestra las secciones, omite las redundantes y ubica los resultados tras los instrumentos',
      (tester) async {
    await abrirInforme(tester);

    expect(find.text('Informe neuropsicológico'), findsOneWidget);
    expect(find.text('MOTIVO DE EVALUACIÓN'), findsOneWidget);
    expect(find.text('DATOS DE LA EVALUACIÓN'), findsNothing);
    expect(find.text('INSTRUMENTOS APLICADOS'), findsOneWidget);
    expect(find.text('RESULTADOS DE LA EVALUACIÓN'), findsOneWidget);
    expect(find.text('Deterioro cognitivo leve probable.'), findsOneWidget);
    expect(find.text('Diabetes tipo 2.'), findsOneWidget); // antecedente en la ficha
    expect(find.text('1 min 15 s'), findsOneWidget);
    expect(find.text('No especificado'), findsOneWidget);

    final instrumentos = tester.getTopLeft(find.text('INSTRUMENTOS APLICADOS'));
    final resultados = tester.getTopLeft(find.text('RESULTADOS DE LA EVALUACIÓN'));
    final dominios = tester.getTopLeft(find.text('RESULTADOS POR DOMINIO'));
    expect(resultados.dy, greaterThan(instrumentos.dy));
    expect(dominios.dy, greaterThan(resultados.dy));
  });

  testWidgets('en el teléfono se reacomoda sin desbordar', (tester) async {
    await abrirInforme(tester, pantalla: const Size(420, 900));
    expect(tester.takeException(), isNull);
    // Las acciones pasan a ser íconos.
    expect(find.byTooltip('Descargar PDF'), findsOneWidget);
    expect(find.byTooltip('Compartir'), findsOneWidget);
    expect(find.text('Descargar PDF'), findsNothing);
    // La etiqueta y el valor van en la misma línea de texto.
    expect(find.textContaining('Memoria: ', findRichText: true), findsWidgets);
  });

  testWidgets('un informe antiguo pone los resultados tras el resumen', (tester) async {
    await abrirInforme(tester, texto: 'RESUMEN CUANTITATIVO:\nsin uso\nRESUMEN CLÍNICO:\nDesempeño global bajo.\n'
        'CONCLUSIÓN:\nSeguimiento.');
    final resumen = tester.getTopLeft(find.text('RESUMEN CLÍNICO'));
    final resultados = tester.getTopLeft(find.text('RESULTADOS DE LA EVALUACIÓN'));
    final conclusion = tester.getTopLeft(find.text('CONCLUSIÓN'));
    expect(resultados.dy, greaterThan(resumen.dy));
    expect(conclusion.dy, greaterThan(resultados.dy));
  });

  testWidgets('un texto sin secciones se muestra completo como "Informe"', (tester) async {
    await abrirInforme(tester, texto: 'Texto libre sin encabezados.', datos: solicitud(pruebas: [], completa: false));
    expect(find.text('INFORME'), findsOneWidget);
    expect(find.text('Texto libre sin encabezados.'), findsOneWidget);
    expect(find.text('RESULTADOS DE LA EVALUACIÓN'), findsNothing);
    expect(find.text('No registrada'), findsOneWidget); // edad 0
  });

  testWidgets('descarga e imprime el PDF del informe', (tester) async {
    final impresion = ImpresionSimulada();
    await abrirInforme(tester);
    await tocar(tester, find.text('Descargar PDF'));
    await esperarPdf(tester, impresion);

    expect(impresion.llamadas, contains('printPdf'));
    expect(String.fromCharCodes(impresion.documentos.single.take(5)), '%PDF-');
  });

  testWidgets('comparte el PDF del informe', (tester) async {
    final impresion = ImpresionSimulada();
    await abrirInforme(tester);
    await tocar(tester, find.text('Compartir'));
    await esperarPdf(tester, impresion);
    expect(impresion.llamadas, contains('sharePdf'));
    expect(impresion.documentos, hasLength(1));
  });

  testWidgets('el PDF también se genera para informes antiguos o sin secciones', (tester) async {
    final impresion = ImpresionSimulada();
    await abrirInforme(tester, texto: 'RESUMEN:\nDesempeño global bajo.', pantalla: const Size(420, 900));
    await tocar(tester, find.byTooltip('Descargar PDF'));
    await esperarPdf(tester, impresion);
    expect(impresion.documentos, hasLength(1));

    await tester.pumpWidget(const SizedBox());
    final otra = ImpresionSimulada();
    await abrirInforme(tester, texto: 'Texto libre.', datos: solicitud(pruebas: [], completa: false),
        pantalla: const Size(420, 900));
    await tocar(tester, find.byTooltip('Compartir'));
    await esperarPdf(tester, otra);
    expect(otra.documentos, hasLength(1));
  });

  testWidgets('genera el informe con IA mientras muestra el progreso', (tester) async {
    final servidor = ServidorSimulado()..reporteGenerado = informe(_textoCompleto);
    final c = await montarApp(tester, servidor, rolConSesion: 'doctor');
    await irA(tester, c, '/home');
    servidor.pausa = Completer<void>();
    c.read(routerProvider).push('/reporte_cognitivo', extra: solicitud());
    await esperar(tester);
    expect(find.text('Generando el informe neuropsicológico...'), findsOneWidget);
    servidor.pausa!.complete();
    servidor.pausa = null;
    await esperar(tester, pasos: 30);
    expect(find.text('MOTIVO DE EVALUACIÓN'), findsOneWidget);
    expect(servidor.recibio('POST', '/evaluacion/generar-reporte'), isTrue);
  });

  testWidgets('si la IA no responde muestra el motivo', (tester) async {
    final c = await montarApp(tester, ServidorSimulado(), rolConSesion: 'doctor');
    await irA(tester, c, '/home');
    c.read(routerProvider).push('/reporte_cognitivo', extra: {'solicitud': solicitud()});
    await esperar(tester, pasos: 30);
    expect(find.text('No se pudo generar el informe'), findsOneWidget);
    expect(find.textContaining('Ollama no disponible'), findsOneWidget);
  });

  testWidgets('la flecha vuelve a la pantalla anterior', (tester) async {
    final c = await abrirInforme(tester);
    await tocar(tester, find.byTooltip('Volver'));
    expect(rutaActual(c), '/home');
  });

  testWidgets('si se abrió directamente, la flecha lleva al inicio', (tester) async {
    final c = await abrirInforme(tester, empujar: false);
    await tocar(tester, find.byTooltip('Volver'));
    expect(rutaActual(c), '/home');
  });

  testWidgets('abrir el informe sin datos es un error de navegación', (tester) async {
    final c = await montarApp(tester, ServidorSimulado(), rolConSesion: 'doctor');
    c.read(routerProvider).go('/reporte_cognitivo');
    await tester.pump();
    expect(tester.takeException(), isA<Exception>());
  });
}
