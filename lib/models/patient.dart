import 'package:freezed_annotation/freezed_annotation.dart';

part 'patient.freezed.dart';
part 'patient.g.dart';

@freezed
class Patient with _$Patient {
  const factory Patient({
    required int id,
    required String name,
    required int age,
    @JsonKey(name: 'birth_date') DateTime? birthDate,
    @JsonKey(name: 'document_id') String? documentId,
    String? phone,
    String? diagnosis,
    @JsonKey(name: 'doctor_id') int? doctorId,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _Patient;

  factory Patient.fromJson(Map<String, dynamic> json) =>
      _$PatientFromJson(json);
}
