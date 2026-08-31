// Unified Item Application Use Cases — مشروع «مُعين» (Mouin)
import 'package:mouin/core/result/result.dart';
import 'package:mouin/core/errors/failures.dart';
import 'package:mouin/core/utils/uuidv7.dart';
import 'package:mouin/domain/entities/item.dart';
import 'package:mouin/domain/repositories/i_item_repository.dart';
import 'package:mouin/domain/value_objects/types.dart';
import 'package:mouin/application/commands/item_commands.dart';

class ItemUseCases {
  final IItemRepository itemRepository;
  final IOutboxRepository outboxRepository;

  ItemUseCases({required this.itemRepository, required this.outboxRepository});

  // 1. Create Task
  Future<Result<Item, Failure>> createTask(CreateTaskCommand cmd) async {
    final itemId = UuidV7.generate();
    final item = Item.createTask(
      id: itemId,
      workspaceId: cmd.workspaceId,
      title: cmd.title,
      dueDate: cmd.dueDate,
      priority: cmd.priority,
      summary: cmd.summary,
      categoryId: cmd.categoryId,
    );

    final saveRes = await itemRepository.save(item);
    if (!saveRes.isSuccess) return Result.failure(saveRes.failure);

    await outboxRepository.enqueue(
      operationId: UuidV7.generate(),
      entityType: 'item',
      entityId: itemId,
      operation: 'insert',
      payload: {
        'id': itemId,
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

  // 2. Create Note
  Future<Result<Item, Failure>> createNote(CreateNoteCommand cmd) async {
    final itemId = UuidV7.generate();
    final item = Item.createNote(
      id: itemId,
      workspaceId: cmd.workspaceId,
      title: cmd.title,
      content: cmd.content,
      contentFormat: cmd.contentFormat,
      summary: cmd.summary,
      categoryId: cmd.categoryId,
    );

    final saveRes = await itemRepository.save(item);
    if (!saveRes.isSuccess) return Result.failure(saveRes.failure);

    await outboxRepository.enqueue(
      operationId: UuidV7.generate(),
      entityType: 'item',
      entityId: itemId,
      operation: 'insert',
      payload: {
        'id': itemId,
        'workspace_id': cmd.workspaceId,
        'item_type': 'note',
        'title': cmd.title,
        'content': cmd.content,
        'content_format': cmd.contentFormat,
        'summary': cmd.summary,
      },
    );

    return Result.success(item);
  }

  // 3. Create Appointment
  Future<Result<Item, Failure>> createAppointment(CreateAppointmentCommand cmd) async {
    final itemId = UuidV7.generate();
    final item = Item.createAppointment(
      id: itemId,
      workspaceId: cmd.workspaceId,
      title: cmd.title,
      startTime: cmd.startTime,
      endTime: cmd.endTime,
      location: cmd.location,
      allDay: cmd.allDay,
      timezone: cmd.timezone,
      summary: cmd.summary,
      categoryId: cmd.categoryId,
    );

    final saveRes = await itemRepository.save(item);
    if (!saveRes.isSuccess) return Result.failure(saveRes.failure);

    await outboxRepository.enqueue(
      operationId: UuidV7.generate(),
      entityType: 'item',
      entityId: itemId,
      operation: 'insert',
      payload: {
        'id': itemId,
        'workspace_id': cmd.workspaceId,
        'item_type': 'appointment',
        'title': cmd.title,
        'start_time': cmd.startTime.toIso8601String(),
        'end_time': cmd.endTime?.toIso8601String(),
        'location': cmd.location,
        'all_day': cmd.allDay,
        'summary': cmd.summary,
      },
    );

    return Result.success(item);
  }

  // 4. Create Document
  Future<Result<Item, Failure>> createDocument(CreateDocumentCommand cmd) async {
    final itemId = UuidV7.generate();
    final item = Item.createDocument(
      id: itemId,
      workspaceId: cmd.workspaceId,
      title: cmd.title,
      documentType: cmd.documentType,
      documentNumber: cmd.documentNumber,
      issuingAuthority: cmd.issuingAuthority,
      issueDate: cmd.issueDate,
      expiryDate: cmd.expiryDate,
      summary: cmd.summary,
      categoryId: cmd.categoryId,
    );

    final saveRes = await itemRepository.save(item);
    if (!saveRes.isSuccess) return Result.failure(saveRes.failure);

    await outboxRepository.enqueue(
      operationId: UuidV7.generate(),
      entityType: 'item',
      entityId: itemId,
      operation: 'insert',
      payload: {
        'id': itemId,
        'workspace_id': cmd.workspaceId,
        'item_type': 'document',
        'title': cmd.title,
        'document_type': cmd.documentType,
        'document_number': cmd.documentNumber,
        'summary': cmd.summary,
      },
    );

    return Result.success(item);
  }

  // 5. Generic Unified Item Creation
  Future<Result<Item, Failure>> createUnifiedItem(CreateUnifiedItemCommand cmd) async {
    final itemId = UuidV7.generate();
    final item = Item.createUnified(
      id: itemId,
      workspaceId: cmd.workspaceId,
      itemType: cmd.itemType,
      title: cmd.title,
      summary: cmd.summary,
      categoryId: cmd.categoryId,
      privacy: cmd.privacy,
      taskDetail: cmd.taskDetail,
      noteDetail: cmd.noteDetail,
      appointmentDetail: cmd.appointmentDetail,
      documentDetail: cmd.documentDetail,
    );

    final saveRes = await itemRepository.save(item);
    if (!saveRes.isSuccess) return Result.failure(saveRes.failure);

    await outboxRepository.enqueue(
      operationId: UuidV7.generate(),
      entityType: 'item',
      entityId: itemId,
      operation: 'insert',
      payload: {
        'id': itemId,
        'workspace_id': cmd.workspaceId,
        'item_type': cmd.itemType.name,
        'title': cmd.title,
        'summary': cmd.summary,
      },
    );

    return Result.success(item);
  }

  // 6. Update Item
  Future<Result<Item, Failure>> updateItem(UpdateItemCommand cmd) async {
    final getRes = await itemRepository.getById(cmd.workspaceId, cmd.itemId);
    if (!getRes.isSuccess) return Result.failure(getRes.failure);
    final item = getRes.value;
    if (item == null || item.isDeleted) {
      return const Result.failure(NotFoundFailure('Item not found'));
    }

    final updated = Item(
      id: item.id,
      workspaceId: item.workspaceId,
      itemType: item.itemType,
      title: cmd.title ?? item.title,
      summary: cmd.summary ?? item.summary,
      privacy: cmd.privacy ?? item.privacy,
      categoryId: item.categoryId,
      taskDetail: item.taskDetail,
      noteDetail: item.noteDetail,
      appointmentDetail: item.appointmentDetail,
      documentDetail: item.documentDetail,
      shoppingListDetail: item.shoppingListDetail,
      createdAt: item.createdAt,
      updatedAt: DateTime.now().toUtc(),
      entityVersion: item.entityVersion + 1,
    );

    final saveRes = await itemRepository.save(updated);
    if (!saveRes.isSuccess) return Result.failure(saveRes.failure);

    await outboxRepository.enqueue(
      operationId: UuidV7.generate(),
      entityType: 'item',
      entityId: item.id,
      operation: 'update',
      payload: {
        'id': item.id,
        'title': updated.title,
        'summary': updated.summary,
        'entity_version': updated.entityVersion,
      },
      baseVersion: item.entityVersion,
    );

    return Result.success(updated);
  }

  // 7. Soft Delete Item
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

  // 8. Query Items by Workspace
  Future<Result<List<Item>, Failure>> listItems(String workspaceId, {ItemType? itemType, int limit = 50, int offset = 0}) async {
    final res = await itemRepository.listByWorkspace(workspaceId, limit: limit, offset: offset);
    if (!res.isSuccess) return Result.failure(res.failure);
    if (itemType != null) {
      final filtered = res.value.where((i) => i.itemType == itemType).toList();
      return Result.success(filtered);
    }
    return res;
  }

  // 9. Search Arabic
  Future<Result<List<Item>, Failure>> searchItems(String workspaceId, String query) {
    return itemRepository.searchArabic(workspaceId, query);
  }

  // 10. Get Item by ID
  Future<Result<Item?, Failure>> getItem(String workspaceId, String id) {
    return itemRepository.getById(workspaceId, id);
  }
}
