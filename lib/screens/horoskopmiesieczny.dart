// lib/screens/horoskopmiesieczny.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:intl/intl.dart';
import '../utils/constants.dart';
import '../services/haptic_service.dart';
import '../services/horoscope_service.dart';
import '../models/horoscope_data.dart';
import '../widgets/haptic_button.dart';
import '../utils/responsive_utils.dart';

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

class _HoroskopMiesiecznyScreenState extends State<HoroskopMiesiecznyScreen>
    with SingleTickerProviderStateMixin {
  final HapticService _hapticService = HapticService();
  final HoroscopeService _horoscopeService = HoroscopeService();

  // Stan aplikacji
  bool _isLoading = true;
  HoroscopeData? _monthlyHoroscope;
  String? _errorMessage;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  // Informacje o miesiącu
  late DateTime _currentMonth;
  late String _monthName;
  late String _yearStr;

  @override
  void initState() {
    super.initState();

    // Inicjalizuj animacje
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    // Ustaw daty
    _currentMonth = DateTime.now();
    _monthName = _getPolishMonthName(_currentMonth.month);
    _yearStr = _currentMonth.year.toString();

    // Pobierz dane
    _loadMonthlyHoroscope();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Funkcja pobierania horoskopu
  Future<void> _loadMonthlyHoroscope() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Inicjalizuj serwis
      await _horoscopeService.initialize();

      // Pobierz horoskop miesięczny
      final horoscope = await _horoscopeService.getMonthlyHoroscope(
        _convertPolishToEnglish(widget.zodiacSign),
        date: _currentMonth,
      );

      setState(() {
        _monthlyHoroscope = horoscope;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Nie udało się pobrać horoskopu: $e';
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
      body: Stack(
        children: [
          // Tło mistyczne
          _buildMysticalBackground(),

          // Główna zawartość
          SafeArea(
            child: _isLoading
                ? _buildLoadingState()
                : _errorMessage != null
                    ? _buildErrorState()
                    : _buildContentState(),
          ),
        ],
      ),
    );
  }

  // Tło mistyczne
  Widget _buildMysticalBackground() {
    return Stack(
      children: [
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
        Opacity(
          opacity: 0.6,
          child: Lottie.asset(
            'assets/animations/star_bg.json',
            fit: BoxFit.cover,
          ),
        ),
      ],
    );
  }

  // Stan ładowania
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Colors.orange,
            strokeWidth: 3,
          ),
          SizedBox(height: 20),
          Text(
            'Przygotowuję Twój horoskop...',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // Stan błędu
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 64,
            ),
            const SizedBox(height: 20),
            Text(
              'Ups! Coś poszło nie tak',
              style: GoogleFonts.cinzelDecorative(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _errorMessage ?? 'Nieznany błąd',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            HapticButton(
              text: 'Spróbuj ponownie',
              onPressed: _loadMonthlyHoroscope,
              hapticType: HapticType.light,
            ),
          ],
        ),
      ),
    );
  }

  // Główna zawartość
  Widget _buildContentState() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),

            // Nagłówek ze znakiem zodiaku
            _buildZodiacHeader(),

            const SizedBox(height: 30),

            // Główny horoskop
            _buildMainHoroscope(),

            const SizedBox(height: 30),

            // CTA do sekcji Premium
            _buildPremiumCTA(),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Nagłówek ze znakiem zodiaku
  Widget _buildZodiacHeader() {
    return ResponsiveContainer(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.orange.withOpacity(0.3),
              Colors.red.withOpacity(0.3),
            ],
          ),
          border: Border.all(
            color: Colors.orange.withOpacity(0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.2),
              blurRadius: 15,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          children: [
            // Symbol zodiaku z animacją
            AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.4),
                      border: Border.all(
                        color: Colors.orange.withOpacity(0.6),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        widget.zodiacEmoji,
                        style: const TextStyle(fontSize: 40),
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(width: 20),

            // Informacje o znaku i miesiącu
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ResponsiveText(
                    'Horoskop na $_monthName $_yearStr',
                    style: GoogleFonts.cinzelDecorative(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                    baseFontSize: 14,
                  ),
                  const SizedBox(height: 4),
                  ResponsiveText(
                    widget.zodiacSign.toUpperCase(),
                    style: GoogleFonts.cinzelDecorative(
                      fontSize: 24,
                      color: Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                    baseFontSize: 24,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Główny horoskop
  Widget _buildMainHoroscope() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.black.withOpacity(0.5),
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.1),
            blurRadius: 15,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Twój horoskop miesięczny',
                  style: GoogleFonts.cinzelDecorative(
                    fontSize: 18,
                    color: Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _monthlyHoroscope?.text ??
                'Brak dostępnego horoskopu na ten miesiąc.',
            style: AppTextStyles.fortuneText.copyWith(
              fontSize: 16,
              color: Colors.white,
              height: 1.8,
            ),
          ),
        ],
      ),
    );
  }

  // CTA do sekcji Premium - w stylu kafelka jak w innych miejscach
  Widget _buildPremiumCTA() {
    final todayButton = _getTodayPremiumButton();

    return GestureDetector(
      onTap: () async {
        await _hapticService.trigger(HapticType.light);
        _showPremiumDialog(todayButton['type']);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.black.withOpacity(0.8),
              Colors.black.withOpacity(0.6),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: todayButton['color'].withOpacity(0.4),
            width: 1,
          ),
        ),
        child: Stack(
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        todayButton['color'].withOpacity(0.3),
                        todayButton['color'].withOpacity(0.1),
                      ],
                    ),
                    border: Border.all(
                      color: todayButton['color'].withOpacity(0.6),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.auto_awesome,
                    size: 24,
                    color: todayButton['color'],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        todayButton['text'],
                        style: GoogleFonts.cinzelDecorative(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Funkcja premium',
                        style: GoogleFonts.cinzelDecorative(
                          fontSize: 12,
                          color: Colors.white70,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: todayButton['color'].withOpacity(0.7),
                ),
              ],
            ),
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: Colors.orange.withOpacity(0.8),
                ),
                child: Text(
                  'Premium',
                  style: GoogleFonts.cinzelDecorative(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Pobierz jeden przycisk premium na dzisiaj
  Map<String, dynamic> _getTodayPremiumButton() {
    final dayOfYear =
        DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;

    final allButtons = [
      {
        'text': '💼 Zobacz co cię czeka w sferze zawodowej',
        'type': 'praca',
        'color': Colors.blue,
      },
      {
        'text': '💖 Sprawdź prognozę miłosną na ten miesiąc',
        'type': 'milosc',
        'color': Colors.pink,
      },
      {
        'text': '💰 Odkryj swoje perspektywy finansowe',
        'type': 'finanse',
        'color': Colors.green,
      },
      {
        'text': '🏥 Poznaj prognozy zdrowotne',
        'type': 'zdrowie',
        'color': Colors.orange,
      },
      {
        'text': '🎯 Sprawdź najlepsze dni na działanie',
        'type': 'akcja',
        'color': Colors.red,
      },
      {
        'text': '🌙 Zobacz wpływ faz księżyca na Ciebie',
        'type': 'ksiezyc',
        'color': Colors.indigo,
      },
      {
        'text': '⭐ Poznaj swoje szczęśliwe liczby i kolory',
        'type': 'szczescie',
        'color': Colors.purple,
      },
    ];

    // Wybierz jeden przycisk na dzisiaj
    final index = dayOfYear % allButtons.length;
    return allButtons[index];
  }

  // Dialog informujący o niedostępności funkcji
  void _showPremiumDialog(String type) {
    final titles = {
      'praca': 'Sfera zawodowa',
      'milosc': 'Prognoza miłosna',
      'finanse': 'Perspektywy finansowe',
      'zdrowie': 'Prognozy zdrowotne',
      'akcja': 'Najlepsze dni na działanie',
      'ksiezyc': 'Wpływ faz księżyca',
      'szczescie': 'Szczęśliwe liczby i kolory',
    };

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1A2332),
                Color(0xFF0B1426),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.orange.withOpacity(0.5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_awesome,
                color: Colors.orange,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                titles[type] ?? 'Funkcja Premium',
                style: GoogleFonts.cinzelDecorative(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Ta funkcja będzie dostępna w pełnej wersji aplikacji.\n\nPracujemy nad wprowadzeniem systemu płatności.',
                style: GoogleFonts.cinzelDecorative(
                  fontSize: 14,
                  fontWeight: FontWeight.w300,
                  color: Colors.white70,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: HapticButton(
                  text: 'Rozumiem',
                  onPressed: () => Navigator.of(context).pop(),
                  hapticType: HapticType.light,
                  backgroundColor: Colors.orange.withOpacity(0.2),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Pomocnicze funkcje
  String _getPolishMonthName(int month) {
    const months = [
      '',
      'Styczeń',
      'Luty',
      'Marzec',
      'Kwiecień',
      'Maj',
      'Czerwiec',
      'Lipiec',
      'Sierpień',
      'Wrzesień',
      'Październik',
      'Listopad',
      'Grudzień'
    ];
    return months[month];
  }

  String _convertPolishToEnglish(String zodiacSign) {
    const polishToEnglish = {
      'Koziorożec': 'capricorn',
      'Wodnik': 'aquarius',
      'Ryby': 'pisces',
      'Baran': 'aries',
      'Byk': 'taurus',
      'Bliźnięta': 'gemini',
      'Rak': 'cancer',
      'Lew': 'leo',
      'Panna': 'virgo',
      'Waga': 'libra',
      'Skorpion': 'scorpio',
      'Strzelec': 'sagittarius',
    };

    return polishToEnglish[zodiacSign] ?? zodiacSign.toLowerCase();
  }
}
