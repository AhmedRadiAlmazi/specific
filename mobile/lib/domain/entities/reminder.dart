// Reminder Domain Entity — مشروع «مُعين» (Mouin)
import '../value_objects/types.dart';

class ReminderRule {
  final String id;
  final String workspaceId;
  final String itemId;
  final ReminderTriggerType triggerType;
  final DateTime? triggerTime;
  final int? offsetMinutes;
  final String? rrule;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ReminderRule({
    required this.id,
    required this.workspaceId,
    required this.itemId,
    required this.triggerType,
    this.triggerTime,
    this.offsetMinutes,
    this.rrule,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  ReminderRule copyWith({
    String? id,
    String? workspaceId,
    String? itemId,
    ReminderTriggerType? triggerType,
    DateTime? triggerTime,
    int? offsetMinutes,
    String? rrule,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReminderRule(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      itemId: itemId ?? this.itemId,
      triggerType: triggerType ?? this.triggerType,
      triggerTime: triggerTime ?? this.triggerTime,
      offsetMinutes: offsetMinutes ?? this.offsetMinutes,
      rrule: rrule ?? this.rrule,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workspace_id': workspaceId,
      'item_id': itemId,
      'trigger_type': triggerType.name,
      'trigger_time': triggerTime?.toIso8601String(),
      'offset_minutes': offsetMinutes,
      'rrule': rrule,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory ReminderRule.fromMap(Map<String, dynamic> map) {
    return ReminderRule(
      id: map['id'] as String,
      workspaceId: map['workspace_id'] as String,
      itemId: map['item_id'] as String,
      triggerType: ReminderTriggerType.values.firstWhere(
        (e) => e.name == map['trigger_type'],
        orElse: () => ReminderTriggerType.absolute,
      ),
      triggerTime: map['trigger_time'] != null
          ? DateTime.tryParse(map['trigger_time'] as String)
          : null,
      offsetMinutes: map['offset_minutes'] as int?,
      rrule: map['rrule'] as String?,
      isActive: map['is_active'] == 1 || map['is_active'] == true,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'] as String)
          : null,
    );
  }
}
