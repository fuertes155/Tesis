import '../core/database/local_database_service.dart';
import 'api_service.dart';

/// Envía en orden y conserva cualquier rechazo para revisión o reintento.
class PendingActionsSynchronizer {
  PendingActionsSynchronizer(this.api, this.localDb);
  final ApiService api;
  final LocalDatabaseService localDb;
  Future<void>? _running;

  Future<void> flush() async {
    if (_running != null) return _running;
    final operation = _flush();
    _running = operation;
    try {
      await operation;
    } finally {
      _running = null;
    }
  }

  Future<void> _flush() async {
    final pending = await localDb.getPendingActions();
    for (final record in pending) {
      final current = await localDb.getPendingActions();
      final matches = current.where((r) => r.key == record.key);
      if (matches.isEmpty) continue;
      final value = matches.single.value;
      final action = value['action'];
      final entity = value['entity'];
      final payload = Map<String, dynamic>.from(value['data'] as Map);
      try {
        if (entity == 'patients' && action == 'CREATE') {
          final patient = await api.createPatient(payload, skipOffline: true);
          final offlineId = payload['id'];
          if (offlineId is int && offlineId < 0) {
            for (final dependent in current.where((r) => r.key != record.key)) {
              final data = Map<String, dynamic>.from(
                dependent.value['data'] as Map,
              );
              if (data['patient_id'] == offlineId) {
                data['patient_id'] = patient.id;
                await localDb.updatePendingAction(dependent.key, data);
              }
            }
          }
        } else if (entity == 'patients' && action == 'UPDATE') {
          await api.updatePatient(
            payload['id'] as int,
            payload,
            skipOffline: true,
          );
        } else if (entity == 'patients' && action == 'DELETE') {
          await api.deletePatient(payload['id'] as int, skipOffline: true);
        } else if (entity == 'sessions' && action == 'CREATE') {
          await api.createSession(
            patientId: payload['patient_id'] as int,
            status: payload['status'] as String,
            notes: payload['notes'] as String? ?? '',
            date: DateTime.parse(payload['date'] as String),
            durationMs: payload['duration_ms'] as int? ?? 0,
            externalId: payload['external_id'] as String?,
            skipOffline: true,
          );
        } else if (entity == 'results' && action == 'CREATE') {
          await api.submitGameResults(
            patientId: payload['patient_id'] as int,
            gameName: payload['game_name'] as String,
            results: {
              'score': payload['score'],
              'details': payload['details'],
              'metrics': payload['metrics'],
            },
            sessionId: payload['session_id'] as int?,
            skipOffline: true,
          );
        } else {
          return;
        }
        await localDb.deletePendingAction(record.key);
      } catch (_) {
        // Conserva el registro y sus dependencias; no borra por texto "400/404".
        return;
      }
    }
  }
}
