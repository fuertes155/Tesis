import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/core/database/local_database_service.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/providers/api_providers.dart';
import 'package:flutter_application_1/router.dart';
import 'package:flutter_application_1/services/api_service.dart';
import 'package:flutter_application_1/services/reporte_cognitivo_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sembast/sembast_memory.dart' show databaseFactoryMemory;
import 'package:shared_preferences/shared_preferences.dart';

import 'servidor_simulado.dart';

var _bases = 0;

/// Monta la app completa (router, tema y proveedores reales) contra un
/// [ServidorSimulado] en lugar del backend. Devuelve el contenedor de Riverpod
/// para poder navegar o inspeccionar el estado desde la prueba.
Future<ProviderContainer> montarApp(
  WidgetTester tester,
  ServidorSimulado servidor, {
  String? rolConSesion,
  int? pacienteActual,
  Size pantalla = const Size(1440, 1000),
}) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  // rootBundle guarda en caché el Future de cada recurso, ligado a la zona de la
  // prueba que lo pidió primero; en la siguiente prueba ese Future no avanzaría.
  rootBundle.clear();
  await initializeDateFormatting('es');
  tester.view.physicalSize = pantalla;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  // El perfil (GET /users/me) corresponde al usuario de la sesión.
  final usuario = switch (rolConSesion) {
    'gestor' => ServidorSimulado.gestor,
    'user' => ServidorSimulado.paciente,
    _ => ServidorSimulado.doctor,
  };
  if (rolConSesion != null) servidor.usuarioActual ??= usuario;

  SharedPreferences.setMockInitialValues({
    if (rolConSesion != null) ...{
      'api_token': 'token-de-prueba',
      'api_role': rolConSesion,
      'api_user_id': usuario['id'] as int,
      'api_username': usuario['username'] as String,
    },
    if (pacienteActual != null) 'api_patient_id': pacienteActual,
  });

  final dio = Dio(BaseOptions(baseUrl: 'http://servidor-simulado/api/v1'))..httpClientAdapter = servidor;
  final container = ProviderContainer(overrides: [
    dioProvider.overrideWith((ref) => dio),
    apiServiceProvider.overrideWith((ref) async {
      final api = ApiService(ref.watch(dioProvider));
      await api.init();
      return api;
    }),
    // Base local (caché y cola offline) en memoria en vez de un archivo en disco.
    localDatabaseProvider.overrideWith(
      (ref) async => LocalDatabaseService(database: await databaseFactoryMemory.openDatabase('app-${_bases++}.db')),
    ),
    // El generador de informes usa otra URL base (sin /api/v1), pero el mismo servidor simulado.
    reporteCognitivoServiceProvider.overrideWithValue(
      ReporteCognitivoService(dio: Dio(BaseOptions(baseUrl: 'http://servidor-simulado'))..httpClientAdapter = servidor),
    ),
  ]);
  addTearDown(container.dispose);

  // El router consulta el rol de forma síncrona: el servicio debe estar listo antes.
  await container.read(apiServiceProvider.future);

  await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const MyApp()));
  await esperar(tester);
  return container;
}

/// Navega con el router real de la app (como lo haría un enlace o un botón).
Future<void> irA(WidgetTester tester, ProviderContainer container, String ruta, {Object? extra}) async {
  container.read(routerProvider).go(ruta, extra: extra);
  await esperar(tester);
}

/// Ruta de la pantalla visible (la de arriba de la pila, también tras un push).
String rutaActual(ProviderContainer container) =>
    container.read(routerProvider).routerDelegate.currentConfiguration.last.matchedLocation;

/// Avanza el reloj de la prueba lo suficiente para que terminen cargas y
/// animaciones, sin depender de pumpAndSettle (hay animaciones en bucle).
Future<void> esperar(WidgetTester tester, {int pasos = 25}) async {
  for (var i = 0; i < pasos; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Toca un elemento como lo haría el usuario: primero lo desplaza a la vista.
/// Si el toque no cae sobre el elemento, la prueba falla (no solo avisa).
Future<void> tocar(WidgetTester tester, Finder elemento, {int pasos = 25}) async {
  WidgetController.hitTestWarningShouldBeFatal = true;
  await tester.pump(); // aplica desplazamientos pendientes (p. ej. del foco de un campo)
  await tester.ensureVisible(elemento);
  await tester.pump(const Duration(milliseconds: 100));
  await tester.tap(elemento);
  await esperar(tester, pasos: pasos);
}
