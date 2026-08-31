// Today Urgent / Overdue Section — مشروع «مُعين» (Mouin)
import 'package:flutter/material.dart';
import 'package:mouin/domain/entities/item.dart';
import 'package:mouin/domain/value_objects/types.dart';
import '../../theme/tokens/mouin_colors.dart';
import '../../theme/tokens/mouin_spacing.dart';
import '../common/mouin_card.dart';

class TodayUrgentSection extends StatelessWidget {
  final List<Item> tasks;
  final Function(String itemId)? onCompleteTask;
  final VoidCallback? onViewAll;

  const TodayUrgentSection({
    super.key,
    required this.tasks,
    this.onCompleteTask,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final urgentOrOverdue = tasks.where((t) {
      if (t.taskDetail == null || t.taskDetail!.status == TaskStatus.completed) {
        return false;
      }
      final isOverdue = t.taskDetail!.dueDate != null && t.taskDetail!.dueDate!.isBefore(now);
      final isUrgent = t.taskDetail!.priority == Priority.urgent;
      return isOverdue || isUrgent;
    }).toList();

    if (urgentOrOverdue.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: MouinSpacing.md, vertical: MouinSpacing.xs),
      child: MouinCard(
        color: MouinColors.priorityUrgentBg,
        borderSide: const BorderSide(color: MouinColors.priorityUrgent, width: 1),
        padding: MouinSpacing.paddingMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: MouinColors.priorityUrgent, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      'العواجل (${urgentOrOverdue.length})',
                      style: const TextStyle(
                        color: MouinColors.priorityUrgent,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                if (onViewAll != null)
                  GestureDetector(
                    onTap: onViewAll,
                    child: const Text(
                      'عرض الكل',
                      style: TextStyle(color: MouinColors.priorityUrgent, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: MouinSpacing.xs),
            ...urgentOrOverdue.take(2).map((item) {
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    const Text('• ', style: TextStyle(color: MouinColors.priorityUrgent, fontWeight: FontWeight.bold)),
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (onCompleteTask != null)
                      GestureDetector(
                        onTap: () => onCompleteTask!(item.id),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: MouinColors.priorityUrgent),
                          ),
                          child: const Text(
                            'إنجاز',
                            style: TextStyle(fontSize: 11, color: MouinColors.priorityUrgent, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
