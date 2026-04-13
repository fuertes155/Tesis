// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserImpl _$$UserImplFromJson(Map<String, dynamic> json) => _$UserImpl(
  id: (json['id'] as num).toInt(),
  username: json['username'] as String,
  role: json['role'] as String,
  fullName: json['full_name'] as String?,
  isActive: json['is_active'] as bool? ?? true,
  isAvailable: json['is_available'] as bool? ?? true,
  registrationDate: json['registration_date'] as String?,
  createdAt: json['created_at'] as String?,
);

Map<String, dynamic> _$$UserImplToJson(_$UserImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'role': instance.role,
      'full_name': instance.fullName,
      'is_active': instance.isActive,
      'is_available': instance.isAvailable,
      'registration_date': instance.registrationDate,
      'created_at': instance.createdAt,
    };
