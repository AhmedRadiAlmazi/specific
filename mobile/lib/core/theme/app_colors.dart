// Design System Color Palette — مشروع «مُعين» (Mouin)
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Brand Colors (Emerald & Teal)
  static const Color primary = Color(0xFF0D9488); // Teal 600
  static const Color primaryDark = Color(0xFF064E3B); // Deep Pine 900
  static const Color primaryLight = Color(0xFF14B8A6); // Teal 500
  static const Color primarySubtle = Color(0xFFCCFBF1); // Teal 100
  static const Color primaryContainer = Color(0xFFE6FFFA);

  // Financial & Accent Colors (Mint & Gold)
  static const Color financeMint = Color(0xFF10B981); // Emerald 500
  static const Color financeMintLight = Color(0xFFD1FAE5); // Emerald 100
  static const Color goldAccent = Color(0xFFF59E0B); // Amber 500
  static const Color goldAccentLight = Color(0xFFFEF3C7); // Amber 100
  static const Color goldDark = Color(0xFFD97706);

  // Semantic & Status Colors
  static const Color urgent = Color(0xFFEF4444); // Red 500
  static const Color urgentLight = Color(0xFFFEE2E2);
  static const Color warning = Color(0xFFF97316); // Orange 500
  static const Color warningLight = Color(0xFFFFEDD5);
  static const Color audioSky = Color(0xFF0284C7); // Sky 600
  static const Color audioSkyLight = Color(0xFFE0F2FE);
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);

  // Neutral Colors (Light Theme)
  static const Color backgroundLight = Color(0xFFF8FAFC); // Slate 50
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE2E8F0); // Slate 200
  static const Color textPrimaryLight = Color(0xFF0F172A); // Slate 900
  static const Color textSecondaryLight = Color(0xFF64748B); // Slate 500
  static const Color textMutedLight = Color(0xFF94A3B8); // Slate 400

  // Neutral Colors (Dark Theme)
  static const Color backgroundDark = Color(0xFF0B131F);
  static const Color surfaceDark = Color(0xFF131F2E);
  static const Color cardDark = Color(0xFF1A293D);
  static const Color borderDark = Color(0xFF2B3A4F);
  static const Color textPrimaryDark = Color(0xFFF1F5F9);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textMutedDark = Color(0xFF64748B);

  // Gradients
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [
      Color(0xFF064E3B), // Deep Pine
      Color(0xFF0D9488), // Emerald Teal
    ],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0D9488),
      Color(0xFF14B8A6),
      Color(0xFF10B981),
    ],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF59E0B),
      Color(0xFFD97706),
    ],
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1A293D),
      Color(0xFF131F2E),
    ],
  );
}
