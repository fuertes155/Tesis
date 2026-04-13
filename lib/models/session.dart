import 'package:freezed_annotation/freezed_annotation.dart';

part 'session.freezed.dart';
part 'session.g.dart';

@freezed
class Session with _$Session {
  const factory Session({
    required int id,
    @JsonKey(name: 'patient_id') required int patientId,
    required String date,
    required String status,
    required String notes,
    @JsonKey(name: 'external_id') String? externalId,
    @JsonKey(name: 'created_at') String? createdAt,
  }) = _Session;

  factory Session.fromJson(Map<String, dynamic> json) => _$SessionFromJson(json);
}
