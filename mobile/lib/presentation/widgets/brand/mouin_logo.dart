// Mouin App Brand Logo Widget — مشروع «مُعين» (Mouin)
import 'package:flutter/material.dart';
import 'package:mouin/core/theme/app_colors.dart';

enum MouinLogoSize {
  small(36, 16, 10),
  medium(56, 20, 12),
  large(84, 24, 13),
  hero(110, 28, 14);

  final double iconSize;
  final double titleSize;
  final double subtitleSize;

  const MouinLogoSize(this.iconSize, this.titleSize, this.subtitleSize);
}

class MouinLogo extends StatelessWidget {
  final MouinLogoSize size;
  final bool showText;
  final bool showSubtitle;
  final bool isLightMode;
  final String? customSubtitle;

  const MouinLogo({
    super.key,
    this.size = MouinLogoSize.medium,
    this.showText = true,
    this.showSubtitle = true,
    this.isLightMode = true,
    this.customSubtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Branded Icon / Logo Mark
        Container(
          width: size.iconSize,
          height: size.iconSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.brandGradient,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.35),
                blurRadius: size.iconSize * 0.25,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/mouin_logo.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // High-grade fallback painted vector emblem
                return Center(
                  child: Icon(
                    Icons.check_circle_outline_rounded,
                    size: size.iconSize * 0.55,
                    color: Colors.white,
                  ),
                );
              },
            ),
          ),
        ),

        if (showText) ...[
          SizedBox(height: size.iconSize * 0.18),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'مُعين',
                style: TextStyle(
                  fontSize: size.titleSize,
                  fontWeight: FontWeight.w900,
                  color: isLightMode ? AppColors.textPrimaryLight : Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.goldAccent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          if (showSubtitle) ...[
            const SizedBox(height: 3),
            Text(
              customSubtitle ?? 'مساعدك الشخصي لإدارة المهام والديون',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: size.subtitleSize,
                fontWeight: FontWeight.w500,
                color: isLightMode ? AppColors.textSecondaryLight : AppColors.textSecondaryDark,
              ),
            ),
          ],
        ],
      ],
    );
  }
}
