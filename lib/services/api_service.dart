import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000';

  static final ApiService _instance = ApiService._internal();

  factory ApiService() {
    return _instance;
  }

  ApiService._internal();

  String? _token;
  String? _currentUsername;
  int? _homeDaysFilter;
  String? _homeStatusFilter;
  String? _homeSearchQuery;
  String? _homeSortMode;

  void setToken(String token) {
    _token = token;
  }

  String? get currentUsername => _currentUsername;
  void setCurrentUsername(String username) {
    _currentUsername = username;
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

  Map<String, String> _jsonHeaders() {
    return {
      'Content-Type': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
  }

  T _decode<T>(http.Response response) {
    return jsonDecode(utf8.decode(response.bodyBytes)) as T;
  }

  void _ensureSuccess(http.Response response, {String? message}) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = response.body.isNotEmpty ? response.body : '';
      throw Exception(message ?? 'Error ${response.statusCode}: $body');
    }
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/login'),
      headers: _jsonHeaders(),
      body: jsonEncode({
        'username': username,
        'password': password,
        'role': 'doctor',
      }),
    );

    _ensureSuccess(response, message: 'Error al iniciar sesión');
    final map = _decode<Map<String, dynamic>>(response);
    _currentUsername = username;
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
        'role': 'doctor',
      }),
    );
    _ensureSuccess(response, message: 'Error al restablecer contraseña');
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
  }) async {
    final d = date ?? DateTime.now();
    final isoDate =
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    final response = await http.post(
      Uri.parse('$baseUrl/sessions/'),
      headers: _jsonHeaders(),
      body: jsonEncode({
        'patient_id': patientId,
        'date': isoDate,
        'status': status,
        'notes': notes,
      }),
    );
    _ensureSuccess(response, message: 'Error al crear sesión');
    return _decode<Map<String, dynamic>>(response);
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
