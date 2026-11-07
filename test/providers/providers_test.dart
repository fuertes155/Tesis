// Proveedores reales de Riverpod: cliente HTTP con token, servicios,
// sincronización por conectividad, tema y arranque de la app.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/core/database/local_database_service.dart';
import 'package:flutter_application_1/main.dart' as app;
import 'package:flutter_application_1/providers/api_providers.dart';
import 'package:flutter_application_1/providers/data_providers.dart';
import 'package:flutter_application_1/providers/theme_provider.dart';
import 'package:flutter_application_1/services/sync_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/servidor_simulado.dart';

var _n = 0;

/// Contenedor con los proveedores reales; solo se cambian la red y el disco.
ProviderContainer contenedor(ServidorSimulado servidor) {
  final c = ProviderContainer(overrides: [
    localDatabaseProvider.overrideWith(
      (ref) async => LocalDatabaseService(database: await databaseFactoryMemory.openDatabase('prov-${_n++}.db')),
    ),
  ]);
  c.read(dioProvider).httpClientAdapter = servidor;
  addTearDown(c.dispose);
  return c;
}

const _conectividad = EventChannel('dev.fluttercommunity.plus/connectivity_status');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({
        'api_token': 'tok-36',
        'api_role': 'doctor',
        'api_user_id': 36,
        'api_username': 'samuel@gmail.com',
      }));

  group('dioProvider', () {
    test('apunta a /api/v1 y envía el token guardado', () async {
      final servidor = ServidorSimulado(pacientes: [pacienteEjemplo()]);
      final c = contenedor(servidor);
      final dio = c.read(dioProvider);
      expect(dio.options.baseUrl, endsWith('/api/v1'));

      await dio.get('/patients/');
      expect(servidor.encabezados['GET /patients/']!['Authorization'], 'Bearer tok-36');
    });

    test('sin token no envía Authorization', () async {
      SharedPreferences.setMockInitialValues({});
      final servidor = ServidorSimulado();
      await contenedor(servidor).read(dioProvider).get('/users/');
      expect(servidor.encabezados['GET /users/']!.containsKey('Authorization'), isFalse);
    });

    test('un 401 borra la sesión guardada', () async {
      final servidor = ServidorSimulado()..fallar('GET /users/me', estado: 401);
      final c = contenedor(servidor);
      await expectLater(c.read(dioProvider).get('/users/me'), throwsA(isA<DioException>()));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('api_token'), isNull);
      expect(prefs.getString('api_role'), isNull);
      expect(prefs.getInt('api_user_id'), isNull);
    });

    test('otros errores conservan la sesión', () async {
      final servidor = ServidorSimulado()..fallar('GET /users/me', estado: 500);
      final c = contenedor(servidor);
      await expectLater(c.read(dioProvider).get('/users/me'), throwsA(isA<DioException>()));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('api_token'), 'tok-36');
    });
  });

  group('servicios', () {
    test('los proveedores entregan servicios listos para usar', () async {
      final servidor = ServidorSimulado(pacientes: [pacienteEjemplo()], sesiones: [sesionEjemplo()]);
      final c = contenedor(servidor);
      expect(await c.read(sharedPrefsProvider.future), isA<SharedPreferences>());

      final auth = await c.read(authServiceProvider.future);
      expect(auth.currentRole, 'doctor');
      final pacientes = await c.read(patientServiceProvider.future);
      expect(await pacientes.getPatients(), hasLength(1));
      final sesiones = await c.read(sessionServiceProvider.future);
      expect(await sesiones.getSessions(), hasLength(1));
      final api = await c.read(apiServiceProvider.future);
      expect(api.currentUserId, 36);
    });

    test('el doctor solo ve a sus pacientes asignados', () async {
      final servidor = ServidorSimulado(pacientes: [
        pacienteEjemplo(),
        pacienteEjemplo(id: 28, doctorId: 99),
      ]);
      final c = contenedor(servidor);
      expect((await c.read(patientsProvider.future)).map((p) => p.id), [21]);
      expect((await c.read(assignedPatientsProvider.future)).map((p) => p.id), [21]);
    });

    test('el gestor ve todos; si falla el perfil también se muestran todos', () async {
      final pacientes = [pacienteEjemplo(), pacienteEjemplo(id: 28, doctorId: 99)];
      final gestor = ServidorSimulado(pacientes: pacientes)..usuarioActual = ServidorSimulado.gestor;
      expect(await contenedor(gestor).read(patientsProvider.future), hasLength(2));

      final sinPerfil = ServidorSimulado(pacientes: pacientes)..fallar('GET /users/me');
      expect(await contenedor(sinPerfil).read(patientsProvider.future), hasLength(2));
    });
  });

  group('SyncService', () {
    testWidgets('al recuperar la conexión y cada 5 minutos envía la cola', (tester) async {
      // El canal se simula dentro de la prueba para que sus eventos usen el reloj simulado.
      MockStreamHandlerEventSink? red;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockStreamHandler(
        _conectividad,
        MockStreamHandler.inline(onListen: (args, sink) {
          red = sink;
        }),
      );
      addTearDown(() =>
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockStreamHandler(_conectividad, null));

      // Todo corre con el reloj simulado: cada pump avanza futuros y temporizadores.
      Future<T> resolver<T>(Future<T> futuro) async {
        late T valor;
        var listo = false;
        futuro.then((v) {
          valor = v;
          listo = true;
        });
        for (var i = 0; i < 100 && !listo; i++) {
          await tester.pump(const Duration(milliseconds: 10));
        }
        expect(listo, isTrue, reason: 'la operación no terminó');
        return valor;
      }

      final servidor = ServidorSimulado(pacientes: [pacienteEjemplo()]);
      final c = ProviderContainer(overrides: [
        localDatabaseProvider.overrideWith(
          (ref) async => LocalDatabaseService(database: await databaseFactoryMemory.openDatabase('sync.db')),
        ),
      ]);
      c.read(dioProvider).httpClientAdapter = servidor;
      final db = await resolver(c.read(localDatabaseProvider.future));
      await resolver(c.read(syncServiceProvider.future));

      Future<int> pendientes() async => (await resolver(db.getPendingActions())).length;
      Future<void> encolar() => resolver(db.addPendingAction(
          'CREATE', 'results', {'patient_id': 21, 'game_name': 'stroop', 'score': 5, 'details': {}, 'metrics': {}}));

      await encolar();
      red!.success(['none']); // sin red: no intenta
      await tester.pump(const Duration(milliseconds: 50));
      expect(await pendientes(), 1);

      red!.success(['wifi']);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));
      expect(await pendientes(), 0);

      await encolar();
      await tester.pump(const Duration(minutes: 5));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));
      expect(await pendientes(), 0);
      expect(servidor.veces('POST', '/sessions/results'), 2);

      c.dispose(); // cancela el temporizador y la suscripción
      await resolver(db.close());
    });
  });

  group('ThemeNotifier', () {
    test('recupera el tema guardado y lo alterna', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': ThemeMode.dark.index});
      final c = ProviderContainer();
      addTearDown(c.dispose);
      c.read(themeProvider);
      await Future<void>.delayed(Duration.zero);
      expect(c.read(themeProvider), ThemeMode.dark);

      final tema = c.read(themeProvider.notifier);
      await tema.toggleTheme();
      expect(c.read(themeProvider), ThemeMode.light);
      await tema.toggleTheme();
      expect(c.read(themeProvider), ThemeMode.dark);

      tema.setTheme(ThemeMode.system);
      await Future<void>.delayed(Duration.zero);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('theme_mode'), ThemeMode.system.index);
    });

    test('sin preferencia guardada empieza en claro', () async {
      SharedPreferences.setMockInitialValues({});
      final c = ProviderContainer();
      addTearDown(c.dispose);
      expect(c.read(themeProvider), ThemeMode.light);
    });
  });

  testWidgets('main() arranca la app en la pantalla de inicio de sesión', (tester) async {
    SharedPreferences.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = false;
    await app.main();
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('INICIAR SESIÓN'), findsOneWidget);
  });
}
