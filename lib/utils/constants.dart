import 'package:flutter/material.dart';

class AppColors {
  static const cyan = Color(0xFF00BCD4);
  
  static const List<Color> welcomeGradient = [
    Color(0xFF2C3E50),
    Color(0xFF000000),
  ];
}

class AppTextStyles {
  static const welcomeTitle = TextStyle(
    fontFamily: 'Playfair Display',
    fontSize: 32,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    fontStyle: FontStyle.normal,
    letterSpacing: 0.5,
  );

  static const welcomeSubtitle = TextStyle(
    fontFamily: 'Playfair Display',
    fontSize: 18,
    fontWeight: FontWeight.w400,
    color: Colors.white70,
    fontStyle: FontStyle.normal,
  );

  static const buttonText = TextStyle(
    fontFamily: 'Playfair Display',
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    letterSpacing: 0.5,
    fontStyle: FontStyle.normal,
  );
}
