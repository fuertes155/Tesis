import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/patient.dart';
import '../models/session.dart';
import '../services/api_service.dart';

part 'data_providers.g.dart';

@riverpod
Future<List<Patient>> patients(Ref ref) {
  return ref.watch(apiServiceProvider).getPatients();
}

@riverpod
Future<List<Session>> sessions(Ref ref) {
  return ref.watch(apiServiceProvider).getSessions();
}
