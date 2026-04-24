import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/patient.dart';
import '../models/session.dart';
import '../models/user.dart';
import 'api_providers.dart';

part 'data_providers.g.dart';

@riverpod
Future<List<Patient>> patients(Ref ref) async {
  final api = await ref.watch(apiServiceProvider.future);
  final allPatients = await api.getPatients();
  
  try {
    final me = await ref.watch(currentUserProvider.future);
    
    if (me.role == 'doctor') {
      return allPatients.where((p) => p.doctorId == me.id).toList();
    }
    
    return allPatients;
  } catch (e) {
    return allPatients;
  }
}

@riverpod
Future<List<Session>> sessions(Ref ref) async {
  final api = await ref.watch(apiServiceProvider.future);
  return api.getSessions();
}

@riverpod
Future<User> currentUser(Ref ref) async {
  final api = await ref.watch(apiServiceProvider.future);
  return api.getMe();
}

@riverpod
Future<List<Patient>> assignedPatients(Ref ref) async {
  final patients = await ref.watch(patientsProvider.future);
  final me = await ref.watch(currentUserProvider.future);
  return patients.where((p) => p.doctorId == me.id).toList();
}
