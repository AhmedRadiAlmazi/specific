// Reminder Aggregate & Instance — مشروع «مُعين» (Mouin)
import 'package:mouin/domain/value_objects/types.dart';

class ReminderInstance {
  final String id;
  final String ruleId;
  final String itemId;
  final String workspaceId;
  final String occurrenceKey;
  final DateTime scheduledTime;
  final ReminderStatus status;
  final DateTime? snoozedUntil;

  ReminderInstance({
    required this.id,
    required this.ruleId,
    required this.itemId,
    required this.workspaceId,
    required this.occurrenceKey,
    required this.scheduledTime,
    this.status = ReminderStatus.pending,
    this.snoozedUntil,
  });
}

class ReminderRule {
  final String id;
  final String workspaceId;
  final String itemId;
  final ReminderTriggerType triggerType;
  final DateTime? triggerTime;
  final int? offsetMinutes;
  final String? rrule;
  final bool isActive;
  final List<ReminderInstance> instances;

  ReminderRule({
    required this.id,
    required this.workspaceId,
    required this.itemId,
    required this.triggerType,
    this.triggerTime,
    this.offsetMinutes,
    this.rrule,
    this.isActive = true,
    List<ReminderInstance>? instances,
  }) : instances = instances ?? [];
}
