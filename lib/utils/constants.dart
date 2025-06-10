import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color darkBlue = Color(0xFF0B1426);
  static const Color deepBlue = Color(0xFF1A2332);
  static const Color cyan = Color(0xFF00F5D4);
  static const Color lightCyan = Color(0xFF88FFF7);
  static const Color purple = Color(0xFF6B46C1);

  static const List<Color> welcomeGradient = [
    Color(0xFF0B1426),
    Color(0xFF1A2332),
    Color(0xFF0F1B2D),
  ];
}

class AppTextStyles {
  static TextStyle get welcomeTitle => GoogleFonts.cinzelDecorative(
        fontSize: 32,
        fontWeight: FontWeight.w400,
        color: Colors.white,
        letterSpacing: 1.5,
        height: 1.2,
      );

  static TextStyle get welcomeSubtitle => GoogleFonts.cinzelDecorative(
        fontSize: 18,
        fontWeight: FontWeight.w300,
        color: const Color(0xFFB0B8C1),
        letterSpacing: 0.8,
      );

  static TextStyle get buttonText => GoogleFonts.cinzelDecorative(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Colors.white,
        letterSpacing: 0.5,
      );
}
