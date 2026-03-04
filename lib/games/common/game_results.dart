import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';

class GameResults {
  static Future<void> sendSession({
    required int patientId,
    required String status,
    required String notes,
    DateTime? date,
  }) async {
    final api = ApiService();
    await api.createSession(
      patientId: patientId,
      status: status,
      notes: notes,
      date: date,
    );
  }

  static void navigateToResults(
    BuildContext context, {
    required String title,
    required int score,
    required Map<String, dynamic> details,
  }) {
    context.go(
      '/results',
      extra: {'title': title, 'score': score, 'details': details},
    );
  }

  static void navigateToResultsFromApi(
    BuildContext context, {
    required int patientId,
  }) {
    final api = ApiService();
    final future = api.getLatestResultsForPatient(patientId);
    context.go('/results', extra: {'dataFuture': future});
  }
}
