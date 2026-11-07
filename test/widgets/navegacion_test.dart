// Navegación real del doctor: Inicio → Pacientes → ficha → Reportes,
// el mismo camino que recorre la prueba E2E en el navegador.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_de_prueba.dart';
import '../helpers/servidor_simulado.dart';

void main() {
  testWidgets('desde Inicio llega a la ficha y a los reportes del paciente', (tester) async {
    final servidor = ServidorSimulado(
      pacientes: [pacienteEjemplo()],
      reportes: [reporteEjemplo()],
      resultados: bateriaEjemplo(21, '2026-09-16', [40, 45, 34, 37]),
    );
    final c = await montarApp(tester, servidor, rolConSesion: 'doctor', pantalla: const Size(1096, 730));
    await irA(tester, c, '/home');

    await tocar(tester, find.text('Ver lista, buscar y editar perfiles'));
    expect(rutaActual(c), '/patients');

    await tocar(tester, find.text('Jorge Enrique Salazar Mejía').first);
    expect(rutaActual(c), '/patient_detail');
    expect(find.text('EVOLUCIÓN COGNITIVA'), findsOneWidget);

    await tocar(tester, find.text('Reportes'));
    expect(rutaActual(c), '/report_preview');
    expect(servidor.recibio('GET', '/evaluacion/reportes/21'), isTrue);
    expect(find.text('Paciente: Jorge Enrique Salazar Mejía'), findsOneWidget);
  });
}
