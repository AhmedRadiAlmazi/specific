// Upcoming 48 Hours Section — مشروع «مُعين» (Mouin)
import 'package:flutter/material.dart';
import 'package:mouin/domain/entities/item.dart';
import 'package:mouin/domain/value_objects/types.dart';
import '../../theme/tokens/mouin_spacing.dart';
import '../common/mouin_card.dart';
import '../common/mouin_section_header.dart';
import '../domain/domain_badges.dart';

class Upcoming48hSection extends StatelessWidget {
  final List<Item> tasks;

  const Upcoming48hSection({
    super.key,
    required this.tasks,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayEnd = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    final windowEnd = todayEnd.add(const Duration(days: 2));

    final upcoming = tasks.where((t) {
      if (t.taskDetail == null || t.taskDetail!.status == TaskStatus.completed) {
        return false;
      }
      final dueDate = t.taskDetail!.dueDate;
      if (dueDate == null) return false;
      return dueDate.isAfter(todayEnd) && dueDate.isBefore(windowEnd);
    }).toList();

    if (upcoming.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MouinSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MouinSectionHeader(
            title: 'القادم خلال 48 ساعة',
            count: upcoming.length,
          ),
          ...upcoming.map((item) {
            final dueDate = item.taskDetail!.dueDate!;
            final isTomorrow = dueDate.day == now.add(const Duration(days: 1)).day;
            final dayLabel = isTomorrow ? 'غداً' : 'بعد غد';

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: MouinSpacing.md, vertical: 3),
              child: MouinCard(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        dayLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (item.taskDetail?.priority != null)
                      PriorityBadge(priority: item.taskDetail!.priority),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
