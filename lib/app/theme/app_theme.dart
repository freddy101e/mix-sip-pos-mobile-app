import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppTheme {
  static const _brand = AppColors.rose;

  static ThemeData get light => _build(
    ColorScheme.fromSeed(
      seedColor: _brand,
      brightness: Brightness.light,
      surface: AppColors.paper,
    ).copyWith(
      primary: AppColors.rose,
      onPrimary: Colors.white,
      primaryContainer: AppColors.blush,
      onPrimaryContainer: AppColors.plum,
      secondary: AppColors.magenta,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.lilac,
      onSecondaryContainer: AppColors.plum,
      tertiary: AppColors.coral,
      tertiaryContainer: AppColors.peach,
      surface: AppColors.paper,
      onSurface: AppColors.ink,
      onSurfaceVariant: AppColors.mauveGray,
      outline: AppColors.roseOutline,
      outlineVariant: AppColors.blushBorder,
      error: AppColors.danger,
    ),
  );

  static ThemeData get dark => _build(
    ColorScheme.fromSeed(
      seedColor: _brand,
      brightness: Brightness.dark,
      surface: AppColors.ink,
    ),
  );

  static ThemeData _build(ColorScheme colors) {
    final textTheme = GoogleFonts.dmSansTextTheme().apply(
      bodyColor: colors.onSurface,
      displayColor: colors.onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: colors.brightness,
      colorScheme: colors,
      scaffoldBackgroundColor:
          colors.brightness == Brightness.light
              ? AppColors.canvas
              : AppColors.ink,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: colors.onSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: colors.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color:
            colors.brightness == Brightness.light
                ? AppColors.paper
                : AppColors.darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: colors.outlineVariant.withValues(alpha: .55)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor:
            colors.brightness == Brightness.light
                ? AppColors.paper
                : AppColors.darkCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          backgroundColor: colors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        side: BorderSide(color: colors.outlineVariant),
        selectedColor: colors.primaryContainer,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.secondary,
        foregroundColor: colors.onSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor:
            colors.brightness == Brightness.light
                ? AppColors.paper
                : AppColors.darkCard,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor:
            colors.brightness == Brightness.light
                ? AppColors.paper
                : AppColors.darkCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: colors.primary),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? colors.onPrimary : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? colors.primary : null,
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      dividerTheme: DividerThemeData(color: colors.outlineVariant),
    );
  }
}

abstract final class AppColors {
  static const rose = Color(0xFFE83E8C);
  static const magenta = Color(0xFFD7297F);
  static const plum = Color(0xFF64264B);
  static const coral = Color(0xFFF06B83);
  static const blush = Color(0xFFFFE5F0);
  static const lilac = Color(0xFFF2E7FA);
  static const peach = Color(0xFFFFE9DF);
  static const roseOutline = Color(0xFFD7A6BB);
  static const blushBorder = Color(0xFFF0D2DF);
  static const mauveGray = Color(0xFF735C68);
  static const cream = Color(0xFFFFF8FB);
  static const canvas = Color(0xFFFFF6FA);
  static const paper = Color(0xFFFFFCFD);
  static const coffee = rose;
  static const coffeeDark = plum;
  static const sage = Color(0xFF8D4C75);
  static const mint = blush;
  static const amber = Color(0xFFFF8BB4);
  static const ink = Color(0xFF281B23);
  static const darkCard = Color(0xFF24211D);
  static const danger = Color(0xFFC63D62);
}
