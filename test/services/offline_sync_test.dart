import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/database/local_database_service.dart';
import 'package:flutter_application_1/services/api_service.dart';
import 'package:flutter_application_1/services/pending_actions_synchronizer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FaultServer implements HttpClientAdapter {
  int status = 200;
  DioExceptionType? networkError;
  Completer<void>? gate;
  final requests = <RequestOptions>[];
  dynamic body;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (gate != null) await gate!.future;
    if (networkError != null) {
      throw DioException(requestOptions: options, type: networkError!);
    }
    return ResponseBody.fromString(
      jsonEncode(body ?? {'id': 42, ...?options.data as Map<String, dynamic>?}),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FaultServer server;
  late LocalDatabaseService db;
  late ApiService api;
  late Dio dio;
  final date = DateTime.utc(2026, 1, 2, 10, 30);
  Future<void> create({bool skipOffline = false}) async {
    await api.createSession(
      patientId: 7,
      status: 'completed',
      notes: 'Prueba',
      date: date,
      durationMs: 12345,
      externalId: 'stable-id',
      skipOffline: skipOffline,
    );
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = LocalDatabaseService(
      database: await databaseFactoryMemory.openDatabase('test.db'),
    );
    await db.clearAll();
    server = FaultServer();
    dio = Dio(BaseOptions(baseUrl: 'https://test.invalid/api/v1'))
      ..httpClientAdapter = server;
    api = ApiService(dio, db);
    await api.init();
  });
  tearDown(() async {
    dio.close(force: true);
    await db.close();
  });
  for (final type in [
    DioExceptionType.connectionError,
    DioExceptionType.connectionTimeout,
    DioExceptionType.receiveTimeout,
  ]) {
    test('sin red ($type) persiste sesión y conserva sus datos', () async {
      server.networkError = type;
      await create();
      final queue = await db.getPendingActions();
      expect(queue, hasLength(1));
      expect(
        queue.single.value['data'],
        containsPair('external_id', 'stable-id'),
      );
      expect(queue.single.value['data'], containsPair('duration_ms', 12345));
    });
  }
  for (final status in [408, 429, 500, 503]) {
    test('HTTP $status conserva sesión para reintento', () async {
      server.status = status;
      await create();
      expect(await db.getPendingActions(), hasLength(1));
    });
  }
  for (final status in [400, 401, 403, 404, 409, 422]) {
    test(
      'HTTP $status se informa y no se convierte en éxito offline',
      () async {
        server.status = status;
        await expectLater(create(), throwsException);
        expect(await db.getPendingActions(), isEmpty);
      },
    );
  }
  test('cancelar no agrega una operación pendiente', () async {
    server.networkError = DioExceptionType.cancel;
    await expectLater(create(), throwsException);
    expect(await db.getPendingActions(), isEmpty);
  });
  test('skipOffline evita duplicar la cola cuando falla el reenvío', () async {
    server.networkError = DioExceptionType.connectionError;
    await expectLater(create(skipOffline: true), throwsException);
    expect(await db.getPendingActions(), isEmpty);
  });
  test(
    'un certificado rechazado no se presenta como sesión offline exitosa',
    () async {
      server.networkError = DioExceptionType.badCertificate;
      await expectLater(create(), throwsException);
      expect(await db.getPendingActions(), isEmpty);
    },
  );
  test('sincroniza con fecha, duración e identificador originales', () async {
    server.networkError = DioExceptionType.connectionError;
    await create();
    server.networkError = null;
    await PendingActionsSynchronizer(api, db).flush();
    expect(await db.getPendingActions(), isEmpty);
    expect(
      server.requests.last.data,
      containsPair('date', date.toIso8601String()),
    );
    expect(server.requests.last.data, containsPair('duration_ms', 12345));
    expect(server.requests.last.data, containsPair('external_id', 'stable-id'));
    expect(server.requests.last.path, '/sessions/');
  });
  test(
    'un rechazo durante sincronización conserva registro y sucesores',
    () async {
      server.networkError = DioExceptionType.connectionError;
      await create();
      await create();
      server.networkError = null;
      server.status = 404;
      final count = server.requests.length;
      await PendingActionsSynchronizer(api, db).flush();
      expect(await db.getPendingActions(), hasLength(2));
      expect(server.requests.length, count + 1);
    },
  );
  test('dos sincronizaciones simultáneas envían una sola vez', () async {
    server.networkError = DioExceptionType.connectionError;
    await create();
    server.networkError = null;
    server.gate = Completer<void>();
    final sync = PendingActionsSynchronizer(api, db);
    final first = sync.flush();
    final second = sync.flush();
    server.gate!.complete();
    await Future.wait([first, second]);
    expect(server.requests, hasLength(2));
    expect(await db.getPendingActions(), isEmpty);
  });
  test('caché de pacientes se utiliza sin red, nunca ante 403', () async {
    server.body = [
      {'id': 7, 'name': 'Paciente Sintético', 'age': 70},
    ];
    await api.getPatients();
    server.networkError = DioExceptionType.connectionError;
    expect((await api.getPatients()).single.name, 'Paciente Sintético');
    server.networkError = null;
    server.status = 403;
    await expectLater(api.getPatients(), throwsException);
  });
  test('logout borra credenciales y no restaura sesión al reiniciar', () async {
    SharedPreferences.setMockInitialValues({
      'api_token': 'secret',
      'api_username': 'doctor',
      'api_role': 'doctor',
      'api_user_id': 5,
    });
    final loggedIn = ApiService(dio, db);
    await loggedIn.init();
    await loggedIn.logout();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('api_token'), isNull);
    final restarted = ApiService(dio, db);
    await restarted.init();
    expect(restarted.currentRole, isNull);
    expect(restarted.currentUserId, isNull);
  });
  test(
    'cola heredada envía sesiones a su ruta y retiene los errores',
    () async {
      await api.enqueuePendingSession(
        patientId: 7,
        status: 'completed',
        notes: '',
        date: date.toIso8601String(),
        externalId: 'legacy',
      );
      server.status = 503;
      await api.flushPendingSessions();
      final prefs = await SharedPreferences.getInstance();
      expect(jsonDecode(prefs.getString('pending_sessions_v1')!), hasLength(1));
      server.status = 200;
      await api.flushPendingSessions();
      expect(prefs.getString('pending_sessions_v1'), isNull);
      expect(server.requests.every((r) => r.path == '/sessions/'), isTrue);
    },
  );
  test('una sesión agregada durante el envío heredado no se pierde', () async {
    await api.enqueuePendingSession(
      patientId: 7,
      status: 'completed',
      notes: '',
      date: date.toIso8601String(),
      externalId: 'first',
    );
    server.gate = Completer<void>();
    final flushing = api.flushPendingSessions();
    final added = api.enqueuePendingSession(
      patientId: 7,
      status: 'completed',
      notes: '',
      date: date.toIso8601String(),
      externalId: 'second',
    );
    server.gate!.complete();
    await Future.wait([flushing, added]);
    final prefs = await SharedPreferences.getInstance();
    final queue = jsonDecode(prefs.getString('pending_sessions_v1')!) as List;
    expect(queue, hasLength(1));
    expect(queue.single['external_id'], 'second');
  });
}
