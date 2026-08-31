// Design Tokens: Colors & Semantic Palette — مشروع «مُعين» (Mouin)
import 'package:flutter/material.dart';

abstract class MouinColors {
  // Brand Palette: Deep Teal / Emerald & Warm Accents
  static const Color primary = Color(0xFF006A60);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF70F7E5);
  static const Color onPrimaryContainer = Color(0xFF00201C);

  static const Color secondary = Color(0xFF4A635F);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFCCE8E3);
  static const Color onSecondaryContainer = Color(0xFF05201C);

  static const Color tertiary = Color(0xFF456179);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFFCDE5FF);
  static const Color onTertiaryContainer = Color(0xFF001D32);

  // Surfaces & Backgrounds
  static const Color surfaceLight = Color(0xFFFBFDFA);
  static const Color onSurfaceLight = Color(0xFF191C1B);
  static const Color surfaceVariantLight = Color(0xFFDAE5E1);
  static const Color onSurfaceVariantLight = Color(0xFF3F4947);
  static const Color backgroundLight = Color(0xFFFBFDFA);

  static const Color surfaceDark = Color(0xFF191C1B);
  static const Color onSurfaceDark = Color(0xFFE0E3E1);
  static const Color surfaceVariantDark = Color(0xFF3F4947);
  static const Color onSurfaceVariantDark = Color(0xFFBEC9C5);
  static const Color backgroundDark = Color(0xFF111413);

  // Semantics
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF410002);

  static const Color success = Color(0xFF2E7D32);
  static const Color successContainer = Color(0xFFE8F5E9);
  static const Color warning = Color(0xFFED6C02);
  static const Color warningContainer = Color(0xFFFFF3E0);
  static const Color info = Color(0xFF0288D1);
  static const Color infoContainer = Color(0xFFE1F5FE);

  // Domain Presentation Semantics (Debts & Priorities)
  static const Color debtReceivable = Color(0xFF1B5E20); // «لي عنده»
  static const Color debtReceivableBg = Color(0xFFE8F5E9);
  static const Color debtPayable = Color(0xFFB71C1C);    // «عليّ له»
  static const Color debtPayableBg = Color(0xFFFFEBEE);

  static const Color priorityUrgent = Color(0xFFC62828);
  static const Color priorityUrgentBg = Color(0xFFFFEBEE);
  static const Color priorityHigh = Color(0xFFE65100);
  static const Color priorityHighBg = Color(0xFFFFF3E0);
  static const Color priorityMedium = Color(0xFF00695C);
  static const Color priorityMediumBg = Color(0xFFE0F2F1);
  static const Color priorityLow = Color(0xFF546E7A);
  static const Color priorityLowBg = Color(0xFFECEFF1);
}
