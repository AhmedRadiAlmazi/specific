import 'package:flutter_test/flutter_test.dart';
import 'package:mouin/core/result/result.dart';
import 'package:mouin/core/errors/failures.dart';
import 'package:mouin/domain/repositories/i_item_repository.dart';
import 'package:mouin/infrastructure/database/local_sqlite_db.dart';
import 'package:mouin/infrastructure/sync/sync_engine.dart';

class MockOutboxRepository implements IOutboxRepository {
  final List<Map<String, dynamic>> pendingOps = [];
  final List<String> completedOpIds = [];

  @override
  Future<Result<List<Map<String, dynamic>>, Failure>> getPendingOperations() async {
    return Result.success(List.from(pendingOps));
  }

  @override
  Future<Result<void, Failure>> markCompleted(String operationId) async {
    completedOpIds.add(operationId);
    pendingOps.removeWhere((op) => op['operation_id'] == operationId);
    return const Result.success(null);
  }

  @override
  Future<Result<void, Failure>> saveOperation(Map<String, dynamic> operation) async {
    pendingOps.add(operation);
    return const Result.success(null);
  }

  @override
  Future<void> enqueue({
    required String operationId,
    required String entityType,
    required String entityId,
    required String operation,
    required Map<String, dynamic> payload,
    int? baseVersion,
  }) async {
    pendingOps.add({
      'operation_id': operationId,
      'entity_type': entityType,
      'entity_id': entityId,
      'operation': operation,
      'payload': payload,
      'base_version': baseVersion,
    });
  }
}

class MockRemoteSyncApi implements IRemoteSyncApi {
  int pushCalls = 0;
  int pullCalls = 0;
  bool shouldFailPush = false;
  List<Map<String, dynamic>> pulledChanges = [];

  @override
  Future<Result<Map<String, dynamic>, Failure>> push(String workspaceId, List<Map<String, dynamic>> operations) async {
    pushCalls++;
    if (shouldFailPush) {
      return const Result.failure(NetworkFailure('Server unreachable'));
    }
    final acks = operations.map((op) => {
      'operation_id': op['operation_id'],
      'status': 'success',
      'server_sequence': 1,
    }).toList();
    return Result.success({'acks': acks});
  }

  @override
  Future<Result<Map<String, dynamic>, Failure>> pull(String workspaceId, int sinceSequence, {int limit = 50}) async {
    pullCalls++;
    return Result.success({
      'changes': pulledChanges,
      'has_more': false,
      'next_cursor': sinceSequence + pulledChanges.length,
    });
  }

  @override
  Future<Result<Map<String, dynamic>, Failure>> bootstrap(String workspaceId) async {
    return const Result.success({
      'snapshot_items': [],
      'initial_cursor': 0,
    });
  }
}

void main() {
  group('SyncEngine Resilience & Backoff Tests', () {
    late LocalSqliteDb localDb;
    late MockOutboxRepository outboxRepo;
    late MockRemoteSyncApi remoteApi;
    late SyncEngine syncEngine;
    const wsId = '018e3a2b-0002-7000-8000-000000000002';

    setUp(() {
      localDb = LocalSqliteDb();
      outboxRepo = MockOutboxRepository();
      remoteApi = MockRemoteSyncApi();
      syncEngine = SyncEngine(
        localDb: localDb,
        outboxRepository: outboxRepo,
        itemRepository: FakeItemRepository(),
        remoteSyncApi: remoteApi,
      );
    });

    test('pushes pending outbox operations and marks them completed', () async {
      outboxRepo.pendingOps.add({
        'operation_id': 'op-001',
        'entity_type': 'item',
        'entity_id': 'task-1',
        'payload': {'title': 'شراء دواء'},
      });

      final result = await syncEngine.push(wsId);
      expect(result.isSuccess, isTrue);
      expect(result.value, equals(1));
      expect(outboxRepo.completedOpIds, contains('op-001'));
      expect(outboxRepo.pendingOps.isEmpty, isTrue);
    });

    test('pulls multi-entity changes and updates localDb state', () async {
      remoteApi.pulledChanges = [
        {
          'entity_type': 'task',
          'entity_id': 'task-100',
          'entity_version': 1,
          'payload': {
            'id': 'task-100',
            'title': 'مراجعة المخطط الهندسي',
            'priority': 'high',
          },
        },
        {
          'entity_type': 'debt',
          'entity_id': 'debt-200',
          'entity_version': 1,
          'payload': {
            'id': 'debt-200',
            'person_id': 'أبو فهد',
            'debt_type': 'payable',
            'total_amount': '25000.00',
          },
        },
      ];

      final result = await syncEngine.pull(wsId);
      expect(result.isSuccess, isTrue);
      expect(result.value, equals(2));
      expect(localDb.items.containsKey('task-100'), isTrue);
      expect(localDb.debts.containsKey('debt-200'), isTrue);
      expect(localDb.syncState[wsId], equals(2));
    });

    test('syncWithBackoff retries on transient network failure and recovers', () async {
      outboxRepo.pendingOps.add({
        'operation_id': 'op-retry-01',
        'entity_type': 'item',
        'entity_id': 'task-retry',
        'payload': {'title': 'مهمة إعادة المحاولة'},
      });

      remoteApi.shouldFailPush = true;

      // First attempt fails, then recovers
      Future.delayed(const Duration(milliseconds: 100), () {
        remoteApi.shouldFailPush = false;
      });

      final result = await syncEngine.syncWithBackoff(wsId, maxAttempts: 3);
      expect(result.isSuccess, isTrue);
      expect(remoteApi.pushCalls, greaterThanOrEqualTo(2));
    });
  });
}

class FakeItemRepository implements IItemRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
