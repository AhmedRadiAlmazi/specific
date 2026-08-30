// Reminder Application Use Cases — مشروع «مُعين» (Mouin)
import 'package:mouin/core/result/result.dart';
import 'package:mouin/core/errors/failures.dart';
import 'package:mouin/core/utils/uuidv7.dart';
import 'package:mouin/domain/entities/reminder.dart';
import 'package:mouin/domain/repositories/i_item_repository.dart';
import 'package:mouin/application/commands/item_commands.dart';

class ReminderUseCases {
  final IReminderRepository reminderRepository;
  final IOutboxRepository outboxRepository;

  ReminderUseCases({required this.reminderRepository, required this.outboxRepository});

  Future<Result<ReminderRule, Failure>> createRule(CreateReminderRuleCommand cmd) async {
    final ruleId = UuidV7.generate();
    final rule = ReminderRule(
      id: ruleId,
      workspaceId: cmd.workspaceId,
      itemId: cmd.itemId,
      triggerType: cmd.triggerType,
      triggerTime: cmd.triggerTime,
      offsetMinutes: cmd.offsetMinutes,
      rrule: cmd.rrule,
      isActive: true,
    );

    final saveRes = await reminderRepository.saveRule(rule);
    if (!saveRes.isSuccess) return Result.failure(saveRes.failure);

    await outboxRepository.enqueue(
      operationId: UuidV7.generate(),
      entityType: 'reminder_rule',
      entityId: ruleId,
      operation: 'insert',
      payload: {
        'id': ruleId,
        'workspace_id': cmd.workspaceId,
        'item_id': cmd.itemId,
        'trigger_type': cmd.triggerType.name,
        'trigger_time': cmd.triggerTime?.toIso8601String(),
        'offset_minutes': cmd.offsetMinutes,
        'rrule': cmd.rrule,
      },
    );

    return Result.success(rule);
  }
}
