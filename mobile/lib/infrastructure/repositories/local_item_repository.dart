// Local SQLite Repositories — مشروع «مُعين» (Mouin)
import 'package:mouin/core/result/result.dart';
import 'package:mouin/core/errors/failures.dart';
import 'package:mouin/core/utils/arabic_normalizer.dart';
import 'package:mouin/domain/entities/item.dart';
import 'package:mouin/domain/entities/debt.dart';
import 'package:mouin/domain/entities/reminder.dart';
import 'package:mouin/domain/repositories/i_item_repository.dart';
import 'package:mouin/domain/value_objects/types.dart';
import 'package:mouin/domain/value_objects/money.dart';
import 'package:mouin/infrastructure/database/local_sqlite_db.dart';

class LocalItemRepository implements IItemRepository {
  final LocalSqliteDb db;
  LocalItemRepository(this.db);

  @override
  Future<Result<void, Failure>> save(Item item) async {
    // 1. Upsert root item
    db.items[item.id] = {
      'id': item.id,
      'workspace_id': item.workspaceId,
      'item_type': item.itemType.name,
      'title': item.title,
      'summary': item.summary,
      'privacy_classification': item.privacy.name,
      'category_id': item.categoryId,
      'created_at': item.createdAt.toIso8601String(),
      'updated_at': item.updatedAt.toIso8601String(),
      'deleted_at': item.deletedAt?.toIso8601String(),
      'entity_version': item.entityVersion,
    };

    // 2. Upsert subtype details
    if (item.taskDetail != null) {
      db.tasks[item.id] = {
        'item_id': item.id,
        'due_date': item.taskDetail!.dueDate?.toIso8601String(),
        'priority': item.taskDetail!.priority.name,
        'status': item.taskDetail!.status.name,
        'completed_at': item.taskDetail!.completedAt?.toIso8601String(),
        'estimated_duration_minutes': item.taskDetail!.estimatedDurationMinutes,
      };
    }
    if (item.noteDetail != null) {
      db.notes[item.id] = {
        'item_id': item.id,
        'content': item.noteDetail!.content,
        'content_format': item.noteDetail!.contentFormat,
        'word_count': item.noteDetail!.wordCount,
      };
    }
    if (item.appointmentDetail != null) {
      db.appointments[item.id] = {
        'item_id': item.id,
        'start_time': item.appointmentDetail!.startTime.toIso8601String(),
        'end_time': item.appointmentDetail!.endTime?.toIso8601String(),
        'location': item.appointmentDetail!.location,
        'calendar_event_id': item.appointmentDetail!.calendarEventId,
        'all_day': item.appointmentDetail!.allDay ? 1 : 0,
        'timezone': item.appointmentDetail!.timezone,
      };
    }
    if (item.documentDetail != null) {
      db.documents[item.id] = {
        'item_id': item.id,
        'document_type': item.documentDetail!.documentType,
        'document_number': item.documentDetail!.documentNumber,
        'issuing_authority': item.documentDetail!.issuingAuthority,
        'issue_date': item.documentDetail!.issueDate?.toIso8601String(),
        'expiry_date': item.documentDetail!.expiryDate?.toIso8601String(),
        'storage_path': item.documentDetail!.storagePath,
        'mime_type': item.documentDetail!.mimeType,
        'file_size_bytes': item.documentDetail!.fileSizeBytes,
      };
    }
    return const Result.success(null);
  }

