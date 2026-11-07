import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Backend de NeuroApp simulado en memoria para las pruebas de widgets.
///
/// Reemplaza la red: responde a las mismas rutas y con el mismo JSON que la API
/// real, y guarda cada petición para que las pruebas puedan verificarlas.
class ServidorSimulado implements HttpClientAdapter {
  ServidorSimulado({
    List<Map<String, dynamic>>? usuarios,
    List<Map<String, dynamic>>? pacientes,
    List<Map<String, dynamic>>? sesiones,
    List<Map<String, dynamic>>? resultados,
    List<Map<String, dynamic>>? reportes,
  })  : usuarios = usuarios ?? [doctor, gestor],
        pacientes = pacientes ?? [],
        sesiones = sesiones ?? [],
        resultados = resultados ?? [],
        reportes = reportes ?? [];

  static const clave = 'Password123!';

  static final doctor = <String, dynamic>{
    'id': 36, 'username': 'samuel@gmail.com', 'role': 'doctor', 'full_name': 'Samuel Vanegas',
    'document_id': null, 'is_active': true, 'is_available': true, 'registration_date': '2026-04-24T16:18:56',
  };

  static final gestor = <String, dynamic>{
    'id': 23, 'username': 'samuel1@gmail.com', 'role': 'gestor', 'full_name': null,
    'document_id': null, 'is_active': true, 'is_available': true, 'registration_date': '2026-03-21T20:14:31',
  };

  final List<Map<String, dynamic>> usuarios;
  final List<Map<String, dynamic>> pacientes;
  final List<Map<String, dynamic>> sesiones;
  final List<Map<String, dynamic>> resultados;
  final List<Map<String, dynamic>> reportes;

  /// Peticiones recibidas, en orden: "GET /patients/".
  final List<String> peticiones = [];

  /// Si se asigna, el login responde que se requiere 2FA.
  bool exigir2fa = false;

  Map<String, dynamic>? _usuarioActual;

