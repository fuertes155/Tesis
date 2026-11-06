import 'package:flutter_application_1/models/reporte_cognitivo_model.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> reporteJson() => {
      'id': 61,
      'paciente_id': '24387615',
      'nombre_paciente': 'María Fernanda Ríos Castaño',
      'edad_paciente': 75,
      'profesional': 'Samuel Vanegas',
      'fecha_evaluacion': '2026-11-04',
      'reporte': 'MOTIVO DE EVALUACIÓN:\n...',
      'created_at': '2026-11-04T15:52:10.000',
      'pruebas': [
        {
          'nombre_prueba': 'Memoria Visual',
          'porcentaje_obtenido': 50,
          'tiempo_segundos': 31,
          'detalles': {'Memoria': 50, 'Atención': 44},
          'metricas': {'level': 2, 'avg_selection_ms': 2378},
        },
        {'nombre_prueba': 'Fluidez Verbal', 'porcentaje_obtenido': 75.5, 'tiempo_segundos': 62},
      ],
    };

void main() {
  group('ReporteCognitivoModel', () {
    test('lee el reporte de la API, incluidas sus pruebas', () {
      final r = ReporteCognitivoModel.fromJson(reporteJson());
      expect(r.id, 61);
      expect(r.nombrePaciente, 'María Fernanda Ríos Castaño');
      expect(r.edadPaciente, 75);
      expect(r.createdAt, DateTime(2026, 11, 4, 15, 52, 10));
      expect(r.pruebas, hasLength(2));
      expect(r.pruebas.first.porcentajeObtenido, 50.0);
      expect(r.pruebas.first.metricas?['level'], 2);
      expect(r.pruebas.last.porcentajeObtenido, 75.5);
      expect(r.pruebas.last.detalles, isNull);
    });

    test('usa valores por defecto si faltan edad, profesional o pruebas', () {
      final r = ReporteCognitivoModel.fromJson({'id': 1, 'created_at': '2026-11-04T10:00:00'});
      expect(r.edadPaciente, 30);
      expect(r.profesional, 'Profesional evaluador');
      expect(r.pruebas, isEmpty);
    });

    test('ida y vuelta toJson → fromJson conserva los datos', () {
      final original = ReporteCognitivoModel.fromJson(reporteJson());
      final copia = ReporteCognitivoModel.fromJson(original.toJson());
      expect(copia.id, original.id);
      expect(copia.createdAt, original.createdAt);
      expect(copia.pruebas.map((p) => p.toJson()), original.pruebas.map((p) => p.toJson()));
    });

    test('toSolicitud reutiliza los datos para reabrir el informe y su PDF', () {
      final s = ReporteCognitivoModel.fromJson(reporteJson()).toSolicitud();
      expect(s.pacienteId, '24387615');
      expect(s.nombrePaciente, 'María Fernanda Ríos Castaño');
      expect(s.fechaEvaluacion, '2026-11-04');
      expect(s.pruebas, hasLength(2));
    });
  });

  group('SolicitudReporteCognitivoModel.toJson', () {
    SolicitudReporteCognitivoModel solicitud({String? diagnostico, String? institucion}) =>
        SolicitudReporteCognitivoModel(
          pacienteId: 'PAC-1',
          nombrePaciente: 'Ana',
          edadPaciente: 70,
          fechaEvaluacion: '2026-11-04',
          profesional: 'Dr. Prueba',
          diagnosticoPaciente: diagnostico,
          institucion: institucion,
          pruebas: const [
            PruebaCognitivaModel(nombrePrueba: 'Memoria Visual', porcentajeObtenido: 50, tiempoSegundos: 60),
          ],
        );

    test('genera el cuerpo que espera POST /evaluacion/generar-reporte', () {
      final json = solicitud(diagnostico: 'DCL', institucion: 'Clínica').toJson();
      expect(json['paciente_id'], 'PAC-1');
      expect(json['edad_paciente'], 70);
      expect(json['diagnostico_paciente'], 'DCL');
      expect(json['pruebas'], [
        {'nombre_prueba': 'Memoria Visual', 'porcentaje_obtenido': 50.0, 'tiempo_segundos': 60},
      ]);
    });

    test('incluye documento y teléfono cuando vienen informados', () {
      final json = SolicitudReporteCognitivoModel(
        pacienteId: 'PAC-1',
        nombrePaciente: 'Ana',
        edadPaciente: 70,
        fechaEvaluacion: '2026-11-04',
        profesional: 'Dr. Prueba',
        documentoPaciente: '24387615',
        telefonoPaciente: '3104527781',
        pruebas: const [],
      ).toJson();
      expect(json['documento_paciente'], '24387615');
      expect(json['telefono_paciente'], '3104527781');
    });

    test('omite los campos opcionales vacíos', () {
      final json = solicitud(diagnostico: '   ').toJson();
      expect(json.containsKey('diagnostico_paciente'), isFalse);
      expect(json.containsKey('institucion'), isFalse);
      expect(json.containsKey('documento_paciente'), isFalse);
    });

    test('fromJson → toJson es simétrico', () {
      final original = solicitud(diagnostico: 'DCL', institucion: 'Clínica').toJson();
      expect(SolicitudReporteCognitivoModel.fromJson(original).toJson(), original);
    });
  });
}
