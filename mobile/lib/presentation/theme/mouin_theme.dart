// Unified Theme System (RTL First & Material 3) — مشروع «مُعين» (Mouin)
import 'package:flutter/material.dart';
import 'tokens/mouin_colors.dart';
import 'tokens/mouin_radii.dart';
import 'tokens/mouin_spacing.dart';
import 'tokens/mouin_dimens.dart';

abstract class MouinTheme {
  static ThemeData get light {
    final colorScheme = ColorScheme.light(
      primary: MouinColors.primary,
      onPrimary: MouinColors.onPrimary,
      primaryContainer: MouinColors.primaryContainer,
      onPrimaryContainer: MouinColors.onPrimaryContainer,
      secondary: MouinColors.secondary,
      onSecondary: MouinColors.onSecondary,
      secondaryContainer: MouinColors.secondaryContainer,
      onSecondaryContainer: MouinColors.onSecondaryContainer,
      tertiary: MouinColors.tertiary,
      onTertiary: MouinColors.onTertiary,
      surface: MouinColors.surfaceLight,
      onSurface: MouinColors.onSurfaceLight,
      error: MouinColors.error,
      onError: MouinColors.onError,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: MouinColors.backgroundLight,
      fontFamily: 'Tajawal',
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: MouinColors.primary,
        foregroundColor: MouinColors.onPrimary,
      ),
      cardTheme: CardTheme(
        elevation: MouinDimens.elevationLow,
        shape: const RoundedRectangleBorder(borderRadius: MouinRadii.borderMd),
        margin: const EdgeInsets.symmetric(vertical: MouinSpacing.xs, horizontal: MouinSpacing.none),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(MouinDimens.minTouchTarget, MouinDimens.minTouchTarget),
          shape: const RoundedRectangleBorder(borderRadius: MouinRadii.borderMd),
          padding: const EdgeInsets.symmetric(horizontal: MouinSpacing.lg, vertical: MouinSpacing.sm),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(MouinDimens.minTouchTarget, MouinDimens.minTouchTarget),
          shape: const RoundedRectangleBorder(borderRadius: MouinRadii.borderMd),
          padding: const EdgeInsets.symmetric(horizontal: MouinSpacing.lg, vertical: MouinSpacing.sm),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(MouinDimens.minTouchTarget, MouinDimens.minTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: MouinSpacing.md, vertical: MouinSpacing.sm),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: MouinColors.surfaceLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: MouinSpacing.md, vertical: MouinSpacing.md),
        border: const OutlineInputBorder(
          borderRadius: MouinRadii.borderMd,
          borderSide: BorderSide(color: MouinColors.surfaceVariantLight),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: MouinRadii.borderMd,
          borderSide: BorderSide(color: MouinColors.surfaceVariantLight),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: MouinRadii.borderMd,
          borderSide: BorderSide(color: MouinColors.primary, width: 2),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: const RoundedRectangleBorder(borderRadius: MouinRadii.borderPill),
        padding: const EdgeInsets.symmetric(horizontal: MouinSpacing.sm, vertical: MouinSpacing.xs),
      ),
    );
  }

  static ThemeData get dark {
    final colorScheme = ColorScheme.dark(
      primary: MouinColors.primaryContainer,
      onPrimary: MouinColors.onPrimaryContainer,
      primaryContainer: MouinColors.primary,
      onPrimaryContainer: MouinColors.primaryContainer,
      secondary: MouinColors.secondaryContainer,
      onSecondary: MouinColors.onSecondaryContainer,
      surface: MouinColors.surfaceDark,
      onSurface: MouinColors.onSurfaceDark,
      error: MouinColors.error,
      onError: MouinColors.onError,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: MouinColors.backgroundDark,
      fontFamily: 'Tajawal',
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: MouinColors.surfaceDark,
        foregroundColor: MouinColors.onSurfaceDark,
      ),
      cardTheme: CardTheme(
        elevation: MouinDimens.elevationLow,
        color: MouinColors.surfaceDark,
        shape: const RoundedRectangleBorder(borderRadius: MouinRadii.borderMd),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(MouinDimens.minTouchTarget, MouinDimens.minTouchTarget),
          shape: const RoundedRectangleBorder(borderRadius: MouinRadii.borderMd),
          padding: const EdgeInsets.symmetric(horizontal: MouinSpacing.lg, vertical: MouinSpacing.sm),
        ),
      ),
    );
  }
}
