// Today Unified Timeline View — مشروع «مُعين» (Mouin)
import 'package:flutter/material.dart';
import 'package:mouin/domain/entities/item.dart';
import 'package:mouin/domain/entities/debt.dart';
import 'package:mouin/domain/value_objects/types.dart';
import '../../theme/tokens/mouin_spacing.dart';
import '../common/mouin_section_header.dart';
import '../states/mouin_states.dart';
import '../quick_capture/quick_capture_types.dart';
import 'today_timeline_entry.dart';

class TodayTimeline extends StatelessWidget {
  final List<Item> tasks;
  final List<Debt> debts;
  final Function(String itemId)? onCompleteTask;
  final Function(String itemId)? onDeleteTask;
  final VoidCallback? onAddPressed;

  const TodayTimeline({
    super.key,
    required this.tasks,
    required this.debts,
    this.onCompleteTask,
    this.onDeleteTask,
    this.onAddPressed,
  });

  List<TodayTimelineEntryModel> _buildEntries() {
    final List<TodayTimelineEntryModel> entries = [];
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    // 1. Tasks
    for (final task in tasks) {
      final detail = task.taskDetail;
      final isCompleted = detail?.status == TaskStatus.completed;
      final dueDate = detail?.dueDate;

      // Include tasks due today or without due date
      if (dueDate == null || (dueDate.isAfter(todayStart.subtract(const Duration(seconds: 1))) && dueDate.isBefore(todayEnd))) {
        entries.add(
          TodayTimelineEntryModel(
            id: task.id,
            title: task.title,
            type: QuickCaptureType.task,
            scheduledTime: dueDate,
            priority: detail?.priority ?? Priority.medium,
            isCompleted: isCompleted,
            onToggleComplete: () {
              if (onCompleteTask != null) onCompleteTask!(task.id);
            },
            onDelete: () {
              if (onDeleteTask != null) onDeleteTask!(task.id);
            },
          ),
        );
      }
    }

    // 2. Debts
    for (final debt in debts) {
      if (debt.dueDate != null &&
          debt.dueDate!.isAfter(todayStart.subtract(const Duration(seconds: 1))) &&
          debt.dueDate!.isBefore(todayEnd)) {
        final isReceivable = debt.debtType == DebtType.receivable;
        entries.add(
          TodayTimelineEntryModel(
            id: debt.id,
            title: isReceivable ? 'تحصيل دين من ${debt.personId}' : 'سداد دين لـ ${debt.personId}',
            type: QuickCaptureType.debt,
            scheduledTime: debt.dueDate,
            amount: debt.totalAmount.toDecimalString(),
            currency: debt.totalAmount.currency,
          ),
        );
      }
    }

    // Sort: entries with time first chronologically, then entries without time
    entries.sort((a, b) {
      if (a.scheduledTime != null && b.scheduledTime != null) {
        return a.scheduledTime!.compareTo(b.scheduledTime!);
      }
      if (a.scheduledTime != null) return -1;
      if (b.scheduledTime != null) return 1;
      return 0;
    });

    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final entries = _buildEntries();

    if (entries.isEmpty) {
      return MouinEmptyState(
        icon: Icons.wb_sunny_outlined,
        title: 'يومك هادئ ومكتمل!',
        subtitle: 'لا توجد التزامات مجدولة لليوم.',
        actionLabel: 'أضف شيئاً',
        onAction: onAddPressed,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MouinSectionHeader(
          title: 'جدول اليوم',
          count: entries.length,
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: entries.length,
          itemBuilder: (ctx, index) {
            return TodayTimelineEntryWidget(entry: entries[index]);
          },
        ),
      ],
    );
  }
}
