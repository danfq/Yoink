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
      headlineSmall: const TextStyle(color: Colors.black),
      bodyMedium: const TextStyle(color: Colors.black),
    ),
  );

  ///Dark Theme
  static ThemeData dark = ThemeData.dark().copyWith(
    scaffoldBackgroundColor: const Color(0xFF24242C),
    colorScheme: const ColorScheme.dark().copyWith(
      secondary: const Color(0xFFE91E63),
    ),
    textTheme: GoogleFonts.poppinsTextTheme().copyWith(
      headlineSmall: const TextStyle(color: Colors.white),
      bodyMedium: const TextStyle(color: Colors.white),
    ),
  );
}
