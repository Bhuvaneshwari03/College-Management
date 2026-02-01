import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Define the custom colors from the palette
  static const Color primaryColor = Color(0xFF692475); // Deep Purple
  static const Color secondaryColor = Color(0xFF82AB7D); // Sage Green
  static const Color tertiaryColor = Color(0xFFA47DAB); // Lavender
  static const Color surfaceVariantColor = Color(0xFF6A6B4E); // Olive Drab

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,

      // Color Scheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        onPrimary: Colors.white,
        secondary: secondaryColor,
        onSecondary: Colors.white,
        tertiary: tertiaryColor,
        onTertiary: Colors.white,
        surface: Colors.white,
        onSurface: Colors.black87,
        background: Colors.grey[50]!,
        onBackground: Colors.black87,

        // Using Olive Drab for containers or specific accents
        secondaryContainer: surfaceVariantColor.withOpacity(0.1),
        onSecondaryContainer: surfaceVariantColor,
      ),

      // Global Typography
      textTheme: GoogleFonts.outfitTextTheme().apply(
        bodyColor: Colors.black87,
        displayColor: Colors.black87,
      ),

      // Scaffold Background
      scaffoldBackgroundColor: Colors.grey[50],

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.black87),
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: primaryColor,
        ),
      ),

      // Elevation Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        elevation: 2,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
        margin: const EdgeInsets.all(8),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[100],
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        labelStyle: TextStyle(color: Colors.grey[700]),
      ),

      // Data Table Theme
      dataTableTheme: DataTableThemeData(
        headingRowColor: MaterialStateProperty.all(
          primaryColor.withOpacity(0.05),
        ),
        headingTextStyle: GoogleFonts.outfit(
          fontWeight: FontWeight.bold,
          color: primaryColor,
        ),
        dataRowColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return secondaryColor.withOpacity(0.1);
          }
          return null;
        }),
      ),
    );
  }
}
