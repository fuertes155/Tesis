import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../providers/api_providers.dart';
import '../core/database/local_database_service.dart';

part 'sync_service.g.dart';

@Riverpod(keepAlive: true)
class SyncService extends _$SyncService {
  Timer? _syncTimer;
  bool _isSyncing = false;

  @override
  FutureOr<void> build() async {
    // Listen to connectivity changes
    Connectivity().onConnectivityChanged.listen((results) {
      if (results.any((r) => r != ConnectivityResult.none)) {
        flushPendingActions();
      }
    });

    // Periodically check (every 5 minutes as a fallback)
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      flushPendingActions();
    });

    ref.onDispose(() {
      _syncTimer?.cancel();
    });
  }

  Future<void> flushPendingActions() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final api = await ref.read(apiServiceProvider.future);
      final localDb = await ref.read(localDatabaseProvider.future);
      
      final pendingRaw = await localDb.getPendingActions();
      if (pendingRaw.isEmpty) return;

      if (kDebugMode) {
        print('[SyncService] Flushing ${pendingRaw.length} pending actions');
      }

      for (final record in pendingRaw) {
        final data = record.value;
        final action = data['action'] as String;
        final entity = data['entity'] as String;
        final payload = data['data'] as Map<String, dynamic>;

        try {
          bool success = false;
          if (entity == 'patients') {
            if (action == 'CREATE') {
              await api.createPatient(payload, skipOffline: true);
              success = true;
            } else if (action == 'UPDATE') {
              final id = payload['id'] as int;
              await api.updatePatient(id, payload, skipOffline: true);
              success = true;
            } else if (action == 'DELETE') {
              final id = payload['id'] as int;
              await api.deletePatient(id, skipOffline: true);
              success = true;
            }
          } else if (entity == 'sessions') {
            if (action == 'CREATE') {
              // Note: For sessions we might need to handle external_id etc.
              await api.createSession(
                patientId: payload['patient_id'],
                status: payload['status'],
                notes: payload['notes'],
                externalId: payload['external_id'],
                skipOffline: true,
              );
              success = true;
            }
          } else if (entity == 'results') {
            await api.submitGameResults(
              patientId: payload['patient_id'],
              gameName: payload['game_name'],
              results: {
                'score': payload['score'],
                'details': payload['details'],
                'metrics': payload['metrics'],
              },
              sessionId: payload['session_id'],
              skipOffline: true,
            );
            success = true;
          }

          if (success) {
            await localDb.deletePendingAction(record.key);
          }
        } catch (e) {
          if (kDebugMode) {
             print('[SyncService] Failed to sync record ${record.key}: $e');
          }
          // If it's a permanent error (e.g. 400), we might want to delete it or move to "failed"
          // For now, we wait for next attempt (retry on network error)
          if (e.toString().contains('400') || e.toString().contains('404')) {
             await localDb.deletePendingAction(record.key);
             continue; // Continue with next record for permanent errors
          }
          break; // Stop syncing this batch on temporary network error
        }
      }
    } finally {
      _isSyncing = false;
    }
  }
}