  @override
  Future<Result<Item?, Failure>> getById(String workspaceId, String id) async {
    final row = db.items[id];
    if (row == null || row['workspace_id'] != workspaceId) {
      return const Result.success(null);
    }

    TaskDetail? taskDetail;
    final tRow = db.tasks[id];
    if (tRow != null) {
      taskDetail = TaskDetail(
        dueDate: tRow['due_date'] != null ? DateTime.parse(tRow['due_date']) : null,
        priority: Priority.values.byName(tRow['priority']),
        status: TaskStatus.values.byName(tRow['status']),
        completedAt: tRow['completed_at'] != null ? DateTime.parse(tRow['completed_at']) : null,
        estimatedDurationMinutes: tRow['estimated_duration_minutes'],
      );
    }

    NoteDetail? noteDetail;
    final nRow = db.notes[id];
    if (nRow != null) {
      noteDetail = NoteDetail(
        content: nRow['content'] ?? '',
        contentFormat: nRow['content_format'] ?? 'plain_text',
        wordCount: nRow['word_count'],
      );
    }

    AppointmentDetail? apptDetail;
    final aRow = db.appointments[id];
    if (aRow != null) {
      apptDetail = AppointmentDetail(
        startTime: DateTime.parse(aRow['start_time']),
        endTime: aRow['end_time'] != null ? DateTime.parse(aRow['end_time']) : null,
        location: aRow['location'],
        calendarEventId: aRow['calendar_event_id'],
        allDay: aRow['all_day'] == 1,
        timezone: aRow['timezone'] ?? 'Asia/Aden',
      );
    }

    DocumentDetail? docDetail;
    final dRow = db.documents[id];
    if (dRow != null) {
      docDetail = DocumentDetail(
        documentType: dRow['document_type'] ?? 'general',
        documentNumber: dRow['document_number'],
        issuingAuthority: dRow['issuing_authority'],
        issueDate: dRow['issue_date'] != null ? DateTime.parse(dRow['issue_date']) : null,
        expiryDate: dRow['expiry_date'] != null ? DateTime.parse(dRow['expiry_date']) : null,
        storagePath: dRow['storage_path'],
        mimeType: dRow['mime_type'],
        fileSizeBytes: dRow['file_size_bytes'],
      );
    }

    final item = Item(
      id: row['id'],
      workspaceId: row['workspace_id'],
      itemType: ItemType.values.byName(row['item_type']),
      title: row['title'],
      summary: row['summary'],
      privacy: PrivacyClassification.values.byName(row['privacy_classification']),
      categoryId: row['category_id'],
      taskDetail: taskDetail,
      noteDetail: noteDetail,
      appointmentDetail: apptDetail,
      documentDetail: docDetail,
      createdAt: DateTime.parse(row['created_at']),
      updatedAt: DateTime.parse(row['updated_at']),
      deletedAt: row['deleted_at'] != null ? DateTime.parse(row['deleted_at']) : null,
      entityVersion: row['entity_version'] ?? 1,
    );
    return Result.success(item);
  }

  @override
  Future<Result<List<Item>, Failure>> listByWorkspace(String workspaceId, {int limit = 50, int offset = 0}) async {
    final list = <Item>[];
    for (final row in db.items.values) {
      if (row['workspace_id'] == workspaceId && row['deleted_at'] == null) {
        final res = await getById(workspaceId, row['id']);
        if (res.isSuccess && res.value != null) {
          list.add(res.value!);
        }
      }
    }
    return Result.success(list);
  }

  @override
  Future<Result<List<Item>, Failure>> searchArabic(String workspaceId, String query) async {
    final normalizedQuery = ArabicNormalizer.normalize(query);
    final results = <Item>[];
    for (final row in db.items.values) {
      if (row['workspace_id'] == workspaceId && row['deleted_at'] == null) {
        final normTitle = ArabicNormalizer.normalize(row['title'] ?? '');
        final normSummary = ArabicNormalizer.normalize(row['summary'] ?? '');
        if (normTitle.contains(normalizedQuery) || normSummary.contains(normalizedQuery)) {
          final itemRes = await getById(workspaceId, row['id']);
          if (itemRes.isSuccess && itemRes.value != null) {
            results.add(itemRes.value!);
          }
        }
      }
    }
    return Result.success(results);
  }
}

class LocalDebtRepository implements IDebtRepository {
  final LocalSqliteDb db;
  LocalDebtRepository(this.db);

  @override
  Future<Result<void, Failure>> save(Debt debt) async {
    db.debts[debt.id] = {
      'id': debt.id,
      'workspace_id': debt.workspaceId,
      'person_id': debt.personId,
      'debt_type': debt.debtType.name,
      'total_amount': debt.totalAmount.toDecimalString(),
      'currency': debt.totalAmount.currency,
      'status': debt.status.name,
      'due_date': debt.dueDate?.toIso8601String(),
      'created_at': debt.createdAt.toIso8601String(),
      'updated_at': debt.updatedAt.toIso8601String(),
      'deleted_at': debt.deletedAt?.toIso8601String(),
      'entity_version': debt.entityVersion,
    };

    for (final tx in debt.transactions) {
      db.debtTransactions[tx.id] = {
        'id': tx.id,
        'debt_id': tx.debtId,
        'workspace_id': tx.workspaceId,
        'transaction_type': tx.transactionType.name,
        'amount': tx.amount.toDecimalString(),
        'currency': tx.amount.currency,
        'transaction_date': tx.transactionDate.toIso8601String(),
        'notes': tx.notes,
        'reference_transaction_id': tx.referenceTransactionId,
        'created_at': tx.createdAt.toIso8601String(),
      };
    }
    return const Result.success(null);
  }

