import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'package:lottie/lottie.dart';
import '../utils/constants.dart';
import '../services/haptic_service.dart';
import '../services/horoscope_service.dart';
import '../services/logging_service.dart';
import '../models/horoscope_data.dart';
import '../widgets/haptic_button.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

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
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  final HapticService _hapticService = HapticService();
  final HoroscopeService _horoscopeService = HoroscopeService();
  final LoggingService _logger = LoggingService();
  
  // ✅ POPRAWKA: Używamy pojedynczy horoskop miesięczny zamiast listy dziennych
  HoroscopeData? _monthlyHoroscope;
  bool _isLoading = true;
  bool _hasError = false;

  // Dates for the monthly horoscope
  late DateTime _startDate;
  late DateTime _endDate;
  late DateTime _creationDate;
  late DateTime _nextUpdateDate;

  @override
  void initState() {
    super.initState();

    // Initialize date formatting for Polish locale
    initializeDateFormatting('pl_PL', null);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
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

    // Calculate the dates
    _calculateDates();

    // ✅ POPRAWKA: Inicjalizuj miesięczne dane
    _initializeMonthlyData();
  }

  void _calculateDates() {
    final now = DateTime.now();

    // First day of current month
    _startDate = DateTime(now.year, now.month, 1);

    // Last day of current month
    _endDate = DateTime(now.year, now.month + 1, 0);

    // Creation date is first day of month
    _creationDate = _startDate;

    // Next update is first day of next month
    _nextUpdateDate = DateTime(now.year, now.month + 1, 1);
  }

  // ✅ POPRAWKA: Używaj getMonthlyHoroscope zamiast pobierania dziennych
  Future<void> _initializeMonthlyData() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      _logger.logToConsole('Inicjalizacja horoskopu miesięcznego dla ${widget.zodiacSign}', 
          tag: 'MONTHLY_HOROSCOPE');

      await _horoscopeService.initialize();

      // ✅ POPRAWKA: Pobierz horoskop miesięczny
      final fetchedHoroscope = await _horoscopeService.getMonthlyHoroscope(
        _getZodiacSignFromName(widget.zodiacSign),
        date: _startDate,
      );

      if (mounted) {
        setState(() {
          _monthlyHoroscope = fetchedHoroscope;
          _isLoading = false;
          _hasError = fetchedHoroscope == null;
        });

        if (fetchedHoroscope != null) {
          _logger.logToConsole('✅ Pomyślnie załadowano horoskop miesięczny', 
              tag: 'MONTHLY_HOROSCOPE');
        } else {
          _logger.logToConsole('⚠️ Nie udało się załadować horoskopu miesięcznego', 
              tag: 'MONTHLY_HOROSCOPE');
        }
      }
    } catch (e) {
      _logger.logToConsole('❌ Błąd inicjalizacji danych miesięcznych: $e', 
          tag: 'ERROR');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  // ✅ POPRAWKA: Konwertuj polską nazwę znaku na kod
  String _getZodiacSignFromName(String name) {
    final Map<String, String> zodiacMap = {
      'koziorożec': 'capricorn',
      'wodnik': 'aquarius',
      'ryby': 'pisces',
      'baran': 'aries',
      'byk': 'taurus',
      'bliźnięta': 'gemini',
      'rak': 'cancer',
      'lew': 'leo',
      'panna': 'virgo',
      'waga': 'libra',
      'skorpion': 'scorpio',
      'strzelec': 'sagittarius',
    };
    
    return zodiacMap[name.toLowerCase()] ?? name.toLowerCase();
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
          'Horoskop Miesięczny',
          style: GoogleFonts.cinzelDecorative(
            fontSize: 22,
            color: AppColors.cyan,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.cyan),
          onPressed: () async {
            await _hapticService.trigger(HapticType.light);
            Navigator.of(context).pop();
          },
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
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  // ✅ POPRAWKA: Obsługa różnych stanów
  Widget _buildContent() {
    if (_isLoading) {
      return _buildLoadingState();
    }
    
    if (_hasError || _monthlyHoroscope == null) {
      return _buildErrorState();
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),

            // Zodiac Header
            _buildZodiacHeader(),

            const SizedBox(height: 30),

            // Monthly Horoscope Content
            _buildMonthlyContent(),

            const SizedBox(height: 30),

            // Lunar Calendar for the month
            _buildMonthlyLunarCalendar(),

            const SizedBox(height: 40),

            // Premium Button
            _buildPremiumButton(
              title: 'Sprawdź Co Szepczą Tylko Do Ciebie',
              color: Colors.amber,
              icon: Icons.visibility,
              onTap: () => _showPremiumDialog('personalny'),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ✅ NOWY: Stan ładowania
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.cyan),
          const SizedBox(height: 20),
          Text(
            'Przywołuję mądrość gwiazd...',
            style: GoogleFonts.cinzelDecorative(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ NOWY: Stan błędu
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.orange,
              size: 64,
            ),
            const SizedBox(height: 20),
            Text(
              'Gwiazdy są dziś nieczytelne...',
              style: GoogleFonts.cinzelDecorative(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Spróbuj ponownie za chwilę',
              style: GoogleFonts.cinzelDecorative(
                fontSize: 14,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            HapticButton(
              text: 'Spróbuj ponownie',
              hapticType: HapticType.light,
              onPressed: _initializeMonthlyData,
              backgroundColor: AppColors.cyan,
              foregroundColor: Colors.black,
            ),
          ],
        ),
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

        // ✅ POPRAWKA: Bezpieczne ładowanie animacji Lottie
        _buildLottieAnimation(),
      ],
    );
  }

  // ✅ NOWA METODA: Bezpieczne ładowanie animacji
  Widget _buildLottieAnimation() {
    try {
      return Opacity(
        opacity: 0.7,
        child: Lottie.asset(
          'assets/animations/star_bg.json',
          fit: BoxFit.cover,
        ),
      );
    } catch (e) {
      // Fallback gdy brak animacji
      return Container();
    }
  }

  Widget _buildZodiacHeader() {
    // Make sure to use proper locale initialization
    String currentMonth;
    try {
      currentMonth = DateFormat('MMMM', 'pl_PL').format(_startDate);
      // Capitalize first letter
      currentMonth = currentMonth[0].toUpperCase() + currentMonth.substring(1);
    } catch (e) {
      // Fallback if there's an error with locale
      currentMonth = DateFormat('MMMM').format(_startDate);
    }

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
      child: Row(
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
                      widget.zodiacEmoji,
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

          // Zodiac sign and month info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Twój znak zodiaku:',
                  style: GoogleFonts.cinzelDecorative(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.zodiacSign.toUpperCase(),
                  style: GoogleFonts.cinzelDecorative(
                    fontSize: 24,
                    color: AppColors.cyan,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Miesiąc: $currentMonth ${_startDate.year}',
                  style: AppTextStyles.fortuneText.copyWith(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ POPRAWKA: Wyświetlaj rzeczywisty horoskop miesięczny
  Widget _buildMonthlyContent() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.black.withOpacity(0.5),
        border: Border.all(
          color: Colors.purple.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: Colors.purple,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Horoskop miesięczny',
                style: GoogleFonts.cinzelDecorative(
                  fontSize: 20,
                  color: Colors.purple,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _monthlyHoroscope?.text ?? _getMonthlyHoroscopePreview(),
            style: AppTextStyles.fortuneText.copyWith(
              fontSize: 16,
              color: Colors.white,
              height: 1.8,
            ),
          ),
          const SizedBox(height: 16),
          // Info o aktualizacji
          Text(
            'Następna aktualizacja: ${DateFormat('d MMMM yyyy', 'pl_PL').format(_nextUpdateDate)}',
            style: GoogleFonts.cinzelDecorative(
              fontSize: 12,
              color: Colors.white60,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyLunarCalendar() {
    // Generate the lunar phases for this month
    final List<String> lunarPhases = [
      'Nów',
      'Przybywający sierp',
      'Pierwsza kwadra',
      'Przybywający garb',
      'Pełnia',
      'Ubywający garb',
      'Ostatnia kwadra',
      'Ubywający sierp'
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Premium button for extended horoscope
        GestureDetector(
          onTap: () async {
            await _hapticService.trigger(HapticType.light);
            _showPremiumDialog('rozbudowany');
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.deepPurple.withOpacity(0.3),
                  Colors.deepPurple.withOpacity(0.1),
                ],
              ),
              border: Border.all(
                color: Colors.deepPurple.withOpacity(0.4),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.deepPurple.withOpacity(0.1),
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
                    color: Colors.deepPurple.withOpacity(0.2),
                    border: Border.all(
                      color: Colors.deepPurple.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.auto_awesome,
                    color: Colors.deepPurple,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sprawdź Rozbudowany Horoskop',
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
                          color: Colors.deepPurple.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.lock_outline,
                  color: Colors.deepPurple.withOpacity(0.7),
                  size: 22,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Lunar calendar container
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
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
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.blueGrey.withOpacity(0.2),
                blurRadius: 15,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kalendarz księżycowy na miesiąc:',
                style: GoogleFonts.cinzelDecorative(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              // Important lunar phases this month
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildLunarPhaseCard('Nów', 8),
                    _buildLunarPhaseCard('Pierwsza kwadra', 15),
                    _buildLunarPhaseCard('Pełnia', 22),
                    _buildLunarPhaseCard('Ostatnia kwadra', 29),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Current moon phase description
              Text(
                'Jak fazy Księżyca wpłyną na Ciebie:',
                style: GoogleFonts.cinzelDecorative(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _getLunarMonthlyDescription(),
                style: AppTextStyles.fortuneText.copyWith(
                  fontSize: 14,
                  color: Colors.white70,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLunarPhaseCard(String phase, int day) {
    // Check if this lunar date already passed
    bool isPast =
        day < DateTime.now().day && DateTime.now().month == _startDate.month;
    bool isCurrent =
        (day <= DateTime.now().day + 3 && day >= DateTime.now().day - 3) &&
            DateTime.now().month == _startDate.month;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      width: 80,
      child: Column(
        children: [
          // Moon phase emoji
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCurrent
                  ? Colors.blueGrey.withOpacity(0.3)
                  : Colors.transparent,
              border: Border.all(
                color: isCurrent ? Colors.blueGrey : Colors.transparent,
                width: isCurrent ? 1 : 0,
              ),
            ),
            child: Center(
              child: Text(
                _getMoonPhaseEmoji(phase),
                style: const TextStyle(
                  fontSize: 30,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Phase name
          Text(
            phase,
            style: GoogleFonts.cinzelDecorative(
              fontSize: 12,
              color: isPast ? Colors.white30 : Colors.white70,
              fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          // Day
          Text(
            '$day ${_getMonthShortName(_startDate.month)}',
            style: GoogleFonts.cinzelDecorative(
              fontSize: 12,
              color: isPast ? Colors.white30 : Colors.white70,
              fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getMonthShortName(int month) {
    switch (month) {
      case 1:
        return 'sty';
      case 2:
        return 'lut';
      case 3:
        return 'mar';
      case 4:
        return 'kwi';
      case 5:
        return 'maj';
      case 6:
        return 'cze';
      case 7:
        return 'lip';
      case 8:
        return 'sie';
      case 9:
        return 'wrz';
      case 10:
        return 'paź';
      case 11:
        return 'lis';
      case 12:
        return 'gru';
      default:
        return '';
    }
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

  Widget _buildPremiumButton({
    required String title,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () async {
        await _hapticService.trigger(HapticType.light);
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.3),
              color.withOpacity(0.1),
            ],
          ),
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
                color: color.withOpacity(0.2),
                border: Border.all(
                  color: color.withOpacity(0.5),
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
                      color: color.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.lock_outline,
              color: color.withOpacity(0.7),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  void _showPremiumDialog(String type) {
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
              color: Colors.amber.withOpacity(0.5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withOpacity(0.2),
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
                color: Colors.amber,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Funkcja Premium',
                style: GoogleFonts.cinzelDecorative(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.amber,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Ta funkcja będzie dostępna w pełnej wersji aplikacji.',
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
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.withOpacity(0.2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                      side: BorderSide(
                        color: Colors.amber.withOpacity(0.6),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Text(
                    'Rozumiem',
                    style: GoogleFonts.cinzelDecorative(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
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

  String _getMonthlyHoroscopePreview() {
    // Return different content based on zodiac sign - longer, 5-6 sentences
    switch (widget.zodiacSign.toLowerCase()) {
      case 'koziorożec':
        return 'Ten miesiąc przyniesie znaczące możliwości rozwoju w sferze zawodowej. Twoja ambicja i wytrwałość zostaną dostrzeżone przez przełożonych, co może skutkować awansem lub podwyżką. W drugiej połowie miesiąca skupisz się na stabilizacji finansowej i długoterminowych inwestycjach. W relacjach osobistych czeka Cię okres spokoju i harmonii, choć pewna osoba z przeszłości może nieoczekiwanie wrócić do Twojego życia. Zadbaj o zdrowie, szczególnie o układ odpornościowy. Weekend pod koniec miesiąca będzie idealny na regenerację sił.';
      case 'wodnik':
        return 'Nadchodzący miesiąc będzie czasem rozwoju Twojej kreatywności i oryginalnych pomysłów. Osoby z Twojego otoczenia zawodowego docenią Twoją innowacyjność, co może przynieść niespodziewane propozycje współpracy. W połowie miesiąca pojawi się szansa na realizację długo odkładanego projektu. Twoje życie towarzyskie rozkwitnie, a nowe znajomości mogą okazać się niezwykle wartościowe. W relacji partnerskiej unikaj podejmowania pochopnych decyzji pod wpływem emocji. Zadbaj o odpowiednią ilość snu i aktywność fizyczną, która pomoże Ci utrzymać wysoki poziom energii.';
      case 'ryby':
        return 'W tym miesiącu Twoja intuicja będzie szczególnie silna - warto jej zaufać, zwłaszcza w kwestiach zawodowych. Pojawi się możliwość rozwoju duchowego lub twórczego, która przyniesie Ci wiele satysfakcji. W drugiej połowie miesiąca możesz oczekiwać pozytywnych zmian w finansach, być może związanych z dodatkowym źródłem dochodu. Relacje rodzinne będą źródłem ciepła i wsparcia, szczególnie w trudniejszych momentach. W życiu uczuciowym czeka Cię głębokie porozumienie i wzajemne zrozumienie. Zadbaj o odpoczynek blisko natury - element wody przyniesie Ci ukojenie i regenerację.';
      case 'baran':
        return 'Ten miesiąc będzie dla Ciebie czasem intensywnej energii i nowych początków. Pierwsza dekada przyniesie możliwości rozwoju zawodowego, które warto wykorzystać bez wahania. Twój entuzjazm i bezpośrednie podejście zjednają Ci sojuszników w ważnych projektach. W połowie miesiąca możliwa jest niespodziewana podróż lub zmiana planów, która ostatecznie okaże się korzystna. W sferze finansowej zachowaj ostrożność - unikaj impulsywnych wydatków i inwestycji wysokiego ryzyka. Twoje życie uczuciowe nabierze rumieńców, a single mają szansę na pasjonującą znajomość. Pod koniec miesiąca zwróć uwagę on zdrowie i zadbaj o regularną aktywność fizyczną.';
      case 'byk':
        return 'Nadchodzący miesiąc przyniesie Ci stabilizację finansową i zawodową, na którą czekałeś. Twoja cierpliwość i konsekwencja w działaniu zostaną nagrodzone, szczególnie w pierwszej połowie miesiąca. Pojawi się okazja do długoterminowej inwestycji związanej z nieruchomościami lub przedmiotami wartościowymi. W życiu osobistym czeka Cię okres harmonii i spokoju, idealny do pogłębiania relacji z bliskimi. Osoby samotne mogą spotkać kogoś, kto podziela ich wartości i pragnienie bezpieczeństwa. Zwróć uwagę na zdrowie - szczególnie na układ trawienny i gospodarkę hormonalną. Ostatni tydzień miesiąca sprzyja odpoczynkowi i cieszeniu się prostymi przyjemnościami.';
      case 'bliźnięta':
        return 'Ten miesiąc będzie dla Ciebie czasem intensywnej komunikacji i nowych znajomości, które mogą przekształcić się w wartościowe relacje zawodowe lub prywatne. Twoja naturalna ciekawość i elastyczność pomogą Ci poradzić sobie z nieoczekiwanymi zmianami planów. W drugiej dekadzie miesiąca pojawi się szansa na podniesienie kwalifikacji lub rozpoczęcie nowego kursu. Finanse będą stabilne, choć warto unikać podejmowania kilku zobowiązań jednocześnie. W życiu uczuciowym czeka Cię ożywienie - być może powrót dawnych uczuć lub nowa fascynująca znajomość. Zadbaj o zdrowie psychiczne i unikaj przemęczenia. Znajdź czas na hobby i aktywności, które naprawdę sprawiają Ci przyjemność.';
      case 'rak':
        return 'Nadchodzący miesiąc będzie dla Ciebie czasem refleksji i emocjonalnego pogłębienia ważnych relacji. Twoja intuicja pomoże Ci podejmować trafne decyzje, szczególnie w sprawach rodzinnych i domowych. W pierwszej połowie miesiąca możesz odczuwać większą potrzebę bezpieczeństwa i stabilizacji, co skłoni Cię do reorganizacji przestrzeni domowej lub finansów. W pracy doceniona zostanie Twoja lojalność i zaangażowanie, co może przełożyć się na poprawę sytuacji materialnej. Życie uczuciowe będzie intensywne - głębokie rozmowy i wzajemne zrozumienie wzmocnią więzi z partnerem. Samotne Raki mogą spotkać kogoś, kto zrozumie ich wrażliwość. Zadbaj o równowagę emocjonalną poprzez regularne praktyki relaksacyjne i kontakt z wodą.';
      case 'lew':
        return 'Ten miesiąc będzie czasem, gdy Twoja naturalna charyzma i zdolności przywódcze zostaną dostrzeżone i docenione. W pierwszej dekadzie pojawią się okazje do zaprezentowania swoich umiejętności szerszemu gronu, co może przynieść uznanie i nowe możliwości zawodowe. Finanse będą sprzyjające, szczególnie jeśli zdecydujesz się zainwestować w swój rozwój osobisty lub zawodowy. W życiu towarzyskim będziesz błyszczeć - liczne zaproszenia i spotkania wypełnią Twój kalendarz. Relacje uczuciowe nabiorą blasku, a Twoja hojność i ciepło przyciągną do Ciebie innych. Pod koniec miesiąca zadbaj o odpoczynek i regenerację - mimo energetycznej natury, potrzebujesz czasu dla siebie. Zwróć uwagę na zdrowie serca i krążenie.';
      case 'panna':
        return 'Nadchodzący miesiąc będzie dla Ciebie czasem porządkowania spraw i wprowadzania ulepszeń zarówno w życiu zawodowym, jak i osobistym. Twoje analityczne podejście i dbałość o szczegóły pozwolą Ci dostrzec możliwości optymalizacji, których inni nie zauważają. W pierwszej połowie miesiąca skupisz się on sprawach zawodowych - możliwe, że otrzymasz propozycję udziału w projekcie wymagającym precyzji i dokładności. Finanse będą stabilne, choć warto przemyśleć długoterminową strategię oszczędzania. W życiu osobistym zadbasz o jakość relacji, eliminując niepotrzebne napięcia i nieporozumienia. Zdrowie będzie dobre, ale pamiętaj o regularnym odpoczynku od obowiązków. Końcówka miesiąca sprzyja wprowadzaniu nowych, zdrowszych nawyków żywieniowych.';
      case 'waga':
        return 'Ten miesiąc przyniesie Ci wiele możliwości budowania harmonijnych i satysfakcjonujących relacji zarówno w życiu prywatnym, jak i zawodowym. Twoje naturalne zdolności dyplomatyczne pomogą rozwiązać długotrwały konflikt w Twoim otoczeniu. W sferze zawodowej doceniona zostanie Twoja umiejętność współpracy i łagodzenia napięć w zespole. Druga dekada miesiąca może przynieść ważne decyzje dotyczące partnerstwa biznesowego lub osobistego. Finanse będą zrównoważone, choć warto unikać impulsywnych wydatków na luksusowe przedmioty. W życiu uczuciowym nastąpi pogłębienie relacji i wzajemne zrozumienie. Zadbaj o równowagę między dawaniem a braniem - Twoja tendencja do poświęcania się dla innych może prowadzić do przemęczenia. Zwróć uwagę na zdrowie nerek i pleców.';
      case 'skorpion':
        return 'Nadchodzący miesiąc będzie dla Ciebie czasem intensywnych transformacji i odkrywania głębszych warstw zarówno w sobie, jak i w relacjach z innymi. Twoja przenikliwość i intuicja będą szczególnie wyostrzone, co pomoże Ci podejmować strategiczne decyzje zawodowe. W pierwszej połowie miesiąca możesz odczuwać silną potrzebę zmiany lub odnowienia - warto wsłuchać się w ten wewnętrzny głos. Finanse mogą przejść pozytywną metamorfozę dzięki nieoczekiwanym źródłom dochodu lub spłacie dawnych należności. W życiu uczuciowym czeka Cię okres namiętności i głębokich, transformujących doświadczeń. Samotne Skorpiony mogą przyciągnąć osobę o magnetycznej osobowości. Zadbaj o zdrowie emocjonalne poprzez praktyki uważności i świadome przepracowywanie dawnych traum.';
      case 'strzelec':
        return 'Ten miesiąc będzie dla Ciebie czasem ekspansji horyzontów i poszukiwania nowych możliwości rozwoju. Twój naturalny optymizm i entuzjazm przyciągną do Ciebie inspirujące osoby i sytuacje. W pierwszej dekadzie miesiąca możliwa jest podróż lub kontakt z odległą kulturą, który poszerzy Twoje perspektywy. W sferze zawodowej pojawią się szanse na awans lub zmianę pracy na bardziej satysfakcjonującą. Finanse będą sprzyjające, choć warto zachować ostrożność przy inwestycjach wysokiego ryzyka. W życiu osobistym nastąpi ożywienie - nowe znajomości i wspólne doświadczenia wzbogacą Twoje życie. Osoby w związkach mogą zaplanować wspólną przygodę lub podróż. Zadbaj o zdrowie, szczególnie o wątrobę i biodra - unikaj nadmiaru i praktykuj umiar we wszystkim.';
      default:
        return 'Nadchodzący miesiąc przyniesie Ci wiele możliwości rozwoju osobistego i zawodowego. Gwiazdy układają się w sposób sprzyjający Twojemu znakowi, co pomoże Ci w realizacji długoterminowych planów. W połowie miesiąca możesz spodziewać się niespodziewanego wydarzenia, które otworzy przed Tobą nowe drzwi. Relacje międzyludzkie będą intensywne, ale satysfakcjonujące - poświęć czas na pogłębienie więzi z bliskimi osobami. W kwestiach finansowych zachowaj ostrożność i unikaj pochopnych decyzji. Twoje zdrowie będzie stabilne, ale pamiętaj o regularnym odpoczynku i regeneracji. Końcówka miesiąca sprzyja refleksji i planowaniu przyszłości.';
    }
  }

  String _getLunarMonthlyDescription() {
    // Lunar calendar monthly influence description for the zodiac sign
    return 'W tym miesiącu fazy Księżyca będą miały szczególny wpływ na Twój znak. Nów (8-go) to idealny czas na wyznaczanie nowych celów i rozpoczynanie projektów. Pierwsza kwadra (15-go) sprzyja przezwyciężaniu przeszkód i podejmowaniu decyzji. Pełnia (22-go) przyniesie kulminację energii - warto wtedy celebrować osiągnięcia i dostrzegać pełny obraz sytuacji. Ostatnia kwadra (29-go) to czas na refleksję i zamknięcie spraw przed nowym cyklem.';
  }
}

class DetailedMonthlyHoroscopeScreen extends StatelessWidget {
  final String zodiacSign;
  final DateTime startDate;
  final DateTime endDate;

  const DetailedMonthlyHoroscopeScreen({
    Key? key,
    required this.zodiacSign,
    required this.startDate,
    required this.endDate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Initialize date formatting for Polish locale to be safe
    initializeDateFormatting('pl_PL', null);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Szczegółowy Horoskop Miesięczny',
          style: GoogleFonts.cinzelDecorative(
            fontSize: 20,
            color: AppColors.cyan,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.cyan),
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF0F0E1C),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Zodiac sign header
            _buildZodiacHeader(),

            const SizedBox(height: 24),

            // Detailed horoscope text
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.purple.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    _getDetailedHoroscope(),
                    style: AppTextStyles.fortuneText.copyWith(
                      fontSize: 16,
                      color: Colors.white,
                      height: 1.8,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Navigation buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate to the previous month
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => DetailedMonthlyHoroscopeScreen(
                            zodiacSign: zodiacSign,
                            startDate: DateTime(
                                startDate.year, startDate.month - 1, 1),
                            endDate:
                                DateTime(startDate.year, startDate.month, 0),
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Poprzedni Miesiąc',
                      style: GoogleFonts.cinzelDecorative(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate to the next month
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => DetailedMonthlyHoroscopeScreen(
                            zodiacSign: zodiacSign,
                            startDate: DateTime(
                                startDate.year, startDate.month + 1, 1),
                            endDate: DateTime(
                                startDate.year, startDate.month + 2, 0),
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Następny Miesiąc',
                      style: GoogleFonts.cinzelDecorative(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZodiacHeader() {
    // Get the zodiac emoji based on the zodiac sign
    final String zodiacEmoji = _getZodiacEmoji(zodiacSign);

    // Format month name with proper locale handling
    String monthName;
    try {
      monthName = DateFormat('MMMM', 'pl_PL').format(startDate);
      monthName = monthName[0].toUpperCase() + monthName.substring(1);
    } catch (e) {
      // Fallback if there's an error
      monthName = DateFormat('MMMM').format(startDate);
    }

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
      child: Row(
        children: [
          // Zodiac symbol
          Container(
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

          const SizedBox(width: 20),

          // Zodiac sign and date range
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Znak zodiaku:',
                  style: GoogleFonts.cinzelDecorative(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 4),
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
                  '$monthName ${startDate.year}',
                  style: AppTextStyles.fortuneText.copyWith(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to get zodiac emoji
  String _getZodiacEmoji(String sign) {
    switch (sign.toLowerCase()) {
      case 'koziorożec':
        return '♑';
      case 'wodnik':
        return '♒';
      case 'ryby':
        return '♓';
      case 'baran':
        return '♈';
      case 'byk':
        return '♉';
      case 'bliźnięta':
        return '♊';
      case 'rak':
        return '♋';
      case 'lew':
        return '♌';
      case 'panna':
        return '♍';
      case 'waga':
        return '♎';
      case 'skorpion':
        return '♏';
      case 'strzelec':
        return '♐';
      default:
        return '⭐';
    }
  }

  String _getDetailedHoroscope() {
    String monthName = DateFormat('MMMM', 'pl_PL').format(startDate);
    monthName = monthName[0].toUpperCase() + monthName.substring(1);

    // Return detailed horoscope based on zodiac sign and date range - this is a longer, more comprehensive version
    return '''Szczegółowy horoskop dla znaku $zodiacSign na miesiąc $monthName ${startDate.year}

Ogólny zarys miesiąca:
Ten miesiąc przyniesie Ci wyjątkową możliwość dostrzeżenia szerszej perspektywy w sprawach, które od dawna zaprzątały Twoją uwagę. Gwiazdy sprzyjają refleksji i podejmowaniu przemyślanych decyzji, które zaowocują w przyszłości. Układ planet wzmacnia Twoją naturalną intuicję - warto jej zaufać, szczególnie w drugiej połowie miesiąca. Pojawi się okazja do zamknięcia pewnego rozdziału w Twoim życiu i otwarcia się na nowe możliwości.

Kariera i finanse:
W sferze zawodowej czeka Cię stabilizacja i stopniowy rozwój. Pierwsza dekada miesiąca będzie sprzyjać planowaniu długoterminowych strategii i nawiązywaniu wartościowych kontaktów biznesowych. Około połowy miesiąca możesz otrzymać propozycję, która początkowo wyda Ci się ryzykowna, ale warto ją dokładnie rozważyć - może przynieść nieoczekiwane korzyści. W kwestiach finansowych zachowaj ostrożność, szczególnie między 15 a 20 dniem miesiąca. To dobry czas na rewizję budżetu i eliminację zbędnych wydatków. Końcówka miesiąca może przynieść dodatkowe źródło dochodu.

Miłość i relacje:
W życiu uczuciowym czeka Cię czas pogłębiania relacji i budowania trwałych więzi. Osoby w związkach doświadczą nowego poziomu zrozumienia i bliskości, szczególnie jeśli poświęcą czas na szczere rozmowy o wspólnej przyszłości. Single mają szansę na spotkanie osoby, która podziela ich wartości i aspiracje - szczególnie sprzyjający będzie okres między 10 a 20 dniem miesiąca. W relacjach rodzinnych może pojawić się napięcie związane z dawnym nieporozumieniem - szczerość i empatia pomogą rozwiązać ten problem.

Zdrowie i energia:
Twoje samopoczucie będzie dobre, choć możesz odczuwać wahania energii, szczególnie w pierwszej połowie miesiąca. Zadbaj o regularny odpoczynek i zdrowy sen - to podstawa Twojej witalności. Układ planet sprzyja rozpoczęciu nowych praktyk zdrowotnych, szczególnie związanych z aktywnością fizyczną na świeżym powietrzu. Druga połowa miesiąca to dobry czas na detoks i oczyszczenie organizmu. Zwróć szczególną uwagę na sygnały, które wysyła Ci ciało - mogą zawierać ważne informacje o Twoich potrzebach.

Rozwój osobisty:
Ten miesiąc stwarza doskonałe warunki do inwestowania w swój rozwój osobisty i duchowy. Medytacja, praktyki uważności czy lektura inspirujących książek przyniosą Ci wiele korzyści. Około 20 dnia miesiąca możesz doświadczyć ważnego olśnienia lub odkrycia, które zmieni Twoją perspektywę. To również dobry czas na przewartościowanie priorytetów i zastanowienie się nad kierunkiem, w którym zmierza Twoje życie.

Szczęśliwe dni: 5, 14, 23
Dni wymagające uważności: 8, 17, 26
''';
  }
}
