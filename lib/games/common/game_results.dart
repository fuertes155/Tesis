import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import '../../services/api_service.dart';

class GameResults {
  static Future<void> sendSession({
    required ApiService api,
    int? patientId,
    required String status,
    required String notes,
    int durationMs = 0,
    DateTime? date,
  }) async {
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
        durationMs: durationMs,
        externalId: externalId,
      );
      await api.flushPendingSessions();
    } catch (_) {
      await api.enqueuePendingSession(
        patientId: pid,
        status: status,
        notes: notes,
        date: isoDate,
        durationMs: durationMs,
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

  static void navigateToResultsFromApi(BuildContext context, {required ApiService api, int? patientId}) {
    final pid = patientId ?? api.currentPatientId;
    final future = api.getLatestResultsForPatient(pid);
    context.go('/results', extra: {'dataFuture': future});
  }

  static Future<void> sendGameResult({
    required ApiService api,
    int? patientId,
    required String title,
    required int score,
    required Map<String, dynamic> details,
    required String gameKey,
    required Map<String, dynamic> metrics,
    int durationMs = 0,
    int? age,
    DateTime? date,
  }) async {
    final pid = patientId ?? api.currentPatientId;
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

    // 1. Create the session record
    await sendSession(
      api: api,
      patientId: pid,
      status: 'completed',
      notes: notes,
      durationMs: durationMs,
      date: date,
    );

    // 2. Also persist to the results table so data is queryable
    try {
      await api.submitGameResults(
        patientId: pid,
        gameName: gameKey,
        results: {
          'score': score,
          'title': title,
          'details': details,
          'metrics': metrics,
          if (age != null) 'age': age,
        },
      );
    } catch (_) {
      // If the results endpoint fails (e.g. offline), the session
      // was already saved/enqueued above so we don't lose data.
    }
  }
}
