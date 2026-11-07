// Lista de pacientes: búsqueda, alta (gestor), eliminación, estados vacíos y avisos.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/providers/api_providers.dart';
import 'package:flutter_application_1/router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_de_prueba.dart';
import '../helpers/servidor_simulado.dart';

ServidorSimulado servidorPacientes() => ServidorSimulado(
      pacientes: [
        pacienteEjemplo(),
        pacienteEjemplo(id: 28, nombre: 'Gloria Zuluaga', documento: '25'),
      ],
      sesiones: [sesionEjemplo(id: 1), sesionEjemplo(id: 2)],
    );

Future<ProviderContainer> abrirLista(WidgetTester tester, ServidorSimulado servidor, {String rol = 'doctor'}) async {
  final c = await montarApp(tester, servidor, rolConSesion: rol);
  await irA(tester, c, rol == 'gestor' ? '/users_admin' : '/home');
  c.read(routerProvider).push('/patients');
  await esperar(tester);
  return c;
}

void main() {
  testWidgets('busca por nombre y limpia la búsqueda', (tester) async {
    await abrirLista(tester, servidorPacientes());
    expect(find.text('Gloria Zuluaga'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'jorge');
    await esperar(tester, pasos: 10); // la tarjeta sale con una animación
    expect(find.text('Gloria Zuluaga'), findsNothing);
    expect(find.text('Jorge Enrique Salazar Mejía'), findsOneWidget);

    await tocar(tester, find.byIcon(Icons.clear_rounded), pasos: 10);
    expect(find.text('Gloria Zuluaga'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'zzz');
    await esperar(tester, pasos: 10);
    expect(find.text('Jorge Enrique Salazar Mejía'), findsNothing);
    // El mensaje aparece en la siguiente reconstrucción (al seguir escribiendo).
    await tester.enterText(find.byType(TextField), 'zzzz');
    await esperar(tester, pasos: 5);
    expect(find.text('Sin resultados'), findsOneWidget);
  });

  testWidgets('el doctor no puede eliminar ni crear pacientes', (tester) async {
    await abrirLista(tester, servidorPacientes());
    expect(find.byTooltip('Eliminar'), findsNothing);
    expect(find.text('Nuevo'), findsNothing);
  });

  testWidgets('el gestor confirma la eliminación con el número de sesiones', (tester) async {
    final servidor = servidorPacientes();
    await abrirLista(tester, servidor, rol: 'gestor');

    await tocar(tester, find.byTooltip('Eliminar').first);
    expect(find.textContaining('y 2 sesión(es)'), findsOneWidget);
    await tocar(tester, find.text('Cancelar'));
    expect(find.text('Paciente eliminado correctamente'), findsNothing);

    servidor.fallar('GET /sessions/count');
    servidor.fallar('GET /sessions/', estado: 500);
    await tocar(tester, find.byTooltip('Eliminar').first);
    expect(find.textContaining('¿Seguro que deseas eliminar'), findsOneWidget);
    servidor.restablecer();
    await tocar(tester, find.text('Eliminar').last);
    expect(find.text('Paciente eliminado correctamente'), findsOneWidget);
  });

  testWidgets('Nuevo abre el alta y al volver recarga la lista', (tester) async {
    final servidor = servidorPacientes();
    final c = await abrirLista(tester, servidor, rol: 'gestor');
    await tocar(tester, find.text('Nuevo'));
    expect(rutaActual(c), '/create_patient');

    await tester.enterText(find.widgetWithText(TextFormField, 'Nombre Completo'), 'Ana Nueva');
    await tocar(tester, find.text('Consentimiento Informado'));
    await tocar(tester, find.text('Crear Expediente'));
    await tocar(tester, find.text('Entendido'));
    await esperar(tester);

    expect(rutaActual(c), '/patients');
    expect(find.text('Ana Nueva'), findsOneWidget);
  });

  testWidgets('sin pacientes, el gestor puede registrar el primero', (tester) async {
    final c = await abrirLista(tester, ServidorSimulado(), rol: 'gestor');
    expect(find.text('Panel de Pacientes Vacío'), findsOneWidget);
    await tocar(tester, find.text('Registrar Primer Paciente'));
    expect(rutaActual(c), '/create_patient');
  });

  testWidgets('sin pacientes, el doctor solo ve el aviso', (tester) async {
    await abrirLista(tester, ServidorSimulado());
    expect(find.text('Panel de Pacientes Vacío'), findsOneWidget);
    expect(find.text('Registrar Primer Paciente'), findsNothing);
  });

  testWidgets('si falla la carga muestra la lista vacía', (tester) async {
    await abrirLista(tester, servidorPacientes()..fallar('GET /patients/'));
    expect(find.text('Panel de Pacientes Vacío'), findsOneWidget);
  });

  testWidgets('mientras carga muestra tarjetas de carga', (tester) async {
    final servidor = servidorPacientes();
    final c = await montarApp(tester, servidor, rolConSesion: 'doctor');
    await irA(tester, c, '/home');
    servidor.pausa = Completer<void>();
    c.read(routerProvider).push('/patients');
    await esperar(tester);
    expect(find.text('Jorge Enrique Salazar Mejía'), findsNothing);
    servidor.pausa!.complete();
    servidor.pausa = null;
    await esperar(tester);
    expect(find.text('Jorge Enrique Salazar Mejía'), findsOneWidget);
  });

  testWidgets('un aviso pendiente se muestra como banner y se puede cerrar', (tester) async {
    final c = await montarApp(tester, servidorPacientes(), rolConSesion: 'doctor');
    await irA(tester, c, '/home');
    c.read(apiServiceProvider).requireValue.pushNotice('no_perms_history');
    c.read(routerProvider).push('/patients');
    await esperar(tester);

    expect(find.text('No tienes permisos para ver el historial'), findsOneWidget);
    expect(find.textContaining('Acceso a Resultados restringido'), findsOneWidget);
    await tocar(tester, find.byIcon(Icons.close_rounded));
    expect(find.textContaining('Acceso a Resultados restringido'), findsNothing);
  });

  testWidgets('si se elimina desde la ficha, la lista se actualiza', (tester) async {
    final servidor = servidorPacientes();
    final c = await abrirLista(tester, servidor, rol: 'gestor');
    await tocar(tester, find.text('Gloria Zuluaga'));
    expect(rutaActual(c), '/patient_detail');
    await tocar(tester, find.byTooltip('Eliminar Paciente'));
    await tocar(tester, find.text('ELIMINAR'));
    await esperar(tester);
    expect(rutaActual(c), '/patients');
    expect(find.text('Gloria Zuluaga'), findsNothing);
  });

  testWidgets('la flecha vuelve al inicio', (tester) async {
    final c = await abrirLista(tester, servidorPacientes());
    await tocar(tester, find.byIcon(Icons.arrow_back_rounded));
    expect(rutaActual(c), '/home');
  });
}
