import 'package:flutter/material.dart';

/// Editorial Warm tokens. All screens read from here — no raw hex in features.
@immutable
class EmberTokens extends ThemeExtension<EmberTokens> {
  const EmberTokens({
    required this.bg,
    required this.surface,
    required this.surfaceMuted,
    required this.text,
    required this.textSecondary,
    required this.textFaint,
    required this.primary,
    required this.primaryPressed,
    required this.onPrimary,
    required this.flame,
    required this.success,
    required this.skipped,
    required this.danger,
    required this.hairline,
    required this.habitColors,
    required this.radiusSm,
    required this.radiusMd,
    required this.radiusLg,
    required this.radiusPill,
    required this.screenPadding,
    required this.spaceXxs,
    required this.spaceXs,
    required this.spaceSm,
    required this.spaceMd,
    required this.spaceLg,
    required this.spaceXl,
    required this.spaceXxl,
    required this.spaceHuge,
    required this.checkSize,
  });

  final Color bg;
  final Color surface;
  final Color surfaceMuted;
  final Color text;
  final Color textSecondary;
  final Color textFaint;
  final Color primary;
  final Color primaryPressed;
  final Color onPrimary;
  final Color flame;
  final Color success;
  final Color skipped;
  final Color danger;
  final Color hairline;
  final Map<String, Color> habitColors;
  final double radiusSm;
  final double radiusMd;
  final double radiusLg;
  final double radiusPill;
  final double screenPadding;
  final double spaceXxs;
  final double spaceXs;
  final double spaceSm;
  final double spaceMd;
  final double spaceLg;
  final double spaceXl;
  final double spaceXxl;
  final double spaceHuge;
  final double checkSize;

  // Compatibility aliases used by existing widgets
  Color get border => hairline;
  double get radiusCard => radiusMd;
  double get radiusInput => radiusSm;
  double get radiusChip => radiusPill;
  double get space4 => spaceXs;
  double get space8 => spaceSm;
  double get space12 => spaceMd;
  double get space16 => spaceLg;
  double get space24 => spaceXl;
  double get space32 => spaceXxl;
  List<BoxShadow> get cardShadow => const [];

