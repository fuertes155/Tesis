import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dio_client.g.dart';

@riverpod
Dio dioClient(Ref ref) {
  var baseUrl = const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );
  if (!baseUrl.endsWith('/api/v1')) {
    baseUrl = '$baseUrl/api/v1';
  }

  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      contentType: 'application/json',
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('api_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401) {
          // Manejar error 401 (No autorizado) - Por ejemplo, cerrar sesión
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('api_token');
          await prefs.remove('api_role');
          // Aquí se podría disparar un evento para redirigir al login
        }
        return handler.next(e);
      },
    ),
  );

  // Agregar log de interceptores en desarrollo si es necesario
  dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));

  return dio;
}
