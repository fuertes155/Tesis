import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart' as dio;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/patient.dart';
import '../models/session.dart';
import '../models/user.dart';
import '../core/database/local_database_service.dart';

class ApiService {
  final dio.Dio _dio;
  final LocalDatabaseService? _localDb;

  static final String baseUrl = const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000/api/v1',
  );
  static const _prefsTokenKey = 'api_token';
  static const _prefsUsernameKey = 'api_username';
  static const _prefsRoleKey = 'api_role';
  static const _prefsPatientIdKey = 'api_patient_id';
  static const _prefsUserIdKey = 'api_user_id';
  static const _prefsPendingSessionsKey = 'pending_sessions_v1';

  ApiService(this._dio, [this._localDb]);

  String? _token;
  String? _currentUsername;
  String? _currentRole;
  String? _currentPatientName;
  int? _currentUserId;
  int _currentPatientId = 1;
  int? _homeDaysFilter;
  String? _homeStatusFilter;
  String? _homeSearchQuery;
  String? _homeSortMode;
  String? _notice;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_prefsTokenKey);
    _currentUsername = prefs.getString(_prefsUsernameKey);
    _currentRole = prefs.getString(_prefsRoleKey);
    _currentUserId = prefs.getInt(_prefsUserIdKey);
    _currentPatientId = prefs.getInt(_prefsPatientIdKey) ?? 1;
    _initialized = true;

    if (_token != null) {
      // unawaited(flushPendingSessions()); // Deprecated in favor of SyncService
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    if (_token != null) await prefs.setString(_prefsTokenKey, _token!);
    if (_currentUsername != null) {
      await prefs.setString(_prefsUsernameKey, _currentUsername!);
    }
    if (_currentRole != null) {
      await prefs.setString(_prefsRoleKey, _currentRole!);
    }
    await prefs.setInt(_prefsPatientIdKey, _currentPatientId);
    if (_currentUserId != null) {
      await prefs.setInt(_prefsUserIdKey, _currentUserId!);
    }
  }

  Future<void> logout() async {
    _token = null;
    _currentUsername = null;
    _currentRole = null;
    _currentUserId = null;
    await _persist();
  }

  void setToken(String token) {
    _token = token;
    unawaited(_persist());
  }

  String? get currentUsername => _currentUsername;
  void setCurrentUsername(String username) {
    _currentUsername = username;
    unawaited(_persist());
  }

  String? get currentRole => _currentRole;
  void setCurrentRole(String role) {
    _currentRole = role;
    unawaited(_persist());
  }

  String? get currentPatientName => _currentPatientName;
  void setCurrentPatientName(String name) {
    _currentPatientName = name;
  }

  int? get currentUserId => _currentUserId;
  void setCurrentUserId(int userId) {
    _currentUserId = userId;
    unawaited(_persist());
  }

  int get currentPatientId => _currentPatientId;
  void setCurrentPatientId(int patientId) {
    _currentPatientId = patientId;
    unawaited(_persist());
  }

  int? get homeDaysFilter => _homeDaysFilter;
  String? get homeStatusFilter => _homeStatusFilter;
  void setHomeFilters({required int days, required String status}) {
    _homeDaysFilter = days;
    _homeStatusFilter = status;
  }

  String? get homeSearchQuery => _homeSearchQuery;
  String? get homeSortMode => _homeSortMode;
  void setHomeSearchAndSort({required String query, required String sortMode}) {
    _homeSearchQuery = query;
    _homeSortMode = sortMode;
  }

  void pushNotice(String code) {
    _notice = code;
  }

  String? takeNotice() {
    final n = _notice;
    _notice = null;
    return n;
  }

  Future<User> getMe() async {
    try {
      final response = await _dio.get('/users/me');
      final user = User.fromJson(response.data);
      _currentUserId = user.id;
      _currentUsername = user.username;
      _currentRole = user.role;
      await _persist();
      return user;
    } on dio.DioException catch (e) {
      throw Exception('Error al obtener perfil: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> login(
    String username,
    String password, {
    String role = 'doctor',
  }) async {
    if (username.trim().isEmpty) throw Exception('El usuario es requerido');
    if (password.trim().isEmpty) throw Exception('La contraseña es requerida');

    try {
      final response = await _dio.post(
        '/users/auth/login',
        data: {'username': username, 'password': password},
      );

      final authMap = response.data;
      final token = authMap['access_token']?.toString();
      if (token != null && token.isNotEmpty) {
        _token = token;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_prefsTokenKey, token);
      }

      final user = authMap['user'];
      if (user is Map<String, dynamic>) {
        _currentUsername = user['username']?.toString() ?? username;
        _currentRole = user['role']?.toString() ?? role;
        _currentUserId = user['id'] is int
            ? user['id']
            : int.tryParse(user['id'].toString());
      }

      await _persist();
      await flushPendingSessions();
      return authMap;
    } on dio.DioException catch (e) {
      final detail = e.response?.data?['detail'];
      if (detail != null) throw Exception(detail);
      
      if (e.response?.statusCode == 401) {
        throw Exception('Credenciales inválidas');
      }
      if (e.response?.statusCode == 404) {
        throw Exception('Usuario no registrado');
      }
      throw Exception('Error al iniciar sesión: ${e.message}');
    }
  }

  Future<bool> verify2FA(String username, String code) async {
    try {
      final response = await _dio.post(
        '/users/verify-2fa',
        data: {'username': username, 'code': code},
      );
      return response.data['status'] == 'success';
    } on dio.DioException catch (e) {
      final detail = e.response?.data?['detail'];
      if (detail != null) throw Exception(detail);
      throw Exception('Código de verificación incorrecto');
    }
  }

  Future<List<Patient>> getPatients() async {
    try {
      final response = await _dio.get('/patients/');
      final list = response.data as List;
      final patients = list
          .map((e) => Patient.fromJson(e as Map<String, dynamic>))
          .toList();

      if (_localDb != null) {
        unawaited(_localDb.savePatients(list.cast<Map<String, dynamic>>()));
        unawaited(_localDb.setLastSync('patients', DateTime.now()));
      }

      return patients;
    } on dio.DioException catch (e) {
      if (_localDb != null) {
        final cached = await _localDb.getPatients();
        if (cached.isNotEmpty) {
          return cached.map((e) => Patient.fromJson(e)).toList();
        }
      }
      throw Exception('Error al cargar pacientes: ${e.message}');
    }
  }

  Future<Patient> createPatient(Map<String, dynamic> patientData, {bool skipOffline = false}) async {
    if (patientData['name'] == null || patientData['name'].toString().isEmpty) {
      throw Exception('El nombre del paciente es requerido');
    }
    if (patientData['age'] == null) {
      throw Exception('La edad del paciente es requerida');
    }

    try {
      final response = await _dio.post('/patients/', data: patientData);
      return Patient.fromJson(response.data);
    } on dio.DioException catch (e) {
      final detail = e.response?.data?['detail'];
      if (detail != null) throw Exception(detail);
      if (!skipOffline && _localDb != null) {
        final extId = 'p-${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(10000)}';
        patientData['external_id'] = extId;
        await _localDb.addPendingAction('CREATE', 'patients', patientData);
        // Return a mock patient or throw a specific 'queued' exception
        return Patient.fromJson({...patientData, 'id': -1, 'external_id': extId}); 
      }
      throw Exception('Error al crear paciente: ${e.message}');
    }
  }

  Future<void> deletePatient(int patientId, {bool skipOffline = false}) async {
    try {
      await _dio.delete('/patients/$patientId');
    } on dio.DioException catch (e) {
      if (!skipOffline && _localDb != null) {
        await _localDb.addPendingAction('DELETE', 'patients', {'id': patientId});
        return;
      }
      throw Exception('Error al eliminar paciente: ${e.message}');
    }
  }

  Future<Patient> updatePatient(int patientId, Map<String, dynamic> patientData, {bool skipOffline = false}) async {
    try {
      final response = await _dio.put('/patients/$patientId', data: patientData);
      return Patient.fromJson(response.data);
    } on dio.DioException catch (e) {
      if (!skipOffline && _localDb != null) {
        await _localDb.addPendingAction('UPDATE', 'patients', {...patientData, 'id': patientId});
        return Patient.fromJson({...patientData, 'id': patientId});
      }
      throw Exception('Error al editar paciente: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> assignDoctorToPatient(
    int patientId,
    int doctorId,
  ) async {
    try {
      final response = await _dio.put(
        '/patients/$patientId/assign-doctor',
        queryParameters: {'doctor_id': doctorId.toString()},
      );
      return response.data;
    } on dio.DioException catch (e) {
      throw Exception('Error al asignar médico: ${e.message}');
    }
  }

  Future<int> getSessionsCountForPatient(int patientId) async {
    try {
      final response = await _dio.get(
        '/sessions/count',
        queryParameters: {'patient_id': patientId.toString()},
      );
      final c = response.data['count'];
      if (c is int) return c;
      if (c is String) return int.tryParse(c) ?? 0;
      return 0;
    } on dio.DioException catch (_) {
      try {
        final response = await _dio.get(
          '/sessions/',
          queryParameters: {
            'patient_id': patientId.toString(),
            'limit': '10000',
          },
        );
        final list = response.data as List;
        return list.length;
      } on dio.DioException catch (e) {
        throw Exception('Error al obtener sesiones: ${e.message}');
      }
    }
  }

  Future<Patient> getPatient(int patientId) async {
    try {
      final response = await _dio.get('/patients/$patientId');
      return Patient.fromJson(response.data);
    } on dio.DioException catch (e) {
      if (_localDb != null) {
        final cached = await _localDb.getPatients();
        final match = cached.firstWhere(
          (p) => p['id'] == patientId,
          orElse: () => <String, dynamic>{},
        );
        if (match.isNotEmpty) {
          return Patient.fromJson(match);
        }
      }
      throw Exception('Error al cargar paciente: ${e.message}');
    }
  }

  Future<Session> createSession({
    required int patientId,
    required String status,
    required String notes,
    DateTime? date,
    String? externalId,
    int durationMs = 0,
    bool skipOffline = false,
  }) async {
    if (patientId <= 0 && !skipOffline) throw Exception('ID de paciente inválido');
    if (status.trim().isEmpty) throw Exception('El estado es requerido');

    final d = date ?? DateTime.now();
    final isoDate = d.toIso8601String();
    final ext = externalId ?? _generateExternalId();

    final data = {
      'patient_id': patientId,
      'date': isoDate,
      'status': status,
      'notes': notes,
      'duration_ms': durationMs,
      'external_id': ext,
    };

    try {
      final response = await _dio.post('/sessions/', data: data);
      return Session.fromJson(response.data);
    } on dio.DioException catch (e) {
      if (!skipOffline && _localDb != null) {
        await _localDb.addPendingAction('CREATE', 'sessions', data);
        return Session.fromJson({...data, 'id': -1});
      }
      throw Exception('Error al crear sesión: ${e.message}');
    }
  }

  Future<void> enqueuePendingSession({
    required int patientId,
    required String status,
    required String notes,
    required String date,
    required String externalId,
    int durationMs = 0,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsPendingSessionsKey);
    final List<dynamic> list = raw == null ? [] : (jsonDecode(raw) as List);
    list.add({
      'patient_id': patientId,
      'status': status,
      'notes': notes,
      'date': date,
      'external_id': externalId,
      'duration_ms': durationMs,
      'ts': DateTime.now().toIso8601String(),
    });
    await prefs.setString(_prefsPendingSessionsKey, jsonEncode(list));
  }

  Future<void> flushPendingSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsPendingSessionsKey);
    if (raw == null) return;

    final List<dynamic> list = jsonDecode(raw) as List;
    if (list.isEmpty) return;

    final List<dynamic> failed = [];
    for (final s in list) {
      try {
        await _dio.post('/sessions/results', data: s);
      } catch (e) {
        failed.add(s);
      }
    }

    if (failed.isEmpty) {
      await prefs.remove(_prefsPendingSessionsKey);
    } else {
      await prefs.setString(_prefsPendingSessionsKey, jsonEncode(failed));
    }
  }

  String _generateExternalId() {
    final ts = DateTime.now().microsecondsSinceEpoch;
    final rand = Random().nextInt(1 << 32);
    final uid = _currentUserId?.toString() ?? 'u0';
    final pid = _currentPatientId.toString();
    return 's-$uid-$pid-$ts-$rand';
  }

  Future<List<Session>> getSessions() async {
    try {
      final response = await _dio.get('/sessions/');
      final list = response.data as List;
      final sessions = list
          .map((e) => Session.fromJson(e as Map<String, dynamic>))
          .toList();

      if (_localDb != null) {
        unawaited(_localDb.saveSessions(list.cast<Map<String, dynamic>>()));
        unawaited(_localDb.setLastSync('sessions', DateTime.now()));
      }

      return sessions;
    } on dio.DioException catch (e) {
      if (_localDb != null) {
        final cached = await _localDb.getSessions();
        if (cached.isNotEmpty) {
          return cached.map((e) => Session.fromJson(e)).toList();
        }
      }
      throw Exception('Error al obtener sesiones: ${e.message}');
    }
  }

  Future<List<User>> getUsers() async {
    try {
      final response = await _dio.get('/users/');
      final list = response.data as List;
      final users = list
          .map((e) => User.fromJson(e as Map<String, dynamic>))
          .toList();

      if (_localDb != null) {
        unawaited(_localDb.saveUsers(list.cast<Map<String, dynamic>>()));
        unawaited(_localDb.setLastSync('users', DateTime.now()));
      }

      return users;
    } on dio.DioException catch (e) {
      if (_localDb != null) {
        final cached = await _localDb.getUsers();
        if (cached.isNotEmpty) {
          return cached.map((e) => User.fromJson(e)).toList();
        }
      }
      throw Exception('Error al obtener usuarios: ${e.message}');
    }
  }

  Future<List<dynamic>> getLatestResultsForPatient(int patientId) async {
    try {
      final response = await _dio.get(
        '/sessions/results/latest',
        queryParameters: {'patient_id': patientId.toString()},
      );
      return response.data as List<dynamic>;
    } on dio.DioException catch (e) {
      throw Exception('Error al obtener resultados: ${e.message}');
    }
  }

  Future<void> submitGameResults({
    required int patientId,
    required String gameName,
    required Map<String, dynamic> results,
    int? sessionId,
    bool skipOffline = false,
  }) async {
    if (patientId <= 0 && !skipOffline) throw Exception('ID de paciente inválido');
    if (gameName.trim().isEmpty) {
      throw Exception('El nombre del juego es requerido');
    }
    if (results.isEmpty) {
      throw Exception('Los resultados no pueden estar vacíos');
    }

    // Extract score from results; the rest goes into details/metrics
    final int score = results['score'] is int
        ? results['score']
        : int.tryParse(results['score']?.toString() ?? '0') ?? 0;

    final data = {
      'patient_id': patientId,
      'game_name': gameName,
      'score': score,
      'details': results['details'],
      'metrics': results['metrics'],
      if (sessionId != null) 'session_id': sessionId,
    };

    try {
      await _dio.post('/sessions/results', data: data);
    } on dio.DioException catch (e) {
      if (!skipOffline && _localDb != null) {
        await _localDb.addPendingAction('CREATE', 'results', data);
        return;
      }
      throw Exception('Error al enviar resultados: ${e.message}');
    }
  }


  Future<Map<String, dynamic>> updateUserAvailability(
    int userId,
    bool isAvailable,
  ) async {
    try {
      final response = await _dio.put(
        '/users/$userId/availability',
        queryParameters: {'is_available': isAvailable.toString()},
      );
      return response.data;
    } on dio.DioException catch (e) {
      throw Exception('Error al actualizar disponibilidad: ${e.message}');
    }
  }

  Future<User> updateUser(int userId, Map<String, dynamic> userData) async {
    try {
      final response = await _dio.put('/users/$userId', data: userData);
      return User.fromJson(response.data);
    } on dio.DioException catch (e) {
      throw Exception('Error al editar usuario: ${e.message}');
    }
  }

  Future<void> deleteUser(int userId) async {
    try {
      await _dio.delete('/users/$userId');
    } on dio.DioException catch (e) {
      throw Exception('Error al eliminar usuario: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> adminCreateUser({
    required String username,
    required String password,
    required String role,
    String? fullName,
    String? documentId,
  }) async {
    try {
      final response = await _dio.post(
        '/users/register',
        data: {
          'username': username,
          'password': password,
          'role': role,
          'full_name': fullName,
          'document_id': documentId,
        },
      );
      return response.data;
    } on dio.DioException catch (e) {
      final detail = e.response?.data?['detail'];
      if (detail != null) throw Exception(detail);
      throw Exception('Error al crear usuario: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> resetPassword(
    String username,
    String newPassword, {
    String? fullName,
  }) async {
    try {
      final response = await _dio.post(
        '/users/reset',
        data: {
          'username': username,
          'password': newPassword,
          'role': _currentRole ?? 'doctor',
          'full_name': fullName,
        },
      );
      return response.data;
    } on dio.DioException catch (e) {
      throw Exception('Error al restablecer contraseña: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> register({
    required String username,
    required String password,
    String role = 'doctor',
    String? fullName,
  }) async {
    try {
      final response = await _dio.post(
        '/users/auth/register',
        data: {
          'username': username,
          'password': password,
          'role': role,
          'full_name': fullName,
        },
      );

      final authMap = response.data;
      final token = authMap['access_token']?.toString();
      if (token != null && token.isNotEmpty) {
        _token = token;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_prefsTokenKey, token);
      }

      _currentUsername = username;
      _currentRole = authMap['user']?['role']?.toString() ?? role;
      _currentUserId = authMap['user']?['id'] is int
          ? authMap['user']['id']
          : int.tryParse(authMap['user']?['id']?.toString() ?? '');
      await _persist();
      return authMap;
    } on dio.DioException catch (e) {
      throw Exception('Error al registrar usuario: ${e.message}');
    }
  }
}
