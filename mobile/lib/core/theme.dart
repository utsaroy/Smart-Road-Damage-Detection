import 'package:flutter/material.dart';

/// Centralized theme configuration for the Smart Road System app.
/// Soft Claymorphism & Frosted Jelly 3D design inspired by VisionOS and tactile Apple Clay UI.
class AppTheme {
  // Canvas & Surfaces
  static const Color background = Color(0xFFF5F6F9); // Silky porcelain / alabaster
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFEDEFF3);
  static const Color borderMedium = Color(0xFFE2E5EB);

  // High-Contrast Obsidian & Charcoal
  static const Color obsidianBlack = Color(0xFF111111);
  static const Color charcoalDark = Color(0xFF1E2022);

  // 3D Frosted Jelly Colors
  static const Color jellyPinkColor = Color(0xFFFF4D6D);
  static const Color jellyBlueColor = Color(0xFF3B82F6);
  static const Color jellyPurpleColor = Color(0xFF7C5CFC);
  static const Color jellyAmberColor = Color(0xFFF59E0B);
  static const Color jellyMintColor = Color(0xFF10B981);

  // 3D Frosted Jelly Gradients
  static const LinearGradient jellyPink = LinearGradient(
    colors: [Color(0xFFFF7E95), Color(0xFFFF4D6D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient jellyBlue = LinearGradient(
    colors: [Color(0xFF60A5FA), Color(0xFF3B82F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient jellyPurple = LinearGradient(
    colors: [Color(0xFFA78BFA), Color(0xFF7C5CFC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient jellyAmber = LinearGradient(
    colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient jellyMint = LinearGradient(
    colors: [Color(0xFF34D399), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Chip & Pill Backgrounds
  static const Color chipBackground = Color(0xFFF0F2F6);
  static const Color chipBorder = Color(0xFFE5E7EB);
  static const Color lilacPill = Color(0xFFEAE6FE);

  // Backward-compatibility aliases for existing widgets
  static const Color primaryDark = background;
  static const Color surfaceDark = surfaceLight;
  static const Color cardDark = cardLight;
  static const Color borderDark = borderLight;
  static const Color accentAmber = jellyPurpleColor;
  static const Color accentOrange = obsidianBlack;
  static const Color aiLavender = jellyPurpleColor;

  // Typography
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);

  // Severity colors (clean, vibrant)
  static const Color severityLow = Color(0xFF10B981);
  static const Color severityMedium = Color(0xFFF59E0B);
  static const Color severityHigh = Color(0xFFFF4D6D);
  static const Color severityCritical = Color(0xFFE11D48);

  // Damage type colors
  static const Color pothole = Color(0xFFFF4D6D);
  static const Color longitudinalCrack = Color(0xFF3B82F6);
  static const Color transverseCrack = Color(0xFFF59E0B);
  static const Color alligatorCrack = Color(0xFF7C5CFC);

  // Gradients
  static const LinearGradient primaryGradient = jellyPurple;
  static const LinearGradient obsidianGradient = LinearGradient(
    colors: [Color(0xFF27272A), Color(0xFF111111)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF9FAFC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient dangerGradient = jellyPink;

  // Soft modern tactile shadows
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: const Color(0xFF000000).withValues(alpha: 0.04),
      blurRadius: 16,
      offset: const Offset(0, 5),
    ),
    const BoxShadow(
      color: Colors.white,
      blurRadius: 8,
      offset: Offset(0, -2),
    ),
  ];

  static List<BoxShadow> get clayShadow => [
    BoxShadow(
      color: const Color(0xFF000000).withValues(alpha: 0.06),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
    const BoxShadow(
      color: Colors.white,
      blurRadius: 10,
      offset: Offset(0, -2),
    ),
  ];

  static List<BoxShadow> get frostedDockShadow => [
    BoxShadow(
      color: const Color(0xFF000000).withValues(alpha: 0.09),
      blurRadius: 28,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get floatingDockShadow => frostedDockShadow;

  static List<BoxShadow> get elevatedButtonShadow => [
    BoxShadow(
      color: obsidianBlack.withValues(alpha: 0.35),
      blurRadius: 18,
      offset: const Offset(0, 7),
    ),
  ];

  static List<BoxShadow> get aiPillShadow => [
    BoxShadow(
      color: jellyPurpleColor.withValues(alpha: 0.35),
      blurRadius: 14,
      offset: const Offset(0, 4),
    ),
  ];

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      primaryColor: obsidianBlack,
      colorScheme: const ColorScheme.light(
        primary: obsidianBlack,
        secondary: jellyPurpleColor,
        surface: surfaceLight,
        error: severityHigh,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
      ),
      cardTheme: CardThemeData(
        color: cardLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: borderLight, width: 1.2),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: obsidianBlack,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
      ),
      dividerTheme: const DividerThemeData(
        color: borderLight,
        thickness: 1,
      ),
    );
  }

  // Fallback to lightTheme for full-switch
  static ThemeData get darkTheme => lightTheme;

  // Severity helpers
  static Color getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'low':
        return severityLow;
      case 'medium':
        return severityMedium;
      case 'high':
        return severityHigh;
      case 'critical':
        return severityCritical;
      default:
        return textMuted;
    }
  }

  static IconData getSeverityIcon(String severity) {
    switch (severity.toLowerCase()) {
      case 'low':
        return Icons.info_outline;
      case 'medium':
        return Icons.warning_amber_rounded;
      case 'high':
        return Icons.error_outline;
      case 'critical':
        return Icons.dangerous_outlined;
      default:
        return Icons.help_outline;
    }
  }

  static Color getDamageTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'pothole':
        return pothole;
      case 'longitudinal crack':
        return longitudinalCrack;
      case 'transverse crack':
        return transverseCrack;
      case 'alligator crack':
        return alligatorCrack;
      case 'no damage detected':
      case 'clear road':
        return severityLow;
      default:
        return textMuted;
    }
  }

  static IconData getDamageTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'pothole':
        return Icons.circle_outlined;
      case 'longitudinal crack':
        return Icons.horizontal_rule;
      case 'transverse crack':
        return Icons.more_vert;
      case 'alligator crack':
        return Icons.grid_on;
      case 'no damage detected':
      case 'clear road':
        return Icons.check_circle_outline;
      default:
        return Icons.help_outline;
    }
  }
}
