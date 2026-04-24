// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$patientsHash() => r'5d6fd944342af89b5b20c90dc73bd1f8c2690efc';

/// See also [patients].
@ProviderFor(patients)
final patientsProvider = AutoDisposeFutureProvider<List<Patient>>.internal(
  patients,
  name: r'patientsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$patientsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PatientsRef = AutoDisposeFutureProviderRef<List<Patient>>;
String _$sessionsHash() => r'68be09f2b80d85a9c569fee118cb4b15d286a341';

/// See also [sessions].
@ProviderFor(sessions)
final sessionsProvider = AutoDisposeFutureProvider<List<Session>>.internal(
  sessions,
  name: r'sessionsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$sessionsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SessionsRef = AutoDisposeFutureProviderRef<List<Session>>;
String _$currentUserHash() => r'1cd75edb5faae3944ed67138bb19502fd61ca867';

/// See also [currentUser].
@ProviderFor(currentUser)
final currentUserProvider = AutoDisposeFutureProvider<User>.internal(
  currentUser,
  name: r'currentUserProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentUserHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentUserRef = AutoDisposeFutureProviderRef<User>;
String _$assignedPatientsHash() => r'1e82f126b7198dc29ed32a34ec50c9d264b76146';

/// See also [assignedPatients].
@ProviderFor(assignedPatients)
final assignedPatientsProvider =
    AutoDisposeFutureProvider<List<Patient>>.internal(
      assignedPatients,
      name: r'assignedPatientsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$assignedPatientsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AssignedPatientsRef = AutoDisposeFutureProviderRef<List<Patient>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
