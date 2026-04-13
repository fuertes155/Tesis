import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import 'package:get_it/get_it.dart';
import '../../services/api_service.dart';

class GameResults {
  static Future<void> sendSession({
    int? patientId,
    required String status,
    required String notes,
    DateTime? date,
  }) async {
    final api = GetIt.I<ApiService>();
    final pid = patientId ?? api.currentPatientId;
    final d = date ?? DateTime.now();
    final isoDate =
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    final externalId =
        's-${api.currentUserId ?? 0}-$pid-${DateTime.now().microsecondsSinceEpoch}';
    try {
      await api.createSession(
        patientId: pid,
        status: status,
        notes: notes,
        date: date,
        externalId: externalId,
      );
      await api.flushPendingSessions();
    } catch (_) {
      await api.enqueuePendingSession(
        patientId: pid,
        status: status,
        notes: notes,
        date: isoDate,
        externalId: externalId,
      );
    }
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

  static void navigateToResultsFromApi(BuildContext context, {int? patientId}) {
    final api = GetIt.I<ApiService>();
    final pid = patientId ?? api.currentPatientId;
    final future = api.getLatestResultsForPatient(pid);
    context.go('/results', extra: {'dataFuture': future});
  }

  static Future<void> sendGameResult({
    int? patientId,
    required String title,
    required int score,
    required Map<String, dynamic> details,
    required String gameKey,
    required Map<String, dynamic> metrics,
    int? age,
    DateTime? date,
  }) async {
    final payload = {
      'v': 1,
      'type': 'game_result',
      'game': gameKey,
      'title': title,
      'score': score,
      'details': details,
      'metrics': metrics,
      if (age != null) 'age': age,
      'ts': DateTime.now().toIso8601String(),
    };
    final notes = jsonEncode(payload);
    await sendSession(
      patientId: patientId,
      status: 'completed',
      notes: notes,
      date: date,
    );
  }
}
