// Historial de sesiones: lista, búsqueda, estados y acceso al detalle.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_de_prueba.dart';
import '../helpers/servidor_simulado.dart';

ServidorSimulado servidorConSesiones() => ServidorSimulado(sesiones: [
      sesionEjemplo(id: 1, notas: 'visual_memory: nivel 3', fecha: '2026-09-16T15:00:00'),
      sesionEjemplo(id: 2, notas: 'reaction 320 ms', estado: 'pending'),
      sesionEjemplo(id: 3, notas: 'fluency animales'),
      sesionEjemplo(id: 4, notas: 'stroop 18/20', estado: 'Completada'),
      sesionEjemplo(id: 15, notas: 'Batería de pruebas finalizada.'),
    ]);

Future<ProviderContainer> abrirHistorial(WidgetTester tester, ServidorSimulado servidor) async {
  final c = await montarApp(tester, servidor, rolConSesion: 'doctor');
  await irA(tester, c, '/home');
  c.read(routerProvider).push('/history');
  await esperar(tester);
  return c;
}

void main() {
  testWidgets('lista las sesiones con su tipo, fecha y estado', (tester) async {
    await abrirHistorial(tester, servidorConSesiones());

    expect(find.text('Sesiones'), findsOneWidget);
    expect(find.text('Sesión #1'), findsOneWidget);
    expect(find.text('16/09/2026 15:00'), findsWidgets);
    for (final tipo in ['Memoria Visual', 'Atención', 'Fluidez Verbal', 'Funciones Ejecutivas', 'Evaluación General']) {
      expect(find.text(tipo), findsOneWidget, reason: tipo);
    }
    expect(find.text('EN PROGRESO'), findsOneWidget);
    expect(find.text('COMPLETADA'), findsNWidgets(4));
  });

  testWidgets('busca por notas o por número de sesión y limpia la búsqueda', (tester) async {
    await abrirHistorial(tester, servidorConSesiones());
    final buscar = find.byType(TextFormField);

    await tester.enterText(buscar, 'STROOP');
    await tester.pump();
    expect(find.text('Sesión #4'), findsOneWidget);
    expect(find.text('Sesión #1'), findsNothing);

    await tester.enterText(buscar, '15');
    await tester.pump();
    expect(find.text('Sesión #15'), findsOneWidget);

    await tester.enterText(buscar, 'nada');
    await tester.pump();
    expect(find.text('Sin resultados'), findsOneWidget);
    expect(find.text('Iniciar Nueva Sesión'), findsNothing);

    await tocar(tester, find.byIcon(Icons.close_rounded));
    expect(find.text('Sesión #1'), findsOneWidget);
  });

  testWidgets('cada sesión abre su resumen de resultados', (tester) async {
    final c = await abrirHistorial(tester, servidorConSesiones());
    final titulos = {
      'Sesión #1': 'Resultados - Memoria Visual',
      'Sesión #2': 'Resultados - Atención',
      'Sesión #3': 'Resultados - Lenguaje',
      'Sesión #4': 'Resultados - Funciones Ejecutivas',
      'Sesión #15': 'Resultados',
    };
    for (final entrada in titulos.entries) {
      await tocar(tester, find.text(entrada.key));
      expect(rutaActual(c), '/results');
      expect(find.text(entrada.value), findsWidgets, reason: entrada.key);
      c.read(routerProvider).pop();
      await esperar(tester);
    }
  });

  testWidgets('sin sesiones invita a iniciar una', (tester) async {
    final c = await abrirHistorial(tester, ServidorSimulado(pacientes: [pacienteEjemplo()]));
    expect(find.text('Historial Vacío'), findsOneWidget);
    await tocar(tester, find.text('Iniciar Nueva Sesión'));
    expect(rutaActual(c), '/new_session');
  });

  testWidgets('si falla la carga muestra el error y se puede reintentar', (tester) async {
    final servidor = servidorConSesiones()..fallar('GET /sessions/');
    await abrirHistorial(tester, servidor);
    expect(find.textContaining('Error al obtener sesiones'), findsOneWidget);

    servidor.restablecer();
    await tocar(tester, find.byTooltip('Actualizar'));
    expect(find.text('Sesión #1'), findsOneWidget);
  });

  testWidgets('mientras carga muestra tarjetas de carga', (tester) async {
    final servidor = servidorConSesiones();
    final c = await montarApp(tester, servidor, rolConSesion: 'doctor');
    await irA(tester, c, '/home');
    servidor.pausa = Completer<void>();
    c.read(routerProvider).push('/history');
    await esperar(tester);
    expect(find.text('Sesión #1'), findsNothing);
    servidor.pausa!.complete();
    servidor.pausa = null;
    await esperar(tester);
    expect(find.text('Sesión #1'), findsOneWidget);
  });

  testWidgets('la flecha vuelve a la pantalla anterior', (tester) async {
    final c = await abrirHistorial(tester, servidorConSesiones());
    await tocar(tester, find.byIcon(Icons.arrow_back_rounded));
    expect(rutaActual(c), '/home');
  });
}
