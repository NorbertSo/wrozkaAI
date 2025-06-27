// lib/screens/horoskopmiesieczny.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';
import '../services/haptic_service.dart';
import '../widgets/haptic_button.dart';

class HoroskopMiesiecznyScreen extends StatefulWidget {
  final String userName;
  final String zodiacSign;
  final String zodiacEmoji;

  const HoroskopMiesiecznyScreen({
    Key? key,
    required this.userName,
    required this.zodiacSign,
    required this.zodiacEmoji,
  }) : super(key: key);

  @override
  State<HoroskopMiesiecznyScreen> createState() =>
      _HoroskopMiesiecznyScreenState();
}

class _HoroskopMiesiecznyScreenState extends State<HoroskopMiesiecznyScreen> {
  final HapticService _hapticService = HapticService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Horoskop Miesięczny',
          style: GoogleFonts.cinzelDecorative(
            fontSize: 20,
            color: Colors.orange,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.orange),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.zodiacEmoji,
                style: const TextStyle(fontSize: 64),
              ),
              const SizedBox(height: 20),
              Text(
                'Horoskop Miesięczny',
                style: GoogleFonts.cinzelDecorative(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'dla znaku ${widget.zodiacSign}',
                style: GoogleFonts.cinzelDecorative(
                  fontSize: 18,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 40),
              Text(
                'Ta funkcja jest w przygotowaniu.\nWkrótce będzie dostępna!',
                style: GoogleFonts.cinzelDecorative(
                  fontSize: 16,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              HapticButton(
                text: 'Powrót',
                onPressed: () => Navigator.of(context).pop(),
                hapticType: HapticType.light,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
