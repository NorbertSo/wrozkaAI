// lib/screens/horoskoptygodniowy.dart
// 📅 NAPRAWIONY EKRAN HOROSKOPU TYGODNIOWEGO
// ✅ Rozwiązane problemy: UI overflow, locale initialization, poprawne pobieranie danych
// Zgodny z wytycznymi projektu AI Wróżka

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

class HoroskopTygodniowyScreen extends StatefulWidget {
  final String userName;
  final String zodiacSign;
  final String zodiacEmoji;

  const HoroskopTygodniowyScreen({
    Key? key,
    required this.userName,
    required this.zodiacSign,
    required this.zodiacEmoji,
  }) : super(key: key);

  @override
  State<HoroskopTygodniowyScreen> createState() =>
      _HoroskopTygodniowyScreenState();
}

class _HoroskopTygodniowyScreenState extends State<HoroskopTygodniowyScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  
  // ✅ Zgodnie z wytycznymi
  final HapticService _hapticService = HapticService();
  final HoroscopeService _horoscopeService = HoroscopeService();
  final LoggingService _logger = LoggingService();
  
  // Stan ekranu
  HoroscopeData? _weeklyHoroscope;
  bool _isLoading = true;
  bool _hasError = false;

  // Daty dla horoskopu tygodniowego
  late DateTime _startDate;
  late DateTime _endDate;
  late DateTime _creationDate;
  late DateTime _nextUpdateDate;

  @override
  void initState() {
    super.initState();
    
    // ✅ NAPRAWKA: Inicjalizacja lokalizacji
    _initializeLocale();
    
    _logger.logToConsole('Inicjalizacja HoroskopTygodniowyScreen dla ${widget.zodiacSign}',
        tag: 'WEEKLY_HOROSCOPE');

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

    // Oblicz daty
    _calculateDates();

    // Załaduj dane tygodniowe
    _initializeWeeklyData();
  }

  /// ✅ NAPRAWKA: Bezpieczna inicjalizacja lokalizacji
  Future<void> _initializeLocale() async {
    try {
      await initializeDateFormatting('pl_PL');
    } catch (e) {
      _logger.logToConsole('⚠️ Błąd inicjalizacji lokalizacji: $e', tag: 'WEEKLY_HOROSCOPE');
      // Kontynuuj bez polskiej lokalizacji
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// 🗓️ Oblicz daty tygodnia
  void _calculateDates() {
    final now = DateTime.now();

    // Znajdź poniedziałek tego tygodnia
    final int weekday = now.weekday;
    final DateTime monday = now.subtract(Duration(days: weekday - 1));

    // Ustaw datę rozpoczęcia (poniedziałek) i zakończenia (niedziela)
    _startDate = DateTime(monday.year, monday.month, monday.day);
    _endDate = _startDate.add(const Duration(days: 6));

    // Data utworzenia to poniedziałek
    _creationDate = _startDate;

    // Następna aktualizacja to kolejny poniedziałek
    _nextUpdateDate = _startDate.add(const Duration(days: 7));

    _logger.logToConsole(
        'Obliczono daty tygodnia: ${DateFormat('yyyy-MM-dd').format(_startDate)} - ${DateFormat('yyyy-MM-dd').format(_endDate)}',
        tag: 'WEEKLY_HOROSCOPE');
  }

  /// 🚀 Załaduj dane tygodniowe
  Future<void> _initializeWeeklyData() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      _logger.logToConsole('Inicjalizacja serwisu horoskopów...', tag: 'WEEKLY_HOROSCOPE');
      
      final initialized = await _horoscopeService.initialize();
      if (!initialized) {
        throw Exception('Nie udało się zainicjalizować serwisu horoskopów');
      }

      // ✅ POPRAWNIE: Używamy getWeeklyHoroscope
      final zodiacSignEn = _getZodiacSignFromName(widget.zodiacSign);
      _logger.logToConsole('Pobieranie horoskopu tygodniowego dla: $zodiacSignEn', 
          tag: 'WEEKLY_HOROSCOPE');

      final horoscope = await _horoscopeService.getWeeklyHoroscope(
        zodiacSignEn,
        date: _startDate,
      );

      if (mounted) {
        setState(() {
          _weeklyHoroscope = horoscope;
          _isLoading = false;
          _hasError = horoscope == null;
        });

        if (horoscope != null) {
          _logger.logToConsole('✅ Pomyślnie załadowano horoskop tygodniowy', 
              tag: 'WEEKLY_HOROSCOPE');
        } else {
          _logger.logToConsole('⚠️ Nie udało się załadować horoskopu tygodniowego', 
              tag: 'WEEKLY_HOROSCOPE');
        }
      }
    } catch (e) {
      _logger.logToConsole('❌ Błąd inicjalizacji danych tygodniowych: $e', 
          tag: 'ERROR');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  /// 🔄 Odśwież horoskop
  Future<void> _refreshHoroscope() async {
    await _hapticService.trigger(HapticType.light);
    await _initializeWeeklyData();
  }

  /// 🔧 Konwertuj nazwę znaku z polskiego na angielski
  String _getZodiacSignFromName(String polishName) {
    final mapping = {
      'BARAN': 'aries',
      'BYK': 'taurus',
      'BLIŹNIĘTA': 'gemini',
      'RAK': 'cancer',
      'LEW': 'leo',
      'PANNA': 'virgo',
      'WAGA': 'libra',
      'SKORPION': 'scorpio',
      'STRZELEC': 'sagittarius',
      'KOZIOROŻEC': 'capricorn',
      'WODNIK': 'aquarius',
      'RYBY': 'pisces',
    };

    return mapping[polishName.toUpperCase()] ?? 'aries';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Horoskop Tygodniowy',
          style: GoogleFonts.cinzelDecorative(
            fontSize: 22,
            color: AppColors.cyan,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        leading: HapticIconButton(
          icon: Icons.arrow_back_ios_new,
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
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _buildLoadingState();
    }
    
    if (_hasError || _weeklyHoroscope == null) {
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

            // Weekly Horoscope Content
            _buildWeeklyContent(),

            const SizedBox(height: 30),

            // Lunar Calendar for the week
            _buildWeeklyLunarCalendar(),

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

  /// 🔄 Stan ładowania
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            child: Lottie.asset(
              'assets/lottie/crystal_ball.json',
              repeat: true,
              errorBuilder: (context, error, stackTrace) {
                return CircularProgressIndicator(color: AppColors.cyan);
              },
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Konsultuję się z gwiazdami...',
            style: GoogleFonts.cinzelDecorative(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  /// ❌ Stan błędu
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
              'Gwiazdy są dziś niekomunikatywne...',
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
              onPressed: _refreshHoroscope,
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

        // ✅ NAPRAWKA: Bezpieczne ładowanie animacji Lottie
        _buildLottieAnimation(),
      ],
    );
  }

  /// ✅ NOWA METODA: Bezpieczne ładowanie animacji
  Widget _buildLottieAnimation() {
    try {
      return Opacity(
        opacity: 0.7,
        child: Lottie.asset(
          'assets/animations/star_bg.json',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(); // Fallback gdy brak animacji
          },
        ),
      );
    } catch (e) {
      return Container(); // Fallback gdy brak animacji
    }
  }

  Widget _buildZodiacHeader() {
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
                      style: const TextStyle(fontSize: 40),
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(width: 20),

          // ✅ NAPRAWKA: Flexible zapobiega overflow
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Twój znak zodiaku:',
                  style: GoogleFonts.cinzelDecorative(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.zodiacSign.toUpperCase(),
                  style: GoogleFonts.cinzelDecorative(
                    fontSize: 24,
                    color: AppColors.cyan,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 8),
                Text(
                  '${DateFormat('dd.MM').format(_startDate)} - ${DateFormat('dd.MM.yyyy').format(_endDate)}',
                  style: AppTextStyles.fortuneText.copyWith(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 🔮 Główny horoskop tygodniowy
  Widget _buildWeeklyContent() {
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
          // ✅ NAPRAWKA: Wrap Row in Flexible to prevent overflow
          Row(
            children: [
              Icon(
                Icons.calendar_view_week,
                color: Colors.purple,
                size: 24,
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  'Horoskop tygodniowy',
                  style: GoogleFonts.cinzelDecorative(
                    fontSize: 20,
                    color: Colors.purple,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _weeklyHoroscope?.text ?? _getWeeklyHoroscopePreview(),
            style: AppTextStyles.fortuneText.copyWith(
              fontSize: 16,
              color: Colors.white,
              height: 1.8,
            ),
          ),
          const SizedBox(height: 16),
          
          // ✅ NAPRAWKA: Bezpieczne formatowanie daty
          _buildUpdateInfo(),
        ],
      ),
    );
  }

  /// ✅ NAPRAWKA: Bezpieczne formatowanie daty
  Widget _buildUpdateInfo() {
    String nextUpdateText;
    try {
      nextUpdateText = DateFormat('d MMMM yyyy', 'pl_PL').format(_nextUpdateDate);
    } catch (e) {
      // Fallback bez polskiej lokalizacji
      nextUpdateText = DateFormat('d MMMM yyyy').format(_nextUpdateDate);
    }

    return Text(
      'Następna aktualizacja: $nextUpdateText',
      style: GoogleFonts.cinzelDecorative(
        fontSize: 12,
        color: Colors.white60,
        fontStyle: FontStyle.italic,
      ),
    );
  }

  Widget _buildWeeklyLunarCalendar() {
    // Generate the days of the current week
    final List<DateTime> weekDays = List.generate(
      7,
      (index) => _startDate.add(Duration(days: index)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Premium button for extended horoscope
        _buildPremiumButton(
          title: 'Sprawdź Rozbudowany Horoskop',
          color: Colors.deepPurple,
          icon: Icons.auto_awesome,
          onTap: () => _showPremiumDialog('rozbudowany'),
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
                'Kalendarz księżycowy na tydzień:',
                style: GoogleFonts.cinzelDecorative(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              
              // Current moon phase description
              Text(
                'Aktualna faza: ${_getCurrentMoonPhase()}',
                style: GoogleFonts.cinzelDecorative(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _getLunarCalendarShortDescription(_getCurrentMoonPhase()),
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

  Widget _buildDayMoonPhase(DateTime day, String moonPhase) {
    final isToday = day.day == DateTime.now().day &&
        day.month == DateTime.now().month &&
        day.year == DateTime.now().year;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        children: [
          // Day name
          Text(
            _getDayName(day.weekday),
            style: GoogleFonts.cinzelDecorative(
              fontSize: 12,
              color: isToday ? Colors.white : Colors.white70,
            ),
          ),
          const SizedBox(height: 4),
          // Moon phase emoji
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isToday
                  ? Colors.deepPurple.withOpacity(0.3)
                  : Colors.transparent,
              border: Border.all(
                color: isToday ? Colors.deepPurple : Colors.transparent,
                width: isToday ? 1 : 0,
              ),
            ),
            child: Center(
              child: Text(
                _getMoonPhaseEmoji(moonPhase),
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Day number
          Text(
            day.day.toString(),
            style: GoogleFonts.cinzelDecorative(
              fontSize: 12,
              fontWeight: isToday ? FontWeight.w600 : FontWeight.normal,
              color: isToday ? Colors.white : Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'Pon';
      case 2: return 'Wt';
      case 3: return 'Śr';
      case 4: return 'Czw';
      case 5: return 'Pt';
      case 6: return 'Sob';
      case 7: return 'Nd';
      default: return '';
    }
  }

  String _getMoonPhaseForDay(DateTime day) {
    // Uproszczony algorytm faz księżyca
    final int moonCycle = (day.day % 28);

    if (moonCycle < 2) return 'Nów';
    if (moonCycle < 7) return 'Przybywający sierp';
    if (moonCycle < 10) return 'Pierwsza kwadra';
    if (moonCycle < 14) return 'Przybywający garb';
    if (moonCycle < 17) return 'Pełnia';
    if (moonCycle < 21) return 'Ubywający garb';
    if (moonCycle < 24) return 'Ostatnia kwadra';
    return 'Ubywający sierp';
  }

  String _getCurrentMoonPhase() {
    final phases = [
      'Nów', 'Przybywający sierp', 'Pierwsza kwadra', 'Przybywający garb',
      'Pełnia', 'Ubywający garb', 'Ostatnia kwadra', 'Ubywający sierp'
    ];
    return phases[DateTime.now().day % phases.length];
  }

  String _getMoonPhaseEmoji(String phase) {
    switch (phase) {
      case 'Nów': return '🌑';
      case 'Przybywający sierp': return '🌒';
      case 'Pierwsza kwadra': return '🌓';
      case 'Przybywający garb': return '🌔';
      case 'Pełnia': return '🌕';
      case 'Ubywający garb': return '🌖';
      case 'Ostatnia kwadra': return '🌗';
      case 'Ubywający sierp': return '🌘';
      default: return '🌙';
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
            
            // ✅ NAPRAWKA: Flexible zamiast Expanded dla lepszej kontroli
            Flexible(
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
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Funkcja premium',
                    style: GoogleFonts.cinzelDecorative(
                      fontSize: 12,
                      color: color.withOpacity(0.7),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 8),
            
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
                child: HapticButton(
                  text: 'Rozumiem',
                  hapticType: HapticType.light,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getWeeklyHoroscopePreview() {
    // Return different content based on zodiac sign
    switch (widget.zodiacSign.toLowerCase()) {
      case 'koziorożec':
        return 'Ten tydzień przyniesie Ci możliwości rozwoju zawodowego. Początek tygodnia sprzyja planowaniu długoterminowych celów. Zwróć uwagę na swoje zdrowie - znajdź czas na odpoczynek.';
      case 'wodnik':
        return 'Twoja kreatywność osiągnie szczyt w połowie tygodnia. To dobry czas na innowacyjne projekty i nawiązywanie nowych kontaktów. Weekend przyniesie niespodziewane wieści.';
      case 'ryby':
        return 'Intuicja będzie Twoim najlepszym przewodnikiem przez cały tydzień. Możliwe duchowe olśnienia i głębokie przemyślenia. W relacjach z bliskimi czeka Cię harmonia.';
      case 'baran':
        return 'Tydzień pełen energii i nowych początków. Środa i czwartek to najlepsze dni na podejmowanie decyzji. Unikaj pochopnych działań w sprawach finansowych.';
      case 'byk':
        return 'Stabilność finansowa jest w zasięgu ręki. W pracy docenią Twoją wytrwałość. Weekend sprzyja relaksowi i przyjemnościom - nie odmawiaj sobie małych radości.';
      case 'bliźnięta':
        return 'Komunikacja będzie Twoją mocną stroną - wykorzystaj to w negocjacjach. Połowa tygodnia może przynieść drobne nieporozumienia. Niedziela to idealny czas na spotkania towarzyskie.';
      case 'rak':
        return 'Emocje mogą falować przez cały tydzień. Zadbaj o równowagę między pracą a życiem prywatnym. Bliskie relacje wymagają Twojej uwagi, szczególnie w weekend.';
      case 'lew':
        return 'Twój blask przyciągnie uwagę innych. Idealny czas na prezentowanie swoich pomysłów i projektów. Weekend sprzyja romantycznym chwilom i kreatywnym zajęciom.';
      case 'panna':
        return 'Tydzień sprzyjający porządkowaniu spraw i analizie. Zwróć uwagę na szczegóły w dokumentach. Piątek może przynieść niespodziewane rozwiązanie długotrwałego problemu.';
      case 'waga':
        return 'Harmonijne relacje będą kluczowe w tym tygodniu. Możliwe ważne decyzje dotyczące partnerstwa. Weekend poświęć na odnowienie równowagi wewnętrznej.';
      case 'skorpion':
        return 'Intensywny tydzień pełen transformacji. Możliwe odkrycia i głębokie przemyślenia. W pracy docenią Twoją strategiczną wizję. Niedziela to czas regeneracji.';
      case 'strzelec':
        return 'Optymizm i energia będą Ci towarzyszyć. Możliwa podróż lub nowe inspirujące znajomości. Końcówka tygodnia sprzyja poszerzaniu horyzontów i nauce.';
      default:
        return 'Ten tydzień przyniesie Ci nowe możliwości i wyzwania. Gwiazdy układają się w sposób sprzyjający Twojemu znakowi. Zwróć uwagę na sygnały, które wysyła Ci Wszechświat.';
    }
  }

  String _getLunarCalendarShortDescription(String phase) {
    switch (phase) {
      case 'Nów':
        return 'Czas nowych początków i planowania. Energia sprzyja wyciszeniu i refleksji. Dobry moment na wyznaczanie celów i intencji.';
      case 'Przybywający sierp':
        return 'Okres wzrostu energii i realizacji planów. Sprzyjający czas na początek nowych projektów. Twoja siła woli rośnie z każdym dniem.';
      case 'Pierwsza kwadra':
        return 'Moment działania i przezwyciężania przeszkód. Energia sprzyja podejmowaniu decyzji. Nie wahaj się realizować swoich zamierzeń.';
      case 'Przybywający garb':
        return 'Czas intensywnego rozwoju i transformacji. Sprzyjający okres dla kreatywności. Twoje pomysły zyskują siłę i klarowność.';
      case 'Pełnia':
        return 'Kulminacja energii, emocje są na powierzchni. Idealny czas na celebrowanie osiągnięć. Możesz dostrzec pełny obraz swoich działań.';
      case 'Ubywający garb':
        return 'Okres wdzięczności i dzielenia się z innymi. Dobry czas na działalność społeczną. Zadbaj o równowagę w relacjach.';
      case 'Ostatnia kwadra':
        return 'Moment rozliczenia i odpuszczania. Energia sprzyja podsumowaniom. Przygotuj się na nowy cykl i zamknij niedokończone sprawy.';
      case 'Ubywający sierp':
        return 'Czas wyciszenia i regeneracji. Sprzyjający okres dla odpoczynku i medytacji. Słuchaj swojej intuicji i zbieraj siły na nowy cykl.';
      default:
        return 'Fazy Księżyca wpływają na nasze emocje i energię. Świadome życie w zgodzie z cyklem księżycowym pomaga osiągnąć harmonię. Każda faza przynosi inne możliwości.';
    }
  }

  // ✅ DODAJ BRAKUJĄCĄ METODĘ: Helper method to get zodiac emoji
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
}

class DetailedWeeklyHoroscopeScreen extends StatelessWidget {
  final String zodiacSign;
  final DateTime startDate;
  final DateTime endDate;

  const DetailedWeeklyHoroscopeScreen({
    Key? key,
    required this.zodiacSign,
    required this.startDate,
    required this.endDate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Szczegółowy Horoskop Tygodniowy',
          style: GoogleFonts.cinzelDecorative(
            fontSize: 22,
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
              children: [
                Flexible(
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate to the previous week
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => DetailedWeeklyHoroscopeScreen(
                            zodiacSign: zodiacSign,
                            startDate:
                                startDate.subtract(const Duration(days: 7)),
                            endDate: endDate.subtract(const Duration(days: 7)),
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
                      'Poprzedni Tydzień',
                      style: GoogleFonts.cinzelDecorative(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Flexible(
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate to the next week
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => DetailedWeeklyHoroscopeScreen(
                            zodiacSign: zodiacSign,
                            startDate: startDate.add(const Duration(days: 7)),
                            endDate: endDate.add(const Duration(days: 7)),
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
                      'Następny Tydzień',
                      style: GoogleFonts.cinzelDecorative(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
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

          // ✅ NAPRAWKA: Flexible zamiast Expanded
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Znak zodiaku:',
                  style: GoogleFonts.cinzelDecorative(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 4),
                Text(
                  zodiacSign.toUpperCase(),
                  style: GoogleFonts.cinzelDecorative(
                    fontSize: 24,
                    color: AppColors.cyan,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 8),
                Text(
                  '${DateFormat('dd.MM').format(startDate)} - ${DateFormat('dd.MM.yyyy').format(endDate)}',
                  style: AppTextStyles.fortuneText.copyWith(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
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
    // Return detailed horoscope based on zodiac sign and date range
    // For simplicity, using static text. This can be expanded to fetch from a service.
    return 'Szczegółowy horoskop dla znaku $zodiacSign na okres od ${DateFormat('dd.MM.yyyy').format(startDate)} do ${DateFormat('dd.MM.yyyy').format(endDate)}. \n\n' +
        'Ogólne: Ten tydzień przyniesie wiele możliwości rozwoju osobistego i zawodowego. Gwiazdy sprzyjają podejmowaniu nowych wyzwań oraz nawiązywaniu cennych kontaktów. ' +
        'Zadbaj o równowagę między pracą a życiem prywatnym. \n\n' +
        'Miłość: W relacjach uczuciowych zapanować może harmonia i zrozumienie. To dobry czas na wspólne chwile i szczerą rozmowę. ' +
        'Single mogą liczyć na interesujące znajomości. \n\n' +
        'Zdrowie: Twoje samopoczucie będzie stabilne, jednak warto zadbać o chwilę relaksu i odpoczynku. Nie ignoruj sygnałów, które wysyła Ci organizm.';
  }
}