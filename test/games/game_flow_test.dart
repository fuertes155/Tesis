// Protocolo de evaluación: encadena las pruebas, registra la sesión y genera
// el informe con los resultados de la batería.
import 'package:flutter/material.dart';
import 'package:flutter_application_1/router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_de_prueba.dart';
import '../helpers/servidor_simulado.dart';

ServidorSimulado servidorDeProtocolo() => ServidorSimulado(pacientes: [pacienteEjemplo()])
  ..reporteGenerado = reporteEjemplo();

Future<ProviderContainer> iniciarProtocolo(WidgetTester tester, ServidorSimulado servidor, List<String> rutas,
    {int paciente = 21}) async {
  final c = await montarApp(tester, servidor, rolConSesion: 'doctor', pacienteActual: paciente);
  c.read(routerProvider).go('/game_flow', extra: {'routes': rutas});
  await esperar(tester, pasos: 5); // menos que los 1,5 s que tarda en abrir la primera prueba
  return c;
}

/// La batería abre cada prueba 1,5 s después de mostrar "Iniciando…".
Future<void> esperarSiguientePrueba(WidgetTester tester) => esperar(tester, pasos: 20);

/// Simula que la prueba abierta devuelve este resultado (como lo hacen los juegos).
Future<void> devolver(WidgetTester tester, ProviderContainer c, Object? resultado) async {
  c.read(routerProvider).pop(resultado);
  await esperar(tester, pasos: 5);
}

Future<void> jugarReaccion(WidgetTester tester) async {
  await tocar(tester, find.text('Comenzar'), pasos: 2);
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(seconds: 5));
    await tester.tapAt(tester.getCenter(find.byType(AnimatedContainer)));
    await tester.pump(const Duration(milliseconds: 200));
    if (i < 4) {
      await tester.tapAt(tester.getCenter(find.byType(AnimatedContainer)));
      await tester.pump(const Duration(milliseconds: 200));
    }
  }
  await esperar(tester, pasos: 10);
}

