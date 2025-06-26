import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'package:lottie/lottie.dart';
import '../utils/constants.dart';
import 'horoskoptygodniowy.dart';
import 'horoskopmiesieczny.dart';
import '../services/horoscope_service.dart';
import '../services/haptic_service.dart';
import '../models/horoscope_data.dart';
import '../widgets/haptic_button.dart';

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
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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

                    // Kalendarz księżycowy
                    _buildLunarCalendarCard(),

                    const SizedBox(height: 20),

                    // Horoskop rozbudowany
                    _buildHoroscopeOption(
                      title: 'Horoskop Rozbudowany',
                      icon: Icons.auto_awesome,
                      description: 'Specjalnie dla Ciebie',
                      color: Colors.deepPurple,
                      onTap: () => _navigateToHoroscope('extended'),
                    ),

                    const SizedBox(height: 16),

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

                    _buildCompactHoroscopeOption(
                      title: 'Horoskop Specjalnie dla Ciebie',
                      icon: Icons.star_outline,
                      color: AppColors.cyan,
                      onTap: () => _navigateToHoroscope('personal'),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title now at the top
          Text(
            'Horoskop codzienny dla:',
            style: GoogleFonts.cinzelDecorative(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 12),

          // Content row with zodiac icon and details
          Row(
            children: [
              // Zodiac symbol
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
                          color: AppColors.cyan.withOpacity(0.6),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          zodiacEmoji,
                          style: const TextStyle(
                            fontSize: 40,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(width: 20),

              // Zodiac sign text and daily horoscope info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      zodiacSign.toUpperCase(),
                      style: GoogleFonts.cinzelDecorative(
                        fontSize: 24,
                        color: AppColors.cyan,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getDailyHoroscopePreview(zodiacSign),
                      style: AppTextStyles.fortuneText.copyWith(
                        fontSize: 11, // Smaller font size
                        color: Colors.white70,
                        height: 1.4, // Reduced line height
                      ),
                      maxLines: 5, // Increased max lines
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLunarCalendarCard() {
    // Get current moon phase
    final String moonPhase = _getCurrentMoonPhase();
    final String moonEmoji = _getMoonPhaseEmoji(moonPhase);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blueGrey.withOpacity(0.3),
            Colors.indigo.withOpacity(0.2),
          ],
        ),
        border: Border.all(
          color: Colors.blueGrey.withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withOpacity(0.2),
            blurRadius: 15,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          // Moon phase symbol - matched size with zodiac icon
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withOpacity(0.4),
              border: Border.all(
                color: Colors.blueGrey.withOpacity(0.6),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                moonEmoji,
                style: const TextStyle(
                  fontSize: 40,
                ),
              ),
            ),
          ),

          const SizedBox(width: 20),

          // Moon phase info - matched styling with zodiac
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kalendarz księżycowy:',
                  style: GoogleFonts.cinzelDecorative(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  moonPhase.toUpperCase(),
                  style: GoogleFonts.cinzelDecorative(
                    fontSize: 24,
                    color: Colors.blueGrey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getLunarCalendarDescription(moonPhase),
                  style: AppTextStyles.fortuneText.copyWith(
                    fontSize: 12,
                    color: Colors.white70,
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
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
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
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
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.black.withOpacity(0.5),
          border: Border.all(
            color: color.withOpacity(0.4),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 20,
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                title,
                style: GoogleFonts.cinzelDecorative(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
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
      case 'daily':
      case 'extended':
      case 'personal':
        // For other types, show "coming soon" dialog or placeholder
        _showComingSoonDialog(type);
        break;
    }
  }

  void _showComingSoonDialog(String type) {
    String title = '';
    switch (type) {
      case 'daily':
        title = 'Horoskop Dzienny';
        break;
      case 'extended':
        title = 'Horoskop Rozbudowany';
        break;
      case 'personal':
        title = 'Specjalny Horoskop';
        break;
      default:
        title = 'Ta Funkcja';
    }

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
              Icon(Icons.hourglass_bottom, color: Colors.orange, size: 48),
              const SizedBox(height: 16),
              Text(
                '$title - Wkrótce',
                style: GoogleFonts.cinzelDecorative(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Ta funkcja będzie dostępna w najbliższej aktualizacji. Pracujemy nad jej udoskonaleniem!',
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
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.withOpacity(0.2),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                      side: BorderSide(
                        color: Colors.orange.withOpacity(0.6),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Text(
                    'Rozumiem',
                    style: GoogleFonts.cinzelDecorative(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getZodiacSign() {
    // If we have a birth date, determine the zodiac sign
    if (widget.birthDate != null) {
      final day = widget.birthDate!.day;
      final month = widget.birthDate!.month;

      switch (month) {
        case 1:
          return day <= 19 ? 'Koziorożec' : 'Wodnik';
        case 2:
          return day <= 18 ? 'Wodnik' : 'Ryby';
        case 3:
          return day <= 20 ? 'Ryby' : 'Baran';
        case 4:
          return day <= 19 ? 'Baran' : 'Byk';
        case 5:
          return day <= 20 ? 'Byk' : 'Bliźnięta';
        case 6:
          return day <= 20 ? 'Bliźnięta' : 'Rak';
        case 7:
          return day <= 22 ? 'Rak' : 'Lew';
        case 8:
          return day <= 22 ? 'Lew' : 'Panna';
        case 9:
          return day <= 22 ? 'Panna' : 'Waga';
        case 10:
          return day <= 22 ? 'Waga' : 'Skorpion';
        case 11:
          return day <= 21 ? 'Skorpion' : 'Strzelec';
        case 12:
          return day <= 21 ? 'Strzelec' : 'Koziorożec';
        default:
          return 'Nieznany';
      }
    }

    // If we don't have a birth date, return a placeholder
    return 'Nieznany';
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
        return '⭐';
    }
  }

  String _getZodiacDescription(String zodiacSign) {
    switch (zodiacSign) {
      case 'Koziorożec':
        return 'Rzetelny, ambitny, konsekwentny';
      case 'Wodnik':
        return 'Niezależny, oryginalny, wizjoner';
      case 'Ryby':
        return 'Wrażliwy, intuicyjny, artystyczny';
      case 'Baran':
        return 'Odważny, energiczny, pionierski';
      case 'Byk':
        return 'Niezawodny, praktyczny, wytrwały';
      case 'Bliźnięta':
        return 'Komunikatywny, ciekawy, adaptacyjny';
      case 'Rak':
        return 'Empatyczny, troskliwy, intuicyjny';
      case 'Lew':
        return 'Charyzmatyczny, dumny, hojny';
      case 'Panna':
        return 'Metodyczny, pracowity, perfekcjonista';
      case 'Waga':
        return 'Dyplomatyczny, sprawiedliwy, harmonijny';
      case 'Skorpion':
        return 'Intensywny, namiętny, strategiczny';
      case 'Strzelec':
        return 'Optymistyczny, szczery, entuzjastyczny';
      default:
        return 'Nieznany znak zodiaku';
    }
  }

  // Helper methods for new features
  String _getDailyHoroscopePreview(String zodiacSign) {
    // This would normally come from an API or database
    switch (zodiacSign) {
      case 'Koziorożec':
        return 'Dzisiaj jest dobry dzień na planowanie przyszłości. Twoja ambicja i cierpliwość zostaną wynagrodzone. Szczęśliwy kolor: granatowy.';
      case 'Wodnik':
        return 'Twoja kreatywność osiąga dzisiaj szczyt. Wykorzystaj ten czas na innowacyjne pomysły. Możliwe niespodziewane spotkanie. Szczęśliwa liczba: 7.';
      case 'Ryby':
        return 'Intuicja podpowiada Ci właściwe rozwiązania. Dzień sprzyja refleksji i duchowemu rozwojowi. Unikaj nadmiernej krytyki. Szczęśliwy kolor: morski.';
      case 'Baran':
        return 'Energia i zapał do działania będą Ci dzisiaj towarzyszyć. Dobry moment na rozpoczęcie nowych projektów. Uważaj na impulsywne decyzje.';
      case 'Byk':
        return 'Stabilność finansowa jest w zasięgu ręki. Zwróć uwagę na szczegóły w dokumentach. Wieczór sprzyja relaksowi. Szczęśliwa liczba: 6.';
      case 'Bliźnięta':
        return 'Komunikacja jest dzisiaj Twoją mocną stroną. Wykorzystaj to w rozmowach zawodowych. Możliwe nieoczekiwane wiadomości od dawno niewidzianej osoby.';
      case 'Rak':
        return 'Emocje mogą dzisiaj falować. Znajdź czas na odpoczynek w domowym zaciszu. Bliscy będą potrzebować Twojego wsparcia. Szczęśliwy kolor: srebrny.';
      case 'Lew':
        return 'Blask Twojej osobowości przyciąga innych. Dobry dzień na spotkania towarzyskie i prezentacje. Możliwe pochwały i uznanie. Szczęśliwa liczba: 1.';
      case 'Panna':
        return 'Precyzja w działaniu pomoże Ci osiągnąć sukces. Zwróć uwagę na zdrowie i dietę. Wieczór sprzyja porządkowaniu myśli. Szczęśliwy kolor: zielony.';
      case 'Waga':
        return 'Harmonijne relacje są dzisiaj najważniejsze. Dobry moment na rozwiązanie konfliktów. Ktoś czeka na Twoją decyzję. Szczęśliwa liczba: 4.';
      case 'Skorpion':
        return 'Intensywność emocji może Cię zaskoczyć. Wykorzystaj tę energię do transformacji. Unikaj zazdrości i kontroli. Szczęśliwy kolor: burgundowy.';
      case 'Strzelec':
        return 'Optymizm i entuzjazm to Twoje atuty. Możliwa inspirująca podróż lub spotkanie. Rozwijaj swoje zainteresowania. Szczęśliwa liczba: 3.';
      default:
        return 'Dziś gwiazdy przygotowały dla Ciebie specjalną wiadomość. Sprawdź pełen horoskop, aby poznać szczegóły.';
    }
  }

  String _getCurrentMoonPhase() {
    // In a real app, this would be calculated based on current date
    // For now, just return a random phase for demonstration
    final phases = [
      'Nów',
      'Przybywający sierp',
      'Pierwsza kwadra',
      'Przybywający garb',
      'Pełnia',
      'Ubywający garb',
      'Ostatnia kwadra',
      'Ubywający sierp'
    ];

    return phases[DateTime.now().day % phases.length];
  }

  String _getMoonPhaseEmoji(String phase) {
    switch (phase) {
      case 'Nów':
        return '🌑';
      case 'Przybywający sierp':
        return '🌒';
      case 'Pierwsza kwadra':
        return '🌓';
      case 'Przybywający garb':
        return '🌔';
      case 'Pełnia':
        return '🌕';
      case 'Ubywający garb':
        return '🌖';
      case 'Ostatnia kwadra':
        return '🌗';
      case 'Ubywający sierp':
        return '🌘';
      default:
        return '🌙';
    }
  }

  String _getLunarCalendarDescription(String phase) {
    switch (phase) {
      case 'Nów':
        return 'Czas nowych początków i planowania. Energia sprzyja wyciszeniu i refleksji. Dobry moment na wyznaczanie celów i intencji.';
      case 'Przybywający sierp':
        return 'Okres wzrostu energii i realizacji planów. Sprzyjający czas na początek nowych projektów i nawiązywanie kontaktów.';
      case 'Pierwsza kwadra':
        return 'Moment działania i przezwyciężania przeszkód. Energia sprzyja podejmowaniu decyzji i rozwiązywaniu problemów.';
      case 'Przybywający garb':
        return 'Czas intensywnego rozwoju i transformacji. Sprzy';
      case 'Pełnia':
        return 'Kulminacja energii, emocje są na powierzchni. Idealny czas na celebrowanie osiągnięć i manifestację pragnień.';
      case 'Ubywający garb':
        return 'Okres wdzięczności i dzielenia się z innymi. Dobry czas na działalność społeczną i pomaganie innym.';
      case 'Ostatnia kwadra':
        return 'Moment rozliczenia i odpuszczania. Energia sprzyja podsumowaniom i przygotowaniu się na nowy cykl.';
      case 'Ubywający sierp':
        return 'Czas wyciszenia i regeneracji. Sprzyjający okres dla odpoczynku, medytacji i praktyk duchowych.';
      default:
        return 'Fazy Księżyca wpływają na nasze emocje i energię. Świadome życie w zgodzie z cyklem księżycowym pomaga osiągnąć harmonię.';
    }
  }
}

class CosmicPainter extends CustomPainter {
  final double animation;

  CosmicPainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = AppColors.cyan.withOpacity(0.2);

    // Draw cosmic circles
    for (int i = 0; i < 3; i++) {
      final radius = 100.0 + (i * 50.0);
      final offset = 20.0 * math.sin(animation * 2 * math.pi + i);

      canvas.drawCircle(
        Offset(size.width / 2, size.height / 2 + offset),
        radius,
        paint,
      );
    }

    // Draw cosmic lines
    for (int i = 0; i < 12; i++) {
      final angle = (i / 12.0) * 2 * math.pi + (animation * math.pi);
      final dx = math.cos(angle);
      final dy = math.sin(angle);

      final startRadius = 50.0;
      final endRadius = size.width * 0.4;

      canvas.drawLine(
        Offset(
          size.width / 2 + dx * startRadius,
          size.height / 2 + dy * startRadius,
        ),
        Offset(
          size.width / 2 + dx * endRadius,
          size.height / 2 + dy * endRadius,
        ),
        paint
          ..color = AppColors.cyan
              .withOpacity(0.1 + (0.1 * math.sin(animation * 2 * math.pi + i))),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
