// Nueva sesión: el paciente a evaluar debe quedar definido antes de aplicar pruebas.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_de_prueba.dart';
import '../helpers/servidor_simulado.dart';

ServidorSimulado servidorConPacientes() => ServidorSimulado(pacientes: [
      pacienteEjemplo(),
      pacienteEjemplo(id: 28, nombre: 'Gloria Patricia Zuluaga Henao', documento: '25172390'),
    ]);

void main() {
  testWidgets('desde Inicio pide elegir paciente y no deja empezar sin él', (tester) async {
    // El "paciente actual" guardado (#1) ya no existe.
    final c = await montarApp(tester, servidorConPacientes(), rolConSesion: 'doctor', pacienteActual: 1);
    await irA(tester, c, '/new_session');

    expect(find.text('Paciente a evaluar'), findsWidgets);
    await tocar(tester, find.text('Protocolo integral'));

    expect(find.text('Primero selecciona el paciente que vas a evaluar.'), findsOneWidget);
    expect(rutaActual(c), '/new_session');
  });

  testWidgets('al elegir un paciente queda como actual y se puede continuar', (tester) async {
    final c = await montarApp(tester, servidorConPacientes(), rolConSesion: 'doctor', pacienteActual: 1);
    await irA(tester, c, '/new_session');

    await tocar(tester, find.byType(DropdownMenu<int>), pasos: 5);
    await tocar(tester, find.text('Gloria Patricia Zuluaga Henao').last, pasos: 5);

    await tocar(tester, find.text('Protocolo integral'));
    expect(rutaActual(c), '/test_selector');
  });

  testWidgets('desde la ficha el paciente viene fijado', (tester) async {
    final c = await montarApp(tester, servidorConPacientes(), rolConSesion: 'doctor', pacienteActual: 1);
    await irA(tester, c, '/new_session', extra: {'patientId': 21});

    expect(find.text('Paciente a evaluar'), findsNothing);
    expect(find.text('Jorge Enrique Salazar Mejía'), findsOneWidget);
    await tocar(tester, find.text('Screening rápido'));
    expect(rutaActual(c), '/test_selector');
  });
}
