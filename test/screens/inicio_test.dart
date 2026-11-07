// Inicio del doctor: indicadores, filtros de actividad (guardados entre
// visitas), accesos rápidos y menú de la cuenta.
import 'package:flutter/material.dart';
import 'package:flutter_application_1/router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/app_de_prueba.dart';
import '../helpers/servidor_simulado.dart';

String _hace(int dias, {int hora = 10}) {
  final d = DateTime.now().subtract(Duration(days: dias));
  return DateTime(d.year, d.month, d.day, hora).toIso8601String();
}

ServidorSimulado servidorInicio() => ServidorSimulado(
      pacientes: [
        pacienteEjemplo(),
        pacienteEjemplo(id: 28, nombre: 'Gloria Zuluaga', documento: '25'),
      ],
      sesiones: [
        sesionEjemplo(id: 1, fecha: _hace(0, hora: 9)),
        sesionEjemplo(id: 2, fecha: _hace(0, hora: 11), estado: 'pending', pacienteId: 28),
        sesionEjemplo(id: 3, fecha: _hace(1), estado: 'scheduled'),
        sesionEjemplo(id: 4, fecha: _hace(3), estado: 'en_progreso', pacienteId: 28),
        sesionEjemplo(id: 5, fecha: _hace(9), estado: 'pending'),
        sesionEjemplo(id: 6, fecha: _hace(20)),
      ],
    );

Future<ProviderContainer> abrirInicio(WidgetTester tester, ServidorSimulado servidor,
    {Size pantalla = const Size(1440, 1000)}) async {
  final c = await montarApp(tester, servidor, rolConSesion: 'doctor', pantalla: pantalla);
  await irA(tester, c, '/home');
  return c;
}

/// Píldora de filtro que muestra [texto] (el mismo texto puede aparecer en otras tarjetas).
Finder pildora(String texto) => find.descendant(
      of: find.byWidgetPredicate((w) => w is PopupMenuButton),
      matching: find.text(texto),
    );

/// Elige una opción en una de las píldoras de filtro.
Future<void> elegir(WidgetTester tester, Finder pildora, String opcion) async {
  await tocar(tester, pildora, pasos: 5);
  await tocar(tester, find.text(opcion).last, pasos: 5);
}

void main() {
  testWidgets('filtra la actividad por días, estado y paciente, y guarda los filtros', (tester) async {
    await abrirInicio(tester, servidorInicio());

    await elegir(tester, pildora('Últimos 7 días'), 'Últimos 30 días');
    await elegir(tester, pildora('Todos'), 'Pendientes');
    await tester.enterText(find.widgetWithText(TextField, 'Buscar paciente…'), 'gloria');
    await tester.pump();
    await elegir(tester, find.byTooltip('Ordenar'), 'Más antiguas primero');
    await esperar(tester);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('home_days'), 30);
    expect(prefs.getString('home_status'), 'pending');
    expect(prefs.getString('home_search'), 'gloria');
    expect(prefs.getString('home_sort'), 'date_asc');

    await tester.enterText(find.widgetWithText(TextField, 'Buscar paciente…'), 'nadie');
    await tester.pump();
    expect(find.text('Sin actividad para estos filtros'), findsOneWidget);
    await esperar(tester); // terminan las animaciones de la lista
  });

  testWidgets('al volver al inicio conserva los filtros elegidos', (tester) async {
    final c = await abrirInicio(tester, servidorInicio());
    await elegir(tester, pildora('Últimos 7 días'), 'Últimos 90 días');
    await elegir(tester, pildora('Todos'), 'Completadas');

    await irA(tester, c, '/profile');
    await irA(tester, c, '/home');
    expect(pildora('Últimos 90 días'), findsOneWidget);
    expect(pildora('Completadas'), findsOneWidget);
  });

  testWidgets('los filtros guardados en el dispositivo se recuperan', (tester) async {
    final c = await montarApp(tester, servidorInicio(), rolConSesion: 'doctor');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('home_days', 30);
    await prefs.setString('home_status', 'completed');
    await prefs.setString('home_search', 'jorge');
    await prefs.setString('home_sort', 'date_asc');
    await irA(tester, c, '/home');
    expect(pildora('Últimos 30 días'), findsOneWidget);
    expect(pildora('Completadas'), findsOneWidget);
  });

  testWidgets('tocar una sesión abre la ficha de su paciente', (tester) async {
    final c = await abrirInicio(tester, servidorInicio());
    await tocar(tester, find.text('Gloria Zuluaga').first);
    expect(rutaActual(c), '/patient_detail');
  });

  testWidgets('accesos rápidos del banner', (tester) async {
    final c = await abrirInicio(tester, servidorInicio());
    await tocar(tester, find.text('Nueva sesión').first);
    expect(rutaActual(c), '/new_session');
    c.read(routerProvider).pop();
    await esperar(tester);
    await tocar(tester, find.text('Ver pacientes'));
    expect(rutaActual(c), '/patients');
  });

  testWidgets('Actualizar vuelve a pedir pacientes y sesiones', (tester) async {
    final servidor = servidorInicio();
    await abrirInicio(tester, servidor);
    final antes = servidor.veces('GET', '/sessions/');
    await tocar(tester, find.byTooltip('Actualizar'));
    expect(servidor.veces('GET', '/sessions/'), greaterThan(antes));
  });

  testWidgets('menú de la cuenta: perfil y cierre de sesión', (tester) async {
    final c = await abrirInicio(tester, servidorInicio());
    await tocar(tester, find.byTooltip('Cuenta'), pasos: 5);
    expect(find.text('Samuel Vanegas'), findsWidgets);
    await tocar(tester, find.text('Mi perfil'));
    expect(rutaActual(c), '/profile');

    await irA(tester, c, '/home');
    await tocar(tester, find.byTooltip('Cuenta'), pasos: 5);
    await tocar(tester, find.text('Cerrar sesión'));
    expect(rutaActual(c), '/');
  });

  testWidgets('sin sesiones invita a iniciar la primera', (tester) async {
    final c = await abrirInicio(tester, ServidorSimulado(pacientes: [pacienteEjemplo()]));
    expect(find.text('Aún no hay sesiones registradas'), findsOneWidget);
    await tocar(tester, find.text('Iniciar primera sesión'));
    expect(rutaActual(c), '/new_session');
  });

  testWidgets('si falla la carga lo informa', (tester) async {
    await abrirInicio(tester, servidorInicio()..fallar('GET /patients/'));
    expect(find.textContaining('Error al cargar datos'), findsOneWidget);
  });

  testWidgets('en pantallas medianas las tarjetas van en una sola columna', (tester) async {
    await abrirInicio(tester, servidorInicio(), pantalla: const Size(900, 1000));
    expect(tester.takeException(), isNull);
    expect(find.text('Ver pacientes'), findsOneWidget);
  });
}
