// Quick Capture Smart Confirmation Card — مشروع «مُعين» (Mouin)
import 'package:flutter/material.dart';
import '../../theme/tokens/mouin_spacing.dart';
import '../common/mouin_card.dart';
import '../common/mouin_button.dart';
import 'quick_capture_types.dart';

class QuickCaptureConfirmation extends StatelessWidget {
  final String title;
  final QuickCaptureType type;
  final String? subtitle;
  final VoidCallback onEdit;
  final VoidCallback onSave;

  const QuickCaptureConfirmation({
    super.key,
    required this.title,
    required this.type,
    this.subtitle,
    required this.onEdit,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MouinCard(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: MouinSpacing.xs),
              Text(
                'تأكيد ما فهمه مُعين:',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: MouinSpacing.sm),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: MouinSpacing.xs),
            Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: MouinSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              MouinButton(
                label: 'تعديل',
                type: MouinButtonType.text,
                onPressed: onEdit,
              ),
              const SizedBox(width: MouinSpacing.sm),
              MouinButton(
                label: 'حفظ وتأكيد',
                type: MouinButtonType.primary,
                onPressed: onSave,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
