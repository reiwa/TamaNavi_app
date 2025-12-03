import 'package:flutter/material.dart';

class AppPalette {
  const AppPalette._();
  static const Color primary = Color(0xFF12A06A);
  static const Color secondary = Color(0xFFFF7A2F);
  static const Color neutral = Color(0xFF1F2A37);
  static const Color muted = Color(0xFF596357);
  static const Color surface = Color(0xFFF8FBF4);
  static const Color surfaceContainer = Color(0xFFFEFFFD);
  static const Color outline = Color(0xFFE0EAD9);
}

ThemeData buildAppTheme() {
  final baseTheme = ThemeData.light();
  final baseTextTheme = baseTheme.textTheme.apply(
    fontFamily: 'RoundedMgenPlus',
    bodyColor: AppPalette.neutral,
    displayColor: AppPalette.neutral,
  );

  final colorScheme =
      ColorScheme.fromSeed(
        seedColor: AppPalette.primary,
        primary: AppPalette.primary,
        secondary: AppPalette.secondary,
      ).copyWith(
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        surface: AppPalette.surface,
        onSurface: AppPalette.neutral,
        outline: AppPalette.outline,
        outlineVariant: AppPalette.outline,
        surfaceContainerHighest: AppPalette.surfaceContainer,
        tertiary: AppPalette.primary.withValues(alpha: 0.6),
        surfaceTint: Colors.transparent,
      );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colorScheme.surface,
    fontFamily: 'RoundedMgenPlus',
    shadowColor: Colors.transparent,
    visualDensity: VisualDensity.standard,
    textTheme: baseTextTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: baseTextTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppPalette.neutral,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        textStyle: baseTextTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colorScheme.primary,
        textStyle: baseTextTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppPalette.surfaceContainer,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titleTextStyle: baseTextTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      contentTextStyle: baseTextTheme.bodyMedium,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: colorScheme.surfaceContainerHighest,
      selectedColor: colorScheme.primary,
      secondarySelectedColor: colorScheme.primary,
      disabledColor: colorScheme.surface,
      labelStyle: baseTextTheme.labelLarge,
      secondaryLabelStyle: baseTextTheme.labelLarge?.copyWith(
        color: colorScheme.onPrimary,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppPalette.surfaceContainer,
      hintStyle: baseTextTheme.bodyMedium?.copyWith(
        color: AppPalette.muted,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppPalette.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppPalette.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.6),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppPalette.neutral,
      contentTextStyle: baseTextTheme.bodyMedium?.copyWith(
        color: Colors.white,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      behavior: SnackBarBehavior.floating,
    ),
    cardTheme: CardThemeData(
      color: AppPalette.surfaceContainer,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      elevation: 0,
      margin: EdgeInsets.zero,
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: AppPalette.surfaceContainer,
        foregroundColor: AppPalette.neutral,
        elevation: 0,
      ),
    ),
  );
}
