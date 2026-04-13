// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'patient.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Patient _$PatientFromJson(Map<String, dynamic> json) {
  return _Patient.fromJson(json);
}

/// @nodoc
mixin _$Patient {
  int get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  int get age => throw _privateConstructorUsedError;
  @JsonKey(name: 'birth_date')
  String? get birthDate => throw _privateConstructorUsedError;
  @JsonKey(name: 'document_id')
  String? get documentId => throw _privateConstructorUsedError;
  String? get phone => throw _privateConstructorUsedError;
  String? get diagnosis => throw _privateConstructorUsedError;
  @JsonKey(name: 'doctor_id')
  int? get doctorId => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  String? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this Patient to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Patient
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PatientCopyWith<Patient> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PatientCopyWith<$Res> {
  factory $PatientCopyWith(Patient value, $Res Function(Patient) then) =
      _$PatientCopyWithImpl<$Res, Patient>;
  @useResult
  $Res call({
    int id,
    String name,
    int age,
    @JsonKey(name: 'birth_date') String? birthDate,
    @JsonKey(name: 'document_id') String? documentId,
    String? phone,
    String? diagnosis,
    @JsonKey(name: 'doctor_id') int? doctorId,
    @JsonKey(name: 'created_at') String? createdAt,
  });
}

/// @nodoc
class _$PatientCopyWithImpl<$Res, $Val extends Patient>
    implements $PatientCopyWith<$Res> {
  _$PatientCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Patient
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? age = null,
    Object? birthDate = freezed,
    Object? documentId = freezed,
    Object? phone = freezed,
    Object? diagnosis = freezed,
    Object? doctorId = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            age: null == age
                ? _value.age
                : age // ignore: cast_nullable_to_non_nullable
                      as int,
            birthDate: freezed == birthDate
                ? _value.birthDate
                : birthDate // ignore: cast_nullable_to_non_nullable
                      as String?,
            documentId: freezed == documentId
                ? _value.documentId
                : documentId // ignore: cast_nullable_to_non_nullable
                      as String?,
            phone: freezed == phone
                ? _value.phone
                : phone // ignore: cast_nullable_to_non_nullable
                      as String?,
            diagnosis: freezed == diagnosis
                ? _value.diagnosis
                : diagnosis // ignore: cast_nullable_to_non_nullable
                      as String?,
            doctorId: freezed == doctorId
                ? _value.doctorId
                : doctorId // ignore: cast_nullable_to_non_nullable
                      as int?,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PatientImplCopyWith<$Res> implements $PatientCopyWith<$Res> {
  factory _$$PatientImplCopyWith(
    _$PatientImpl value,
    $Res Function(_$PatientImpl) then,
  ) = __$$PatientImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int id,
    String name,
    int age,
    @JsonKey(name: 'birth_date') String? birthDate,
    @JsonKey(name: 'document_id') String? documentId,
    String? phone,
    String? diagnosis,
    @JsonKey(name: 'doctor_id') int? doctorId,
    @JsonKey(name: 'created_at') String? createdAt,
  });
}

/// @nodoc
class __$$PatientImplCopyWithImpl<$Res>
    extends _$PatientCopyWithImpl<$Res, _$PatientImpl>
    implements _$$PatientImplCopyWith<$Res> {
  __$$PatientImplCopyWithImpl(
    _$PatientImpl _value,
    $Res Function(_$PatientImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Patient
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? age = null,
    Object? birthDate = freezed,
    Object? documentId = freezed,
    Object? phone = freezed,
    Object? diagnosis = freezed,
    Object? doctorId = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(
      _$PatientImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        age: null == age
            ? _value.age
            : age // ignore: cast_nullable_to_non_nullable
                  as int,
        birthDate: freezed == birthDate
            ? _value.birthDate
            : birthDate // ignore: cast_nullable_to_non_nullable
                  as String?,
        documentId: freezed == documentId
            ? _value.documentId
            : documentId // ignore: cast_nullable_to_non_nullable
                  as String?,
        phone: freezed == phone
            ? _value.phone
            : phone // ignore: cast_nullable_to_non_nullable
                  as String?,
        diagnosis: freezed == diagnosis
            ? _value.diagnosis
            : diagnosis // ignore: cast_nullable_to_non_nullable
                  as String?,
        doctorId: freezed == doctorId
            ? _value.doctorId
            : doctorId // ignore: cast_nullable_to_non_nullable
                  as int?,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PatientImpl implements _Patient {
  const _$PatientImpl({
    required this.id,
    required this.name,
    required this.age,
    @JsonKey(name: 'birth_date') this.birthDate,
    @JsonKey(name: 'document_id') this.documentId,
    this.phone,
    this.diagnosis,
    @JsonKey(name: 'doctor_id') this.doctorId,
    @JsonKey(name: 'created_at') this.createdAt,
  });

  factory _$PatientImpl.fromJson(Map<String, dynamic> json) =>
      _$$PatientImplFromJson(json);

  @override
  final int id;
  @override
  final String name;
  @override
  final int age;
  @override
  @JsonKey(name: 'birth_date')
  final String? birthDate;
  @override
  @JsonKey(name: 'document_id')
  final String? documentId;
  @override
  final String? phone;
  @override
  final String? diagnosis;
  @override
  @JsonKey(name: 'doctor_id')
  final int? doctorId;
  @override
  @JsonKey(name: 'created_at')
  final String? createdAt;

  @override
  String toString() {
    return 'Patient(id: $id, name: $name, age: $age, birthDate: $birthDate, documentId: $documentId, phone: $phone, diagnosis: $diagnosis, doctorId: $doctorId, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PatientImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.age, age) || other.age == age) &&
            (identical(other.birthDate, birthDate) ||
                other.birthDate == birthDate) &&
            (identical(other.documentId, documentId) ||
                other.documentId == documentId) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.diagnosis, diagnosis) ||
                other.diagnosis == diagnosis) &&
            (identical(other.doctorId, doctorId) ||
                other.doctorId == doctorId) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    age,
    birthDate,
    documentId,
    phone,
    diagnosis,
    doctorId,
    createdAt,
  );

  /// Create a copy of Patient
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PatientImplCopyWith<_$PatientImpl> get copyWith =>
      __$$PatientImplCopyWithImpl<_$PatientImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PatientImplToJson(this);
  }
}

abstract class _Patient implements Patient {
  const factory _Patient({
    required final int id,
    required final String name,
    required final int age,
    @JsonKey(name: 'birth_date') final String? birthDate,
    @JsonKey(name: 'document_id') final String? documentId,
    final String? phone,
    final String? diagnosis,
    @JsonKey(name: 'doctor_id') final int? doctorId,
    @JsonKey(name: 'created_at') final String? createdAt,
  }) = _$PatientImpl;

  factory _Patient.fromJson(Map<String, dynamic> json) = _$PatientImpl.fromJson;

  @override
  int get id;
  @override
  String get name;
  @override
  int get age;
  @override
  @JsonKey(name: 'birth_date')
  String? get birthDate;
  @override
  @JsonKey(name: 'document_id')
  String? get documentId;
  @override
  String? get phone;
  @override
  String? get diagnosis;
  @override
  @JsonKey(name: 'doctor_id')
  int? get doctorId;
  @override
  @JsonKey(name: 'created_at')
  String? get createdAt;

  /// Create a copy of Patient
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PatientImplCopyWith<_$PatientImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
