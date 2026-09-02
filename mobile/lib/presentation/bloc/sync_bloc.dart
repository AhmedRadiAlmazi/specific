// Sync BLoC — مشروع «مُعين» (Mouin)
import 'dart:async';
import 'package:mouin/infrastructure/sync/sync_engine.dart';

abstract class SyncState {}

class SyncIdle extends SyncState {
  final int pendingCount;
  final DateTime? lastSyncedAt;
  SyncIdle({this.pendingCount = 0, this.lastSyncedAt});
}

class SyncInProgress extends SyncState {}
class SyncSuccess extends SyncState {
  final int pushedCount;
  final int pulledCount;
  SyncSuccess(this.pushedCount, this.pulledCount);
}

class SyncFailed extends SyncState {
  final String error;
  SyncFailed(this.error);
}

class SyncBloc {
  final SyncEngine? syncEngine;
  final _stateController = StreamController<SyncState>.broadcast();
  Stream<SyncState> get state => _stateController.stream;
  SyncState _currentState = SyncIdle();
  SyncState get currentState => _currentState;

  SyncBloc({this.syncEngine});

  void _emit(SyncState newState) {
    _currentState = newState;
    _stateController.add(newState);
  }

  Future<void> triggerSync(String workspaceId) async {
    if (syncEngine == null) {
      _emit(SyncIdle(lastSyncedAt: DateTime.now()));
      return;
    }
    _emit(SyncInProgress());
    final pushRes = await syncEngine!.push(workspaceId);
    if (!pushRes.isSuccess) {
      _emit(SyncFailed(pushRes.failure.message));
      return;
    }

    final pullRes = await syncEngine!.pull(workspaceId);
    if (!pullRes.isSuccess) {
      _emit(SyncFailed(pullRes.failure.message));
      return;
    }

    _emit(SyncSuccess(pushRes.value, pullRes.value));
    _emit(SyncIdle(lastSyncedAt: DateTime.now()));
  }

  void dispose() {
    _stateController.close();
  }
}