  static const light = EmberTokens(
    bg: Color(0xFFF6F1E9),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFEFE8DC),
    text: Color(0xFF1C1917),
    textSecondary: Color(0xFF6B645C),
    textFaint: Color(0xFF9A9289),
    primary: Color(0xFFC4553A),
    primaryPressed: Color(0xFFA3442F),
    onPrimary: Color(0xFFFFFFFF),
    flame: Color(0xFFB45309),
    success: Color(0xFF2F7D5B),
    skipped: Color(0xFF6B645C),
    danger: Color(0xFFB3382C),
    hairline: Color(0x1A1C1917),
    habitColors: {
      'habit1': Color(0xFF2F5D50),
      'habit2': Color(0xFFC4553A),
      'habit3': Color(0xFFB45309),
      'habit4': Color(0xFF5B4B8A),
      'habit5': Color(0xFF3D5A80),
      'habit6': Color(0xFF9B4D6C),
      'habit7': Color(0xFF3F6F5A),
      'habit8': Color(0xFF8B3A3A),
    },
    radiusSm: 8,
    radiusMd: 14,
    radiusLg: 22,
    radiusPill: 999,
    screenPadding: 20,
    spaceXxs: 2,
    spaceXs: 4,
    spaceSm: 8,
    spaceMd: 12,
    spaceLg: 16,
    spaceXl: 24,
    spaceXxl: 32,
    spaceHuge: 48,
    checkSize: 52,
  );

  static const dark = EmberTokens(
    bg: Color(0xFF14110F),
    surface: Color(0xFF1D1916),
    surfaceMuted: Color(0xFF26211D),
    text: Color(0xFFF3EEE7),
    textSecondary: Color(0xFFA59D93),
    textFaint: Color(0xFF756E66),
    primary: Color(0xFFE27A5E),
    primaryPressed: Color(0xFFF09A80),
    onPrimary: Color(0xFF1A0F0B),
    flame: Color(0xFFFBBF24),
    success: Color(0xFF5FC49A),
    skipped: Color(0xFFA59D93),
    danger: Color(0xFFF0867B),
    hairline: Color(0x1FF3EEE7),
    habitColors: {
      'habit1': Color(0xFF7BA896),
      'habit2': Color(0xFFE27A5E),
      'habit3': Color(0xFFFBBF24),
      'habit4': Color(0xFFB4A5D6),
      'habit5': Color(0xFF8FA8C4),
      'habit6': Color(0xFFD4A0B4),
      'habit7': Color(0xFF8FBF9F),
      'habit8': Color(0xFFE08A8A),
    },
    radiusSm: 8,
    radiusMd: 14,
    radiusLg: 22,
    radiusPill: 999,
    screenPadding: 20,
    spaceXxs: 2,
    spaceXs: 4,
    spaceSm: 8,
    spaceMd: 12,
    spaceLg: 16,
    spaceXl: 24,
    spaceXxl: 32,
    spaceHuge: 48,
    checkSize: 52,
  );

  Color habitColor(String key) =>
      habitColors[key] ?? habitColors['habit1']!;

  /// Soft leading disc — not a pastel content card.
  Color habitTint(String key) => habitColor(key).withValues(alpha: 0.12);

  @override
  EmberTokens copyWith({
    Color? bg,
    Color? surface,
    Color? surfaceMuted,
    Color? text,
    Color? textSecondary,
    Color? textFaint,
    Color? primary,
    Color? primaryPressed,
    Color? onPrimary,
    Color? flame,
    Color? success,
    Color? skipped,
    Color? danger,
    Color? hairline,
    Map<String, Color>? habitColors,
    double? radiusSm,
    double? radiusMd,
    double? radiusLg,
    double? radiusPill,
    double? screenPadding,
    double? spaceXxs,
    double? spaceXs,
    double? spaceSm,
    double? spaceMd,
    double? spaceLg,
    double? spaceXl,
    double? spaceXxl,
    double? spaceHuge,
    double? checkSize,
  }) {
    return EmberTokens(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      text: text ?? this.text,
      textSecondary: textSecondary ?? this.textSecondary,
      textFaint: textFaint ?? this.textFaint,
      primary: primary ?? this.primary,
      primaryPressed: primaryPressed ?? this.primaryPressed,
      onPrimary: onPrimary ?? this.onPrimary,
      flame: flame ?? this.flame,
      success: success ?? this.success,
      skipped: skipped ?? this.skipped,
      danger: danger ?? this.danger,
      hairline: hairline ?? this.hairline,
      habitColors: habitColors ?? this.habitColors,
      radiusSm: radiusSm ?? this.radiusSm,
      radiusMd: radiusMd ?? this.radiusMd,
      radiusLg: radiusLg ?? this.radiusLg,
      radiusPill: radiusPill ?? this.radiusPill,
      screenPadding: screenPadding ?? this.screenPadding,
      spaceXxs: spaceXxs ?? this.spaceXxs,
      spaceXs: spaceXs ?? this.spaceXs,
      spaceSm: spaceSm ?? this.spaceSm,
      spaceMd: spaceMd ?? this.spaceMd,
      spaceLg: spaceLg ?? this.spaceLg,
      spaceXl: spaceXl ?? this.spaceXl,
      spaceXxl: spaceXxl ?? this.spaceXxl,
      spaceHuge: spaceHuge ?? this.spaceHuge,
      checkSize: checkSize ?? this.checkSize,
    );
  }

  @override
  EmberTokens lerp(ThemeExtension<EmberTokens>? other, double t) {
    if (other is! EmberTokens) return this;
    return t < 0.5 ? this : other;
  }
}

extension EmberTokensX on BuildContext {
  EmberTokens get tokens => Theme.of(this).extension<EmberTokens>()!;
}
