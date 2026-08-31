// Today Timeline Entry Model & Widget — مشروع «مُعين» (Mouin)
import 'package:flutter/material.dart';
import 'package:mouin/domain/value_objects/types.dart';
import '../../theme/tokens/mouin_colors.dart';
import '../../theme/tokens/mouin_radii.dart';
import '../../theme/tokens/mouin_spacing.dart';
import '../common/mouin_card.dart';
import '../common/mouin_badge.dart';
import '../domain/domain_badges.dart';
import '../quick_capture/quick_capture_types.dart';

class TodayTimelineEntryModel {
  final String id;
  final String title;
  final QuickCaptureType type;
  final DateTime? scheduledTime;
  final Priority? priority;
  final String? amount;
  final String? currency;
  final bool isCompleted;
  final bool isOverdue;
  final VoidCallback? onToggleComplete;
  final VoidCallback? onDelete;

  const TodayTimelineEntryModel({
    required this.id,
    required this.title,
    required this.type,
    this.scheduledTime,
    this.priority,
    this.amount,
    this.currency,
    this.isCompleted = false,
    this.isOverdue = false,
    this.onToggleComplete,
    this.onDelete,
  });

  String get formattedTime {
    if (scheduledTime == null) return 'خلال اليوم';
    final hour = scheduledTime!.hour;
    final minute = scheduledTime!.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'م' : 'ص';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }
}

class TodayTimelineEntryWidget extends StatelessWidget {
  final TodayTimelineEntryModel entry;

  const TodayTimelineEntryWidget({
    super.key,
    required this.entry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget cardContent = MouinCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (entry.type == QuickCaptureType.task && entry.onToggleComplete != null)
            Checkbox(
              value: entry.isCompleted,
              onChanged: (_) => entry.onToggleComplete!(),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Icon(entry.type.icon, color: theme.colorScheme.primary, size: 20),
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    decoration: entry.isCompleted ? TextDecoration.lineThrough : null,
                    color: entry.isCompleted ? theme.colorScheme.onSurfaceVariant : null,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    MouinBadge(
                      label: entry.type.label,
                      textColor: theme.colorScheme.onSecondaryContainer,
                      backgroundColor: theme.colorScheme.secondaryContainer,
                    ),
                    if (entry.priority != null) ...[
                      const SizedBox(width: 6),
                      PriorityBadge(priority: entry.priority!),
                    ],
                    if (entry.amount != null) ...[
                      const SizedBox(width: 6),
                      MoneyDisplay(
                        amount: entry.amount!,
                        currency: entry.currency ?? 'YER',
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (entry.onDelete != null) {
      cardContent = Dismissible(
        key: Key(entry.id),
        direction: DismissDirection.endToStart,
        background: Container(
          color: MouinColors.error,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 20),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        onDismissed: (_) => entry.onDelete!(),
        child: cardContent,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: MouinSpacing.md, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time Column & Bullet
          SizedBox(
            width: 70,
            child: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Text(
                entry.formattedTime,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          // Vertical Line & Node
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: entry.isCompleted ? MouinColors.success : theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 2,
                height: 50,
                color: theme.colorScheme.surfaceVariant,
              ),
            ],
          ),
          const SizedBox(width: 8),
          // Content Card
          Expanded(child: cardContent),
        ],
      ),
    );
  }
}
