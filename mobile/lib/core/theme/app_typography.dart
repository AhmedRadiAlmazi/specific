// Design System Typography — مشروع «مُعين» (Mouin)
import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  // Headings
  static const TextStyle displayLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    height: 1.3,
  );

  static const TextStyle headingLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    height: 1.35,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    height: 1.4,
  );

  static const TextStyle headingSmall = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  // Body & Titles
  static const TextStyle titleMedium = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  // Buttons & Labels
  static const TextStyle buttonText = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
  );

  static const TextStyle badgeText = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 11,
    color: AppColors.textMutedLight,
    height: 1.3,
  );
}
