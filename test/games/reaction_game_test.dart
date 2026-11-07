// Prueba de atención sostenida (tiempo de reacción): rondas, errores por
// anticipación, envío del resultado y modo protocolo.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/router.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/app_de_prueba.dart';
import '../helpers/servidor_simulado.dart';

ServidorSimulado servidorConPaciente() => ServidorSimulado(pacientes: [pacienteEjemplo()]);

Future<void> tocarPantalla(WidgetTester tester) async {
  await tester.tapAt(tester.getCenter(find.byType(AnimatedContainer)));
  await tester.pump(const Duration(milliseconds: 200));
}

/// Espera a que el fondo se ponga verde (2–5 s) y toca.
Future<void> reaccionar(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  expect(find.text('¡AHORA!'), findsOneWidget);
  await tocarPantalla(tester);
}

Future<void> completarIntentos(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await reaccionar(tester);
    if (i < 4) {
      expect(find.textContaining('Toca para continuar'), findsOneWidget);
      await tocarPantalla(tester); // siguiente ronda
    }
  }
  await esperar(tester, pasos: 10);
}

void main() {
  testWidgets('muestra las instrucciones antes de empezar', (tester) async {
    final c = await montarApp(tester, servidorConPaciente(), rolConSesion: 'doctor', pacienteActual: 21);
    await irA(tester, c, '/game_reaction');

    expect(find.text('Atención'), findsOneWidget);
    expect(find.text('Atención Sostenida'), findsOneWidget);
    expect(find.text('INSTRUCCIONES'), findsOneWidget);
    expect(find.text('Completa 5 intentos para finalizar la prueba.'), findsOneWidget);
  });

  testWidgets('tocar antes del verde cuenta como anticipación y permite reintentar', (tester) async {
    final c = await montarApp(tester, servidorConPaciente(), rolConSesion: 'doctor', pacienteActual: 21);
    await irA(tester, c, '/game_reaction');
    await tocar(tester, find.text('Comenzar'), pasos: 2);

    expect(find.text('Esperar...'), findsOneWidget);
    expect(find.text('Toca la pantalla cuando se ponga VERDE'), findsOneWidget);
    expect(find.text('Atención (0/5)'), findsOneWidget);

    await tocarPantalla(tester);
    expect(find.text('¡Muy rápido! Toca para intentar de nuevo.'), findsOneWidget);

    await tocarPantalla(tester);
    expect(find.text('Esperar...'), findsOneWidget);
    await reaccionar(tester);
    expect(find.textContaining('Mejor:'), findsOneWidget);
    expect(find.text('Atención (1/5)'), findsOneWidget);
    await esperar(tester, pasos: 5);
  });

  testWidgets('tras 5 intentos guarda el resultado y muestra el resumen', (tester) async {
    final servidor = servidorConPaciente();
    final c = await montarApp(tester, servidor, rolConSesion: 'doctor', pacienteActual: 21);
    await irA(tester, c, '/game_reaction');
    await tocar(tester, find.text('Comenzar'), pasos: 2);

    await completarIntentos(tester);

    expect(find.text('Prueba de Atención Finalizada'), findsOneWidget);
    expect(find.textContaining('Intentos: 5'), findsOneWidget);
    expect(servidor.recibio('POST', '/sessions/'), isTrue);
    final enviado = servidor.cuerpos['POST /sessions/results'] as Map;
    expect(enviado['game_name'], 'reaction');
    expect(enviado['patient_id'], 21);
    expect((enviado['metrics'] as Map)['attempts'], 5);

    await tocar(tester, find.text('Ver Resultados'));
    expect(rutaActual(c), '/results');
  });

  testWidgets('Reiniciar vuelve a las instrucciones con los intentos en cero', (tester) async {
    final c = await montarApp(tester, servidorConPaciente(), rolConSesion: 'doctor', pacienteActual: 21);
    await irA(tester, c, '/game_reaction');
    await tocar(tester, find.text('Comenzar'), pasos: 2);
    await completarIntentos(tester);

    await tocar(tester, find.text('Reiniciar'));
    expect(find.text('INSTRUCCIONES'), findsOneWidget);
    await tocar(tester, find.text('Comenzar'), pasos: 2);
    expect(find.text('Atención (0/5)'), findsOneWidget);
    await esperar(tester, pasos: 60);
  });

  testWidgets('en el protocolo devuelve el resultado a la batería', (tester) async {
    final servidor = servidorConPaciente();
    final c = await montarApp(tester, servidor, rolConSesion: 'doctor', pacienteActual: 21);
    await irA(tester, c, '/home');
    final resultado = c.read(routerProvider).push<Object?>(
      '/game_reaction',
      extra: {'flow': true, 'index': 0, 'total': 2, 'age': 70},
    );
    await esperar(tester);

    expect(find.text('Atención (1/2)'), findsOneWidget);
    await tocar(tester, find.text('Comenzar'), pasos: 2);
    expect(find.text('Atención (1/2)'), findsOneWidget);
    await completarIntentos(tester);

    await tocar(tester, find.text('Siguiente'));
    final devuelto = await resultado as Map;
    expect(devuelto['completed'], isTrue);
    expect((devuelto['result'] as Map)['nombre_prueba'], 'Atención Sostenida');
    expect(rutaActual(c), '/home');
  });

  testWidgets('si se cierra el resumen con Atrás, tocar la pantalla lo vuelve a mostrar', (tester) async {
    final c = await montarApp(tester, servidorConPaciente(), rolConSesion: 'doctor', pacienteActual: 21);
    await irA(tester, c, '/game_reaction');
    await tocar(tester, find.text('Comenzar'), pasos: 2);
    await completarIntentos(tester);

    await tester.binding.handlePopRoute(); // botón Atrás de Android
    await esperar(tester, pasos: 5);
    expect(find.text('Prueba de Atención Finalizada'), findsNothing);

    await tocarPantalla(tester);
    await esperar(tester, pasos: 5);
    expect(find.text('Prueba de Atención Finalizada'), findsOneWidget);
  });

  testWidgets('sin conexión la sesión queda en cola para enviarse después', (tester) async {
    final servidor = servidorConPaciente()..sinConexion('POST /sessions/');
    final c = await montarApp(tester, servidor, rolConSesion: 'doctor', pacienteActual: 21);
    await irA(tester, c, '/game_reaction');
    await tocar(tester, find.text('Comenzar'), pasos: 2);
    await completarIntentos(tester);

    final prefs = await SharedPreferences.getInstance();
    final cola = jsonDecode(prefs.getString('pending_sessions_v1')!) as List;
    expect(cola, hasLength(1));
    expect(cola.single['patient_id'], 21);
    expect(cola.single['status'], 'completed');
    // El resultado del juego sí llegó por su propio endpoint.
    expect(servidor.recibio('POST', '/sessions/results'), isTrue);
  });

  testWidgets('la última prueba del protocolo ofrece Finalizar', (tester) async {
    final c = await montarApp(tester, servidorConPaciente(), rolConSesion: 'doctor', pacienteActual: 21);
    await irA(tester, c, '/home');
    c.read(routerProvider).push('/game_reaction', extra: {'flow': true, 'index': 1, 'total': 2});
    await esperar(tester);
    await tocar(tester, find.text('Comenzar'), pasos: 2);
    await completarIntentos(tester);
    expect(find.text('Finalizar'), findsOneWidget);
    expect(find.text('Ver Resultados'), findsNothing);
  });
}
