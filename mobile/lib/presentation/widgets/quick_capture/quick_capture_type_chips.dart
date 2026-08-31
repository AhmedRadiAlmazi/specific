// Quick Capture Type Selection Chips — مشروع «مُعين» (Mouin)
import 'package:flutter/material.dart';
import '../../theme/tokens/mouin_dimens.dart';
import '../../theme/tokens/mouin_spacing.dart';
import 'quick_capture_types.dart';

class QuickCaptureTypeChips extends StatelessWidget {
  final QuickCaptureType selectedType;
  final ValueChanged<QuickCaptureType> onTypeChanged;

  const QuickCaptureTypeChips({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: QuickCaptureType.values.map((type) {
          final isSelected = type == selectedType;
          return Padding(
            padding: const EdgeInsets.only(left: MouinSpacing.sm),
            child: Semantics(
              label: 'اختيار نوع ${type.label}',
              selected: isSelected,
              button: true,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: MouinDimens.minTouchTarget),
                child: ChoiceChip(
                  avatar: Icon(
                    type.icon,
                    size: 18,
                    color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.primary,
                  ),
                  label: Text(type.label),
                  selected: isSelected,
                  selectedColor: theme.colorScheme.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (selected) {
                    if (selected) onTypeChanged(type);
                  },
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
