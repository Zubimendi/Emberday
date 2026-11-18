import 'package:emberday/ui/tokens.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

TextTheme _buildTextTheme(Brightness brightness, EmberTokens tokens) {
  final display = GoogleFonts.fraunces(
    fontWeight: FontWeight.w600,
    color: tokens.text,
  );
  final body = GoogleFonts.dmSans(color: tokens.text);
  final bodyMedium = GoogleFonts.dmSans(
    fontWeight: FontWeight.w500,
    color: tokens.text,
  );

  return TextTheme(
    displayLarge: display.copyWith(
      fontSize: 44,
      height: 46 / 44,
      letterSpacing: -1.2,
    ),
    displayMedium: display.copyWith(
      fontSize: 28,
      height: 32 / 28,
      letterSpacing: -0.6,
    ),
    titleLarge: bodyMedium.copyWith(fontSize: 17, height: 22 / 17),
    titleMedium: bodyMedium.copyWith(fontSize: 16, height: 22 / 16),
    bodyLarge: body.copyWith(fontSize: 16, height: 24 / 16),
    bodyMedium: body.copyWith(fontSize: 13, height: 18 / 13),
    labelLarge: bodyMedium.copyWith(
      fontSize: 12,
      height: 16 / 12,
      letterSpacing: 0.4,
    ),
    labelSmall: GoogleFonts.jetBrainsMono(
      fontSize: 15,
      height: 20 / 15,
      fontWeight: FontWeight.w500,
      color: tokens.text,
      fontFeatures: const [FontFeature.tabularFigures()],
    ),
  );
}

ThemeData buildLightTheme() {
  const tokens = EmberTokens.light;
  final textTheme = _buildTextTheme(Brightness.light, tokens);
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: tokens.bg,
    colorScheme: ColorScheme.light(
      primary: tokens.primary,
      onPrimary: tokens.onPrimary,
      surface: tokens.surface,
      onSurface: tokens.text,
      error: tokens.danger,
    ),
    extensions: const [tokens],
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: tokens.bg,
      foregroundColor: tokens.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: textTheme.displayMedium,
    ),
    dividerColor: tokens.hairline,
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: tokens.surface,
      indicatorColor: tokens.primary.withValues(alpha: 0.14),
      labelTextStyle: WidgetStatePropertyAll(textTheme.labelLarge),
      elevation: 0,
      height: 64,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: tokens.text,
      contentTextStyle: textTheme.bodyLarge?.copyWith(color: tokens.surface),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: tokens.primary,
        foregroundColor: tokens.onPrimary,
        minimumSize: const Size(48, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.radiusMd),
        ),
        textStyle: textTheme.titleMedium,
      ),
    ),
  );
}

ThemeData buildDarkTheme() {
  const tokens = EmberTokens.dark;
  final textTheme = _buildTextTheme(Brightness.dark, tokens);
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: tokens.bg,
    colorScheme: ColorScheme.dark(
      primary: tokens.primary,
      onPrimary: tokens.onPrimary,
      surface: tokens.surface,
      onSurface: tokens.text,
      error: tokens.danger,
    ),
    extensions: const [tokens],
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: tokens.bg,
      foregroundColor: tokens.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: textTheme.displayMedium,
    ),
    dividerColor: tokens.hairline,
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: tokens.surface,
      indicatorColor: tokens.primary.withValues(alpha: 0.2),
      labelTextStyle: WidgetStatePropertyAll(textTheme.labelLarge),
      elevation: 0,
      height: 64,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: tokens.surfaceMuted,
      contentTextStyle: textTheme.bodyLarge,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: tokens.primary,
        foregroundColor: tokens.onPrimary,
        minimumSize: const Size(48, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.radiusMd),
        ),
        textStyle: textTheme.titleMedium,
      ),
    ),
  );
}
