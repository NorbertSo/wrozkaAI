import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/palm_analysis.dart';
import '../utils/constants.dart';

class PalmAnalysisResultScreen extends StatelessWidget {
  final String userName;
  final String userGender;
  final PalmAnalysis palmData;

  const PalmAnalysisResultScreen({
    super.key,
    required this.userName,
    required this.userGender,
    required this.palmData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: AppColors.welcomeGradient,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Analiza Zakończona!',
                  style: GoogleFonts.cinzelDecorative(
                    fontSize: 24,
                    color: AppColors.cyan,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Drogi${userGender == 'female' ? 'a' : ''} $userName,\nTwoja dłoń została przeanalizowana.',
                  style: GoogleFonts.cinzelDecorative(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Text(
                  'Wykryta ręka: ${palmData.handType == "left" ? "Lewa" : "Prawa"}',
                  style: GoogleFonts.cinzelDecorative(
                    fontSize: 14,
                    color: AppColors.cyan,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
