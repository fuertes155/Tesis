// Pantalla de resultados: puntaje global, dominios, carga, error y PDF.
import 'dart:async';

import 'package:flutter_application_1/router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_de_prueba.dart';
import '../helpers/plugins_simulados.dart';
import '../helpers/servidor_simulado.dart';

/// La generación del PDF mezcla trabajo real (recursos) y del reloj simulado.
Future<void> esperarPdf(WidgetTester tester, ImpresionSimulada impresion) async {
  for (var i = 0; i < 60 && impresion.documentos.isEmpty; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump(const Duration(milliseconds: 50));
  }
  await esperar(tester, pasos: 5);
}

Future<ProviderContainer> abrir(WidgetTester tester, Object? extra) async {
  final c = await montarApp(tester, ServidorSimulado(pacientes: [pacienteEjemplo()]),
      rolConSesion: 'doctor', pacienteActual: 21);
  await irA(tester, c, '/home');
  c.read(routerProvider).push('/results', extra: extra);
  await esperar(tester, pasos: 30);
  return c;
}

void main() {
  testWidgets('un puntaje alto se destaca y cada dominio muestra su nivel', (tester) async {
    await abrir(tester, {
      'title': 'Resultados - Memoria Visual',
      'score': 95,
      'details': {'Memoria': 95, 'Atención': 70, 'Lenguaje': 40, 'Funciones Ejecutivas': 85, 'Velocidad': null},
    });

    expect(find.text('Resultados - Memoria Visual'), findsOneWidget);
    expect(find.text('95'), findsWidgets);
    expect(find.text('RENDIMIENTO SOBRESALIENTE'), findsOneWidget);
    expect(find.text('Rendimiento Superior'), findsOneWidget);
    for (final dominio in ['Memoria', 'Atención', 'Lenguaje', 'Funciones Ejecutivas', 'Velocidad']) {
      expect(find.text(dominio), findsOneWidget, reason: dominio);
    }
    expect(find.text('Puntuación: 50/100'), findsOneWidget); // dominio sin puntaje → 50
    expect(find.text('Puntuación: 40/100'), findsOneWidget);
  });

  testWidgets('un puntaje medio se muestra como rendimiento estándar', (tester) async {
    await abrir(tester, {'title': 'Resultados - Atención', 'score': 62, 'details': {'Atención': 62}});
    expect(find.text('PUNTUACIÓN GLOBAL'), findsOneWidget);
    expect(find.text('Rendimiento Estándar'), findsOneWidget);
  });

  testWidgets('sin datos muestra un resumen vacío', (tester) async {
    await abrir(tester, null);
    expect(find.text('Resultados'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
  });

  testWidgets('mientras llegan los datos muestra la carga y luego el resultado', (tester) async {
    final datos = Completer<Map<String, dynamic>>();
    await abrir(tester, {'dataFuture': datos.future});
    expect(find.text('Cargando...'), findsOneWidget);
    datos.complete({'title': 'Resultados - Lenguaje', 'score': 75, 'details': {'Lenguaje': 75}});
    await esperar(tester, pasos: 30);
    expect(find.text('Resultados - Lenguaje'), findsOneWidget);
  });

  testWidgets('si fallan los datos lo informa y permite volver', (tester) async {
    final datos = Completer<Map<String, dynamic>>();
    final c = await abrir(tester, {'dataFuture': datos.future});
    datos.completeError(Exception('sin red'));
    await esperar(tester);
    expect(find.text('Error al cargar'), findsOneWidget);
    await tocar(tester, find.text('Reintentar'));
    expect(rutaActual(c), '/home');
  });

  testWidgets('exporta el resultado a PDF con los datos del paciente', (tester) async {
    final impresion = ImpresionSimulada();
    await abrir(tester, {
      'title': 'Resultados - Stroop', 'score': 70, 'details': {'Funciones Ejecutivas': 70},
      'patientName': 'Jorge', 'patientId': 21,
    });
    await tocar(tester, find.byTooltip('Exportar PDF'));
    await esperarPdf(tester, impresion);
    expect(impresion.llamadas, contains('printPdf'));
    expect(impresion.documentos, isNotEmpty);
    expect(String.fromCharCodes(impresion.documentos.single.take(5)), '%PDF-');
  });

  testWidgets('sin datos del paciente el PDF usa los de la sesión', (tester) async {
    final impresion = ImpresionSimulada();
    await abrir(tester, {'title': 'Resultados', 'score': 10, 'details': <String, dynamic>{}});
    await tocar(tester, find.byTooltip('Exportar PDF'));
    await esperarPdf(tester, impresion);
    expect(impresion.documentos, hasLength(1));
  });

  testWidgets('VOLVER AL PANEL PRINCIPAL lleva al inicio', (tester) async {
    final c = await abrir(tester, {'title': 'Resultados', 'score': 10, 'details': <String, dynamic>{}});
    await tocar(tester, find.text('VOLVER AL PANEL PRINCIPAL'));
    expect(rutaActual(c), '/home');
  });
}
