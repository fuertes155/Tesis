import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'pending_actions_synchronizer.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../providers/api_providers.dart';
import '../core/database/local_database_service.dart';

part 'sync_service.g.dart';

@Riverpod(keepAlive: true)
class SyncService extends _$SyncService {
  Timer? _syncTimer;
  PendingActionsSynchronizer? _synchronizer;

  @override
  FutureOr<void> build() async {
    // Listen to connectivity changes
    final subscription = Connectivity().onConnectivityChanged.listen((results) {
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
      unawaited(subscription.cancel());
    });
  }

  Future<void> flushPendingActions() async {
    final api = await ref.read(apiServiceProvider.future);
    final localDb = await ref.read(localDatabaseProvider.future);
    _synchronizer ??= PendingActionsSynchronizer(api, localDb);
    await _synchronizer!.flush();
  }
}
