// Fluidez verbal sin micrófono: el profesional cuenta las palabras con + y −.
// (Con reconocimiento de voz: fluency_voz_test.dart; el plugin es un singleton
// por proceso, por eso van en archivos separados.)
import 'package:flutter/material.dart';
import 'package:flutter_application_1/router.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_de_prueba.dart';
import '../helpers/plugins_simulados.dart';
import '../helpers/servidor_simulado.dart';

final _mas = find.widgetWithIcon(FloatingActionButton, Icons.add);
final _menos = find.widgetWithIcon(FloatingActionButton, Icons.remove);

Future<ServidorSimulado> abrir(WidgetTester tester, {Size pantalla = const Size(1440, 1000)}) async {
  VozSimulada(disponible: false);
  final servidor = ServidorSimulado(pacientes: [pacienteEjemplo()]);
  final c = await montarApp(tester, servidor, rolConSesion: 'doctor', pacienteActual: 21, pantalla: pantalla);
  await irA(tester, c, '/game_fluency');
  return servidor;
}

int conteo(WidgetTester tester) => int.parse(tester
    .widget<Text>(find.descendant(of: find.byType(Row), matching: find.byWidgetPredicate(
        (w) => w is Text && int.tryParse(w.data ?? '') != null && w.style?.fontWeight == FontWeight.bold)))
    .data!);

