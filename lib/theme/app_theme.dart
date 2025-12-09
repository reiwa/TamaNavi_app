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

  static const PaletteSet light = PaletteSet(
    primary: primary,
    secondary: secondary,
    neutral: neutral,
    muted: muted,
    surface: surface,
    surfaceContainer: surfaceContainer,
    outline: outline,
  );

  static const PaletteSet dark = PaletteSet(
    primary: Color(0xFF7BCFB9),
    secondary: Color(0xFFFFA46E),
    neutral: Color(0xFFEAEFF4),
    muted: Color(0xFF9EA7B3),
    surface: Color(0xFF1F2228),
    surfaceContainer: Color(0xFF2C3038),
    outline: Color(0xFF444854),
  );
}

class PaletteSet {
  const PaletteSet({
    required this.primary,
    required this.secondary,
    required this.neutral,
    required this.muted,
    required this.surface,
    required this.surfaceContainer,
    required this.outline,
  });

  final Color primary;
  final Color secondary;
  final Color neutral;
  final Color muted;
  final Color surface;
  final Color surfaceContainer;
  final Color outline;
}

ThemeData buildAppTheme([Brightness brightness = Brightness.light]) {
  final palette = brightness == Brightness.dark ? AppPalette.dark : AppPalette.light;
  final baseTheme =
      brightness == Brightness.dark ? ThemeData.dark() : ThemeData.light();
  final baseTextTheme = baseTheme.textTheme.apply(
    fontFamily: 'RoundedMgenPlus',
    bodyColor: palette.neutral,
    displayColor: palette.neutral,
  );

  final colorScheme =
      ColorScheme.fromSeed(
        seedColor: palette.primary,
        primary: palette.primary,
        secondary: palette.secondary,
        brightness: brightness,
      ).copyWith(
        onPrimary: brightness == Brightness.dark
            ? const Color(0xFF072815)
            : Colors.white,
        onSecondary: brightness == Brightness.dark
            ? const Color(0xFF2C1302)
            : Colors.white,
        surface: palette.surface,
        onSurface: palette.neutral,
        outline: palette.outline,
        outlineVariant: palette.outline,
        surfaceContainerHighest: palette.surfaceContainer,
        tertiary: palette.primary.withValues(alpha: brightness == Brightness.dark ? 0.35 : 0.6),
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
        color: palette.neutral,
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
      backgroundColor: palette.surfaceContainer,
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
      fillColor: palette.surfaceContainer,
      hintStyle: baseTextTheme.bodyMedium?.copyWith(
        color: palette.muted,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: palette.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: palette.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.6),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor:
          brightness == Brightness.dark ? palette.surfaceContainer : palette.neutral,
      contentTextStyle: baseTextTheme.bodyMedium?.copyWith(
        color: brightness == Brightness.dark ? palette.neutral : Colors.white,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      behavior: SnackBarBehavior.floating,
    ),
    cardTheme: CardThemeData(
      color: palette.surfaceContainer,
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
        backgroundColor: palette.surfaceContainer,
        foregroundColor: palette.neutral,
        elevation: 0,
      ),
    ),
  );
}
