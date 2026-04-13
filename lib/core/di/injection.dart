import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../../services/api_service.dart';
import '../database/local_database_service.dart';

final getIt = GetIt.instance;

Future<void> setupInjection() async {
  // Base network configuration
  final dio = Dio(
    BaseOptions(
      baseUrl: const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://127.0.0.1:8000',
      ),
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
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        if (kDebugMode) {
          debugPrint(
            '[API] ${options.method} ${options.baseUrl}${options.path}',
          );
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        if (kDebugMode) {
          debugPrint(
            '[API] ${response.statusCode} ${response.requestOptions.path}',
          );
        }
        return handler.next(response);
      },
      onError: (DioException e, handler) async {
        if (kDebugMode) {
          debugPrint(
            '[API] ERROR ${e.requestOptions.path} ${e.response?.statusCode} ${e.type}',
          );
        }
        if (e.response?.statusCode == 401) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('api_token');
          await prefs.remove('api_role');
          await prefs.remove('api_user_id');
          await prefs.remove('api_username');
        }
        return handler.next(e);
      },
    ),
  );

  // Database Service (must be initialized first)
  final localDb = LocalDatabaseService();
  await localDb.init();
  getIt.registerSingleton<LocalDatabaseService>(localDb);

  // Api Service (Depends on Dio and LocalDatabaseService)
  final apiService = ApiService(dio, localDb);
  await apiService.init();
  getIt.registerSingleton<ApiService>(apiService);
}
