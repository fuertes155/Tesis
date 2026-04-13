// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SessionImpl _$$SessionImplFromJson(Map<String, dynamic> json) =>
    _$SessionImpl(
      id: (json['id'] as num).toInt(),
      patientId: (json['patient_id'] as num).toInt(),
      date: json['date'] as String,
      status: json['status'] as String,
      notes: json['notes'] as String,
      externalId: json['external_id'] as String?,
      createdAt: json['created_at'] as String?,
    );

Map<String, dynamic> _$$SessionImplToJson(_$SessionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'patient_id': instance.patientId,
      'date': instance.date,
      'status': instance.status,
      'notes': instance.notes,
      'external_id': instance.externalId,
      'created_at': instance.createdAt,
    };
