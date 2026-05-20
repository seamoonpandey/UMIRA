import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../features/preferences/models/preferences_models.dart';
import 'tokens.dart';

class AppTheme {
  static ThemeData light(LocalPrefs prefs) => _build(Brightness.light, prefs);
  static ThemeData dark(LocalPrefs prefs) => _build(Brightness.dark, prefs);
  static ThemeData warm(LocalPrefs prefs) => _buildWarm(prefs);

  static ThemeData _buildWarm(LocalPrefs prefs) {
    const warmSeed = Color(0xFFFF6F00);
    final scheme = ColorScheme.fromSeed(
      seedColor: warmSeed,
      brightness: Brightness.light,
      primary: const Color(0xFFE65100),
      onPrimary: Colors.white,
      surface: const Color(0xFFFFF8E1),
      onSurface: const Color(0xFF3E2723),
    );
    final textTheme = prefs.useDyslexiaFont
        ? GoogleFonts.lexendTextTheme(
            ThemeData(brightness: Brightness.light).textTheme,
          )
        : GoogleFonts.interTextTheme(
            ThemeData(brightness: Brightness.light).textTheme,
          );

    final spacingFactor = switch (prefs.spacingMode) {
      'wide' => 1.4,
      'extra-wide' => 1.7,
      _ => 1.2,
    };

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFFFFF8E1),
      textTheme: textTheme
          .apply(
            bodyColor: const Color(0xFF3E2723),
            displayColor: const Color(0xFF3E2723),
            fontSizeFactor: 1.0,
          )
          .copyWith(
            bodyLarge: textTheme.bodyLarge?.copyWith(height: spacingFactor),
            bodyMedium: textTheme.bodyMedium?.copyWith(height: spacingFactor),
            bodySmall: textTheme.bodySmall?.copyWith(height: spacingFactor),
          ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(UmiraRadius.md),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(UmiraRadius.md),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UmiraRadius.md),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFFFFECB3).withValues(alpha: 0.6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UmiraRadius.lg),
        ),
      ),
      focusColor: scheme.primary.withValues(alpha: 0.2),
    );
  }

  static ThemeData _build(Brightness brightness, LocalPrefs prefs) {
    final scheme = ColorScheme.fromSeed(
      seedColor: UmiraColors.seed,
      brightness: brightness,
    );
    final textTheme = prefs.useDyslexiaFont
        ? GoogleFonts.lexendTextTheme(
            ThemeData(brightness: brightness).textTheme,
          )
        : GoogleFonts.interTextTheme(
            ThemeData(brightness: brightness).textTheme,
          );

    final spacingFactor = switch (prefs.spacingMode) {
      'wide' => 1.4,
      'extra-wide' => 1.7,
      _ => 1.2,
    };

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor:
          brightness == Brightness.light ? UmiraColors.surfaceCalm : null,
      textTheme: textTheme
          .apply(
            bodyColor: scheme.onSurface,
            displayColor: scheme.onSurface,
            fontSizeFactor: 1.0,
          )
          .copyWith(
            bodyLarge: textTheme.bodyLarge?.copyWith(height: spacingFactor),
            bodyMedium: textTheme.bodyMedium?.copyWith(height: spacingFactor),
            bodySmall: textTheme.bodySmall?.copyWith(height: spacingFactor),
          ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(UmiraRadius.md),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(UmiraRadius.md),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UmiraRadius.md),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UmiraRadius.lg),
        ),
      ),
      focusColor: scheme.primary.withValues(alpha: 0.2),
    );
  }
}
