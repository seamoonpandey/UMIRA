import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../features/preferences/models/preferences_models.dart';
import 'tokens.dart';

class AppTheme {
  static ThemeData light(LocalPrefs prefs) => _build(Brightness.light, prefs);
  static ThemeData dark(LocalPrefs prefs) => _build(Brightness.dark, prefs);

  static ThemeData _build(Brightness brightness, LocalPrefs prefs) {
    final scheme = ColorScheme.fromSeed(seedColor: UmiraColors.seed, brightness: brightness);
    final textTheme = prefs.useDyslexiaFont
        ? GoogleFonts.lexendTextTheme(ThemeData(brightness: brightness).textTheme)
        : GoogleFonts.interTextTheme(ThemeData(brightness: brightness).textTheme);

    final spacingFactor = switch (prefs.spacingMode) {
      'wide' => 1.4,
      'extra-wide' => 1.7,
      _ => 1.2,
    };

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: brightness == Brightness.light ? UmiraColors.surfaceCalm : null,
      textTheme: textTheme.apply(
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
        fontSizeFactor: 1.0,
      ).copyWith(
        bodyLarge: textTheme.bodyLarge?.copyWith(height: spacingFactor),
        bodyMedium: textTheme.bodyMedium?.copyWith(height: spacingFactor),
        bodySmall: textTheme.bodySmall?.copyWith(height: spacingFactor),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(UmiraRadius.md)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(UmiraRadius.md)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(UmiraRadius.md)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(UmiraRadius.lg)),
      ),
      focusColor: scheme.primary.withValues(alpha: 0.2),
    );
  }
}
