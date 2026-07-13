import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../models/reporte_cognitivo_model.dart';

/// Devuelve la URL base correcta según la plataforma.
/// - Web / Desktop Windows: http://localhost:8000
/// - Emulador Android:      http://10.0.2.2:8000
String _defaultBaseUrl() {
  const envUrl = String.fromEnvironment('REPORTE_API_BASE_URL');
  if (envUrl.isNotEmpty) return envUrl;
  if (kIsWeb) return 'http://localhost:8000';
  // En desktop nativo (Windows / Linux / macOS) también usamos localhost
  return 'http://localhost:8000';
}

class ReporteCognitivoService {
  ReporteCognitivoService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: _defaultBaseUrl(),
              connectTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(minutes: 10),
              sendTimeout: const Duration(seconds: 20),
              contentType: 'application/json',
            ),
          );

  final Dio _dio;

  Future<ReporteCognitivoModel> generarReporte(
    SolicitudReporteCognitivoModel solicitud,
  ) async {
    try {
      final respuesta = await _dio.post(
        '/evaluacion/generar-reporte',
        data: solicitud.toJson(),
      );

      return ReporteCognitivoModel.fromJson(
        respuesta.data as Map<String, dynamic>,
      );
    } on DioException catch (error) {
      final detalle = error.response?.data is Map<String, dynamic>
          ? error.response?.data['detail']?.toString()
          : null;

      if (detalle != null && detalle.isNotEmpty) {
        throw Exception(detalle);
      }
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        throw Exception(
          'La generación del reporte tardó más de 10 minutos. Verifica que Ollama esté activo, que el modelo esté cargado y vuelve a intentarlo.',
        );
      }
      if (error.type == DioExceptionType.connectionError) {
        throw Exception(
          'No se pudo conectar con el backend. En emulador Android usa http://10.0.2.2:8000.',
        );
      }

      throw Exception(
        'Error al generar el reporte cognitivo: ${error.message}',
      );
    } catch (error) {
      throw Exception(
        'Error inesperado al generar el reporte cognitivo: $error',
      );
    }
  }
}
