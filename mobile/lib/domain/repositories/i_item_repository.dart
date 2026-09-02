// Repository Interfaces — مشروع «مُعين» (Mouin)
import 'package:mouin/core/result/result.dart';
import 'package:mouin/core/errors/failures.dart';
import 'package:mouin/domain/entities/item.dart';
import 'package:mouin/domain/entities/debt.dart';
import 'package:mouin/domain/entities/reminder.dart';

abstract class IItemRepository {
  Future<Result<List<Item>, Failure>> listByWorkspace(String workspaceId, {int limit = 50, int offset = 0});
  Future<Result<Item?, Failure>> getById(String workspaceId, String id);
  Future<Result<void, Failure>> save(Item item);
  Future<Result<void, Failure>> delete(String workspaceId, String id);
  Future<Result<List<Item>, Failure>> searchArabic(String workspaceId, String query);
}

abstract class IOutboxRepository {
  Future<Result<List<Map<String, dynamic>>, Failure>> getPendingOperations();
  Future<Result<void, Failure>> saveOperation(Map<String, dynamic> operation);
  Future<Result<void, Failure>> markCompleted(String operationId);
  Future<void> enqueue({
    required String operationId,
    required String entityType,
    required String entityId,
    required String operation,
    required Map<String, dynamic> payload,
    int? baseVersion,
  });
}

abstract class IReminderRepository {
  Future<Result<void, Failure>> saveRule(ReminderRule rule);
  Future<Result<List<ReminderRule>, Failure>> getRulesByItem(String itemId);
  Future<Result<void, Failure>> deleteRule(String ruleId);
}

abstract class IDebtRepository {
  Future<Result<void, Failure>> save(Debt debt);
  Future<Result<List<Debt>, Failure>> listByWorkspace(String workspaceId);
  Future<Result<Debt?, Failure>> getById(String workspaceId, String id);
  Future<Result<void, Failure>> delete(String workspaceId, String id);
}
