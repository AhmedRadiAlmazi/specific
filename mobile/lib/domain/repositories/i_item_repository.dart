// Domain Repository Interfaces — مشروع «مُعين» (Mouin)
import 'package:mouin/core/result/result.dart';
import 'package:mouin/core/errors/failures.dart';
import 'package:mouin/domain/entities/item.dart';
import 'package:mouin/domain/entities/debt.dart';
import 'package:mouin/domain/entities/reminder.dart';

abstract class IItemRepository {
  Future<Result<void, Failure>> save(Item item);
  Future<Result<Item?, Failure>> getById(String workspaceId, String id);
  Future<Result<List<Item>, Failure>> listByWorkspace(String workspaceId, {int limit = 50, int offset = 0});
  Future<Result<List<Item>, Failure>> searchArabic(String workspaceId, String query);
}

abstract class IDebtRepository {
  Future<Result<void, Failure>> save(Debt debt);
  Future<Result<Debt?, Failure>> getById(String workspaceId, String id);
  Future<Result<List<Debt>, Failure>> listByWorkspace(String workspaceId);
}

abstract class IReminderRepository {
  Future<Result<void, Failure>> saveRule(ReminderRule rule);
  Future<Result<ReminderRule?, Failure>> getRuleById(String workspaceId, String id);
  Future<Result<void, Failure>> saveInstance(ReminderInstance instance);
}

abstract class IOutboxRepository {
  Future<Result<void, Failure>> enqueue({
    required String operationId,
    required String entityType,
    required String entityId,
    required String operation,
    required Map<String, dynamic> payload,
    int baseVersion = 1,
  });
  Future<Result<List<Map<String, dynamic>>, Failure>> getPendingOperations({int limit = 50});
  Future<Result<void, Failure>> markCompleted(String operationId);
}
