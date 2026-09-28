// lib/utils/constants.dart
import 'package:flutter/material.dart';

class AppConstants {
  // App Info
  static const String appTitle = 'Student Quiz App';
  static const String studentPanelTitle = '🎓 Học sinh Panel';

  // Global dark mode flag, updated by ThemeProvider
  static bool isDark = false;

  // Colors (from Material 3 / Web UI) - Static Constants for light mode & const expressions
  static const Color primary = Color(0xFF003D9B);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF0052CC);
  static const Color onPrimaryContainer = Color(0xFFC4D2FF);

  static const Color secondary = Color(0xFF006C47);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFF82F9BE);
  static const Color onSecondaryContainer = Color(0xFF00734C);

  static const Color tertiary = Color(0xFF851800);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFFB02300);
  static const Color onTertiaryContainer = Color(0xFFFFC6B9);

  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);

  static const Color background = Color(0xFFF9F9FF);
  static const Color onBackground = Color(0xFF041B3C);

  static const Color surface = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF041B3C);
  static const Color surfaceVariant = Color(0xFFD7E2FF);
  static const Color onSurfaceVariant = Color(0xFF434654);

  static const Color surfaceContainerLow = Color(0xFFF1F3FF);
  static const Color surfaceContainer = Color(0xFFE8EDFF);
  static const Color surfaceContainerHigh = Color(0xFFE0E8FF);

  static const Color outline = Color(0xFF737685);
  static const Color outlineVariant = Color(0xFFC3C6D6);

  // Dark Theme Palette Constants
  static const Color darkBackground = Color(0xFF121418);
  static const Color darkSurface = Color(0xFF1E2128);
  static const Color darkOnSurface = Color(0xFFF1F3F7);
  static const Color darkOnSurfaceVariant = Color(0xFF9EA3B0);
  static const Color darkSurfaceContainerLow = Color(0xFF181A20);
  static const Color darkSurfaceContainer = Color(0xFF242730);
  static const Color darkSurfaceContainerHigh = Color(0xFF2C303B);
  static const Color darkOutline = Color(0xFF5A606E);
  static const Color darkOutlineVariant = Color(0xFF2F333D);
  static const Color darkPrimary = Color(0xFF6B9BFF);

  // Context-aware Dynamic Color Helpers (Adapts automatically to Dark / Light Mode)
  static bool isDarkMode(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color bg(BuildContext context) =>
      isDarkMode(context) ? darkBackground : background;

  static Color surf(BuildContext context) =>
      isDarkMode(context) ? darkSurface : surface;

  static Color txt(BuildContext context) =>
      isDarkMode(context) ? darkOnSurface : onSurface;

  static Color txtMuted(BuildContext context) =>
      isDarkMode(context) ? darkOnSurfaceVariant : onSurfaceVariant;

  static Color surfLow(BuildContext context) =>
      isDarkMode(context) ? darkSurfaceContainerLow : surfaceContainerLow;

  static Color surfHigh(BuildContext context) =>
      isDarkMode(context) ? darkSurfaceContainerHigh : surfaceContainerHigh;

  static Color border(BuildContext context) =>
      isDarkMode(context) ? darkOutlineVariant : outlineVariant;

  static Color brand(BuildContext context) =>
      isDarkMode(context) ? darkPrimary : primary;

  // Legacy aliases
  static const Color primaryColor = primary;
  static const Color surfaceColor = surface;
  static const Color onSurfaceColor = onSurface;
  static const Color successColor = secondary;
  static const Color errorColor = error;
  static const Color warningColor = tertiary;

  // Score Thresholds
  static const double excellentScoreThreshold = 0.8; // 80%
  static const double goodScoreThreshold = 0.6; // 60%

  // Timer Colors
  static const double timerGreenThreshold = 0.5; // 50%
  static const double timerOrangeThreshold = 0.25; // 25%

  // Spacing & Border Radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;

  // Text Sizes
  static const double fontSmall = 12.0;
  static const double fontMedium = 14.0;
  static const double fontLarge = 16.0;
  static const double fontTitle = 20.0;
  static const double fontHeader = 24.0;
}