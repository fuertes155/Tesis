import 'package:flutter_application_1/models/patient.dart';
import 'package:flutter_application_1/models/session.dart';
import 'package:flutter_application_1/models/user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Patient.fromJson', () {
    // Respuesta real de GET /api/v1/patients/
    final json = <String, dynamic>{
      'name': 'Gloria Patricia Zuluaga Henao',
      'age': 71,
      'birth_date': '1955-06-25',
      'document_id': '25172390',
      'phone': '3113360957',
      'diagnosis': 'Envejecimiento cognitivo normal',
      'institution': 'Consulta particular',
      'medical_history': 'Control anual.',
      'email': 'gpzuluaga@example.com',
      'doctor_id': 36,
      'has_consent': false,
      'external_id': null,
      'id': 28,
      'created_at': '2026-10-21T18:59:00',
      'registration_date': null,
    };

    test('lee todos los campos de la API', () {
      final p = Patient.fromJson(json);
      expect(p.id, 28);
      expect(p.name, 'Gloria Patricia Zuluaga Henao');
      expect(p.age, 71);
      expect(p.birthDate, DateTime(1955, 6, 25));
      expect(p.documentId, '25172390');
      expect(p.diagnosis, 'Envejecimiento cognitivo normal');
      expect(p.institution, 'Consulta particular');
      expect(p.doctorId, 36);
      expect(p.createdAt, DateTime(2026, 10, 21, 18, 59));
    });

    test('acepta campos opcionales nulos', () {
      final p = Patient.fromJson({'id': 1, 'name': 'Ana', 'age': 30});
      expect(p.birthDate, isNull);
      expect(p.diagnosis, isNull);
      expect(p.doctorId, isNull);
    });

    test('ida y vuelta toJson → fromJson conserva los datos', () {
      final p = Patient.fromJson(json);
      expect(Patient.fromJson(p.toJson()), p);
    });
  });

  group('Session.fromJson', () {
    test('lee una sesión de la API', () {
      final s = Session.fromJson({
        'id': 221,
        'patient_id': 28,
        'date': '2026-11-03T08:50:53.689',
        'status': 'completed',
        'notes': 'Batería de pruebas finalizada.',
        'external_id': 's-36-28-1',
        'created_at': '2026-11-03T13:50:53.689000',
      });
      expect(s.patientId, 28);
      expect(s.date, DateTime(2026, 11, 3, 8, 50, 53, 689));
      expect(s.status, 'completed');
      expect(s.notes, 'Batería de pruebas finalizada.');
    });

    test('toJson usa los nombres de campo de la API', () {
      final s = Session.fromJson({'id': 1, 'patient_id': 2, 'date': '2026-04-27', 'status': 'pending', 'notes': 'x'});
      expect(s.toJson(), {
        'id': 1,
        'patient_id': 2,
        'date': '2026-04-27T00:00:00.000',
        'status': 'pending',
        'notes': 'x',
        'external_id': null,
        'created_at': null,
      });
    });

    test('acepta fechas sin hora', () {
      final s = Session.fromJson({'id': 1, 'patient_id': 2, 'date': '2026-04-27', 'status': 'pending', 'notes': ''});
      expect(s.date, DateTime(2026, 4, 27));
    });
  });

  group('User.fromJson', () {
    test('lee el usuario de la API', () {
      final u = User.fromJson({
        'id': 36,
        'username': 'samuel@gmail.com',
        'role': 'doctor',
        'full_name': 'Samuel Vanegas',
        'document_id': null,
        'is_active': true,
        'is_available': false,
        'registration_date': '2026-04-24T16:18:56',
      });
      expect(u.fullName, 'Samuel Vanegas');
      expect(u.isAvailable, isFalse);
      expect(u.registrationDate, DateTime(2026, 4, 24, 16, 18, 56));
    });

    test('activo y disponible son verdaderos por defecto', () {
      final u = User.fromJson({'id': 1, 'username': 'a@b.co', 'role': 'gestor'});
      expect(u.isActive, isTrue);
      expect(u.isAvailable, isTrue);
    });

    test('ida y vuelta toJson → fromJson conserva los datos', () {
      final u = User.fromJson({'id': 1, 'username': 'a@b.co', 'role': 'user', 'created_at': '2026-11-06T10:00:00'});
      expect(User.fromJson(u.toJson()), u);
    });
  });
}
