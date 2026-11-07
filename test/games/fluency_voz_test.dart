// Fluidez verbal con reconocimiento de voz: las palabras dichas se cuentan
// solas (sin repetir) y el micrófono se apaga al terminar.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_de_prueba.dart';
import '../helpers/plugins_simulados.dart';
import '../helpers/servidor_simulado.dart';

void main() {
  testWidgets('cuenta las palabras reconocidas sin repetir y apaga el micrófono', (tester) async {
    final voz = VozSimulada(disponible: true);
    final servidor = ServidorSimulado(pacientes: [pacienteEjemplo()]);
    final c = await montarApp(tester, servidor, rolConSesion: 'doctor', pacienteActual: 21);
    await irA(tester, c, '/game_fluency');
    expect(voz.llamadas, contains('initialize'));

    await tocar(tester, find.text('Elegir tipo de prueba'));
    await tocar(tester, find.text('Semántica'), pasos: 1);
    expect(voz.llamadas, contains('listen'));
    // Indicador de escucha: un segundo anillo animado alrededor del tiempo.
    expect(find.byType(CircularProgressIndicator), findsNWidgets(2));

    await voz.reconocer('perro gato y');
    await tester.pump();
    expect(find.text('Última palabra: perro gato y'), findsOneWidget);
    expect(find.text('2'), findsOneWidget); // "y" no cuenta (una letra)

    await voz.reconocer('perro gato');
    await tester.pump();
    expect(find.text('2'), findsOneWidget); // repetidas no suman

    await voz.reconocer('');
    await tester.pump();
    await voz.reconocer('caballo', esFinal: true);
    await tester.pump();
    expect(find.text('3'), findsOneWidget);

    await tocar(tester, find.text('Finalizar Ahora'));
    expect(voz.llamadas, contains('stop'));
    expect(find.text('Palabras generadas: 3'), findsOneWidget);
    expect((servidor.cuerpos['POST /sessions/results'] as Map)['metrics']['count'], 3);
    await esperar(tester, pasos: 30);
  });
}
