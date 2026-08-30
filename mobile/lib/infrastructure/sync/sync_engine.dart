// Bidirectional Sync Engine — مشروع «مُعين» (Mouin)
import 'package:mouin/core/result/result.dart';
import 'package:mouin/core/errors/failures.dart';
import 'package:mouin/domain/repositories/i_item_repository.dart';
import 'package:mouin/infrastructure/database/local_sqlite_db.dart';

abstract class IRemoteSyncApi {
  Future<Result<Map<String, dynamic>, Failure>> push(String workspaceId, List<Map<String, dynamic>> operations);
  Future<Result<Map<String, dynamic>, Failure>> pull(String workspaceId, int sinceSequence, {int limit = 50});
  Future<Result<Map<String, dynamic>, Failure>> bootstrap(String workspaceId);
}

class SyncEngine {
  final LocalSqliteDb localDb;
  final IOutboxRepository outboxRepository;
  final IItemRepository itemRepository;
  final IRemoteSyncApi remoteSyncApi;

  SyncEngine({
    required this.localDb,
    required this.outboxRepository,
    required this.itemRepository,
    required this.remoteSyncApi,
  });

  // 1. Push Phase: sends pending local outbox operations
  Future<Result<int, Failure>> push(String workspaceId) async {
    final pendingRes = await outboxRepository.getPendingOperations();
    if (!pendingRes.isSuccess) return Result.failure(pendingRes.failure);
    final ops = pendingRes.value;
    if (ops.isEmpty) return const Result.success(0);

    final pushRes = await remoteSyncApi.push(workspaceId, ops);
    if (!pushRes.isSuccess) return Result.failure(pushRes.failure);

    final acks = pushRes.value['acks'] as List<dynamic>? ?? [];
    for (final ack in acks) {
      final opId = ack['operation_id'] as String;
      await outboxRepository.markCompleted(opId);
    }
    return Result.success(acks.length);
  }

  // 2. Pull Phase: pulls new server sequence changes with No-Gap atomicity
  Future<Result<int, Failure>> pull(String workspaceId) async {
    final currentSeq = localDb.syncState[workspaceId] ?? 0;
    final pullRes = await remoteSyncApi.pull(workspaceId, currentSeq);
    if (!pullRes.isSuccess) return Result.failure(pullRes.failure);

    final changes = pullRes.value['changes'] as List<dynamic>? ?? [];
    final nextCursor = pullRes.value['next_cursor'] as int? ?? currentSeq;

    // Apply changes locally
    for (final change in changes) {
      final entityType = change['entity_type'];
      final payload = change['payload'] as Map<String, dynamic>? ?? {};
      if (entityType == 'item' || entityType == 'task') {
        localDb.items[payload['id']] = {
          'id': payload['id'],
          'workspace_id': workspaceId,
          'item_type': 'task',
          'title': payload['title'] ?? 'عنوان المهمة',
          'privacy_classification': 'private',
          'created_at': DateTime.now().toUtc().toIso8601String(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
          'deleted_at': payload['deleted_at'],
          'entity_version': change['entity_version'] ?? 1,
        };
      }
    }

    // Atomic update of server cursor sequence
    localDb.syncState[workspaceId] = nextCursor;
    return Result.success(changes.length);
  }

  // 3. Bootstrap Phase: downloads atomic snapshot + initial sequence cursor
  Future<Result<void, Failure>> bootstrap(String workspaceId) async {
    final bootRes = await remoteSyncApi.bootstrap(workspaceId);
    if (!bootRes.isSuccess) return Result.failure(bootRes.failure);

    final snapshotItems = bootRes.value['snapshot_items'] as List<dynamic>? ?? [];
    final initialCursor = bootRes.value['initial_cursor'] as int? ?? 0;

    for (final itemJson in snapshotItems) {
      localDb.items[itemJson['id']] = {
        'id': itemJson['id'],
        'workspace_id': workspaceId,
        'item_type': itemJson['item_type'] ?? 'task',
        'title': itemJson['title'] ?? '',
        'summary': itemJson['summary'],
        'privacy_classification': itemJson['privacy_classification'] ?? 'private',
        'created_at': itemJson['created_at'] ?? DateTime.now().toUtc().toIso8601String(),
        'updated_at': itemJson['updated_at'] ?? DateTime.now().toUtc().toIso8601String(),
        'deleted_at': itemJson['deleted_at'],
        'entity_version': itemJson['entity_version'] ?? 1,
      };
    }
    localDb.syncState[workspaceId] = initialCursor;
    return const Result.success(null);
  }
}
