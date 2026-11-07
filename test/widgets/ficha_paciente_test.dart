// I12 — Detalle del paciente con gráficas de evolución (RF12, RF13, HU03).
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_de_prueba.dart';
import '../helpers/servidor_simulado.dart';

ServidorSimulado servidorConJorge({bool dosEvaluaciones = true}) => ServidorSimulado(
      pacientes: [
        pacienteEjemplo(),
        pacienteEjemplo(id: 28, nombre: 'Gloria Patricia Zuluaga Henao', edad: 71,
            diagnostico: 'Envejecimiento cognitivo normal', documento: '25172390'),
      ],
      resultados: [
        ...bateriaEjemplo(21, '2026-09-16', [40, 45, 34, 37]),
        if (dosEvaluaciones) ...bateriaEjemplo(21, '2026-05-01', [50, 51, 40, 43]),
      ],
      reportes: [reporteEjemplo()],
    );

Future<void> abrirFicha(WidgetTester tester, ServidorSimulado servidor, {int id = 21}) async {
  final c = await montarApp(tester, servidor, rolConSesion: 'doctor');
  await irA(tester, c, '/patient_detail', extra: {'name': 'Paciente', 'id': id});
}

void main() {
  testWidgets('muestra los datos clínicos del paciente', (tester) async {
    await abrirFicha(tester, servidorConJorge());

    expect(find.text('Jorge Enrique Salazar Mejía'), findsWidgets);
    expect(find.text('#21'), findsOneWidget);
    expect(find.text('80 años'), findsOneWidget);
    expect(find.text('Enfermedad de Alzheimer, fase leve'), findsOneWidget);
    expect(find.text('Asignado'), findsOneWidget);
  });

  testWidgets('dibuja la evolución con una línea por prueba y un punto por evaluación', (tester) async {
    await abrirFicha(tester, servidorConJorge());

    expect(find.text('EVOLUCIÓN COGNITIVA'), findsOneWidget);
    for (final dominio in ['Memoria', 'Atención', 'Funciones ejecutivas', 'Lenguaje']) {
      expect(find.text(dominio), findsOneWidget, reason: 'leyenda: $dominio');
    }
    final grafica = tester.widget<LineChart>(find.byType(LineChart));
    expect(grafica.data.lineBarsData, hasLength(4));
    final memoria = grafica.data.lineBarsData.first.spots;
    expect(memoria.map((s) => s.y), [50, 40]); // mayo → septiembre: descenso
    expect(find.textContaining('Una sola evaluación'), findsNothing);
  });

  testWidgets('con una sola evaluación lo indica debajo de la gráfica', (tester) async {
    await abrirFicha(tester, servidorConJorge(dosEvaluaciones: false));
    expect(find.byType(LineChart), findsOneWidget);
    expect(find.textContaining('Una sola evaluación registrada'), findsOneWidget);
  });

  testWidgets('sin resultados no muestra gráfica y ofrece iniciar la evaluación', (tester) async {
    await abrirFicha(tester, servidorConJorge(), id: 28);
    expect(find.text('Gloria Patricia Zuluaga Henao'), findsWidgets);
    expect(find.text('EVOLUCIÓN COGNITIVA'), findsNothing);
    expect(find.text('Sin Evaluaciones'), findsOneWidget);
  });

  testWidgets('el directorio permite cambiar de paciente sin salir de la ficha', (tester) async {
    await abrirFicha(tester, servidorConJorge());
    await tocar(tester, find.text('ID: #28'));
    expect(find.text('Envejecimiento cognitivo normal'), findsOneWidget);
    expect(find.text('71 años'), findsOneWidget);
  });

  testWidgets('el botón Reportes abre los informes de ese paciente', (tester) async {
    final servidor = servidorConJorge();
    final c = await montarApp(tester, servidor, rolConSesion: 'doctor');
    await irA(tester, c, '/patient_detail', extra: {'name': 'Paciente', 'id': 21});

    await tocar(tester, find.text('Reportes'));

    expect(rutaActual(c), '/report_preview');
    expect(find.text('Reportes del paciente'), findsOneWidget);
    expect(servidor.recibio('GET', '/evaluacion/reportes/21'), isTrue);
  });
}
