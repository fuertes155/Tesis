class PruebaCognitivaModel {
  const PruebaCognitivaModel({
    required this.nombrePrueba,
    required this.porcentajeObtenido,
    required this.tiempoSegundos,
  });

  final String nombrePrueba;
  final double porcentajeObtenido;
  final int tiempoSegundos;

  factory PruebaCognitivaModel.fromJson(Map<String, dynamic> json) {
    return PruebaCognitivaModel(
      nombrePrueba: json['nombre_prueba']?.toString() ?? '',
      porcentajeObtenido: (json['porcentaje_obtenido'] as num).toDouble(),
      tiempoSegundos: (json['tiempo_segundos'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre_prueba': nombrePrueba,
      'porcentaje_obtenido': porcentajeObtenido,
      'tiempo_segundos': tiempoSegundos,
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
  });

  final String pacienteId;
  final String nombrePaciente;
  final int edadPaciente;
  final String fechaEvaluacion;
  final String profesional;
  final List<PruebaCognitivaModel> pruebas;

  factory SolicitudReporteCognitivoModel.fromJson(Map<String, dynamic> json) {
    final pruebasJson = json['pruebas'] as List<dynamic>? ?? const [];
    return SolicitudReporteCognitivoModel(
      pacienteId: json['paciente_id']?.toString() ?? '',
      nombrePaciente: json['nombre_paciente']?.toString() ?? '',
      edadPaciente: (json['edad_paciente'] as num).toInt(),
      fechaEvaluacion: json['fecha_evaluacion']?.toString() ?? '',
      profesional: json['profesional']?.toString() ?? '',
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
      'pruebas': pruebas.map((prueba) => prueba.toJson()).toList(),
    };
  }
}

class ReporteCognitivoModel {
  const ReporteCognitivoModel({
    this.id,
    required this.pacienteId,
    required this.nombrePaciente,
    required this.fechaEvaluacion,
    required this.reporte,
    this.createdAt,
  });

  final int? id;
  final String pacienteId;
  final String nombrePaciente;
  final String fechaEvaluacion;
  final String reporte;
  final String? createdAt;

  factory ReporteCognitivoModel.fromJson(Map<String, dynamic> json) {
    return ReporteCognitivoModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? ''),
      pacienteId: json['paciente_id']?.toString() ?? '',
      nombrePaciente: json['nombre_paciente']?.toString() ?? '',
      fechaEvaluacion: json['fecha_evaluacion']?.toString() ?? '',
      reporte: json['reporte']?.toString() ?? '',
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'paciente_id': pacienteId,
      'nombre_paciente': nombrePaciente,
      'fecha_evaluacion': fechaEvaluacion,
      'reporte': reporte,
      if (createdAt != null) 'created_at': createdAt,
    };
  }
}
