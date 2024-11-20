import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

///App Themes
class Themes {
  ///Light Theme
  static ThemeData light = ThemeData.light().copyWith(
    scaffoldBackgroundColor: const Color(0xFFFAFAFA),
    colorScheme: const ColorScheme.light().copyWith(
      secondary: const Color(0xFF008080),
    ),
    textTheme: GoogleFonts.poppinsTextTheme().copyWith(
      // Display styles
      displayLarge: const TextStyle(color: Colors.black),
      displayMedium: const TextStyle(color: Colors.black),
      displaySmall: const TextStyle(color: Colors.black),

      // Headline styles
      headlineLarge: const TextStyle(color: Colors.black),
      headlineMedium: const TextStyle(color: Colors.black),
      headlineSmall: const TextStyle(color: Colors.black),

      // Title styles
      titleLarge: const TextStyle(color: Colors.black),
      titleMedium: const TextStyle(color: Colors.black),
      titleSmall: const TextStyle(color: Colors.black),

      // Body styles
      bodyLarge: const TextStyle(color: Colors.black),
      bodyMedium: const TextStyle(color: Colors.black),
      bodySmall: const TextStyle(color: Colors.black),

      // Label styles
      labelLarge: const TextStyle(color: Colors.black),
      labelMedium: const TextStyle(color: Colors.black),
      labelSmall: const TextStyle(color: Colors.black),
    ),
  );

  ///Dark Theme
  static ThemeData dark = ThemeData.dark().copyWith(
    scaffoldBackgroundColor: const Color(0xFF24242C),
    colorScheme: const ColorScheme.dark().copyWith(
      secondary: const Color(0xFFE91E63),
    ),
    textTheme: GoogleFonts.poppinsTextTheme().copyWith(
      // Display styles
      displayLarge: const TextStyle(color: Colors.white),
      displayMedium: const TextStyle(color: Colors.white),
      displaySmall: const TextStyle(color: Colors.white),

      // Headline styles
      headlineLarge: const TextStyle(color: Colors.white),
      headlineMedium: const TextStyle(color: Colors.white),
      headlineSmall: const TextStyle(color: Colors.white),

      // Title styles
      titleLarge: const TextStyle(color: Colors.white),
      titleMedium: const TextStyle(color: Colors.white),
      titleSmall: const TextStyle(color: Colors.white),

      // Body styles
      bodyLarge: const TextStyle(color: Colors.white),
      bodyMedium: const TextStyle(color: Colors.white),
      bodySmall: const TextStyle(color: Colors.white),

      // Label styles
      labelLarge: const TextStyle(color: Colors.white),
      labelMedium: const TextStyle(color: Colors.white),
      labelSmall: const TextStyle(color: Colors.white),
    ),
  );
}
