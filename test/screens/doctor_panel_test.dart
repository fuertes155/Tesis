// Panel médico: disponibilidad del doctor, KPIs y sus pacientes asignados.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_de_prueba.dart';
import '../helpers/servidor_simulado.dart';

ServidorSimulado servidorDoctor() => ServidorSimulado(pacientes: [
      pacienteEjemplo(),
      pacienteEjemplo(id: 28, nombre: 'Gloria Zuluaga', diagnostico: 'Deterioro cognitivo leve', documento: '25'),
      pacienteEjemplo(id: 30, nombre: 'Otro Médico', doctorId: 99, documento: '30'),
      pacienteEjemplo(id: 31, nombre: 'Sin Diagnóstico', diagnostico: '  ', documento: '31'),
    ]);

Future<ProviderContainer> abrir(WidgetTester tester, ServidorSimulado servidor,
    {Size pantalla = const Size(1440, 1000)}) async {
  final c = await montarApp(tester, servidor, rolConSesion: 'doctor', pantalla: pantalla);
  await irA(tester, c, '/doctor_panel');
  return c;
}

void main() {
  testWidgets('muestra al doctor, su disponibilidad y solo sus pacientes', (tester) async {
    await abrir(tester, servidorDoctor());

    expect(find.text('samuel@gmail.com'), findsOneWidget);
    expect(find.text('Panel Médico'), findsOneWidget);
    expect(find.text('Disponible'), findsWidgets);
    expect(find.text('Pacientes asignados'), findsOneWidget);
    expect(find.text('3'), findsWidgets); // KPI y contador de la sección
    expect(find.text('MIS PACIENTES'), findsOneWidget);
    expect(find.text('Jorge Enrique Salazar Mejía'), findsOneWidget);
    expect(find.text('Gloria Zuluaga'), findsOneWidget);
    expect(find.text('Otro Médico'), findsNothing);
    expect(find.text('Deterioro cognitivo leve'), findsOneWidget);
    expect(find.text('JE'), findsOneWidget); // iniciales
  });

  testWidgets('mientras carga muestra el esqueleto', (tester) async {
    final servidor = servidorDoctor();
    final c = await montarApp(tester, servidor, rolConSesion: 'doctor');
    servidor.pausa = Completer<void>();
    await irA(tester, c, '/doctor_panel');
    expect(find.text('MIS PACIENTES'), findsNothing);
    servidor.pausa!.complete();
    servidor.pausa = null;
    await esperar(tester);
    expect(find.text('MIS PACIENTES'), findsOneWidget);
  });

  testWidgets('cambiar la disponibilidad la actualiza en el servidor y en pantalla', (tester) async {
    final servidor = servidorDoctor();
    servidor.usuarios.first['is_available'] = true;
    servidor.usuarioActual = servidor.usuarios.first;
    await abrir(tester, servidor);

    await tocar(tester, find.text('Disponible').first);
    expect(servidor.consultas['PUT /users/36/availability'], {'is_available': 'false'});
    expect(find.text('Ocupado'), findsOneWidget);
    expect(find.text('No disponible'), findsOneWidget);
  });

  testWidgets('si falla el cambio de disponibilidad lo informa', (tester) async {
    await abrir(tester, servidorDoctor()..fallar('PUT /users/36/availability'));
    await tocar(tester, find.text('Disponible').first);
    expect(find.textContaining('Error al actualizar disponibilidad'), findsOneWidget);
  });

  testWidgets('busca por nombre o diagnóstico', (tester) async {
    await abrir(tester, servidorDoctor());
    final buscar = find.byType(TextField);

    await tester.enterText(buscar, 'deterioro');
    await tester.pump();
    expect(find.text('Gloria Zuluaga'), findsOneWidget);
    expect(find.text('Jorge Enrique Salazar Mejía'), findsNothing);

    await tester.enterText(buscar, 'zzz');
    await tester.pump();
    expect(find.text('Sin pacientes asignados'), findsOneWidget);
    await esperar(tester); // terminan las animaciones de entrada
  });

  testWidgets('Iniciar abre una nueva sesión para ese paciente', (tester) async {
    final c = await abrir(tester, servidorDoctor());
    await tocar(tester, find.text('Iniciar').first);
    expect(rutaActual(c), '/new_session');
    expect(find.text('Jorge Enrique Salazar Mejía'), findsWidgets);
  });

  testWidgets('Resultados pide los últimos resultados del paciente', (tester) async {
    final servidor = servidorDoctor();
    servidor.resultados.addAll(bateriaEjemplo(21, '2026-09-16', [40, 45, 34, 37]));
    final c = await abrir(tester, servidor);
    await tocar(tester, find.text('Resultados').first);
    expect(servidor.consultas['GET /sessions/results/latest'], {'patient_id': '21', 'limit': '10'});
    expect(rutaActual(c), '/results');
  });

  testWidgets('sin pacientes asignados lo indica', (tester) async {
    await abrir(tester, ServidorSimulado(pacientes: [pacienteEjemplo(doctorId: 99)]));
    expect(find.text('Sin pacientes asignados'), findsOneWidget);
    expect(find.text('0'), findsWidgets);
  });

  testWidgets('si no se puede leer el perfil usa el usuario de la sesión', (tester) async {
    await abrir(tester, servidorDoctor()..fallar('GET /users/me'));
    expect(find.text('samuel@gmail.com'), findsOneWidget);
    expect(find.text('Sin pacientes asignados'), findsOneWidget);
    // Sin perfil no se puede cambiar la disponibilidad.
    await tocar(tester, find.text('Disponible').first);
    expect(find.textContaining('availability'), findsNothing);
  });

  testWidgets('si fallan los pacientes muestra la lista vacía', (tester) async {
    await abrir(tester, servidorDoctor()..fallar('GET /patients/'));
    expect(find.text('Sin pacientes asignados'), findsOneWidget);
  });

  testWidgets('Actualizar vuelve a pedir los datos', (tester) async {
    final servidor = servidorDoctor();
    await abrir(tester, servidor);
    final antes = servidor.veces('GET', '/patients/');
    await tocar(tester, find.byTooltip('Actualizar'));
    expect(servidor.veces('GET', '/patients/'), greaterThan(antes));
  });

  testWidgets('en el teléfono las acciones van debajo del paciente', (tester) async {
    await abrir(tester, servidorDoctor(), pantalla: const Size(390, 844));
    final nombre = tester.getTopLeft(find.text('Gloria Zuluaga'));
    final iniciar = tester.getTopLeft(find.text('Iniciar').at(1));
    expect(iniciar.dy, greaterThan(nombre.dy));
    expect(tester.takeException(), isNull);
  });

  testWidgets('cerrar sesión vuelve al inicio de sesión', (tester) async {
    final c = await abrir(tester, servidorDoctor());
    await tocar(tester, find.byTooltip('Cerrar Sesión'));
    expect(rutaActual(c), '/');
  });
}
