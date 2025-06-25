// lib/screens/horoskopmenu.dart
// 🔮 KOMPLETNY, DZIAŁAJĄCY EKRAN HOROSKOPÓW

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'package:lottie/lottie.dart';
import '../utils/constants.dart';
import '../services/logging_service.dart';
import '../services/horoscope_service.dart'; // ✅ DODAJ TEN IMPORT
import 'horoskoptygodniowy.dart';
import 'horoskopmiesieczny.dart';
import 'package:intl/intl.dart';
import '../models/horoscope_data.dart';

class HoroskopeMenuScreen extends StatefulWidget {
  final String userName;
  final String userGender;
  final DateTime? birthDate;

  const HoroskopeMenuScreen({
    Key? key,
    required this.userName,
    required this.userGender,
    this.birthDate,
  }) : super(key: key);

  @override
  State<HoroskopeMenuScreen> createState() => _HoroskopeMenuScreenState();
}

class _HoroskopeMenuScreenState extends State<HoroskopeMenuScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;

  final LoggingService _logger = LoggingService();
  final HoroscopeService _horoscopeService =
      HoroscopeService(); // ✅ DODAJ SERWIS

  // Stan ładowania
  bool _isLoading = true;
  String? _error;
  String? _dailyHoroscopeText;
  String? _moonPhase;
  String? _moonEmoji;
  HoroscopeData? _currentHoroscope; // ✅ DODAJ DANE HOROSKOPU

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(_animationController);

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _loadHoroscopeData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // ✅ NOWA METODA - POBIERA Z FIREBASE
  Future<void> _loadHoroscopeData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final zodiacSign = _getZodiacSign();
      _logger.logToConsole('Ładowanie horoskopu dla $zodiacSign',
          tag: 'HOROSCOPE');

      // ✅ INICJALIZUJ SERWIS
      await _horoscopeService.initialize();

      // ✅ POBIERZ PRAWDZIWY HOROSKOP Z FIREBASE
      _currentHoroscope = await _horoscopeService.getDailyHoroscope(zodiacSign);

      if (_currentHoroscope != null) {
        setState(() {
          _dailyHoroscopeText = _currentHoroscope!.text;
          _moonPhase = _currentHoroscope!.moonPhase;
          _moonEmoji = _currentHoroscope!.moonEmoji;
          _isLoading = false;
        });
        _logger.logToConsole('✅ Horoskop z Firebase załadowany',
            tag: 'HOROSCOPE');
      } else {
        // Fallback do statycznych tekstów
        setState(() {
          _dailyHoroscopeText = _getDailyHoroscopePreview(zodiacSign);
          _moonPhase = _getCurrentMoonPhase();
          _moonEmoji = _getMoonPhaseEmoji(_moonPhase!);
          _isLoading = false;
        });
        _logger.logToConsole('⚠️ Używam fallback horoskopu', tag: 'HOROSCOPE');
      }
    } catch (e) {
      _logger.logToConsole('❌ Błąd ładowania horoskopu: $e', tag: 'ERROR');
      setState(() {
        // Fallback w przypadku błędu
        final zodiacSign = _getZodiacSign();
        _dailyHoroscopeText = _getDailyHoroscopePreview(zodiacSign);
        _moonPhase = _getCurrentMoonPhase();
        _moonEmoji = _getMoonPhaseEmoji(_moonPhase!);
        _error = null; // Nie pokazuj błędu, użyj fallback
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Horoskopy',
          style: GoogleFonts.cinzelDecorative(
            fontSize: 22,
            color: AppColors.cyan,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.cyan),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          // Background animation
          Positioned.fill(
            child: _buildMysticalBackground(),
          ),

          // Content
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Dzisiejszy horoskop z symbolem zodiaku
                    _buildDailyHoroscopeCard(),

                    const SizedBox(height: 20),

                    // ✅ PRZENIESIONY: Horoskop rozbudowany Z ANIMACJĄ PŁOMIENIA
                    _buildAnimatedHoroscopeOption(
                      title: 'Horoskop Rozbudowany',
                      icon: Icons.auto_awesome,
                      description: 'Specjalnie dla Ciebie',
                      color: Colors.deepPurple,
                      onTap: () => _navigateToHoroscope('extended'),
                    ),

                    const SizedBox(height: 20),

                    // Kalendarz księżycowy
                    _buildLunarCalendarCard(),

                    const SizedBox(height: 20),

                    // Pozostałe opcje horoskopów
                    Row(
                      children: [
                        Expanded(
                          child: _buildCompactHoroscopeOption(
                            title: 'Tygodniowy',
                            icon: Icons.calendar_view_week_outlined,
                            color: Colors.blueAccent,
                            onTap: () => _navigateToHoroscope('weekly'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildCompactHoroscopeOption(
                            title: 'Miesięczny',
                            icon: Icons.calendar_month_outlined,
                            color: Colors.orange,
                            onTap: () => _navigateToHoroscope('monthly'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    ElevatedButton(
                      onPressed: () => _navigateToHoroscope('personal'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.cyan.withOpacity(0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: AppColors.cyan,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'Horoskop Specjalnie dla Ciebie',
                          style: GoogleFonts.cinzelDecorative(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Information footer
                    Text(
                      'Horoskopy tworzone są na podstawie Twojej daty urodzenia i aktualnego układu planet',
                      style: GoogleFonts.cinzelDecorative(
                        fontSize: 12,
                        color: Colors.white60,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMysticalBackground() {
    return Stack(
      children: [
        // Background gradient
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF1A1A2E),
                Color(0xFF0F0E1C),
                Color(0xFF080612),
              ],
            ),
          ),
        ),

        // Stars animation
        Opacity(
          opacity: 0.7,
          child: Lottie.asset(
            'assets/animations/star_bg.json',
            fit: BoxFit.cover,
          ),
        ),

        // Animated cosmic background
        AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return CustomPaint(
              painter: CosmicPainter(
                animation: _animationController.value,
              ),
              size: Size.infinite,
            );
          },
        ),
      ],
    );
  }

  Widget _buildDailyHoroscopeCard() {
    final String zodiacSign = _getZodiacSign();
    final String zodiacEmoji = _getZodiacEmoji(zodiacSign);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.indigo.withOpacity(0.3),
            Colors.purple.withOpacity(0.3),
          ],
        ),
        border: Border.all(
          color: AppColors.cyan.withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.cyan.withOpacity(0.2),
            blurRadius: 15,
            spreadRadius: 1,
          ),
        ],
      ),
      child: _isLoading
          ? _buildLoadingIndicator()
          : _error != null
              ? _buildErrorIndicator()
              : _buildHoroscopeContent(zodiacSign, zodiacEmoji),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Column(
      children: [
        CircularProgressIndicator(color: AppColors.cyan),
        SizedBox(height: 16),
        Text(
          'Ładowanie horoskopu...',
          style: TextStyle(color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildErrorIndicator() {
    return Column(
      children: [
        const Icon(Icons.error_outline, color: Colors.orange, size: 40),
        const SizedBox(height: 16),
        Text(
          _error ?? 'Wystąpił błąd',
          style: const TextStyle(color: Colors.white70),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: _loadHoroscopeData,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.orange.withOpacity(0.2),
              border: Border.all(
                color: Colors.orange,
                width: 1,
              ),
            ),
            child: const Text(
              'Spróbuj ponownie',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  // ✅ ZAKTUALIZUJ METODĘ BUDOWANIA CONTENTU
  Widget _buildHoroscopeContent(String zodiacSign, String zodiacEmoji) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Zodiac symbol
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppColors.cyan.withOpacity(0.3),
                AppColors.cyan.withOpacity(0.1),
              ],
            ),
            border: Border.all(
              color: AppColors.cyan.withOpacity(0.6),
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              zodiacEmoji,
              style: const TextStyle(fontSize: 28),
            ),
          ),
        ),
        const SizedBox(width: 16),

        // Horoscope content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ USUŃ ZNACZNIK AI/FIREBASE - pozostaw tylko tytuł
              Text(
                'Dziś dla $zodiacSign',
                style: GoogleFonts.cinzelDecorative(
                  fontSize: 18,
                  color: AppColors.cyan,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _dailyHoroscopeText ?? 'Brak horoskopu na dziś',
                style: AppTextStyles.fortuneText.copyWith(
                  fontSize: 14,
                  color: Colors.white,
                  height: 1.4,
                ),
              ),
              // ✅ DODAJ DODATKOWE INFO Z FIREBASE
              if (_currentHoroscope != null) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (_currentHoroscope!.luckyNumber != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.green.withOpacity(0.2),
                          border: Border.all(
                            color: Colors.green.withOpacity(0.4),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'Szczęśliwa liczba: ${_currentHoroscope!.luckyNumber}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ],
                    if (_currentHoroscope!.luckyColor != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.orange.withOpacity(0.2),
                          border: Border.all(
                            color: Colors.orange.withOpacity(0.4),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'Kolor: ${_currentHoroscope!.luckyColor}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLunarCalendarCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.deepPurple.withOpacity(0.3),
            Colors.indigo.withOpacity(0.3),
          ],
        ),
        border: Border.all(
          color: Colors.purple.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start, // ✅ DODAJ WYRÓWNANIE DO GÓRY
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.purple.withOpacity(0.2),
              border: Border.all(
                color: Colors.purple.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                _moonEmoji ?? '🌙',
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Faza Księżyca: ${_moonPhase ?? "Nieznana"}',
                  style: GoogleFonts.cinzelDecorative(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getLunarCalendarDescription(_moonPhase ?? "Nieznana"),
                  style: AppTextStyles.fortuneText.copyWith(
                    fontSize: 12,
                    color: Colors.white70,
                    height: 1.5,
                  ),
                  // ✅ USUŃ: maxLines i overflow
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHoroscopeOption({
    required String title,
    required IconData icon,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.black.withOpacity(0.5),
          border: Border.all(
            color: color.withOpacity(0.4),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.1),
                border: Border.all(
                  color: color.withOpacity(0.4),
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.cinzelDecorative(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.cinzelDecorative(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: color,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactHoroscopeOption({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            vertical: 16, horizontal: 12), // ✅ ZMNIEJSZ PADDING
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.black.withOpacity(0.5),
          border: Border.all(
            color: color.withOpacity(0.4),
            width: 1,
          ),
        ),
        child: Column(
          // ✅ ZMIEŃ NA COLUMN zamiast ROW
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 24, // ✅ ZWIĘKSZ ROZMIAR IKONY
            ),
            const SizedBox(height: 8), // ✅ ODSTĘP PIONOWY
            Text(
              title,
              style: GoogleFonts.cinzelDecorative(
                fontSize: 12, // ✅ ZMNIEJSZ CZCIONKĘ
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center, // ✅ WYŚRODKUJ TEKST
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToHoroscope(String type) {
    switch (type) {
      case 'weekly':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => HoroskopTygodniowyScreen(
              userName: widget.userName,
              zodiacSign: _getZodiacSign(),
              zodiacEmoji: _getZodiacEmoji(_getZodiacSign()),
            ),
          ),
        );
        break;
      case 'monthly':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => HoroskopMiesiecznyScreen(
              userName: widget.userName,
              zodiacSign: _getZodiacSign(),
              zodiacEmoji: _getZodiacEmoji(_getZodiacSign()),
            ),
          ),
        );
        break;
      case 'extended':
      case 'personal':
        _logger.logToConsole('Nawigacja do $type - do implementacji',
            tag: 'NAVIGATION');
        break;
    }
  }

  // 🔮 HELPER METHODS
  String _getZodiacSign() {
    if (widget.birthDate == null) return 'Nieznany';

    final month = widget.birthDate!.month;
    final day = widget.birthDate!.day;

    if ((month == 12 && day >= 22) || (month == 1 && day <= 19)) {
      return 'Koziorożec';
    } else if ((month == 1 && day >= 20) || (month == 2 && day <= 18)) {
      return 'Wodnik';
    } else if ((month == 2 && day >= 19) || (month == 3 && day <= 20)) {
      return 'Ryby';
    } else if ((month == 3 && day >= 21) || (month == 4 && day <= 19)) {
      return 'Baran';
    } else if ((month == 4 && day >= 20) || (month == 5 && day <= 20)) {
      return 'Byk';
    } else if ((month == 5 && day >= 21) || (month == 6 && day <= 20)) {
      return 'Bliźnięta';
    } else if ((month == 6 && day >= 21) || (month == 7 && day <= 22)) {
      return 'Rak';
    } else if ((month == 7 && day >= 23) || (month == 8 && day <= 22)) {
      return 'Lew';
    } else if ((month == 8 && day >= 23) || (month == 9 && day <= 22)) {
      return 'Panna';
    } else if ((month == 9 && day >= 23) || (month == 10 && day <= 22)) {
      return 'Waga';
    } else if ((month == 10 && day >= 23) || (month == 11 && day <= 21)) {
      return 'Skorpion';
    } else if ((month == 11 && day >= 22) || (month == 12 && day <= 21)) {
      return 'Strzelec';
    } else {
      return 'Nieznany';
    }
  }

  String _getZodiacEmoji(String zodiacSign) {
    switch (zodiacSign) {
      case 'Koziorożec':
        return '♑';
      case 'Wodnik':
        return '♒';
      case 'Ryby':
        return '♓';
      case 'Baran':
        return '♈';
      case 'Byk':
        return '♉';
      case 'Bliźnięta':
        return '♊';
      case 'Rak':
        return '♋';
      case 'Lew':
        return '♌';
      case 'Panna':
        return '♍';
      case 'Waga':
        return '♎';
      case 'Skorpion':
        return '♏';
      case 'Strzelec':
        return '♐';
      default:
        return '♈'; // Domyślnie Baran
    }
  }

  // ✅ NOWA METODA: Animowany Horoskop Rozbudowany z płomieniem
  Widget _buildAnimatedHoroscopeOption({
    required String title,
    required IconData icon,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          // Główny kontener
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withOpacity(0.3),
                  Colors.orange.withOpacity(0.2),
                  color.withOpacity(0.3),
                ],
              ),
              border: Border.all(
                color: Colors.orange.withOpacity(0.6),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              children: [
                // Animowana ikona z płomieniem
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.orange.withOpacity(0.8),
                            Colors.red.withOpacity(0.5),
                            color.withOpacity(0.3),
                          ],
                        ),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.8),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.5),
                            blurRadius: 10 +
                                (math.sin(_animationController.value *
                                        2 *
                                        math.pi) *
                                    3),
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Transform.scale(
                        scale: 1.0 +
                            (math.sin(
                                    _animationController.value * 2 * math.pi) *
                                0.1),
                        child: Icon(
                          icon,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.cinzelDecorative(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: GoogleFonts.cinzelDecorative(
                          fontSize: 14,
                          color: Colors.orange.shade200,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle:
                          math.sin(_animationController.value * 2 * math.pi) *
                              0.1,
                      child: Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.orange,
                        size: 20,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // ✅ ANIMOWANE PŁOMIENIE WOKÓŁ KONTENERA
          ...List.generate(8, (index) {
            return AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                final angle = (index * math.pi / 4) +
                    (_animationController.value * 2 * math.pi);
                final radius = 30.0;
                final flameSize = 8.0 +
                    (math.sin(
                            _animationController.value * 4 * math.pi + index) *
                        3);

                return Positioned(
                  left: radius * math.cos(angle) + 150,
                  top: radius * math.sin(angle) + 40,
                  child: Container(
                    width: flameSize,
                    height: flameSize * 1.5,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          Colors.orange.withOpacity(0.8),
                          Colors.red.withOpacity(0.4),
                          Colors.transparent,
                        ],
                      ),
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(flameSize / 2),
                        top: Radius.circular(flameSize / 4),
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }

  String _getCurrentMoonPhase() {
    final now = DateTime.now();
    // ✅ ZMIEŃ: Zwróć prawdziwą fazę księżyca zamiast dnia tygodnia
    final dayOfMonth = now.day;
    if (dayOfMonth <= 7) return 'Nów';
    if (dayOfMonth <= 14) return 'Rosnący';
    if (dayOfMonth <= 21) return 'Pełnia';
    return 'Malejący';
  }

  String _getMoonPhaseEmoji(String moonPhase) {
    switch (moonPhase) {
      case 'Nów':
        return '🌑';
      case 'Rosnący':
        return '🌓';
      case 'Pełnia':
        return '🌕';
      case 'Malejący':
        return '🌗';
      default:
        return '🌑';
    }
  }

  String _getLunarCalendarDescription(String moonPhase) {
    switch (moonPhase) {
      case 'Nów':
        return 'Dziś Księżyc jest w nowiu. To idealny czas na nowe początki i postanowienia.';
      case 'Rosnący':
        return 'Księżyc rośnie, a wraz z nim Twoja energia. To dobry moment na działania twórcze.';
      case 'Pełnia':
        return 'Pełnia Księżyca. Emocje sięgają zenitu, a Ty czujesz przypływ energii.';
      case 'Malejący':
        return 'Księżyc maleje, co sprzyja refleksji i zakończeniu rozpoczętych spraw.';
      default:
        return 'Czas refleksji i planowania przyszłości.'; // ✅ USUŃ przypadek "Nieznana faza"
    }
  }

  // ✅ ZACHOWAJ METODĘ FALLBACK (dla bezpieczeństwa)
  String _getDailyHoroscopePreview(String zodiacSign) {
    switch (zodiacSign) {
      case 'Koziorożec':
        return 'Dzisiaj jest dobry dzień na planowanie przyszłości. Twoja ambicja i cierpliwość zostaną wynagrodzone. Szczęśliwy kolor: granatowy.';
      case 'Wodnik':
        return 'Twoja kreatywność osiąga dzisiaj szczyt. Wykorzystaj ten czas na innowacyjne pomysły. Możliwe niespodziewane spotkanie. Szczęśliwa liczba: 7.';
      case 'Byk':
        return 'Stabilność finansowa jest w zasięgu ręki. Zwróć uwagę na szczegóły w dokumentach. Wieczór sprzyja relaksowi. Szczęśliwa liczba: 6.';
      // ... pozostałe przypadki ...
      default:
        return 'Dziś gwiazdy przygotowały dla Ciebie specjalną wiadomość. Sprawdź pełen horoskop, aby poznać szczegóły.';
    }
  }
}

// 🎨 COSMIC PAINTER - ANIMOWANE TŁO
class CosmicPainter extends CustomPainter {
  final double animation;

  CosmicPainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Draw animated stars
    for (int i = 0; i < 50; i++) {
      final x = (i * 37) % size.width;
      final y = (i * 23) % size.height;
      final opacity = (math.sin(animation * 2 * math.pi + i) + 1) / 2;

      paint.color = Colors.white.withOpacity(opacity * 0.3);
      canvas.drawCircle(
        Offset(x, y),
        1 + opacity,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
