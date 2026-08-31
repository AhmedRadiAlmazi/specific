// Standardized Accessible Buttons — مشروع «مُعين» (Mouin)
import 'package:flutter/material.dart';

enum MouinButtonType { primary, secondary, text }

class MouinButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final MouinButtonType type;
  final Widget? icon;
  final bool isLoading;

  const MouinButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.type = MouinButtonType.primary,
    this.icon,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : (icon != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  icon!,
                  const SizedBox(width: 8),
                  Text(label),
                ],
              )
            : Text(label));

    switch (type) {
      case MouinButtonType.primary:
        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          child: child,
        );
      case MouinButtonType.secondary:
        return OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          child: child,
        );
      case MouinButtonType.text:
        return TextButton(
          onPressed: isLoading ? null : onPressed,
          child: child,
        );
    }
  }
}