void main() {
  testWidgets('una prueba: la juega, guarda la sesión y abre el informe generado', (tester) async {
    final servidor = servidorDeProtocolo();
    final c = await iniciarProtocolo(tester, servidor, ['/game_reaction'], paciente: 21);
    // Antes de abrir la prueba muestra a quién se evalúa.
    expect(find.text('Iniciando prueba...'), findsOneWidget);
    expect(find.text('Paciente: 80 años'), findsOneWidget);

    await esperarSiguientePrueba(tester);
    expect(find.text('Atención (1/1)'), findsOneWidget);
    await jugarReaccion(tester);
    await tocar(tester, find.text('Finalizar'), pasos: 40);

    expect(rutaActual(c), '/reporte_cognitivo');
    final solicitud = servidor.cuerpos['POST /evaluacion/generar-reporte'] as Map;
    expect(solicitud['paciente_id'], '10234587');
    expect(solicitud['nombre_paciente'], 'Jorge Enrique Salazar Mejía');
    expect(solicitud['edad_paciente'], 80);
    expect(solicitud['profesional'], 'Samuel Vanegas');
    expect(solicitud['institucion'], 'Remisión EPS');
    expect(solicitud['diagnostico_paciente'], 'Diabetes tipo 2.'); // antecedentes antes que diagnóstico
    final pruebas = solicitud['pruebas'] as List;
    expect(pruebas.single['nombre_prueba'], 'Atención Sostenida');
    // Sesión de la prueba + sesión de la batería.
    expect(servidor.veces('POST', '/sessions/'), 2);
    expect(find.text('Informe neuropsicológico'), findsOneWidget);
  });

  testWidgets('varias pruebas: muestra el total y nombra cada resultado', (tester) async {
    final servidor = servidorDeProtocolo();
    final c = await iniciarProtocolo(tester, servidor, List.filled(6, '/test_placeholder'));
    expect(find.text('Iniciando protocolo (6 pruebas)...'), findsOneWidget);

    // Resultados con el formato antiguo (sin nombre_prueba, valores como texto).
    final titulos = ['Resultados - Memoria', 'Resultados - Atencion', 'Fluidez', 'Test Stroop', 'Otra prueba', ''];
    for (var i = 0; i < titulos.length; i++) {
      await esperarSiguientePrueba(tester);
      expect(rutaActual(c), '/test_placeholder');
      await devolver(tester, c, {
        'completed': true,
        'result': <dynamic, dynamic>{'title': titulos[i], 'score': '${40 + i}', 'duration_ms': '${(i + 1) * 1000}'},
      });
    }
    await esperar(tester, pasos: 20);

    final pruebas = (servidor.cuerpos['POST /evaluacion/generar-reporte'] as Map)['pruebas'] as List;
    expect(pruebas.map((p) => p['nombre_prueba']), [
      'Memoria Visual',
      'Atención Sostenida',
      'Fluidez Verbal',
      'Funciones Ejecutivas (Stroop)',
      'Otra prueba',
      'Prueba Cognitiva',
    ]);
    expect(pruebas.map((p) => p['porcentaje_obtenido']), [40, 41, 42, 43, 44, 45]);
    expect(pruebas.map((p) => p['tiempo_segundos']), [1, 2, 3, 4, 5, 6]);
  });

  testWidgets('puntajes fuera de rango se acotan a 0–100', (tester) async {
    final servidor = servidorDeProtocolo();
    final c = await iniciarProtocolo(tester, servidor, ['/test_placeholder', '/test_placeholder']);
    await esperarSiguientePrueba(tester);
    await devolver(tester, c, {'result': {'nombre_prueba': 'A', 'score': 140, 'duration_ms': 2500}});
    await esperarSiguientePrueba(tester);
    await devolver(tester, c, {'result': {'nombre_prueba': 'B', 'score': 'n/d', 'duration_ms': null}});
    await esperar(tester, pasos: 20);

    final pruebas = (servidor.cuerpos['POST /evaluacion/generar-reporte'] as Map)['pruebas'] as List;
    expect(pruebas.map((p) => p['porcentaje_obtenido']), [100, 0]);
    expect(pruebas.map((p) => p['tiempo_segundos']), [3, 0]);
  });

  testWidgets('si se abandonan todas las pruebas vuelve al inicio sin informe', (tester) async {
    final servidor = servidorDeProtocolo();
    final c = await iniciarProtocolo(tester, servidor, ['/game_reaction']);
    await esperarSiguientePrueba(tester);
    await devolver(tester, c, null); // botón Atrás dentro de la prueba
    await esperar(tester, pasos: 20);

    expect(rutaActual(c), '/home');
    expect(servidor.recibio('POST', '/evaluacion/generar-reporte'), isFalse);
    expect(servidor.recibio('POST', '/sessions/'), isTrue); // la sesión queda registrada
  });

  testWidgets('sin datos del paciente ni del profesional usa valores por defecto', (tester) async {
    final servidor = servidorDeProtocolo()
      ..pacientes.first['institution'] = '  '
      ..fallar('GET /users/me');
    final c = await iniciarProtocolo(tester, servidor, ['/test_placeholder'], paciente: 99);
    expect(find.text('Paciente: 30 años'), findsOneWidget); // el paciente #99 no existe

    await esperarSiguientePrueba(tester);
    await devolver(tester, c, {'result': {'nombre_prueba': 'Memoria Visual', 'score': 50}});
    await esperar(tester, pasos: 20);

    final solicitud = servidor.cuerpos['POST /evaluacion/generar-reporte'] as Map;
    expect(solicitud['nombre_paciente'], 'Paciente');
    expect(solicitud['paciente_id'], 'PAC-000');
    expect(solicitud['edad_paciente'], 30);
    expect(solicitud['profesional'], 'samuel@gmail.com');
    expect(solicitud['institucion'], 'NeuroApp360');
  });

  testWidgets('un paciente sin documento ni institución se identifica por su número', (tester) async {
    final servidor = servidorDeProtocolo();
    servidor.pacientes.first
      ..['document_id'] = null
      ..['institution'] = null
      ..['medical_history'] = null;
    servidor.usuarioActual = {...ServidorSimulado.doctor, 'full_name': '  '};
    final c = await iniciarProtocolo(tester, servidor, ['/test_placeholder']);
    await esperarSiguientePrueba(tester);
    await devolver(tester, c, {'result': {'nombre_prueba': 'Memoria Visual', 'score': 50}});
    await esperar(tester, pasos: 20);

    final solicitud = servidor.cuerpos['POST /evaluacion/generar-reporte'] as Map;
    expect(solicitud['paciente_id'], 'PAC-21');
    expect(solicitud['institucion'], 'NeuroApp360');
    expect(solicitud['diagnostico_paciente'], 'Enfermedad de Alzheimer, fase leve');
    expect(solicitud['profesional'], 'samuel@gmail.com'); // nombre vacío → usuario
  });

  testWidgets('Salir abandona el protocolo', (tester) async {
    final c = await iniciarProtocolo(tester, servidorDeProtocolo(), ['/game_reaction']);
    await tocar(tester, find.text('Salir'), pasos: 20);
    expect(rutaActual(c), '/home');
  });
}
