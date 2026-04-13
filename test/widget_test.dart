import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart' as dio;
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/services/api_service.dart';

void main() {
  testWidgets('App renders login screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final getIt = GetIt.instance;
    await getIt.reset();
    getIt.registerSingleton<ApiService>(
      ApiService(
        dio.Dio(
          dio.BaseOptions(
            baseUrl: 'http://127.0.0.1:8000',
            connectTimeout: const Duration(seconds: 1),
            receiveTimeout: const Duration(seconds: 1),
          ),
        ),
      ),
    );

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Bienvenido de nuevo'), findsOneWidget);
    expect(find.text('Iniciar Sesión'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
  });
}