  bool recibio(String metodo, String ruta) => peticiones.contains('$metodo $ruta');

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final ruta = options.uri.path.replaceFirst(RegExp(r'^/api/v1'), '');
    final metodo = options.method.toUpperCase();
    peticiones.add('$metodo $ruta');
    final (estado, cuerpo) = _responder(metodo, ruta, options.uri.queryParameters, options.data);
    return ResponseBody.fromString(
      jsonEncode(cuerpo),
      estado,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  (int, Object?) _responder(String metodo, String ruta, Map<String, String> query, Object? datos) {
    final cuerpo = datos is Map ? Map<String, dynamic>.from(datos) : <String, dynamic>{};

    if (metodo == 'POST' && ruta == '/users/auth/login') {
      final usuario = usuarios.where((u) => u['username'] == cuerpo['username']).firstOrNull;
      if (usuario == null || cuerpo['password'] != clave) {
        return (401, {'detail': 'Usuario o contraseña incorrectos'});
      }
      _usuarioActual = usuario;
      return (200, {
        'access_token': 'token-${usuario['id']}',
        'token_type': 'bearer',
        'user': usuario,
        if (exigir2fa) 'mfa_required': true,
      });
    }
    if (metodo == 'GET' && ruta == '/users/me') return (200, _usuarioActual ?? doctor);
    if (metodo == 'GET' && ruta == '/users/') return (200, usuarios);

    if (metodo == 'GET' && ruta == '/patients/') return (200, pacientes);
    final paciente = RegExp(r'^/patients/(\d+)$').firstMatch(ruta);
    if (metodo == 'GET' && paciente != null) {
      final p = pacientes.where((x) => x['id'] == int.parse(paciente.group(1)!)).firstOrNull;
      return p == null ? (404, {'detail': 'Patient not found'}) : (200, p);
    }

    if (metodo == 'GET' && ruta == '/sessions/') return (200, sesiones);
    if (metodo == 'POST' && ruta == '/sessions/') {
      final s = {'id': sesiones.length + 1, 'external_id': null, 'created_at': null, ...cuerpo};
      sesiones.add(s);
      return (200, s);
    }
    if (metodo == 'GET' && ruta == '/sessions/results/latest') {
      final pid = int.tryParse(query['patient_id'] ?? '');
      final limite = int.tryParse(query['limit'] ?? '') ?? 10;
      final lista = resultados.where((r) => r['patient_id'] == pid).toList()
        ..sort((a, b) => (b['timestamp'] as String).compareTo(a['timestamp'] as String));
      return (200, lista.take(limite).toList());
    }
    if (metodo == 'POST' && ruta == '/sessions/results') {
      final r = {'id': resultados.length + 1, 'timestamp': '2026-11-06T15:00:00', ...cuerpo};
      resultados.add(r);
      return (201, r);
    }

    if (metodo == 'GET' && ruta == '/evaluacion/reportes') return (200, reportes);
    final delPaciente = RegExp(r'^/evaluacion/reportes/(.+)$').firstMatch(ruta);
    if (metodo == 'GET' && delPaciente != null) {
      final id = delPaciente.group(1);
      return (200, reportes.where((r) => r['_patient_db_id'].toString() == id || r['paciente_id'] == id).toList());
    }

    return (404, {'detail': 'Not Found'});
  }

  @override
  void close({bool force = false}) {}
}

// ── Datos de ejemplo ─────────────────────────────────────────────────────────

Map<String, dynamic> pacienteEjemplo({
  int id = 21,
  String nombre = 'Jorge Enrique Salazar Mejía',
  int edad = 80,
  String? diagnostico = 'Enfermedad de Alzheimer, fase leve',
  int? doctorId = 36,
  String documento = '10234587',
}) =>
    {
      'id': id, 'name': nombre, 'age': edad, 'birth_date': '1946-08-22', 'document_id': documento,
      'phone': '3157784412', 'diagnosis': diagnostico, 'institution': 'Remisión EPS',
      'medical_history': 'Diabetes tipo 2.', 'email': 'jesalazar@example.com', 'doctor_id': doctorId,
      'has_consent': true, 'external_id': null, 'created_at': '2026-04-20T15:00:00', 'registration_date': null,
    };

/// Resultados de una batería completa (4 juegos) en una fecha dada (UTC, como la API).
List<Map<String, dynamic>> bateriaEjemplo(int pacienteId, String fecha, List<int> puntajes) {
  const juegos = ['visual_memory', 'reaction', 'stroop', 'fluency'];
  return [
    for (var i = 0; i < 4; i++)
      {
        'id': pacienteId * 100 + i + (fecha.hashCode % 50),
        'patient_id': pacienteId,
        'session_id': null,
        'game_name': juegos[i],
        'score': puntajes[i],
        'details': {'Global': puntajes[i]},
        'metrics': {},
        'timestamp': '${fecha}T15:0$i:00',
      },
  ];
}

Map<String, dynamic> reporteEjemplo({
  int id = 7,
  int pacienteId = 21,
  String nombre = 'Jorge Enrique Salazar Mejía',
  String fecha = '2026-09-16',
}) =>
    {
      'id': id,
      '_patient_db_id': pacienteId, // solo para el filtrado del servidor simulado
      'paciente_id': '10234587',
      'nombre_paciente': nombre,
      'edad_paciente': 80,
      'profesional': 'Samuel Vanegas',
      'fecha_evaluacion': fecha,
      'created_at': '${fecha}T15:30:00',
      'pruebas': [
        {'nombre_prueba': 'Memoria Visual', 'porcentaje_obtenido': 40, 'tiempo_segundos': 31},
        {'nombre_prueba': 'Fluidez Verbal', 'porcentaje_obtenido': 37, 'tiempo_segundos': 62},
      ],
      'reporte': 'MOTIVO DE EVALUACIÓN:\n'
          'Evaluación neuropsicológica de tamizaje de $nombre.\n\n'
          'IMPRESIÓN DIAGNÓSTICA:\n'
          'Categoría: Deterioro cognitivo mayor probable.\n\n'
          'RECOMENDACIONES:\n'
          'Reevaluación neuropsicológica sugerida en 3 meses.',
    };
