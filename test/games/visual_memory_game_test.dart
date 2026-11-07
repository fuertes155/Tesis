// Prueba de memoria visual: patrón, selección, subida de nivel, error y resultado.
import 'package:flutter/material.dart';
import 'package:flutter_application_1/router.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_de_prueba.dart';
import '../helpers/servidor_simulado.dart';

final _celdas = find.descendant(of: find.byType(GridView), matching: find.byType(AnimatedContainer));

/// Índices de las casillas que se muestran en azul (el patrón a memorizar).
List<int> patronVisible(WidgetTester tester) {
  final celdas = tester.widgetList<AnimatedContainer>(_celdas).toList();
  return [
    for (var i = 0; i < celdas.length; i++)
      if ((celdas[i].decoration as BoxDecoration).color == Colors.blue) i,
  ];
}

Future<void> tocarCelda(WidgetTester tester, int indice) async {
  await tester.tap(_celdas.at(indice));
  await tester.pump(const Duration(milliseconds: 50));
}

Future<void> iniciar(WidgetTester tester, {Map<String, Object?>? extra, bool empujar = false}) async {
  final c = await montarApp(tester, ServidorSimulado(pacientes: [pacienteEjemplo()]),
      rolConSesion: 'doctor', pacienteActual: 21);
  await irA(tester, c, '/home');
  if (empujar) {
    c.read(routerProvider).push('/game_memory', extra: extra);
    await esperar(tester);
  } else {
    await irA(tester, c, '/game_memory', extra: extra);
  }
}

/// Supera el nivel actual: memoriza el patrón, espera a que se oculte y lo repite.
Future<void> superarNivel(WidgetTester tester, {required int segundos}) async {
  final patron = patronVisible(tester);
  await tester.pump(Duration(seconds: segundos));
  await tester.pump(const Duration(milliseconds: 100));
  expect(find.text('Selecciona las casillas que viste'), findsOneWidget);
  for (final i in patron) {
    await tocarCelda(tester, i);
  }
}

/// Toca una casilla que no forma parte del patrón y espera el resumen.
Future<void> fallar(WidgetTester tester, List<int> patron) async {
  final incorrecta = List.generate(16, (i) => i).firstWhere((i) => !patron.contains(i));
  await tocarCelda(tester, incorrecta);
  await esperar(tester, pasos: 10);
}

void main() {
  testWidgets('las instrucciones explican la prueba', (tester) async {
    await iniciar(tester);
    expect(find.text('Memoria Visual'), findsWidgets);
    expect(find.text('Cada nivel aumenta la dificultad.'), findsOneWidget);
  });

  testWidgets('muestra el patrón, lo oculta y sube de nivel al acertarlo', (tester) async {
    final servidor = ServidorSimulado(pacientes: [pacienteEjemplo()]);
    final c = await montarApp(tester, servidor, rolConSesion: 'doctor', pacienteActual: 21);
    await irA(tester, c, '/game_memory');
    await tocar(tester, find.text('Comenzar'), pasos: 1);

    expect(find.text('Memorizar las casillas azules'), findsNothing);
    expect(find.text('Memoriza las casillas azules'), findsOneWidget);
    expect(find.text('Memoria Visual - Nivel 1'), findsOneWidget);
    expect(find.text('Recordar: 3'), findsOneWidget);
    final patron = patronVisible(tester);
    expect(patron, hasLength(3));
    expect(find.text('2'), findsWidgets); // cuenta regresiva sobre las casillas

    // Durante la memorización los toques no cuentan.
    await tocarCelda(tester, patron.first);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('1'), findsWidgets);

    await superarNivel(tester, segundos: 1);
    // Tocar dos veces la misma casilla no suma dos aciertos.
    await tocarCelda(tester, patron.first);
    expect(find.text('¡Nivel 2! Puntos: 130'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Memoria Visual - Nivel 2'), findsOneWidget);
    expect(find.text('Recordar: 4'), findsOneWidget);
    expect(find.text('Tiempo: 1s'), findsOneWidget);

    final patron2 = patronVisible(tester);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 100));
    await fallar(tester, patron2);

    expect(find.text('Prueba Finalizada'), findsOneWidget);
    expect(find.text('Puntuación final: 130\nNivel alcanzado: 2'), findsOneWidget);
    final enviado = servidor.cuerpos['POST /sessions/results'] as Map;
    expect(enviado['game_name'], 'visual_memory');
    expect((enviado['metrics'] as Map)['level'], 2);

    await tocar(tester, find.text('Ver Resultados'));
    expect(rutaActual(c), '/results');
  });

  testWidgets('Intentar de Nuevo reinicia desde el nivel 1', (tester) async {
    await iniciar(tester);
    await tocar(tester, find.text('Comenzar'), pasos: 1);
    final patron = patronVisible(tester);
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 100));
    await fallar(tester, patron);

    await tocar(tester, find.text('Intentar de Nuevo'), pasos: 1);
    expect(find.text('Memoria Visual - Nivel 1'), findsOneWidget);
    expect(find.text('Puntos: 0'), findsOneWidget);
    expect(find.text('Memoriza las casillas azules'), findsOneWidget);
    await esperar(tester, pasos: 30);
  });

  testWidgets('el botón Reiniciar de la barra empieza otra vez', (tester) async {
    await iniciar(tester);
    await tocar(tester, find.text('Comenzar'), pasos: 1);
    await superarNivel(tester, segundos: 2);
    await esperar(tester, pasos: 15);
    expect(find.text('Memoria Visual - Nivel 2'), findsOneWidget);

    await tocar(tester, find.text('Reiniciar'), pasos: 1);
    expect(find.text('Memoria Visual - Nivel 1'), findsOneWidget);
    await esperar(tester, pasos: 30);
  });

  testWidgets('en el protocolo muestra el progreso y devuelve el resultado', (tester) async {
    await iniciar(tester, empujar: true, extra: {'flow': true, 'index': 0, 'total': 4, 'age': 80});
    expect(find.text('Memoria Visual (1/4)'), findsOneWidget);
    await tocar(tester, find.text('Comenzar'), pasos: 1);
    expect(find.text('Memoria Visual (1/4)'), findsOneWidget);

    final patron = patronVisible(tester);
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 100));
    await fallar(tester, patron);

    expect(find.text('Ver Resultados'), findsNothing);
    await tocar(tester, find.text('Siguiente'));
    expect(find.text('Prueba Finalizada'), findsNothing);
    expect(find.byType(GridView), findsNothing);
  });

  testWidgets('la última prueba del protocolo ofrece Finalizar', (tester) async {
    await iniciar(tester, empujar: true, extra: {'flow': true, 'index': 3, 'total': 4});
    await tocar(tester, find.text('Comenzar'), pasos: 1);
    final patron = patronVisible(tester);
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 100));
    await fallar(tester, patron);
    expect(find.text('Finalizar'), findsOneWidget);
  });

  testWidgets('en pantallas bajas la cuadrícula se adapta sin desbordar', (tester) async {
    final c = await montarApp(tester, ServidorSimulado(pacientes: [pacienteEjemplo()]),
        rolConSesion: 'doctor', pacienteActual: 21, pantalla: const Size(360, 480));
    await irA(tester, c, '/game_memory');
    await tocar(tester, find.text('Comenzar'), pasos: 1);
    expect(tester.takeException(), isNull);
    expect(patronVisible(tester), hasLength(3));
    await esperar(tester, pasos: 30);
  });
}