void main() {
  testWidgets('instrucciones y elección del tipo de prueba', (tester) async {
    await abrir(tester);
    expect(find.text('Fluidez Verbal'), findsWidgets);
    expect(find.text('Usa los botones + y − para registrar el número de palabras.'), findsOneWidget);

    await tocar(tester, find.text('Elegir tipo de prueba'));
    expect(find.text('Selecciona el tipo de prueba'), findsOneWidget);
    expect(find.text('Palabras con una letra'), findsOneWidget);
    expect(find.text('Palabras de una categoría'), findsOneWidget);

    // El modo enfoque oculta las descripciones y cambia el título.
    await tocar(tester, find.byTooltip('Activar Enfoque'));
    expect(find.text('Modo Enfoque'), findsOneWidget);
    expect(find.text('Palabras con una letra'), findsNothing);
    await tocar(tester, find.byTooltip('Desactivar Enfoque'));
    expect(find.text('Palabras con una letra'), findsOneWidget);
  });

  testWidgets('prueba fonológica: contar, descontar, pausar y finalizar', (tester) async {
    final servidor = await abrir(tester);
    await tocar(tester, find.text('Elegir tipo de prueba'));
    await tocar(tester, find.text('Fonológica'), pasos: 1);

    expect(find.textContaining('Letra: '), findsOneWidget);
    expect(find.text('60'), findsOneWidget);
    expect(find.text('Conteo de Palabras'), findsOneWidget);

    // Sin palabras, el botón − no baja de cero.
    await tester.tap(_menos);
    await tester.pump();
    expect(conteo(tester), 0);

    for (var i = 0; i < 3; i++) {
      await tester.tap(_mas);
      await tester.pump();
    }
    await tester.tap(_menos);
    await tester.pump();
    expect(conteo(tester), 2);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('59'), findsOneWidget);

    await tester.tap(find.byTooltip('Pausar'));
    await tester.pump();
    expect(find.text('PAUSA'), findsOneWidget);
    expect(tester.widget<FloatingActionButton>(_mas).onPressed, isNull);
    await tester.tap(find.byTooltip('Reanudar'));
    await tester.pump();
    expect(find.text('PAUSA'), findsNothing);

    // En modo enfoque también se cuenta (con vibración distinta).
    await tester.tap(find.byTooltip('Activar Enfoque'));
    await tester.pump();
    expect(find.text('Finalizar Ahora'), findsNothing);
    await tester.tap(_mas);
    await tester.pump();
    await tester.tap(_mas);
    await tester.pump();
    await tester.tap(_menos);
    await tester.pump();
    expect(conteo(tester), 3);
    await tester.tap(find.byTooltip('Desactivar Enfoque'));
    await tester.pump();

    await tocar(tester, find.text('Finalizar Ahora'));
    expect(find.text('Prueba Finalizada'), findsOneWidget);
    expect(find.text('Palabras generadas: 3'), findsOneWidget);
    final enviado = servidor.cuerpos['POST /sessions/results'] as Map;
    expect(enviado['game_name'], 'fluency');
    expect((enviado['metrics'] as Map)['count'], 3);

    await tocar(tester, find.text('Nueva Prueba'));
    expect(find.text('Selecciona el tipo de prueba'), findsOneWidget);
  });

  testWidgets('prueba semántica: al agotarse el minuto termina sola', (tester) async {
    final servidor = await abrir(tester);
    await tocar(tester, find.text('Elegir tipo de prueba'));
    await tocar(tester, find.text('Semántica'), pasos: 1);

    expect(
      find.byWidgetPredicate((w) => w is Text && ['Animales', 'Frutas', 'Ciudades', 'Profesiones'].contains(w.data)),
      findsOneWidget,
    );
    await tester.tap(_mas);
    for (var s = 0; s < 61; s++) {
      await tester.pump(const Duration(seconds: 1));
    }
    await esperar(tester, pasos: 5);

    expect(find.text('Palabras generadas: 1'), findsOneWidget);
    expect((servidor.cuerpos['POST /sessions/results'] as Map)['score'], isA<int>());
    await tocar(tester, find.text('Ver Resultados'));
    expect(find.text('Fluidez Verbal'), findsNothing);
  });

  testWidgets('en el móvil las opciones se apilan y caben en pantalla', (tester) async {
    await abrir(tester, pantalla: const Size(400, 640));
    await tocar(tester, find.text('Elegir tipo de prueba'));
    final fono = tester.getTopLeft(find.text('Fonológica'));
    final sema = tester.getTopLeft(find.text('Semántica'));
    expect(sema.dy, greaterThan(fono.dy)); // una debajo de la otra
    await tocar(tester, find.text('Fonológica'), pasos: 1);
    await tester.tap(find.byTooltip('Activar Enfoque'));
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tocar(tester, find.byTooltip('Desactivar Enfoque'), pasos: 1);
    await tocar(tester, find.text('Finalizar Ahora'));
    expect(find.text('Prueba Finalizada'), findsOneWidget);
  });

  testWidgets('en el protocolo devuelve el resultado', (tester) async {
    VozSimulada(disponible: false);
    final c = await montarApp(tester, ServidorSimulado(pacientes: [pacienteEjemplo()]),
        rolConSesion: 'doctor', pacienteActual: 21);
    await irA(tester, c, '/home');
    final resultado = c.read(routerProvider).push<Object?>(
      '/game_fluency',
      extra: {'flow': true, 'index': 0, 'total': 2, 'age': 66},
    );
    await esperar(tester);
    expect(find.text('Fluidez Verbal (1/2)'), findsOneWidget);
    await tocar(tester, find.text('Elegir tipo de prueba'));
    expect(find.text('Fluidez Verbal (1/2)'), findsOneWidget);
    await tocar(tester, find.text('Fonológica'), pasos: 1);
    await tocar(tester, find.text('Finalizar Ahora'));

    expect(find.text('Ver Resultados'), findsNothing);
    await tocar(tester, find.text('Siguiente'));
    final devuelto = await resultado as Map;
    expect((devuelto['result'] as Map)['nombre_prueba'], 'Fluidez Verbal');
  });

  testWidgets('la última prueba del protocolo ofrece Finalizar', (tester) async {
    VozSimulada(disponible: false);
    final c = await montarApp(tester, ServidorSimulado(pacientes: [pacienteEjemplo()]),
        rolConSesion: 'doctor', pacienteActual: 21);
    await irA(tester, c, '/home');
    c.read(routerProvider).push('/game_fluency', extra: {'flow': true, 'index': 1, 'total': 2});
    await esperar(tester);
    await tocar(tester, find.text('Elegir tipo de prueba'));
    await tocar(tester, find.text('Fonológica'), pasos: 1);
    await tocar(tester, find.text('Finalizar Ahora'));
    expect(find.text('Finalizar'), findsOneWidget);
  });
}
