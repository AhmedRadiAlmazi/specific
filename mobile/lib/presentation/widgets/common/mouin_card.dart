// Standardized Card Widget — مشروع «مُعين» (Mouin)
import 'package:flutter/material.dart';
import '../../theme/tokens/mouin_radii.dart';
import '../../theme/tokens/mouin_spacing.dart';

class MouinCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final BorderSide? borderSide;

  const MouinCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.color,
    this.borderSide,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: MouinRadii.borderMd,
        side: borderSide ?? BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: MouinRadii.borderMd,
        child: Padding(
          padding: padding ?? MouinSpacing.paddingMd,
          child: child,
        ),
      ),
    );
  }
}
