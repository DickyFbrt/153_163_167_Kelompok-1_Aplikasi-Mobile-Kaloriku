import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors
  static const Color primary = Color(0xFF27AE60);        // Fresh Cheerful Green
  static const Color primaryLight = Color(0xFF2ECC71);   // Light Mint Green
  static const Color primarySurface = Color(0xFFE8F8F0); // Very light minty background
  static const Color primaryBorder = Color(0xFFC2EED7);  // Soft border for cards

  static const Color blue = Color(0xFF3498DB);           // Cheerful Sky Blue
  static const Color blueSurface = Color(0xFFEBF5FB);    // Light blue card background

  static const Color amber = Color(0xFFF39C12);          // Sunny Orange-Yellow
  static const Color amberSurface = Color(0xFFFEF5E7);   // Light amber surface

  static const Color red = Color(0xFFE74C3C);            // Cheerful Soft Red
  static const Color redSurface = Color(0xFFFDEDEC);     // Light red surface

  static const Color surface = Color(0xFFF4F6F4);        // Fresh light beige-green scaffold background
  static const Color card = Colors.white;
  static const Color border = Color(0xFFE2EBE5);         // Clean soft border for cards

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: surface,
        textTheme: GoogleFonts.dmSansTextTheme().copyWith(
          displayLarge: GoogleFonts.dmSerifDisplay(fontSize: 32),
          displayMedium: GoogleFonts.dmSerifDisplay(fontSize: 26),
          headlineLarge: GoogleFonts.dmSerifDisplay(fontSize: 22),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: surface,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: GoogleFonts.dmSerifDisplay(
            fontSize: 20,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        cardTheme: CardThemeData(
          color: card,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: border, width: 0.8),
          ),
          margin: EdgeInsets.zero,
        ),
      );
}

// Meal type config
class MealConfig {
  final String id;
  final String label;
  final String emoji;
  final Color color;
  final Color surface;

  const MealConfig({
    required this.id,
    required this.label,
    required this.emoji,
    required this.color,
    required this.surface,
  });
}

const List<MealConfig> mealTypes = [
  MealConfig(id: 'breakfast', label: 'Sarapan', emoji: '🌅', color: Color(0xFF2ECC71), surface: Color(0xFFE8F8F0)),
  MealConfig(id: 'lunch', label: 'Makan Siang', emoji: '☀️', color: Color(0xFF3498DB), surface: Color(0xFFEBF5FB)),
  MealConfig(id: 'snack', label: 'Snack', emoji: '🌤️', color: Color(0xFFF39C12), surface: Color(0xFFFEF5E7)),
  MealConfig(id: 'dinner', label: 'Makan Malam', emoji: '🌙', color: Color(0xFF9B59B6), surface: Color(0xFFF5EEF8)),
];

MealConfig getMealConfig(String id) =>
    mealTypes.firstWhere((m) => m.id == id, orElse: () => mealTypes[0]);
