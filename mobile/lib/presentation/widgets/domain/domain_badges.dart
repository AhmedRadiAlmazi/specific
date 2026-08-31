// Domain Presentation Badges & Formatters (Presentation Only) — مشروع «مُعين» (Mouin)
import 'package:flutter/material.dart';
import 'package:mouin/domain/value_objects/types.dart';
import '../../theme/tokens/mouin_colors.dart';
import '../common/mouin_badge.dart';

class PriorityBadge extends StatelessWidget {
  final Priority priority;
  const PriorityBadge({super.key, required this.priority});

  @override
  Widget build(BuildContext context) {
    switch (priority) {
      case Priority.urgent:
        return const MouinBadge(
          label: 'عاجل جداً',
          textColor: MouinColors.priorityUrgent,
          backgroundColor: MouinColors.priorityUrgentBg,
          icon: Icons.priority_high,
        );
      case Priority.high:
        return const MouinBadge(
          label: 'أولوية عالية',
          textColor: MouinColors.priorityHigh,
          backgroundColor: MouinColors.priorityHighBg,
          icon: Icons.arrow_upward,
        );
      case Priority.medium:
        return const MouinBadge(
          label: 'متوسطة',
          textColor: MouinColors.priorityMedium,
          backgroundColor: MouinColors.priorityMediumBg,
        );
      case Priority.low:
        return const MouinBadge(
          label: 'منخفضة',
          textColor: MouinColors.priorityLow,
          backgroundColor: MouinColors.priorityLowBg,
        );
    }
  }
}

class DirectionalBadge extends StatelessWidget {
  final DebtType debtType;
  const DirectionalBadge({super.key, required this.debtType});

  @override
  Widget build(BuildContext context) {
    if (debtType == DebtType.receivable) {
      return const MouinBadge(
        label: 'لي عنده',
        textColor: MouinColors.debtReceivable,
        backgroundColor: MouinColors.debtReceivableBg,
        icon: Icons.arrow_downward,
      );
    } else {
      return const MouinBadge(
        label: 'عليّ له',
        textColor: MouinColors.debtPayable,
        backgroundColor: MouinColors.debtPayableBg,
        icon: Icons.arrow_upward,
      );
    }
  }
}

class MoneyDisplay extends StatelessWidget {
  final String amount;
  final String currency;
  final TextStyle? style;
  final bool showDirectionColor;
  final bool isPositive;

  const MoneyDisplay({
    super.key,
    required this.amount,
    this.currency = 'YER',
    this.style,
    this.showDirectionColor = false,
    this.isPositive = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = showDirectionColor
        ? (isPositive ? MouinColors.debtReceivable : MouinColors.debtPayable)
        : null;

    return Text(
      '$amount $currency',
      style: (style ?? const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)).copyWith(color: color),
    );
  }
}
