import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/patient_service.dart';
import '../services/session_service.dart';
import '../core/database/local_database_service.dart';

part 'api_providers.g.dart';

@Riverpod(keepAlive: true)
Future<SharedPreferences> sharedPrefs(Ref ref) {
  return SharedPreferences.getInstance();
}

@Riverpod(keepAlive: true)
Dio dio(Ref ref) {
  final dioInstance = Dio(
    BaseOptions(
      baseUrl: const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://localhost:8000/api/v1',
      ),
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      contentType: 'application/json',
    ),
  );

  dioInstance.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await ref.read(sharedPrefsProvider.future);
        final token = prefs.getString('api_token');
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        if (kDebugMode) {
          print('[API] ${options.method} ${options.baseUrl}${options.path}');
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        if (kDebugMode) {
          print('[API] ${response.statusCode} ${response.requestOptions.path}');
        }
        return handler.next(response);
      },
      onError: (DioException e, handler) async {
        if (kDebugMode) {
          print('[API] ERROR ${e.requestOptions.path} ${e.response?.statusCode}');
        }
        if (e.response?.statusCode == 401) {
          final prefs = await ref.read(sharedPrefsProvider.future);
          await prefs.remove('api_token');
          await prefs.remove('api_role');
          await prefs.remove('api_user_id');
          await prefs.remove('api_username');
        }
        return handler.next(e);
      },
    ),
  );

  return dioInstance;
}

@Riverpod(keepAlive: true)
Future<AuthService> authService(Ref ref) async {
  final dioInstance = ref.watch(dioProvider);
  final service = AuthService(dioInstance);
  await service.init();
  return service;
}

@Riverpod(keepAlive: true)
Future<PatientService> patientService(Ref ref) async {
  final dioInstance = ref.watch(dioProvider);
  final localDb = await ref.watch(localDatabaseProvider.future);
  return PatientService(dioInstance, localDb);
}

@Riverpod(keepAlive: true)
Future<SessionService> sessionService(Ref ref) async {
  final dioInstance = ref.watch(dioProvider);
  final localDb = await ref.watch(localDatabaseProvider.future);
  return SessionService(dioInstance, localDb);
}

@Riverpod(keepAlive: true)
Future<ApiService> apiService(Ref ref) async {
  final dioInstance = ref.watch(dioProvider);
  final localDb = await ref.watch(localDatabaseProvider.future);
  final service = ApiService(dioInstance, localDb);
  await service.init();
  return service;
}
