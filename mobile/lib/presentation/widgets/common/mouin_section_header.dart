// Section Header Widget — مشروع «مُعين» (Mouin)
import 'package:flutter/material.dart';
import '../../theme/tokens/mouin_spacing.dart';

class MouinSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final int? count;
  final Widget? trailing;

  const MouinSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.count,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: MouinSpacing.md, vertical: MouinSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (count != null) ...[
                const SizedBox(width: MouinSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: MouinSpacing.xs, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
