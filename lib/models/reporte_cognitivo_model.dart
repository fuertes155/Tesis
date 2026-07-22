class PruebaCognitivaModel {
  const PruebaCognitivaModel({
    required this.nombrePrueba,
    required this.porcentajeObtenido,
    required this.tiempoSegundos,
    this.detalles,
    this.metricas,
  });

  final String nombrePrueba;
  final double porcentajeObtenido;
  final int tiempoSegundos;
  final Map<String, dynamic>? detalles;
  final Map<String, dynamic>? metricas;

  factory PruebaCognitivaModel.fromJson(Map<String, dynamic> json) {
    return PruebaCognitivaModel(
      nombrePrueba: json['nombre_prueba']?.toString() ?? '',
      porcentajeObtenido: (json['porcentaje_obtenido'] as num).toDouble(),
      tiempoSegundos: (json['tiempo_segundos'] as num).toInt(),
      detalles: json['detalles'] as Map<String, dynamic>?,
      metricas: json['metricas'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre_prueba': nombrePrueba,
      'porcentaje_obtenido': porcentajeObtenido,
      'tiempo_segundos': tiempoSegundos,
      if (detalles != null) 'detalles': detalles,
      if (metricas != null) 'metricas': metricas,
    };
  }
}

class SolicitudReporteCognitivoModel {
  const SolicitudReporteCognitivoModel({
    required this.pacienteId,
    required this.nombrePaciente,
    required this.edadPaciente,
    required this.fechaEvaluacion,
    required this.profesional,
    required this.pruebas,
    this.documentoPaciente,
    this.telefonoPaciente,
    this.diagnosticoPaciente,
    this.institucion,
  });

  final String pacienteId;
  final String nombrePaciente;
  final int edadPaciente;
  final String fechaEvaluacion;
  final String profesional;
  final List<PruebaCognitivaModel> pruebas;
  final String? documentoPaciente;
  final String? telefonoPaciente;
  final String? diagnosticoPaciente;
  final String? institucion;

  factory SolicitudReporteCognitivoModel.fromJson(Map<String, dynamic> json) {
    final pruebasJson = json['pruebas'] as List<dynamic>? ?? const [];
    return SolicitudReporteCognitivoModel(
      pacienteId: json['paciente_id']?.toString() ?? '',
      nombrePaciente: json['nombre_paciente']?.toString() ?? '',
      edadPaciente: (json['edad_paciente'] as num).toInt(),
      fechaEvaluacion: json['fecha_evaluacion']?.toString() ?? '',
      profesional: json['profesional']?.toString() ?? '',
      documentoPaciente: json['documento_paciente']?.toString(),
      telefonoPaciente: json['telefono_paciente']?.toString(),
      diagnosticoPaciente: json['diagnostico_paciente']?.toString(),
      institucion: json['institucion']?.toString(),
      pruebas: pruebasJson
          .map(
            (item) =>
                PruebaCognitivaModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'paciente_id': pacienteId,
      'nombre_paciente': nombrePaciente,
      'edad_paciente': edadPaciente,
      'fecha_evaluacion': fechaEvaluacion,
      'profesional': profesional,
      if (documentoPaciente?.trim().isNotEmpty ?? false)
        'documento_paciente': documentoPaciente,
      if (telefonoPaciente?.trim().isNotEmpty ?? false)
        'telefono_paciente': telefonoPaciente,
      if (diagnosticoPaciente?.trim().isNotEmpty ?? false)
        'diagnostico_paciente': diagnosticoPaciente,
      if (institucion?.trim().isNotEmpty ?? false) 'institucion': institucion,
      'pruebas': pruebas.map((prueba) => prueba.toJson()).toList(),
    };
  }
}

class ReporteCognitivoModel {
  const ReporteCognitivoModel({
    required this.id,
    required this.pacienteId,
    required this.nombrePaciente,
    required this.edadPaciente,
    required this.profesional,
    required this.pruebas,
    required this.fechaEvaluacion,
    required this.reporte,
    required this.createdAt,
  });

  final int id;
  final String pacienteId;
  final String nombrePaciente;
  final int edadPaciente;
  final String profesional;
  final List<PruebaCognitivaModel> pruebas;
  final String fechaEvaluacion;
  final String reporte;
  final DateTime createdAt;

  factory ReporteCognitivoModel.fromJson(Map<String, dynamic> json) {
    return ReporteCognitivoModel(
      id: json['id'] as int,
      pacienteId: json['paciente_id']?.toString() ?? '',
      nombrePaciente: json['nombre_paciente']?.toString() ?? '',
      edadPaciente: (json['edad_paciente'] as num?)?.toInt() ?? 30,
      profesional: json['profesional']?.toString() ?? 'Profesional evaluador',
      pruebas: (json['pruebas'] as List<dynamic>?)
              ?.map((e) => PruebaCognitivaModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      fechaEvaluacion: json['fecha_evaluacion']?.toString() ?? '',
      reporte: json['reporte']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'paciente_id': pacienteId,
      'nombre_paciente': nombrePaciente,
      'edad_paciente': edadPaciente,
      'profesional': profesional,
      'pruebas': pruebas.map((e) => e.toJson()).toList(),
      'fecha_evaluacion': fechaEvaluacion,
      'reporte': reporte,
      'created_at': createdAt.toIso8601String(),
    };
  }

  SolicitudReporteCognitivoModel toSolicitud() {
    return SolicitudReporteCognitivoModel(
      pacienteId: pacienteId,
      nombrePaciente: nombrePaciente,
      edadPaciente: edadPaciente,
      fechaEvaluacion: fechaEvaluacion,
      profesional: profesional,
      pruebas: pruebas,
    );
  }
}
