// Standardized Accessible Icon Button — مشروع «مُعين» (Mouin)
import 'package:flutter/material.dart';
import '../../theme/tokens/mouin_dimens.dart';

class MouinIconButton extends StatelessWidget {
  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final Color? color;
  final String? tooltip;

  const MouinIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    this.color,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: MouinDimens.minTouchTarget,
          minHeight: MouinDimens.minTouchTarget,
        ),
        child: IconButton(
          icon: Icon(icon, color: color),
          tooltip: tooltip ?? semanticLabel,
          onPressed: onPressed,
        ),
      ),
    );
  }
}
