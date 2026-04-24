import 'dart:async';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:sembast/sembast_io.dart';
import 'package:sembast_web/sembast_web.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'local_database_service.g.dart';

@riverpod
Future<LocalDatabaseService> localDatabase(Ref ref) async {
  final service = LocalDatabaseService();
  await service.init();
  return service;
}

class LocalDatabaseService {
  late Database _db;

  // Stores
  final _patientsStore = intMapStoreFactory.store('patients');
  final _sessionsStore = intMapStoreFactory.store('sessions');
  final _usersStore = intMapStoreFactory.store('users');
  final _metaStore = stringMapStoreFactory.store('metadata');
  final _pendingStore = intMapStoreFactory.store('pending_actions');

  Future<void> init() async {
    if (kIsWeb) {
      _db = await databaseFactoryWeb.openDatabase('neuroapp_local.db');
      return;
    }
    final dir = await getApplicationDocumentsDirectory();
    await dir.create(recursive: true);
    final dbPath = join(dir.path, 'neuroapp_local.db');
    _db = await databaseFactoryIo.openDatabase(dbPath);
  }

  // --- Patients ---
  Future<void> savePatients(List<Map<String, dynamic>> patients) async {
    await _db.transaction((txn) async {
      await _patientsStore.delete(txn);
      for (final p in patients) {
        await _patientsStore.add(txn, p);
      }
    });
  }

  Future<List<Map<String, dynamic>>> getPatients() async {
    final records = await _patientsStore.find(_db);
    return records.map((r) => r.value).toList();
  }

  // --- Sessions ---
  Future<void> saveSessions(List<Map<String, dynamic>> sessions) async {
    await _db.transaction((txn) async {
      await _sessionsStore.delete(txn);
      for (final s in sessions) {
        await _sessionsStore.add(txn, s);
      }
    });
  }

  Future<List<Map<String, dynamic>>> getSessions() async {
    final records = await _sessionsStore.find(_db);
    return records.map((r) => r.value).toList();
  }

  // --- Users ---
  Future<void> saveUsers(List<Map<String, dynamic>> users) async {
    await _db.transaction((txn) async {
      await _usersStore.delete(txn);
      for (final u in users) {
        await _usersStore.add(txn, u);
      }
    });
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    final records = await _usersStore.find(_db);
    return records.map((r) => r.value).toList();
  }

  // --- Metadata (Cache Timestamps) ---
  Future<void> setLastSync(String key, DateTime time) async {
    await _metaStore.record(key).put(_db, {
      'timestamp': time.toIso8601String(),
    });
  }

  Future<DateTime?> getLastSync(String key) async {
    final record = await _metaStore.record(key).get(_db);
    if (record == null) return null;
    return DateTime.tryParse(record['timestamp'] as String);
  }

  Future<void> clearAll() async {
    await _db.transaction((txn) async {
      await _patientsStore.delete(txn);
      await _sessionsStore.delete(txn);
      await _usersStore.delete(txn);
      await _metaStore.delete(txn);
      await _pendingStore.delete(txn);
    });
  }

  // --- Pending Actions ---
  Future<void> addPendingAction(String action, String entity, Map<String, dynamic> data) async {
    await _pendingStore.add(_db, {
      'action': action, // CREATE, UPDATE, DELETE
      'entity': entity, // patients, sessions
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<List<RecordSnapshot<int, Map<String, dynamic>>>> getPendingActions() async {
    return await _pendingStore.find(_db, finder: Finder(sortOrders: [SortOrder('timestamp')]));
  }

  Future<void> deletePendingAction(int key) async {
    await _pendingStore.record(key).delete(_db);
  }
}
