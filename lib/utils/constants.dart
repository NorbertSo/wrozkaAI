// lib/utils/constants.dart
// Zaktualizowane z Open Sans do długich tekstów

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
  // ===== NAGŁÓWKI - Cinzel Decorative =====
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

  static TextStyle get sectionTitle => GoogleFonts.cinzelDecorative(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppColors.cyan,
        letterSpacing: 1.2,
      );

  static TextStyle get cardTitle => GoogleFonts.cinzelDecorative(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: Colors.white,
        letterSpacing: 0.5,
      );

  // ===== DŁUGIE TEKSTY - Open Sans =====
  static TextStyle get bodyText => GoogleFonts.openSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: Colors.white,
        height: 1.6,
        letterSpacing: 0.2,
      );

  static TextStyle get bodyTextLarge => GoogleFonts.openSans(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        color: Colors.white,
        height: 1.7,
        letterSpacing: 0.3,
      );

  static TextStyle get bodyTextLight => GoogleFonts.openSans(
        fontSize: 16,
        fontWeight: FontWeight.w300,
        color: Colors.white70,
        height: 1.6,
        letterSpacing: 0.2,
      );

  static TextStyle get fortuneText => GoogleFonts.openSans(
        fontSize: 17,
        fontWeight: FontWeight.w400,
        color: Colors.white,
        height: 1.8,
        letterSpacing: 0.3,
      );

  static TextStyle get introText => GoogleFonts.openSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: Colors.white,
        height: 1.7,
        letterSpacing: 0.2,
      );

  // ===== PODPISY I DETALE - Open Sans =====
  static TextStyle get caption => GoogleFonts.openSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: Colors.white60,
        letterSpacing: 0.1,
      );

  static TextStyle get smallText => GoogleFonts.openSans(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: Colors.white54,
      );

  // ===== SPECJALNE STYLE =====
  static TextStyle get mysticalAccent => GoogleFonts.cinzelDecorative(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.cyan,
        letterSpacing: 0.8,
      );

  static TextStyle get errorText => GoogleFonts.openSans(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Colors.red,
        height: 1.5,
      );

  static TextStyle get successText => GoogleFonts.openSans(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Colors.green,
        height: 1.5,
      );
}

// ===== FUNKCJE POMOCNICZE DLA FONTÓW =====
class AppFonts {
  /// Zwraca styl dla nagłówków sekcji
  static TextStyle sectionHeader({
    Color? color,
    double? fontSize,
  }) {
    return GoogleFonts.cinzelDecorative(
      fontSize: fontSize ?? 20,
      fontWeight: FontWeight.w600,
      color: color ?? AppColors.cyan,
      letterSpacing: 1.0,
    );
  }

  /// Zwraca styl dla długich tekstów (Open Sans)
  static TextStyle longText({
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    double? height,
  }) {
    return GoogleFonts.openSans(
      fontSize: fontSize ?? 16,
      fontWeight: fontWeight ?? FontWeight.w400,
      color: color ?? Colors.white,
      height: height ?? 1.6,
      letterSpacing: 0.2,
    );
  }

  /// Zwraca styl dla przycisków i akcji
  static TextStyle buttonStyle({
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
  }) {
    return GoogleFonts.cinzelDecorative(
      fontSize: fontSize ?? 16,
      fontWeight: fontWeight ?? FontWeight.w500,
      color: color ?? Colors.white,
      letterSpacing: 0.5,
    );
  }
}
