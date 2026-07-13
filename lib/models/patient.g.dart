// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'patient.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PatientImpl _$$PatientImplFromJson(Map<String, dynamic> json) =>
    _$PatientImpl(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      age: (json['age'] as num).toInt(),
      birthDate: json['birth_date'] == null
          ? null
          : DateTime.parse(json['birth_date'] as String),
      documentId: json['document_id'] as String?,
      phone: json['phone'] as String?,
      diagnosis: json['diagnosis'] as String?,
      doctorId: (json['doctor_id'] as num?)?.toInt(),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      externalId: json['external_id'] as String?,
    );

Map<String, dynamic> _$$PatientImplToJson(_$PatientImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'age': instance.age,
      'birth_date': instance.birthDate?.toIso8601String(),
      'document_id': instance.documentId,
      'phone': instance.phone,
      'diagnosis': instance.diagnosis,
      'doctor_id': instance.doctorId,
      'created_at': instance.createdAt?.toIso8601String(),
      'external_id': instance.externalId,
    };