  @override
  Future<Result<Debt?, Failure>> getById(String workspaceId, String id) async {
    final row = db.debts[id];
    if (row == null || row['workspace_id'] != workspaceId) {
      return const Result.success(null);
    }

    final txList = <DebtTransaction>[];
    for (final txRow in db.debtTransactions.values) {
      if (txRow['debt_id'] == id && txRow['workspace_id'] == workspaceId) {
        txList.add(DebtTransaction(
          id: txRow['id'],
          debtId: txRow['debt_id'],
          workspaceId: txRow['workspace_id'],
          transactionType: DebtTransactionType.values.byName(txRow['transaction_type']),
          amount: Money.fromDecimalString(txRow['amount'], currency: txRow['currency'] ?? 'YER'),
          transactionDate: DateTime.parse(txRow['transaction_date']),
          notes: txRow['notes'],
          referenceTransactionId: txRow['reference_transaction_id'],
          createdAt: DateTime.parse(txRow['created_at']),
        ));
      }
    }

    final debt = Debt(
      id: row['id'],
      workspaceId: row['workspace_id'],
      personId: row['person_id'],
      debtType: DebtType.values.byName(row['debt_type']),
      totalAmount: Money.fromDecimalString(row['total_amount'], currency: row['currency'] ?? 'YER'),
      status: DebtStatus.values.byName(row['status']),
      dueDate: row['due_date'] != null ? DateTime.parse(row['due_date']) : null,
      transactions: txList,
      createdAt: DateTime.parse(row['created_at']),
      updatedAt: DateTime.parse(row['updated_at']),
      deletedAt: row['deleted_at'] != null ? DateTime.parse(row['deleted_at']) : null,
      entityVersion: row['entity_version'],
    );
    return Result.success(debt);
  }

  @override
  Future<Result<List<Debt>, Failure>> listByWorkspace(String workspaceId) async {
    final list = <Debt>[];
    for (final row in db.debts.values) {
      if (row['workspace_id'] == workspaceId && row['deleted_at'] == null) {
        final res = await getById(workspaceId, row['id']);
        if (res.isSuccess && res.value != null) {
          list.add(res.value!);
        }
      }
    }
    return Result.success(list);
  }
}

class LocalReminderRepository implements IReminderRepository {
  final LocalSqliteDb db;
  LocalReminderRepository(this.db);

  @override
  Future<Result<void, Failure>> saveRule(ReminderRule rule) async {
    db.reminderRules[rule.id] = {
      'id': rule.id,
      'workspace_id': rule.workspaceId,
      'item_id': rule.itemId,
      'trigger_type': rule.triggerType.name,
      'trigger_time': rule.triggerTime?.toIso8601String(),
      'offset_minutes': rule.offsetMinutes,
      'rrule': rule.rrule,
      'is_active': rule.isActive ? 1 : 0,
    };
    return const Result.success(null);
  }

  @override
  Future<Result<ReminderRule?, Failure>> getRuleById(String workspaceId, String id) async {
    final row = db.reminderRules[id];
    if (row == null || row['workspace_id'] != workspaceId) {
      return const Result.success(null);
    }
    final rule = ReminderRule(
      id: row['id'],
      workspaceId: row['workspace_id'],
      itemId: row['item_id'],
      triggerType: ReminderTriggerType.values.byName(row['trigger_type']),
      triggerTime: row['trigger_time'] != null ? DateTime.parse(row['trigger_time']) : null,
      offsetMinutes: row['offset_minutes'],
      rrule: row['rrule'],
      isActive: row['is_active'] == 1,
    );
    return Result.success(rule);
  }

  @override
  Future<Result<void, Failure>> saveInstance(ReminderInstance instance) async {
    db.reminderInstances[instance.id] = {
      'id': instance.id,
      'rule_id': instance.ruleId,
      'item_id': instance.itemId,
      'workspace_id': instance.workspaceId,
      'occurrence_key': instance.occurrenceKey,
      'scheduled_time': instance.scheduledTime.toIso8601String(),
      'status': instance.status.name,
      'snoozed_until': instance.snoozedUntil?.toIso8601String(),
    };
    return const Result.success(null);
  }
}

class LocalOutboxRepository implements IOutboxRepository {
  final LocalSqliteDb db;
  LocalOutboxRepository(this.db);

  @override
  Future<Result<void, Failure>> enqueue({
    required String operationId,
    required String entityType,
    required String entityId,
    required String operation,
    required Map<String, dynamic> payload,
    int baseVersion = 1,
  }) async {
    db.outbox[operationId] = {
      'operation_id': operationId,
      'entity_type': entityType,
      'entity_id': entityId,
      'operation': operation,
      'payload': payload,
      'base_version': baseVersion,
      'status': 'pending',
      'attempt_count': 0,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    };
    return const Result.success(null);
  }

  @override
  Future<Result<List<Map<String, dynamic>>, Failure>> getPendingOperations({int limit = 50}) async {
    final list = db.outbox.values.where((op) => op['status'] == 'pending').toList();
    return Result.success(list.take(limit).toList());
  }

  @override
  Future<Result<void, Failure>> markCompleted(String operationId) async {
    db.outbox.remove(operationId);
    return const Result.success(null);
  }
}
