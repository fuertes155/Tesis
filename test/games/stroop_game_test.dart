// Test Stroop: elegir el color de la tinta (no la palabra) durante 20 rondas.
import 'package:flutter/material.dart';
import 'package:flutter_application_1/router.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_de_prueba.dart';
import '../helpers/servidor_simulado.dart';

const _palabras = ['ROJO', 'AZUL', 'VERDE', 'AMARILLO'];

/// Color de la tinta de la palabra que se ve en pantalla.
Color tintaActual(WidgetTester tester) {
  final palabra = tester.widget<Text>(
    find.byWidgetPredicate((w) => w is Text && _palabras.contains(w.data) && w.style?.fontWeight == FontWeight.w900),
  );
  return palabra.style!.color!;
}

const _tintas = [Colors.red, Colors.blue, Colors.green, Colors.orange];

/// Botón circular del color indicado (o de cualquier otro color, si `igual` es falso).
Finder botonDeColor({required Color color, bool igual = true}) => find.ancestor(
      of: find.byWidgetPredicate((w) {
        if (w is! Ink || w.decoration is! ShapeDecoration) return false;
        final tinta = (w.decoration as ShapeDecoration).color;
        return _tintas.contains(tinta) && (tinta == color) == igual;
      }),
      matching: find.byType(InkWell),
    );

/// Responde la ronda actual, bien o mal.
Future<void> responder(WidgetTester tester, {required bool bien}) async {
  final tinta = tintaActual(tester);
  await tester.tap(botonDeColor(color: tinta, igual: bien).first);
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> jugarRondas(WidgetTester tester, {int errores = 3}) async {
  for (var ronda = 0; ronda < 20; ronda++) {
    await responder(tester, bien: ronda >= errores);
  }
  await esperar(tester, pasos: 10);
}

void main() {
  testWidgets('las instrucciones piden elegir la tinta, no la palabra', (tester) async {
    final c = await montarApp(tester, ServidorSimulado(pacientes: [pacienteEjemplo()]),
        rolConSesion: 'doctor', pacienteActual: 21);
    await irA(tester, c, '/game_stroop');
    expect(find.text('Funciones Ejecutivas'), findsOneWidget);
    expect(find.text('Test Stroop'), findsOneWidget);
    expect(find.text('Tu tarea es seleccionar el COLOR de la tinta, no la palabra.'), findsOneWidget);
  });

  testWidgets('20 rondas con aciertos y errores, guarda el resultado', (tester) async {
    final servidor = ServidorSimulado(pacientes: [pacienteEjemplo()]);
    final c = await montarApp(tester, servidor, rolConSesion: 'doctor', pacienteActual: 21);
    await irA(tester, c, '/game_stroop');
    await tocar(tester, find.text('Comenzar'), pasos: 3);

    expect(find.text('Funciones Ejecutivas (1/20)'), findsOneWidget);
    expect(find.text('Ronda: 1/20'), findsOneWidget);
    expect(find.text('Selecciona el color:'), findsOneWidget);

    await responder(tester, bien: false);
    expect(find.text('Puntos: 0'), findsOneWidget);
    await responder(tester, bien: true);
    expect(find.text('Puntos: 10'), findsOneWidget);
    await responder(tester, bien: true);
    expect(find.text('Puntos: 22'), findsOneWidget); // bonificación por racha
    for (var ronda = 3; ronda < 20; ronda++) {
      await responder(tester, bien: ronda != 10);
    }
    await esperar(tester, pasos: 10);

    expect(find.text('Prueba Finalizada'), findsOneWidget);
    final enviado = servidor.cuerpos['POST /sessions/results'] as Map;
    expect(enviado['game_name'], 'stroop');
    final metricas = enviado['metrics'] as Map;
    expect(metricas['correct'], 18);
    expect(metricas['wrong'], 2);

    await tocar(tester, find.text('Ver Resultados'));
    expect(rutaActual(c), '/results');
  });

  testWidgets('Intentar de Nuevo reinicia las rondas', (tester) async {
    final c = await montarApp(tester, ServidorSimulado(pacientes: [pacienteEjemplo()]),
        rolConSesion: 'doctor', pacienteActual: 21);
    await irA(tester, c, '/game_stroop');
    await tocar(tester, find.text('Comenzar'), pasos: 3);
    await jugarRondas(tester);

    await tocar(tester, find.text('Intentar de Nuevo'), pasos: 3);
    expect(find.text('Ronda: 1/20'), findsOneWidget);
    expect(find.text('Puntos: 0'), findsOneWidget);
  });

  testWidgets('si se cierra el resumen con Atrás se puede volver a comenzar', (tester) async {
    final c = await montarApp(tester, ServidorSimulado(pacientes: [pacienteEjemplo()]),
        rolConSesion: 'doctor', pacienteActual: 21, pantalla: const Size(400, 560));
    await irA(tester, c, '/game_stroop');
    await tocar(tester, find.text('Comenzar'), pasos: 3);
    await jugarRondas(tester, errores: 20);

    await tester.binding.handlePopRoute();
    await esperar(tester, pasos: 5);
    expect(find.text('Selecciona el COLOR de la tinta,\nno la palabra escrita.'), findsOneWidget);

    await tocar(tester, find.text('COMENZAR'), pasos: 3);
    expect(find.text('Ronda: 1/20'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('en el protocolo devuelve el resultado', (tester) async {
    final c = await montarApp(tester, ServidorSimulado(pacientes: [pacienteEjemplo()]),
        rolConSesion: 'doctor', pacienteActual: 21);
    await irA(tester, c, '/home');
    final resultado = c.read(routerProvider).push<Object?>(
      '/game_stroop',
      extra: {'flow': true, 'index': 2, 'total': 4, 'age': 75},
    );
    await esperar(tester);
    expect(find.text('Funciones Ejecutivas (3/4)'), findsOneWidget);
    await tocar(tester, find.text('Comenzar'), pasos: 3);
    expect(find.text('Funciones Ejecutivas (3/4)'), findsOneWidget);
    await jugarRondas(tester);

    expect(find.text('Ver Resultados'), findsNothing);
    await tocar(tester, find.text('Siguiente'));
    final devuelto = await resultado as Map;
    expect((devuelto['result'] as Map)['nombre_prueba'], 'Funciones Ejecutivas (Stroop)');
    expect(rutaActual(c), '/home');
  });

  testWidgets('la última prueba del protocolo ofrece Finalizar', (tester) async {
    final c = await montarApp(tester, ServidorSimulado(pacientes: [pacienteEjemplo()]),
        rolConSesion: 'doctor', pacienteActual: 21);
    await irA(tester, c, '/home');
    c.read(routerProvider).push('/game_stroop', extra: {'flow': true, 'index': 3, 'total': 4});
    await esperar(tester);
    await tocar(tester, find.text('Comenzar'), pasos: 3);
    await jugarRondas(tester);
    expect(find.text('Finalizar'), findsOneWidget);
  });
}
