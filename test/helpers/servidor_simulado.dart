import 'dart:async';
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
  })  : usuarios = usuarios ?? [Map.of(doctor), Map.of(gestor)],
        pacientes = pacientes ?? [],
        sesiones = sesiones ?? [],
        resultados = resultados ?? [],
        reportes = reportes ?? [];

  static const clave = 'Password123!';
  static const codigo2fa = '123456';

  static final doctor = <String, dynamic>{
    'id': 36, 'username': 'samuel@gmail.com', 'role': 'doctor', 'full_name': 'Samuel Vanegas',
    'document_id': null, 'is_active': true, 'is_available': true, 'registration_date': '2026-04-24T16:18:56',
  };

  static final gestor = <String, dynamic>{
    'id': 23, 'username': 'samuel1@gmail.com', 'role': 'gestor', 'full_name': null,
    'document_id': null, 'is_active': true, 'is_available': true, 'registration_date': '2026-03-21T20:14:31',
  };

  /// Usuario con rol paciente (`user`).
  static final paciente = <String, dynamic>{
    'id': 50, 'username': 'paciente@gmail.com', 'role': 'user', 'full_name': 'Paciente de Prueba',
    'document_id': null, 'is_active': true, 'is_available': true, 'registration_date': '2026-05-02T09:00:00',
  };

  final List<Map<String, dynamic>> usuarios;
  final List<Map<String, dynamic>> pacientes;
  final List<Map<String, dynamic>> sesiones;
  final List<Map<String, dynamic>> resultados;
  final List<Map<String, dynamic>> reportes;

  /// Peticiones recibidas, en orden: "GET /patients/".
  final List<String> peticiones = [];

  /// Último cuerpo enviado a cada petición ("POST /patients/" → JSON).
  final Map<String, Object?> cuerpos = {};

  /// Último query enviado a cada petición.
  final Map<String, Map<String, String>> consultas = {};

  /// Encabezados de la última petición a cada ruta (p. ej. Authorization).
  final Map<String, Map<String, dynamic>> encabezados = {};

  /// Si se asigna, el login responde que se requiere 2FA.
  bool exigir2fa = false;

  /// Respuesta de `GET /users/me` (por defecto, el usuario que inició sesión o el doctor).
  Map<String, dynamic>? usuarioActual;

  /// Si se asigna, cada petición espera a que se complete (para ver estados de carga).
  Completer<void>? pausa;

  /// Respuesta del generador de informes (`POST /evaluacion/generar-reporte`).
  Map<String, dynamic>? reporteGenerado;

  final Map<String, (int, Object?)> _fallos = {};

  /// Hace que `'METODO /ruta'` responda con un error HTTP.
  void fallar(String peticion, {int estado = 500, Object? cuerpo = const {'detail': 'Error simulado'}}) =>
      _fallos[peticion] = (estado, cuerpo);

  /// Hace que `'METODO /ruta'` falle como si no hubiera conexión.
  void sinConexion(String peticion) => _fallos[peticion] = (0, null);

  /// Quita los fallos configurados.
  void restablecer() => _fallos.clear();

  bool recibio(String metodo, String ruta) => peticiones.contains('$metodo $ruta');

  int veces(String metodo, String ruta) => peticiones.where((p) => p == '$metodo $ruta').length;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final ruta = options.uri.path.replaceFirst(RegExp(r'^/api/v1'), '');
    final metodo = options.method.toUpperCase();
    final clave = '$metodo $ruta';
    peticiones.add(clave);
    cuerpos[clave] = options.data;
    consultas[clave] = options.uri.queryParameters;
    encabezados[clave] = Map.of(options.headers);
    if (pausa != null) await pausa!.future;

    final fallo = _fallos[clave];
    if (fallo != null && fallo.$1 == 0) {
      throw DioException(requestOptions: options, type: DioExceptionType.connectionError, message: 'Sin conexión');
    }
    final (estado, cuerpo) = fallo ?? _responder(metodo, ruta, options.uri.queryParameters, options.data);
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

    // ── Usuarios ──────────────────────────────────────────────────────────
    if (metodo == 'POST' && ruta == '/users/auth/login') {
      final usuario = usuarios.where((u) => u['username'] == cuerpo['username']).firstOrNull;
      if (usuario == null || cuerpo['password'] != clave) {
        return (401, {'detail': 'Usuario o contraseña incorrectos'});
      }
      usuarioActual = usuario;
      return (200, {
        'access_token': 'token-${usuario['id']}',
        'token_type': 'bearer',
        'user': usuario,
        if (exigir2fa) 'mfa_required': true,
      });
    }
    if (metodo == 'POST' && ruta == '/users/verify-2fa') {
      return cuerpo['code'] == codigo2fa
          ? (200, {'status': 'success'})
          : (400, {'detail': 'Código de verificación incorrecto'});
    }
    if (metodo == 'GET' && ruta == '/users/me') return (200, usuarioActual ?? doctor);
    if (metodo == 'GET' && ruta == '/users/') return (200, usuarios);
    if (metodo == 'POST' && (ruta == '/users/register' || ruta == '/users/auth/register')) {
      if (usuarios.any((u) => u['username'] == cuerpo['username'])) {
        return (400, {'detail': 'El usuario ya existe'});
      }
      final nuevo = {
        'id': 100 + usuarios.length,
        'username': cuerpo['username'],
        'role': cuerpo['role'] ?? 'doctor',
        'full_name': cuerpo['full_name'],
        'document_id': cuerpo['document_id'],
        'is_active': true,
        'is_available': true,
        'registration_date': '2026-11-06T10:00:00',
      };
      usuarios.add(nuevo);
      return (200, {'access_token': 'token-${nuevo['id']}', 'user': nuevo, ...nuevo});
    }
    if (metodo == 'POST' && ruta == '/users/reset') {
      final usuario = usuarios.where((u) => u['username'] == cuerpo['username']).firstOrNull;
      return usuario == null
          ? (404, {'detail': 'Usuario no encontrado'})
          : (200, {'status': 'success', 'username': cuerpo['username']});
    }
    final disponibilidad = RegExp(r'^/users/(\d+)/availability$').firstMatch(ruta);
    if (metodo == 'PUT' && disponibilidad != null) {
      final u = _buscar(usuarios, disponibilidad.group(1)!);
      if (u == null) return (404, {'detail': 'User not found'});
      u['is_available'] = query['is_available'] == 'true';
      return (200, u);
    }
    final usuario = RegExp(r'^/users/(\d+)$').firstMatch(ruta);
    if (usuario != null) {
      final u = _buscar(usuarios, usuario.group(1)!);
      if (u == null) return (404, {'detail': 'User not found'});
      if (metodo == 'PUT') {
        u.addAll(cuerpo..remove('password'));
        return (200, u);
      }
      if (metodo == 'DELETE') {
        usuarios.remove(u);
        return (200, {'ok': true});
      }
    }

    // ── Pacientes ─────────────────────────────────────────────────────────
    if (metodo == 'GET' && ruta == '/patients/') return (200, pacientes);
    if (metodo == 'POST' && ruta == '/patients/') {
      final p = {
        'id': 500 + pacientes.length,
        'birth_date': null, 'document_id': null, 'phone': null, 'diagnosis': null, 'institution': null,
        'medical_history': null, 'email': null, 'doctor_id': null, 'has_consent': false, 'external_id': null,
        'created_at': '2026-11-06T10:00:00', 'registration_date': null,
        ...cuerpo,
      };
      pacientes.add(p);
      return (200, p);
    }
    final asignar = RegExp(r'^/patients/(\d+)/assign-doctor$').firstMatch(ruta);
    if (metodo == 'PUT' && asignar != null) {
      final p = _buscar(pacientes, asignar.group(1)!);
      if (p == null) return (404, {'detail': 'Patient not found'});
      p['doctor_id'] = int.tryParse(query['doctor_id'] ?? '');
      return (200, p);
    }
    final paciente = RegExp(r'^/patients/(\d+)$').firstMatch(ruta);
    if (paciente != null) {
      final p = _buscar(pacientes, paciente.group(1)!);
      if (p == null) return (404, {'detail': 'Patient not found'});
      if (metodo == 'GET') return (200, p);
      if (metodo == 'PUT') {
        p.addAll(cuerpo);
        return (200, p);
      }
      if (metodo == 'DELETE') {
        pacientes.remove(p);
        return (200, {'ok': true});
      }
    }

    // ── Sesiones y resultados ─────────────────────────────────────────────
    if (metodo == 'GET' && ruta == '/sessions/') {
      final pid = int.tryParse(query['patient_id'] ?? '');
      return (200, pid == null ? sesiones : sesiones.where((s) => s['patient_id'] == pid).toList());
    }
    if (metodo == 'GET' && ruta == '/sessions/count') {
      final pid = int.tryParse(query['patient_id'] ?? '');
      return (200, {'count': sesiones.where((s) => s['patient_id'] == pid).length});
    }
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

    // ── Informes ──────────────────────────────────────────────────────────
    if (metodo == 'POST' && ruta == '/evaluacion/generar-reporte') {
      return reporteGenerado == null ? (503, {'detail': 'Ollama no disponible'}) : (200, reporteGenerado);
    }
    if (metodo == 'GET' && ruta == '/evaluacion/reportes') return (200, reportes);
    final delPaciente = RegExp(r'^/evaluacion/reportes/(.+)$').firstMatch(ruta);
    if (metodo == 'GET' && delPaciente != null) {
      final id = delPaciente.group(1);
      return (200, reportes.where((r) => r['_patient_db_id'].toString() == id || r['paciente_id'] == id).toList());
    }

    return (404, {'detail': 'Not Found'});
  }

  static Map<String, dynamic>? _buscar(List<Map<String, dynamic>> lista, String id) =>
      lista.where((x) => x['id'] == int.parse(id)).firstOrNull;

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

/// Sesión registrada (como la devuelve `GET /sessions/`).
Map<String, dynamic> sesionEjemplo({
  int id = 1,
  int pacienteId = 21,
  String fecha = '2026-09-16T15:00:00',
  String estado = 'completed',
  String notas = 'Batería de pruebas finalizada.',
  int duracionMs = 300000,
}) =>
    {
      'id': id, 'patient_id': pacienteId, 'date': fecha, 'status': estado, 'notes': notas,
      'duration_ms': duracionMs, 'external_id': 's-$id', 'created_at': fecha,
    };

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
