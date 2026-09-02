// Bidirectional Sync Engine with Exponential Backoff — مشروع «مُعين» (Mouin)
import 'dart:async';
import 'dart:math';
import 'package:mouin/core/result/result.dart';
import 'package:mouin/core/errors/failures.dart';
import 'package:mouin/domain/repositories/i_item_repository.dart';
import 'package:mouin/infrastructure/database/local_sqlite_db.dart';

abstract class IRemoteSyncApi {
  Future<Result<Map<String, dynamic>, Failure>> push(String workspaceId, List<Map<String, dynamic>> operations);
  Future<Result<Map<String, dynamic>, Failure>> pull(String workspaceId, int sinceSequence, {int limit = 50});
  Future<Result<Map<String, dynamic>, Failure>> bootstrap(String workspaceId);
}

enum SyncStateStatus {
  idle,
  syncing,
  success,
  offline,
  failed,
}

class SyncEngine {
  final LocalSqliteDb localDb;
  final IOutboxRepository outboxRepository;
  final IItemRepository itemRepository;
  final IRemoteSyncApi remoteSyncApi;

  int _consecutiveFailures = 0;
  final Random _random = Random();

  SyncEngine({
    required this.localDb,
    required this.outboxRepository,
    required this.itemRepository,
    required this.remoteSyncApi,
  });

  int get consecutiveFailures => _consecutiveFailures;

  /// Full two-way sync loop with Exponential Backoff retry resilience
  Future<Result<int, Failure>> syncWithBackoff(String workspaceId, {int maxAttempts = 3}) async {
    int attempts = 0;
    Failure? lastFailure;

    while (attempts < maxAttempts) {
      attempts++;
      final pushRes = await push(workspaceId);
      if (!pushRes.isSuccess) {
        lastFailure = pushRes.failure;
        _consecutiveFailures++;
        if (attempts < maxAttempts) {
          final backoffMs = _calculateBackoffDelay(attempts);
          await Future.delayed(Duration(milliseconds: backoffMs));
        }
        continue;
      }

      final pullRes = await pull(workspaceId);
      if (!pullRes.isSuccess) {
        lastFailure = pullRes.failure;
        _consecutiveFailures++;
        if (attempts < maxAttempts) {
          final backoffMs = _calculateBackoffDelay(attempts);
          await Future.delayed(Duration(milliseconds: backoffMs));
        }
        continue;
      }

      _consecutiveFailures = 0;
      return Result.success((pushRes.value) + (pullRes.value));
    }

    return Result.failure(lastFailure ?? const NetworkFailure('Sync failed after maximum retry attempts.'));
  }

  int _calculateBackoffDelay(int attempt) {
    // Exponential backoff: base 200ms * 2^(attempt - 1) + jitter (0-50ms)
    final base = 200 * pow(2, attempt - 1).toInt();
    final jitter = _random.nextInt(50);
    return base + jitter;
  }

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

    // Apply changes locally across items, debts, and subtypes
    for (final change in changes) {
      final entityType = change['entity_type'] as String? ?? 'item';
      final payload = change['payload'] as Map<String, dynamic>? ?? {};
      final entityId = payload['id'] as String? ?? change['entity_id'] as String? ?? '';
      if (entityId.isEmpty) continue;

      if (entityType == 'debt') {
        localDb.debts[entityId] = {
          'id': entityId,
          'workspace_id': workspaceId,
          'person_id': payload['person_id'] ?? 'طرف المعاملة',
          'debt_type': payload['debt_type'] ?? 'payable',
          'total_amount': payload['total_amount'] ?? '0.00',
          'currency': payload['currency'] ?? 'YER',
          'status': payload['status'] ?? 'active',
          'due_date': payload['due_date'],
          'created_at': payload['created_at'] ?? DateTime.now().toUtc().toIso8601String(),
          'updated_at': payload['updated_at'] ?? DateTime.now().toUtc().toIso8601String(),
          'deleted_at': payload['deleted_at'],
          'entity_version': change['entity_version'] ?? 1,
        };
      } else if (entityType == 'item' || entityType == 'task' || entityType == 'note' ||
          entityType == 'appointment' || entityType == 'document' || entityType == 'shopping') {
        final iType = payload['item_type'] as String? ?? (entityType == 'item' ? 'task' : entityType);
        localDb.items[entityId] = {
          'id': entityId,
          'workspace_id': workspaceId,
          'item_type': iType,
          'title': payload['title'] ?? 'عنوان العنصر',
          'summary': payload['summary'],
          'privacy_classification': payload['privacy_classification'] ?? 'private',
          'created_at': payload['created_at'] ?? DateTime.now().toUtc().toIso8601String(),
          'updated_at': payload['updated_at'] ?? DateTime.now().toUtc().toIso8601String(),
          'deleted_at': payload['deleted_at'],
          'entity_version': change['entity_version'] ?? 1,
        };

        if (iType == 'task') {
          localDb.tasks[entityId] = {
            'item_id': entityId,
            'due_date': payload['due_date'],
            'priority': payload['priority'] ?? 'medium',
            'status': payload['status'] ?? 'pending',
            'completed_at': payload['completed_at'],
          };
        } else if (iType == 'note') {
          localDb.notes[entityId] = {
            'item_id': entityId,
            'content': payload['content'] ?? '',
            'content_format': payload['content_format'] ?? 'plain_text',
          };
        } else if (iType == 'appointment') {
          localDb.appointments[entityId] = {
            'item_id': entityId,
            'start_time': payload['start_time'] ?? DateTime.now().toUtc().toIso8601String(),
            'end_time': payload['end_time'],
            'location': payload['location'],
            'all_day': payload['all_day'] == true ? 1 : 0,
            'timezone': payload['timezone'] ?? 'Asia/Aden',
          };
        } else if (iType == 'document') {
          localDb.documents[entityId] = {
            'item_id': entityId,
            'document_type': payload['document_type'] ?? 'general',
            'document_number': payload['document_number'],
          };
        }
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
      final itemId = itemJson['id'] as String;
      final iType = itemJson['item_type'] as String? ?? 'task';
      localDb.items[itemId] = {
        'id': itemId,
        'workspace_id': workspaceId,
        'item_type': iType,
        'title': itemJson['title'] ?? '',
        'summary': itemJson['summary'],
        'privacy_classification': itemJson['privacy_classification'] ?? 'private',
        'created_at': itemJson['created_at'] ?? DateTime.now().toUtc().toIso8601String(),
        'updated_at': itemJson['updated_at'] ?? DateTime.now().toUtc().toIso8601String(),
        'deleted_at': itemJson['deleted_at'],
        'entity_version': itemJson['entity_version'] ?? 1,
      };
      if (iType == 'task') {
        localDb.tasks[itemId] = {
          'item_id': itemId,
          'due_date': itemJson['due_date'],
          'priority': itemJson['priority'] ?? 'medium',
          'status': itemJson['status'] ?? 'pending',
          'completed_at': itemJson['completed_at'],
        };
      } else if (iType == 'note') {
        localDb.notes[itemId] = {
          'item_id': itemId,
          'content': itemJson['content'] ?? '',
          'content_format': itemJson['content_format'] ?? 'plain_text',
        };
      }
    }
    localDb.syncState[workspaceId] = initialCursor;
    return const Result.success(null);
  }
}
