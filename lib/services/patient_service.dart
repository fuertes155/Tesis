import 'dart:async';
import 'package:dio/dio.dart' as dio;
import '../models/patient.dart';
import '../core/database/local_database_service.dart';

class PatientService {
  final dio.Dio _dio;
  final LocalDatabaseService? _localDb;

  PatientService(this._dio, [this._localDb]);

  Future<List<Patient>> getPatients() async {
    try {
      final response = await _dio.get('/patients/');
      final list = response.data as List;
      final patients = list.map((e) => Patient.fromJson(e as Map<String, dynamic>)).toList();
      if (_localDb != null) {
        unawaited(_localDb.savePatients(list.cast<Map<String, dynamic>>()));
      }
      return patients;
    } on dio.DioException catch (e) {
      if (_localDb != null) {
        final cached = await _localDb.getPatients();
        if (cached.isNotEmpty) return cached.map((e) => Patient.fromJson(e)).toList();
      }
      throw Exception('Error al cargar pacientes: ${e.message}');
    }
  }

  Future<Patient> getPatient(int patientId) async {
    try {
      final response = await _dio.get('/patients/$patientId');
      return Patient.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al cargar paciente');
    }
  }

  Future<Patient> createPatient(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/patients/', data: data);
      return Patient.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al crear paciente');
    }
  }

  Future<void> deletePatient(int id) async {
    try {
      await _dio.delete('/patients/$id');
    } catch (e) {
      throw Exception('Error al eliminar paciente');
    }
  }

  Future<Patient> updatePatient(int id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/patients/$id', data: data);
      return Patient.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al actualizar paciente');
    }
  }

  Future<void> assignDoctor(int patientId, int doctorId) async {
    try {
      await _dio.put('/patients/$patientId/assign-doctor', queryParameters: {'doctor_id': doctorId});
    } catch (e) {
      throw Exception('Error al asignar médico');
    }
  }
}
