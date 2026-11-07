// ApiService contra el servidor simulado: validaciones, mensajes de error,
// caché local y cola offline de cada operación.
import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/database/local_database_service.dart';
import 'package:flutter_application_1/services/api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/servidor_simulado.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ServidorSimulado servidor;
  late LocalDatabaseService db;
  late ApiService api;
  late ApiService sinCache;
  var n = 0;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    servidor = ServidorSimulado(
      pacientes: [pacienteEjemplo()],
      sesiones: [sesionEjemplo()],
      reportes: [reporteEjemplo()],
    );
    final dio = Dio(BaseOptions(baseUrl: 'http://servidor-simulado/api/v1'))..httpClientAdapter = servidor;
    db = LocalDatabaseService(database: await databaseFactoryMemory.openDatabase('api-${n++}.db'));
    api = ApiService(dio, db);
    sinCache = ApiService(dio);
    await api.init();
    await sinCache.init();
  });
  tearDown(() => db.close());

  Future<List<String>> accionesPendientes() async =>
      [for (final r in await db.getPendingActions()) '${r.value['action']} ${r.value['entity']}'];

  group('estado de la sesión', () {
    test('los datos de sesión se guardan y se recuperan en otra instancia', () async {
      api
        ..setToken('t-1')
        ..setCurrentUsername('ana@x.com')
        ..setCurrentRole('gestor')
        ..setCurrentUserId(9)
        ..setCurrentPatientId(21)
        ..setCurrentPatientName('Jorge');
      await Future<void>.delayed(Duration.zero);
      expect(api.currentPatientName, 'Jorge');

      final otra = ApiService(Dio());
      await otra.init();
      await otra.init(); // la segunda vez no vuelve a leer
      expect(otra.currentUsername, 'ana@x.com');
      expect(otra.currentRole, 'gestor');
      expect(otra.currentUserId, 9);
      expect(otra.currentPatientId, 21);

      await api.logout();
      expect(api.currentRole, isNull);
      expect(api.currentPatientName, isNull);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('api_token'), isNull);
    });

    test('filtros del inicio y avisos de una sola lectura', () {
      api.setHomeFilters(days: 30, status: 'completed');
      api.setHomeSearchAndSort(query: 'jorge', sortMode: 'recent');
      expect(api.homeDaysFilter, 30);
      expect(api.homeStatusFilter, 'completed');
      expect(api.homeSearchQuery, 'jorge');
      expect(api.homeSortMode, 'recent');

      api.pushNotice('patient_deleted');
      expect(api.takeNotice(), 'patient_deleted');
      expect(api.takeNotice(), isNull);
    });
  });

  group('autenticación', () {
    test('login exige usuario y contraseña', () async {
      await expectLater(api.login(' ', 'x'), throwsA(predicate((e) => '$e'.contains('usuario es requerido'))));
      await expectLater(api.login('a', ' '), throwsA(predicate((e) => '$e'.contains('contraseña es requerida'))));
    });

    test('login guarda el usuario aunque el id llegue como texto', () async {
      servidor.usuarios.add({...ServidorSimulado.doctor, 'id': '77', 'username': 'texto@x.com'});
      await api.login('texto@x.com', ServidorSimulado.clave);
      expect(api.currentUserId, 77);
      expect(api.currentRole, 'doctor');
    });

    test('mensajes de error del login', () async {
      servidor.fallar('POST /users/auth/login', estado: 401, cuerpo: {});
      await expectLater(api.login('a', 'b'), throwsA(predicate((e) => '$e'.contains('Credenciales inválidas'))));
      servidor.fallar('POST /users/auth/login', estado: 404, cuerpo: {});
      await expectLater(api.login('a', 'b'), throwsA(predicate((e) => '$e'.contains('Usuario no registrado'))));
      servidor.fallar('POST /users/auth/login', estado: 500, cuerpo: {});
      await expectLater(api.login('a', 'b'), throwsA(predicate((e) => '$e'.contains('Error al iniciar sesión'))));
    });

    test('verificación en dos pasos', () async {
      expect(await api.verify2FA('samuel@gmail.com', ServidorSimulado.codigo2fa), isTrue);
      await expectLater(api.verify2FA('samuel@gmail.com', '000000'),
          throwsA(predicate((e) => '$e'.contains('Código de verificación incorrecto'))));
      servidor.fallar('POST /users/verify-2fa', estado: 500, cuerpo: {});
      await expectLater(api.verify2FA('a', '1'), throwsA(predicate((e) => '$e'.contains('Código de verificación'))));
    });

    test('registro público guarda el token y el rol', () async {
      final r = await api.register(username: 'nuevo@x.com', password: 'Clave123!', fullName: 'Nuevo');
      expect(r['access_token'], isNotNull);
      expect(api.currentUsername, 'nuevo@x.com');
      expect(api.currentRole, 'doctor');
      expect(api.currentUserId, isNotNull);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('api_token'), r['access_token']);

      servidor.fallar('POST /users/auth/register', estado: 200, cuerpo: {'user': {'id': '15'}});
      await api.register(username: 'otro@x.com', password: 'x', role: 'user');
      expect(api.currentUserId, 15);
      expect(api.currentRole, 'user');

      servidor.fallar('POST /users/auth/register');
      await expectLater(api.register(username: 'x', password: 'y'), throwsA(predicate((e) => '$e'.contains('registrar'))));
    });

    test('restablecer contraseña', () async {
      final r = await api.resetPassword('samuel@gmail.com', 'Nueva123!', fullName: 'Samuel');
      expect(r['status'], 'success');
      expect((servidor.cuerpos['POST /users/reset'] as Map)['role'], 'doctor');
      await expectLater(api.resetPassword('nadie@x.com', 'x'), throwsA(predicate((e) => '$e'.contains('restablecer'))));
    });
  });

  group('usuarios', () {
    test('crear, editar, cambiar disponibilidad y eliminar', () async {
      final creado = await api.adminCreateUser(
          username: 'dra@x.com', password: 'Clave123!', role: 'doctor', fullName: 'Dra', documentId: '1');
      final id = creado['id'] as int;

      final editado = await api.updateUser(id, {'full_name': 'Dra. Ana'});
      expect(editado.fullName, 'Dra. Ana');
      final disp = await api.updateUserAvailability(id, false);
      expect(disp['is_available'], isFalse);
      await api.deleteUser(id);
      expect(servidor.usuarios.any((u) => u['id'] == id), isFalse);
    });

    test('errores de usuarios', () async {
      await expectLater(api.adminCreateUser(username: 'samuel@gmail.com', password: 'x', role: 'doctor'),
          throwsA(predicate((e) => '$e'.contains('El usuario ya existe'))));
      servidor.fallar('POST /users/register', cuerpo: {});
      await expectLater(api.adminCreateUser(username: 'z', password: 'x', role: 'doctor'),
          throwsA(predicate((e) => '$e'.contains('Error al crear usuario'))));
      await expectLater(api.updateUser(999, {}), throwsA(predicate((e) => '$e'.contains('editar usuario'))));
      await expectLater(
          api.updateUserAvailability(999, true), throwsA(predicate((e) => '$e'.contains('disponibilidad'))));
      await expectLater(api.deleteUser(999), throwsA(predicate((e) => '$e'.contains('eliminar usuario'))));
    });

    test('la lista se guarda en caché y se usa sin conexión', () async {
      expect(await api.getUsers(), hasLength(2));
      expect(await db.getLastSync('users'), isNotNull);
      servidor.sinConexion('GET /users/');
      expect(await api.getUsers(), hasLength(2));
      await expectLater(sinCache.getUsers(), throwsA(predicate((e) => '$e'.contains('obtener usuarios'))));
    });
  });

  group('pacientes', () {
    test('crear exige nombre y edad', () async {
      await expectLater(api.createPatient({'age': 3}), throwsA(predicate((e) => '$e'.contains('nombre'))));
      await expectLater(api.createPatient({'name': ''}), throwsA(predicate((e) => '$e'.contains('nombre'))));
      await expectLater(api.createPatient({'name': 'A'}), throwsA(predicate((e) => '$e'.contains('edad'))));
    });

    test('crear, editar, asignar médico y eliminar', () async {
      final p = await api.createPatient({'name': 'Ana', 'age': 70});
      expect(p.id, greaterThan(0));
      final editado = await api.updatePatient(p.id, {'name': 'Ana María', 'age': 71});
      expect(editado.name, 'Ana María');
      final asignado = await api.assignDoctorToPatient(p.id, 36);
      expect(asignado['doctor_id'], 36);
      await api.deletePatient(p.id);
      expect(servidor.pacientes.any((x) => x['id'] == p.id), isFalse);
    });

    test('sin conexión las operaciones quedan en cola', () async {
      for (final r in ['POST /patients/', 'PUT /patients/21', 'DELETE /patients/21']) {
        servidor.sinConexion(r);
      }
      final creado = await api.createPatient({'name': 'Offline', 'age': 60});
      expect(creado.id, -1);
      expect(creado.externalId, startsWith('p-'));
      final editado = await api.updatePatient(21, {'name': 'Jorge', 'age': 80});
      expect(editado.id, 21);
      await api.deletePatient(21);
      expect(await accionesPendientes(), ['CREATE patients', 'UPDATE patients', 'DELETE patients']);
    });

    test('un rechazo del servidor no se encola', () async {
      servidor.fallar('POST /patients/', estado: 422, cuerpo: {'detail': 'Documento duplicado'});
      await expectLater(api.createPatient({'name': 'A', 'age': 1}), throwsA(predicate((e) => '$e'.contains('duplicado'))));
      servidor.fallar('POST /patients/', estado: 409, cuerpo: {});
      await expectLater(api.createPatient({'name': 'A', 'age': 1}), throwsA(predicate((e) => '$e'.contains('crear paciente'))));
      await expectLater(api.updatePatient(999, {}), throwsA(predicate((e) => '$e'.contains('editar paciente'))));
      await expectLater(api.deletePatient(999), throwsA(predicate((e) => '$e'.contains('eliminar paciente'))));
      await expectLater(api.assignDoctorToPatient(999, 1), throwsA(predicate((e) => '$e'.contains('asignar médico'))));
      // Sin conexión pero sin base local tampoco hay cola.
      servidor.sinConexion('POST /patients/');
      await expectLater(sinCache.createPatient({'name': 'A', 'age': 1}), throwsA(isA<Exception>()));
      expect(await accionesPendientes(), isEmpty);
    });

    test('la ficha de un paciente sale de la caché si no hay red', () async {
      await api.getPatients();
      servidor.sinConexion('GET /patients/21');
      expect((await api.getPatient(21)).name, 'Jorge Enrique Salazar Mejía');
      servidor.sinConexion('GET /patients/5');
      await expectLater(api.getPatient(5), throwsA(predicate((e) => '$e'.contains('cargar paciente'))));
    });

    test('conteo de sesiones con y sin el endpoint de conteo', () async {
      servidor.sesiones.addAll([sesionEjemplo(id: 2), sesionEjemplo(id: 3, pacienteId: 28)]);
      expect(await api.getSessionsCountForPatient(21), 2);

      servidor.fallar('GET /sessions/count', estado: 200, cuerpo: {'count': '4'});
      expect(await api.getSessionsCountForPatient(21), 4);
      servidor.fallar('GET /sessions/count', estado: 200, cuerpo: {'count': null});
      expect(await api.getSessionsCountForPatient(21), 0);

      servidor.fallar('GET /sessions/count', estado: 404);
      expect(await api.getSessionsCountForPatient(21), 2); // cuenta la lista
      servidor.fallar('GET /sessions/', estado: 500);
      await expectLater(api.getSessionsCountForPatient(21), throwsA(predicate((e) => '$e'.contains('obtener sesiones'))));
    });
  });

  group('sesiones y resultados', () {
    test('crear sesión valida paciente y estado y genera un identificador', () async {
      await expectLater(api.createSession(patientId: 0, status: 'x', notes: ''), throwsA(isA<Exception>()));
      await expectLater(api.createSession(patientId: 1, status: ' ', notes: ''), throwsA(isA<Exception>()));
      api.setCurrentUserId(36);
      api.setCurrentPatientId(21);
      final s = await api.createSession(patientId: 21, status: 'completed', notes: 'ok');
      expect(s.externalId, startsWith('s-36-21-'));
    });

    test('la lista de sesiones se guarda en caché y se usa sin conexión', () async {
      expect(await api.getSessions(), hasLength(1));
      servidor.sinConexion('GET /sessions/');
      expect(await api.getSessions(), hasLength(1));
      await expectLater(sinCache.getSessions(), throwsA(predicate((e) => '$e'.contains('obtener sesiones'))));
    });

    test('enviar resultados valida los datos', () async {
      await expectLater(api.submitGameResults(patientId: 0, gameName: 'x', results: {'score': 1}), throwsA(isA<Exception>()));
      await expectLater(api.submitGameResults(patientId: 1, gameName: ' ', results: {'score': 1}), throwsA(isA<Exception>()));
      await expectLater(api.submitGameResults(patientId: 1, gameName: 'x', results: {}), throwsA(isA<Exception>()));
    });

    test('el puntaje se normaliza y la sesión se adjunta', () async {
      await api.submitGameResults(patientId: 21, gameName: 'stroop', results: {'score': '57'}, sessionId: 4);
      final enviado = servidor.cuerpos['POST /sessions/results'] as Map;
      expect(enviado['score'], 57);
      expect(enviado['session_id'], 4);
      await api.submitGameResults(patientId: 21, gameName: 'stroop', results: {'score': 'n/d'});
      expect((servidor.cuerpos['POST /sessions/results'] as Map)['score'], 0);
    });

    test('sin conexión el resultado queda en cola; un rechazo no', () async {
      servidor.sinConexion('POST /sessions/results');
      await api.submitGameResults(patientId: 21, gameName: 'reaction', results: {'score': 50});
      expect(await accionesPendientes(), ['CREATE results']);
      servidor.fallar('POST /sessions/results', estado: 400);
      await expectLater(api.submitGameResults(patientId: 21, gameName: 'reaction', results: {'score': 50}),
          throwsA(predicate((e) => '$e'.contains('enviar resultados'))));
    });

    test('errores al leer resultados e informes', () async {
      servidor.fallar('GET /sessions/results/latest');
      await expectLater(api.getLatestResultsForPatient(21), throwsA(predicate((e) => '$e'.contains('resultados'))));
      servidor.fallar('GET /evaluacion/reportes/21');
      await expectLater(api.getReportesByPatient('21'), throwsA(predicate((e) => '$e'.contains('historial'))));
      servidor.fallar('GET /evaluacion/reportes');
      await expectLater(api.getAllReportes(), throwsA(predicate((e) => '$e'.contains('historial'))));
    });
  });
}
