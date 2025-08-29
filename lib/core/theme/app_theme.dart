import 'package:flutter/material.dart';

class AppTheme {
  // Dark Color Scheme
  static const Color primaryColor = Color(0xFF3B82F6);
  static const Color secondaryColor = Color(0xFFF59E0B);
  static const Color backgroundColor = Color(0xFF1E1E2E);
  static const Color surfaceColor = Color(0xFF2A2A3E);
  static const Color cardColor = Color(0xFF363650);
  static const Color textPrimaryColor = Color(0xFFE5E5E7);
  static const Color textSecondaryColor = Color(0xFFA1A1AA);
  
  // Light Color Scheme
  static const Color lightBackgroundColor = Color(0xFFF8FAFC);
  static const Color lightSurfaceColor = Color(0xFFFFFFFF);
  static const Color lightCardColor = Color(0xFFFFFFFF);
  static const Color lightTextPrimaryColor = Color(0xFF1F2937);
  static const Color lightTextSecondaryColor = Color(0xFF6B7280);
  static const Color dividerColor = Color(0xFFE5E7EB);
  
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: backgroundColor,
        surfaceContainerHighest: surfaceColor,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: textPrimaryColor,
        onSurfaceVariant: textPrimaryColor,
      ),
      
      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundColor,
        foregroundColor: textPrimaryColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: textPrimaryColor,
        ),
      ),
      
      // Card Theme
        cardTheme: CardThemeData(
        color: cardColor,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      
      // Text Theme
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textPrimaryColor,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w500,
          color: textPrimaryColor,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: textPrimaryColor,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textPrimaryColor,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: textPrimaryColor,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: textSecondaryColor,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: textSecondaryColor,
        ),
      ),
      
      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor),
        ),
        hintStyle: const TextStyle(color: textSecondaryColor),
      ),
    );
  }
  
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: lightBackgroundColor,
        surfaceContainerHighest: lightSurfaceColor,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: lightTextPrimaryColor,
        onSurfaceVariant: lightTextPrimaryColor,
      ),
      
      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: lightSurfaceColor,
        foregroundColor: lightTextPrimaryColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: lightTextPrimaryColor,
        ),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        color: lightCardColor,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      
      // Text Theme
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: lightTextPrimaryColor,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w500,
          color: lightTextPrimaryColor,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: lightTextPrimaryColor,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: lightTextPrimaryColor,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: lightTextPrimaryColor,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: lightTextSecondaryColor,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: lightTextSecondaryColor,
        ),
      ),
      
      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor),
        ),
        hintStyle: const TextStyle(color: lightTextSecondaryColor),
      ),
    );
  }
}
