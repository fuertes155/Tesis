import 'dart:async';
import 'package:dio/dio.dart' as dio;
import '../models/session.dart';
import '../core/database/local_database_service.dart';

class SessionService {
  final dio.Dio _dio;
  final LocalDatabaseService? _localDb;

  SessionService(this._dio, [this._localDb]);

  Future<List<Session>> getSessions() async {
    try {
      final response = await _dio.get('/sessions/');
      final list = response.data as List;
      final sessions = list.map((e) => Session.fromJson(e as Map<String, dynamic>)).toList();
      if (_localDb != null) {
        unawaited(_localDb.saveSessions(list.cast<Map<String, dynamic>>()));
      }
      return sessions;
    } on dio.DioException catch (e) {
      if (_localDb != null) {
        final cached = await _localDb.getSessions();
        if (cached.isNotEmpty) return cached.map((e) => Session.fromJson(e)).toList();
      }
      throw Exception('Error al cargar sesiones: ${e.message}');
    }
  }

  Future<Session> createSession({
    required int patientId,
    required String status,
    required String notes,
    DateTime? date,
  }) async {
    final d = date ?? DateTime.now();
    final data = {
      'patient_id': patientId,
      'date': d.toIso8601String(),
      'status': status,
      'notes': notes,
    };
    try {
      final response = await _dio.post('/sessions/', data: data);
      return Session.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al crear sesión');
    }
  }

  Future<void> submitResults({
    required int patientId,
    required String gameName,
    required Map<String, dynamic> results,
    int? sessionId,
  }) async {
    final data = {
      'patient_id': patientId,
      'game_name': gameName,
      'results': results,
      'session_id': sessionId,
    };
    try {
      await _dio.post('/sessions/results', data: data);
    } catch (e) {
      throw Exception('Error al enviar resultados');
    }
  }

  Future<List<dynamic>> getLatestResults(int patientId) async {
    try {
      final response = await _dio.get('/sessions/results/latest', queryParameters: {'patient_id': patientId});
      return response.data as List;
    } catch (e) {
      throw Exception('Error al obtener últimos resultados');
    }
  }
}
