// Servicios auxiliares: AuthService, PatientService, SessionService,
// generador de informes, base local y sincronizador de la cola offline.
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/core/database/local_database_service.dart';
import 'package:flutter_application_1/models/reporte_cognitivo_model.dart';
import 'package:flutter_application_1/services/api_service.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/services/patient_service.dart';
import 'package:flutter_application_1/services/pending_actions_synchronizer.dart';
import 'package:flutter_application_1/services/reporte_cognitivo_service.dart';
import 'package:flutter_application_1/services/session_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/servidor_simulado.dart';

Matcher fallaCon(String texto) => throwsA(predicate((e) => '$e'.contains(texto), 'error con "$texto"'));

/// Adaptador que falla siempre con el tipo de error de red indicado.
class RedQueFalla implements HttpClientAdapter {
  RedQueFalla(this.tipo);
  final DioExceptionType tipo;
  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<Uint8List>? s, Future<void>? c) async =>
      throw DioException(requestOptions: o, type: tipo);
  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ServidorSimulado servidor;
  late Dio dio;
  late LocalDatabaseService db;
  var n = 0;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    servidor = ServidorSimulado(pacientes: [pacienteEjemplo()], sesiones: [sesionEjemplo()]);
    servidor.resultados.addAll(bateriaEjemplo(21, '2026-09-16', [40, 45, 34, 37]));
    dio = Dio(BaseOptions(baseUrl: 'http://servidor-simulado/api/v1'))..httpClientAdapter = servidor;
    db = LocalDatabaseService(database: await databaseFactoryMemory.openDatabase('srv-${n++}.db'));
  });
  tearDown(() => db.close());

  group('AuthService', () {
    test('login, perfil y cierre de sesión', () async {
      final auth = AuthService(dio);
      await auth.init();
      expect(auth.token, isNull);

      await auth.login('samuel@gmail.com', ServidorSimulado.clave);
      expect(auth.token, 'token-36');
      expect(auth.currentUsername, 'samuel@gmail.com');
      expect(auth.currentRole, 'doctor');
      expect(auth.currentUserId, 36);

      final otra = AuthService(dio);
      await otra.init();
      expect(otra.currentUserId, 36);

      final me = await auth.getMe();
      expect(me.username, 'samuel@gmail.com');

      await auth.logout();
      expect(auth.token, isNull);
      expect(auth.currentRole, isNull);
    });

    test('login con id como texto y sin rol', () async {
      servidor.fallar('POST /users/auth/login', estado: 200, cuerpo: {
        'access_token': 't',
        'user': {'id': '8'},
      });
      final auth = AuthService(dio);
      await auth.login('x@x.com', 'y');
      expect(auth.currentUserId, 8);
      expect(auth.currentRole, 'doctor');
      expect(auth.currentUsername, 'x@x.com');
    });

    test('errores', () async {
      final auth = AuthService(dio);
      await expectLater(auth.login('samuel@gmail.com', 'mala'), fallaCon('Credenciales inválidas'));
      servidor.fallar('POST /users/auth/login');
      await expectLater(auth.login('a', 'b'), fallaCon('Error al iniciar sesión'));
      servidor.fallar('GET /users/me');
      await expectLater(auth.getMe(), fallaCon('Error al obtener perfil'));
    });
  });

  group('PatientService', () {
    test('operaciones sobre pacientes', () async {
      final s = PatientService(dio, db);
      expect(await s.getPatients(), hasLength(1));
      expect((await s.getPatient(21)).age, 80);
      final p = await s.createPatient({'name': 'Ana', 'age': 70});
      expect((await s.updatePatient(p.id, {'name': 'Ana M.'})).name, 'Ana M.');
      await s.assignDoctor(p.id, 36);
      expect(servidor.pacientes.last['doctor_id'], 36);
      await s.deletePatient(p.id);
      expect(servidor.pacientes, hasLength(1));
    });

    test('sin conexión usa la caché; sin caché informa el error', () async {
      final s = PatientService(dio, db);
      await s.getPatients();
      await Future<void>.delayed(const Duration(milliseconds: 10)); // la caché se guarda en segundo plano
      servidor.sinConexion('GET /patients/');
      expect(await s.getPatients(), hasLength(1));
      await expectLater(PatientService(dio).getPatients(), fallaCon('Error al cargar pacientes'));
      await db.clearAll();
      await expectLater(s.getPatients(), fallaCon('Error al cargar pacientes'));
    });

    test('errores', () async {
      final s = PatientService(dio);
      await expectLater(s.getPatient(9), fallaCon('Error al cargar paciente'));
      servidor.fallar('POST /patients/');
      await expectLater(s.createPatient({}), fallaCon('Error al crear paciente'));
      await expectLater(s.deletePatient(9), fallaCon('Error al eliminar paciente'));
      await expectLater(s.updatePatient(9, {}), fallaCon('Error al actualizar paciente'));
      await expectLater(s.assignDoctor(9, 1), fallaCon('Error al asignar médico'));
    });
  });

  group('SessionService', () {
    test('sesiones y resultados', () async {
      final s = SessionService(dio, db);
      expect(await s.getSessions(), hasLength(1));
      final nueva = await s.createSession(patientId: 21, status: 'completed', notes: 'ok', date: DateTime(2026, 1, 2));
      expect(nueva.patientId, 21);
      await s.createSession(patientId: 21, status: 'pending', notes: '');
      await s.submitResults(patientId: 21, gameName: 'stroop', results: {'score': 3}, sessionId: 1);
      expect((servidor.cuerpos['POST /sessions/results'] as Map)['results'], {'score': 3});
      expect(await s.getLatestResults(21), hasLength(5)); // 4 de la batería + el recién enviado
    });

    test('sin conexión usa la caché; sin caché informa el error', () async {
      final s = SessionService(dio, db);
      await s.getSessions();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      servidor.sinConexion('GET /sessions/');
      expect(await s.getSessions(), hasLength(1));
      await expectLater(SessionService(dio).getSessions(), fallaCon('Error al cargar sesiones'));
      await db.clearAll();
      await expectLater(s.getSessions(), fallaCon('Error al cargar sesiones'));
    });

    test('errores', () async {
      final s = SessionService(dio);
      servidor
        ..fallar('POST /sessions/')
        ..fallar('POST /sessions/results')
        ..fallar('GET /sessions/results/latest');
      await expectLater(s.createSession(patientId: 1, status: 'x', notes: ''), fallaCon('Error al crear sesión'));
      await expectLater(s.submitResults(patientId: 1, gameName: 'x', results: {}), fallaCon('Error al enviar resultados'));
      await expectLater(s.getLatestResults(1), fallaCon('Error al obtener últimos resultados'));
    });
  });

  group('ReporteCognitivoService', () {
    const solicitud = SolicitudReporteCognitivoModel(
      pacienteId: '10234587', nombrePaciente: 'Jorge', edadPaciente: 80, fechaEvaluacion: '2026-09-16',
      profesional: 'Samuel', pruebas: [PruebaCognitivaModel(nombrePrueba: 'Memoria Visual', porcentajeObtenido: 40, tiempoSegundos: 31)],
    );
    ReporteCognitivoService conServidor() =>
        ReporteCognitivoService(dio: Dio(BaseOptions(baseUrl: 'http://x'))..httpClientAdapter = servidor);

    test('el provider crea el servicio con la URL por defecto', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      expect(c.read(reporteCognitivoServiceProvider), isA<ReporteCognitivoService>());
    });

    test('genera el informe y envía la solicitud completa', () async {
      servidor.reporteGenerado = reporteEjemplo();
      final r = await conServidor().generarReporte(solicitud);
      expect(r.nombrePaciente, 'Jorge Enrique Salazar Mejía');
      expect((servidor.cuerpos['POST /evaluacion/generar-reporte'] as Map)['pruebas'], hasLength(1));
    });

    test('muestra el detalle que envía el backend', () async {
      await expectLater(conServidor().generarReporte(solicitud), fallaCon('Ollama no disponible'));
    });

    test('mensajes según el tipo de fallo de red', () async {
      Future<void> conRed(DioExceptionType tipo, String texto) => expectLater(
          ReporteCognitivoService(dio: Dio()..httpClientAdapter = RedQueFalla(tipo)).generarReporte(solicitud),
          fallaCon(texto));
      await conRed(DioExceptionType.connectionTimeout, 'tardó más de 10 minutos');
      await conRed(DioExceptionType.receiveTimeout, 'tardó más de 10 minutos');
      await conRed(DioExceptionType.sendTimeout, 'tardó más de 10 minutos');
      await conRed(DioExceptionType.connectionError, 'No se pudo conectar con el backend');
      await conRed(DioExceptionType.cancel, 'Error al generar el reporte cognitivo');
    });

    test('un error sin detalle o una respuesta inválida', () async {
      servidor.fallar('POST /evaluacion/generar-reporte', estado: 500, cuerpo: {'detail': ''});
      await expectLater(conServidor().generarReporte(solicitud), fallaCon('Error al generar el reporte cognitivo'));
      servidor.fallar('POST /evaluacion/generar-reporte', estado: 500, cuerpo: ['no es un objeto']);
      await expectLater(conServidor().generarReporte(solicitud), fallaCon('Error al generar el reporte cognitivo'));
      servidor.fallar('POST /evaluacion/generar-reporte', estado: 200, cuerpo: ['no es un objeto']);
      await expectLater(conServidor().generarReporte(solicitud), fallaCon('Error inesperado'));
    });
  });

  group('LocalDatabaseService', () {
    test('guarda y lee sesiones, usuarios y marcas de sincronización', () async {
      await db.saveSessions([sesionEjemplo(), sesionEjemplo(id: 2)]);
      expect(await db.getSessions(), hasLength(2));
      await db.saveUsers([ServidorSimulado.doctor]);
      expect((await db.getUsers()).single['username'], 'samuel@gmail.com');
      expect(await db.getLastSync('users'), isNull);
      final ahora = DateTime(2026, 11, 6, 10);
      await db.setLastSync('users', ahora);
      expect(await db.getLastSync('users'), ahora);
    });

    test('init abre la base en la carpeta de documentos de la app', () async {
      final carpeta = await Directory.systemTemp.createTemp('neuroapp');
      addTearDown(() => carpeta.delete(recursive: true));
      const canal = MethodChannel('plugins.flutter.io/path_provider');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(canal, (llamada) async => '${carpeta.path}${Platform.pathSeparator}docs');
      addTearDown(() =>
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(canal, null));

      final c = ProviderContainer();
      addTearDown(c.dispose);
      final local = await c.read(localDatabaseProvider.future);
      await local.savePatients([pacienteEjemplo()]);
      expect(await local.getPatients(), hasLength(1));
      await local.close();
      expect(File('${carpeta.path}${Platform.pathSeparator}docs${Platform.pathSeparator}neuroapp_local.db').existsSync(),
          isTrue);
    });
  });

  group('PendingActionsSynchronizer', () {
    late ApiService api;
    setUp(() async {
      api = ApiService(dio, db);
      await api.init();
    });

    test('envía en orden y enlaza al paciente creado sin conexión', () async {
      await db.addPendingAction('CREATE', 'patients', {'id': -1, 'name': 'Offline', 'age': 60});
      await Future<void>.delayed(const Duration(milliseconds: 2));
      await db.addPendingAction('CREATE', 'results',
          {'patient_id': -1, 'game_name': 'stroop', 'score': 50, 'details': {}, 'metrics': {}, 'session_id': null});
      await Future<void>.delayed(const Duration(milliseconds: 2));
      await db.addPendingAction('CREATE', 'results',
          {'patient_id': 21, 'game_name': 'reaction', 'score': 40, 'details': {}, 'metrics': {}});
      await Future<void>.delayed(const Duration(milliseconds: 2));
      await db.addPendingAction('UPDATE', 'patients', {'id': 21, 'name': 'Jorge E.', 'age': 80});
      await Future<void>.delayed(const Duration(milliseconds: 2));
      await db.addPendingAction('DELETE', 'patients', {'id': 21});

      await PendingActionsSynchronizer(api, db).flush();

      expect(await db.getPendingActions(), isEmpty);
      final creado = servidor.pacientes.firstWhere((p) => p['name'] == 'Offline');
      final resultados = servidor.resultados.where((r) => r['game_name'] == 'stroop' && r['score'] == 50);
      expect(resultados.single['patient_id'], creado['id']); // ya no -1
      expect(servidor.pacientes.any((p) => p['id'] == 21), isFalse);
    });

    test('un paciente creado con id definitivo no reescribe dependientes', () async {
      await db.addPendingAction('CREATE', 'patients', {'name': 'Ana', 'age': 1});
      await Future<void>.delayed(const Duration(milliseconds: 2));
      await db.addPendingAction('CREATE', 'results',
          {'patient_id': 21, 'game_name': 'x', 'score': 1, 'details': {}, 'metrics': {}});
      await PendingActionsSynchronizer(api, db).flush();
      expect(servidor.resultados.last['patient_id'], 21);
    });

    test('se detiene en una acción desconocida y la conserva', () async {
      await db.addPendingAction('PATCH', 'patients', {'id': 21});
      await PendingActionsSynchronizer(api, db).flush();
      expect(await db.getPendingActions(), hasLength(1));
    });
  });
}
