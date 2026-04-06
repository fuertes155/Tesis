import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static final String baseUrl = const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );
  static const _prefsTokenKey = 'api_token';
  static const _prefsUsernameKey = 'api_username';
  static const _prefsRoleKey = 'api_role';
  static const _prefsPatientIdKey = 'api_patient_id';
  static const _prefsUserIdKey = 'api_user_id';
  static const _prefsPendingSessionsKey = 'pending_sessions_v1';

  static final ApiService _instance = ApiService._internal();

  factory ApiService() {
    return _instance;
  }

  ApiService._internal();

  String? _token;
  String? _currentUsername;
  String? _currentRole;
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
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    if (_token == null) {
      await prefs.remove(_prefsTokenKey);
    } else {
      await prefs.setString(_prefsTokenKey, _token!);
    }
    if (_currentUsername == null) {
      await prefs.remove(_prefsUsernameKey);
    } else {
      await prefs.setString(_prefsUsernameKey, _currentUsername!);
    }
    if (_currentRole == null) {
      await prefs.remove(_prefsRoleKey);
    } else {
      await prefs.setString(_prefsRoleKey, _currentRole!);
    }
    if (_currentUserId == null) {
      await prefs.remove(_prefsUserIdKey);
    } else {
      await prefs.setInt(_prefsUserIdKey, _currentUserId!);
    }
    await prefs.setInt(_prefsPatientIdKey, _currentPatientId);
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

  Map<String, String> _jsonHeaders() {
    return {
      'Content-Type': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
  }

  T _decode<T>(http.Response response) {
    return jsonDecode(utf8.decode(response.bodyBytes)) as T;
  }

  String _tryExtractFastApiDetail(http.Response response) {
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) {
        final detail = decoded['detail'];
        if (detail is String) return detail;
        if (detail is List) return detail.map((e) => e.toString()).join('\n');
        return decoded.toString();
      }
      return decoded.toString();
    } catch (_) {
      return response.body.isNotEmpty ? response.body : '';
    }
  }

  void _ensureSuccess(http.Response response, {String? message}) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = _tryExtractFastApiDetail(response);
      throw Exception(message ?? 'Error ${response.statusCode}: $body');
    }
  }

  Future<Map<String, dynamic>> login(
    String username,
    String password, {
    String role = 'doctor',
  }) async {
    http.Response authResponse;
    try {
      authResponse = await http.post(
        Uri.parse('$baseUrl/users/auth/login'),
        headers: _jsonHeaders(),
        body: jsonEncode({'username': username, 'password': password}),
      );
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('failed to fetch') ||
          msg.contains('connection refused') ||
          msg.contains('connection') ||
          msg.contains('socket')) {
        throw Exception(
          'No se pudo conectar con el servidor. Verifica que el backend esté encendido en $baseUrl',
        );
      }
      rethrow;
    }

    if (authResponse.statusCode >= 200 && authResponse.statusCode < 300) {
      final authMap = _decode<Map<String, dynamic>>(authResponse);
      final token = authMap['access_token']?.toString();
      if (token != null && token.isNotEmpty) {
        _token = token;
      }
      final user = authMap['user'];
      if (user is Map<String, dynamic>) {
        _currentUsername = user['username']?.toString() ?? username;
        _currentRole = user['role']?.toString() ?? role;
        final idVal = user['id'];
        if (idVal is int) {
          _currentUserId = idVal;
        } else if (idVal is String) {
          _currentUserId = int.tryParse(idVal);
        }
      } else {
        _currentUsername = username;
        _currentRole = role;
      }
      await _persist();
      await flushPendingSessions();
      return authMap;
    }

    final response = await http.post(
      Uri.parse('$baseUrl/users/login'),
      headers: _jsonHeaders(),
      body: jsonEncode({
        'username': username,
        'password': password,
        'role': role,
      }),
    );

    _ensureSuccess(response, message: 'Error al iniciar sesión');
    final map = _decode<Map<String, dynamic>>(response);
    _currentUsername = username;
    _currentRole = map['role']?.toString() ?? role;
    _currentUserId = null;
    await _persist();
    await flushPendingSessions();
    return map;
  }

  Future<Map<String, dynamic>> getMe() async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/me'),
      headers: _jsonHeaders(),
    );
    _ensureSuccess(response, message: 'Error al obtener perfil');
    final map = _decode<Map<String, dynamic>>(response);
    final idVal = map['id'];
    if (idVal is int) {
      _currentUserId = idVal;
    } else if (idVal is String) {
      _currentUserId = int.tryParse(idVal);
    }
    final u = map['username']?.toString();
    if (u != null && u.isNotEmpty) {
      _currentUsername = u;
    }
    final r = map['role']?.toString();
    if (r != null && r.isNotEmpty) {
      _currentRole = r;
    }
    await _persist();
    return map;
  }

  Future<Map<String, dynamic>> resetPassword(
    String username,
    String newPassword,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/reset'),
      headers: _jsonHeaders(),
      body: jsonEncode({
        'username': username,
        'password': newPassword,
        'role': _currentRole ?? 'doctor',
      }),
    );
    _ensureSuccess(response, message: 'Error al restablecer contraseña');
    return _decode<Map<String, dynamic>>(response);
  }

  Future<Map<String, dynamic>> register({
    required String username,
    required String password,
    String role = 'doctor',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/'),
      headers: _jsonHeaders(),
      body: jsonEncode({
        'username': username,
        'password': password,
        'role': role,
      }),
    );
    _ensureSuccess(response, message: 'Error al registrar usuario');
    final map = _decode<Map<String, dynamic>>(response);
    _currentUsername = username;
    _currentRole = map['role']?.toString() ?? role;
    return map;
  }

  Future<Map<String, dynamic>> adminCreateUser({
    required String username,
    required String password,
    required String role,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/'),
      headers: _jsonHeaders(),
      body: jsonEncode({
        'username': username,
        'password': password,
        'role': role,
      }),
    );
    _ensureSuccess(response, message: 'Error al crear usuario');
    return _decode<Map<String, dynamic>>(response);
  }

  Future<List<dynamic>> getUsers() async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/'),
      headers: _jsonHeaders(),
    );
    _ensureSuccess(response, message: 'Error al obtener usuarios');
    return _decode<List<dynamic>>(response);
  }

  Future<Map<String, dynamic>> updateUserAvailability(
    int userId,
    bool isAvailable,
  ) async {
    final response = await http.put(
      Uri.parse(
        '$baseUrl/users/$userId/availability',
      ).replace(queryParameters: {'is_available': isAvailable.toString()}),
      headers: _jsonHeaders(),
    );
    _ensureSuccess(response, message: 'Error al actualizar disponibilidad');
    return _decode<Map<String, dynamic>>(response);
  }

  Future<List<dynamic>> getPatients() async {
    final response = await http.get(
      Uri.parse('$baseUrl/patients/'),
      headers: _jsonHeaders(),
    );

    _ensureSuccess(response, message: 'Error al cargar pacientes');
    return _decode<List<dynamic>>(response);
  }

  Future<Map<String, dynamic>> getPatient(int patientId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/patients/$patientId'),
      headers: _jsonHeaders(),
    );
    _ensureSuccess(response, message: 'Error al cargar paciente');
    return _decode<Map<String, dynamic>>(response);
  }

  Future<Map<String, dynamic>> createPatient(
    Map<String, dynamic> patientData,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/patients/'),
      headers: _jsonHeaders(),
      body: jsonEncode(patientData),
    );

    _ensureSuccess(response, message: 'Error al crear paciente');
    return _decode<Map<String, dynamic>>(response);
  }

  Future<void> deletePatient(int patientId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/patients/$patientId'),
      headers: _jsonHeaders(),
    );
    _ensureSuccess(response, message: 'Error al eliminar paciente');
  }

  Future<Map<String, dynamic>> assignDoctorToPatient(
    int patientId,
    int doctorId,
  ) async {
    final response = await http.put(
      Uri.parse(
        '$baseUrl/patients/$patientId/assign-doctor',
      ).replace(queryParameters: {'doctor_id': doctorId.toString()}),
      headers: _jsonHeaders(),
    );
    _ensureSuccess(response, message: 'Error al asignar médico');
    return _decode<Map<String, dynamic>>(response);
  }

  Future<int> getSessionsCountForPatient(int patientId) async {
    // Prefer dedicated count endpoint for efficiency
    final uri = Uri.parse(
      '$baseUrl/sessions/count',
    ).replace(queryParameters: {'patient_id': '$patientId'});
    final response = await http.get(uri, headers: _jsonHeaders());
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final map = _decode<Map<String, dynamic>>(response);
      final c = map['count'];
      if (c is int) return c;
      if (c is String) return int.tryParse(c) ?? 0;
    }
    // Fallback to list length if count endpoint not available
    final listUri = Uri.parse(
      '$baseUrl/sessions/',
    ).replace(queryParameters: {'patient_id': '$patientId', 'limit': '10000'});
    final listResp = await http.get(listUri, headers: _jsonHeaders());
    _ensureSuccess(listResp, message: 'Error al obtener sesiones');
    final list = _decode<List<dynamic>>(listResp);
    return list.length;
  }

  Future<Map<String, dynamic>> createSession({
    required int patientId,
    required String status,
    required String notes,
    DateTime? date,
    String? externalId,
  }) async {
    final d = date ?? DateTime.now();
    final isoDate =
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    final ext = externalId ?? _generateExternalId();
    final response = await http.post(
      Uri.parse('$baseUrl/sessions/'),
      headers: _jsonHeaders(),
      body: jsonEncode({
        'patient_id': patientId,
        'date': isoDate,
        'status': status,
        'notes': notes,
        'external_id': ext,
      }),
    );
    _ensureSuccess(response, message: 'Error al crear sesión');
    return _decode<Map<String, dynamic>>(response);
  }

  Future<void> enqueuePendingSession({
    required int patientId,
    required String status,
    required String notes,
    required String date,
    required String externalId,
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
      'ts': DateTime.now().toIso8601String(),
    });
    await prefs.setString(_prefsPendingSessionsKey, jsonEncode(list));
  }

  Future<void> flushPendingSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsPendingSessionsKey);
    if (raw == null || raw.trim().isEmpty) return;

    List<dynamic> list;
    try {
      list = jsonDecode(raw) as List<dynamic>;
    } catch (_) {
      await prefs.remove(_prefsPendingSessionsKey);
      return;
    }
    if (list.isEmpty) return;

    final remaining = <dynamic>[];
    for (final item in list) {
      if (item is! Map) continue;
      final pid = item['patient_id'];
      final status = item['status'];
      final notes = item['notes'];
      final date = item['date'];
      final externalId = item['external_id'];
      final int? patientId = pid is int ? pid : int.tryParse('$pid');
      if (patientId == null ||
          status is! String ||
          notes is! String ||
          date is! String ||
          externalId is! String) {
        continue;
      }
      try {
        final resp = await http.post(
          Uri.parse('$baseUrl/sessions/'),
          headers: _jsonHeaders(),
          body: jsonEncode({
            'patient_id': patientId,
            'date': date,
            'status': status,
            'notes': notes,
            'external_id': externalId,
          }),
        );
        _ensureSuccess(resp, message: 'Error al sincronizar sesión');
      } catch (_) {
        remaining.add(item);
      }
    }

    if (remaining.isEmpty) {
      await prefs.remove(_prefsPendingSessionsKey);
    } else {
      await prefs.setString(_prefsPendingSessionsKey, jsonEncode(remaining));
    }
  }

  String _generateExternalId() {
    final ts = DateTime.now().microsecondsSinceEpoch;
    final rand = Random().nextInt(1 << 32);
    final uid = _currentUserId?.toString() ?? 'u0';
    final pid = _currentPatientId.toString();
    return 's-$uid-$pid-$ts-$rand';
  }

  Future<List<dynamic>> getSessions() async {
    final response = await http.get(
      Uri.parse('$baseUrl/sessions/'),
      headers: _jsonHeaders(),
    );
    _ensureSuccess(response, message: 'Error al obtener sesiones');
    return _decode<List<dynamic>>(response);
  }

  Future<Map<String, dynamic>> getLatestResultsForPatient(int patientId) async {
    final sessions = await getSessions();
    final list = sessions.cast<Map<String, dynamic>>();
    List<Map<String, dynamic>> filtered = list;
    if (list.isNotEmpty && list.first.containsKey('patient_id')) {
      filtered = list.where((s) => s['patient_id'] == patientId).toList();
    }
    if (filtered.isEmpty) {
      return {
        'title': 'Resultados',
        'score': 70,
        'details': {'General': 70},
      };
    }
    filtered.sort((a, b) {
      final ad = a['date']?.toString();
      final bd = b['date']?.toString();
      if (ad != null && bd != null) {
        return ad.compareTo(bd);
      }
      final ai = (a['id'] ?? 0) as int;
      final bi = (b['id'] ?? 0) as int;
      return ai.compareTo(bi);
    });
    final latest = filtered.last;
    return _parseSessionToResult(latest);
  }

  Map<String, dynamic> _parseSessionToResult(Map<String, dynamic> s) {
    final notes = (s['notes'] ?? '').toString();
    if (notes.trimLeft().startsWith('{')) {
      try {
        final decoded = jsonDecode(notes);
        if (decoded is Map<String, dynamic>) {
          final title = decoded['title'];
          final score = decoded['score'];
          final details = decoded['details'];
          if (title is String && score is num && details is Map) {
            return {
              'title': title,
              'score': score,
              'details': details.cast<String, dynamic>(),
            };
          }
        }
      } catch (_) {}
    }
    try {
      if (notes.startsWith('reaction')) {
        final avgMatch = RegExp(r'average=(\d+)ms').firstMatch(notes);
        final avg = avgMatch != null ? int.parse(avgMatch.group(1)!) : 300;
        final att = (100 - (avg / 4)).clamp(20, 100).toInt();
        return {
          'title': 'Resultados - Atención',
          'score': att,
          'details': {'Atención': att, 'Funciones Ejecutivas': 65},
        };
      }
      if (notes.startsWith('visual_memory')) {
        final scoreMatch = RegExp(r'score=(\d+)').firstMatch(notes);
        final mem = scoreMatch != null ? int.parse(scoreMatch.group(1)!) : 70;
        return {
          'title': 'Resultados - Memoria Visual',
          'score': mem,
          'details': {'Memoria': mem, 'Atención': 70},
        };
      }
      if (notes.startsWith('fluency')) {
        final countMatch = RegExp(r'count=(\d+)').firstMatch(notes);
        final count = countMatch != null ? int.parse(countMatch.group(1)!) : 10;
        final lang = (count * 5).clamp(30, 100);
        return {
          'title': 'Resultados - Lenguaje',
          'score': lang,
          'details': {'Lenguaje': lang, 'Memoria': 72},
        };
      }
      if (notes.startsWith('stroop')) {
        final scoreMatch = RegExp(r'score=(\d+)').firstMatch(notes);
        final avgMatch = RegExp(r'avg=(\d+)ms').firstMatch(notes);
        final raw = scoreMatch != null ? int.parse(scoreMatch.group(1)!) : 30;
        final avg = avgMatch != null ? int.parse(avgMatch.group(1)!) : 400;
        final exec = (raw * 2).clamp(20, 100);
        final att = (100 - (avg / 4)).clamp(20, 100).toInt();
        return {
          'title': 'Resultados - Funciones Ejecutivas',
          'score': exec,
          'details': {'Funciones Ejecutivas': exec, 'Atención': att},
        };
      }
    } catch (_) {
      // Fallback below
    }
    return {
      'title': 'Resultados',
      'score': 70,
      'details': {'General': 70},
    };
  }
}
