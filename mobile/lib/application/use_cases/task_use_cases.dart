// Task Application Use Cases — مشروع «مُعين» (Mouin)
import 'package:mouin/core/result/result.dart';
import 'package:mouin/core/errors/failures.dart';
import 'package:mouin/core/utils/uuidv7.dart';
import 'package:mouin/domain/entities/item.dart';
import 'package:mouin/domain/repositories/i_item_repository.dart';
import 'package:mouin/domain/value_objects/types.dart';
import 'package:mouin/application/commands/item_commands.dart';

class TaskUseCases {
  final IItemRepository itemRepository;
  final IOutboxRepository outboxRepository;

  TaskUseCases({required this.itemRepository, required this.outboxRepository});

  Future<Result<Item, Failure>> createTask(CreateTaskCommand cmd) async {
    final taskId = UuidV7.generate();
    final item = Item.createTask(
      id: taskId,
      workspaceId: cmd.workspaceId,
      title: cmd.title,
      dueDate: cmd.dueDate,
      priority: cmd.priority,
      summary: cmd.summary,
    );

    final saveRes = await itemRepository.save(item);
    if (!saveRes.isSuccess) return Result.failure(saveRes.failure);

    // Enqueue Outbox mutation atomically
    await outboxRepository.enqueue(
      operationId: UuidV7.generate(),
      entityType: 'item',
      entityId: taskId,
      operation: 'insert',
      payload: {
        'id': taskId,
        'workspace_id': cmd.workspaceId,
        'item_type': 'task',
        'title': cmd.title,
        'priority': cmd.priority.name,
        'due_date': cmd.dueDate?.toIso8601String(),
        'summary': cmd.summary,
      },
    );

    return Result.success(item);
  }

  Future<Result<Item, Failure>> completeTask(CompleteTaskCommand cmd) async {
    final getRes = await itemRepository.getById(cmd.workspaceId, cmd.itemId);
    if (!getRes.isSuccess) return Result.failure(getRes.failure);
    final item = getRes.value;
    if (item == null || item.isDeleted) {
      return const Result.failure(NotFoundFailure('Task not found'));
    }

    final updatedTaskDetail = item.taskDetail?.copyWith(
      status: TaskStatus.completed,
      completedAt: DateTime.now().toUtc(),
    );

    final updatedItem = Item(
      id: item.id,
      workspaceId: item.workspaceId,
      itemType: item.itemType,
      title: item.title,
      summary: item.summary,
      privacy: item.privacy,
      taskDetail: updatedTaskDetail,
      createdAt: item.createdAt,
      updatedAt: DateTime.now().toUtc(),
      entityVersion: item.entityVersion + 1,
    );

    final saveRes = await itemRepository.save(updatedItem);
    if (!saveRes.isSuccess) return Result.failure(saveRes.failure);

    await outboxRepository.enqueue(
      operationId: UuidV7.generate(),
      entityType: 'item',
      entityId: item.id,
      operation: 'update',
      payload: {
        'id': item.id,
        'status': 'completed',
        'completed_at': updatedTaskDetail?.completedAt?.toIso8601String(),
        'entity_version': updatedItem.entityVersion,
      },
      baseVersion: item.entityVersion,
    );

    return Result.success(updatedItem);
  }

  Future<Result<Item, Failure>> updateTask({
    required String workspaceId,
    required String itemId,
    String? title,
    String? summary,
    Priority? priority,
    DateTime? dueDate,
    TaskStatus? status,
  }) async {
    final getRes = await itemRepository.getById(workspaceId, itemId);
    if (!getRes.isSuccess) return Result.failure(getRes.failure);
    final item = getRes.value;
    if (item == null || item.isDeleted) {
      return const Result.failure(NotFoundFailure('Task not found'));
    }

    final updatedTaskDetail = item.taskDetail?.copyWith(
      priority: priority ?? item.taskDetail?.priority,
      dueDate: dueDate ?? item.taskDetail?.dueDate,
      status: status ?? item.taskDetail?.status,
      completedAt: status == TaskStatus.completed
          ? (item.taskDetail?.completedAt ?? DateTime.now().toUtc())
          : (status == TaskStatus.pending ? null : item.taskDetail?.completedAt),
    );

    final updatedItem = Item(
      id: item.id,
      workspaceId: item.workspaceId,
      itemType: item.itemType,
      title: title ?? item.title,
      summary: summary ?? item.summary,
      privacy: item.privacy,
      taskDetail: updatedTaskDetail,
      createdAt: item.createdAt,
      updatedAt: DateTime.now().toUtc(),
      entityVersion: item.entityVersion + 1,
    );

    final saveRes = await itemRepository.save(updatedItem);
    if (!saveRes.isSuccess) return Result.failure(saveRes.failure);

    await outboxRepository.enqueue(
      operationId: UuidV7.generate(),
      entityType: 'item',
      entityId: item.id,
      operation: 'update',
      payload: {
        'id': item.id,
        'title': updatedItem.title,
        'summary': updatedItem.summary,
        'priority': updatedTaskDetail?.priority.name,
        'due_date': updatedTaskDetail?.dueDate?.toIso8601String(),
        'status': updatedTaskDetail?.status.name,
        'entity_version': updatedItem.entityVersion,
      },
      baseVersion: item.entityVersion,
    );

    return Result.success(updatedItem);
  }

  Future<Result<void, Failure>> softDelete(SoftDeleteItemCommand cmd) async {
    final getRes = await itemRepository.getById(cmd.workspaceId, cmd.itemId);
    if (!getRes.isSuccess) return Result.failure(getRes.failure);
    final item = getRes.value;
    if (item == null || item.isDeleted) return const Result.success(null);

    final deletedItem = item.markDeleted();
    await itemRepository.save(deletedItem);

    await outboxRepository.enqueue(
      operationId: UuidV7.generate(),
      entityType: 'item',
      entityId: item.id,
      operation: 'delete',
      payload: {'id': item.id, 'deleted_at': deletedItem.deletedAt?.toIso8601String()},
      baseVersion: item.entityVersion,
    );

    return const Result.success(null);
  }
}
