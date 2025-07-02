import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;
import 'dart:math';
import '../utils/constants.dart' as constants;
import '../models/user_data.dart';
import '../services/fortune_history_service.dart';
import '../services/user_preferences_service.dart';
import '../services/haptic_service.dart';
import '../services/horoscope_service.dart';
import '../widgets/haptic_button.dart';
import '../widgets/candle_counter_widget.dart';
import '../widgets/candle_balance_display.dart';
import 'palm_intro_screen.dart';
import 'fortune_history_screen.dart';
import 'user_data_screen.dart';
import 'horoskopmenu.dart';
import 'horoskopmiesieczny.dart';
import 'onboarding/music_selection_screen.dart';
import '../utils/logger.dart';
import '../utils/app_colors.dart' as app_colors;

class MainMenuScreen extends StatefulWidget {
  final String userName;
  final String userGender;
  final String? dominantHand;
  final DateTime? birthDate;

  const MainMenuScreen({
    super.key,
    required this.userName,
    required this.userGender,
    this.dominantHand,
    this.birthDate,
  });

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen>
    with TickerProviderStateMixin {
  final HapticService _hapticService = HapticService();
  final FortuneHistoryService _historyService = FortuneHistoryService();

  // Tab Controller
  late TabController _tabController;

  // Data fields
  String _userName = '';
  String _userGender = '';
  String? _dominantHand;
  DateTime? _birthDate;

  // State
  int _fortuneCount = 0;

  // ✅ DODAJ HOROSCOPE DATA
  String _currentMoonPhase = '';
  List<int> _luckyNumbers = [];
  bool _isLoadingHoroscope = true;

  // Animations
  late AnimationController _pulseController;
  late AnimationController _starController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _starAnimation;

  // Testowa liczba świec
  int _candlesCount = 5; // TODO: zsynchronizuj z backendem lub innym ekranem

  @override
  void initState() {
    super.initState();
    _userName = widget.userName;
    _userGender = widget.userGender;
    _dominantHand = widget.dominantHand;
    _birthDate = widget.birthDate;

    _tabController = TabController(length: 4, vsync: this);
    _initializeAnimations();
    _loadFortuneCount();
    _loadHoroscopeData(); // ✅ DODAJ ŁADOWANIE DANYCH HOROSKOPU
  }

  // ✅ NOWA METODA - ładuj dane z horoskopu
  Future<void> _loadHoroscopeData() async {
    try {
      setState(() {
        _isLoadingHoroscope = true;
      });

      final horoscopeService = HoroscopeService();
      await horoscopeService.initialize();

      // Pobierz horoskop dla znaku użytkownika lub domyślny
      String? zodiacSign;
      if (_birthDate != null) {
        zodiacSign = getZodiacSign(_birthDate!);
      }

      final horoscope = await horoscopeService.getDailyHoroscope(
        zodiacSign ?? 'aries',
        date: DateTime.now(),
      );

      // ✅ POPRAWKA: Bezpieczny dostęp do danych horoskopu
      String moonPhase = '';
      String horoscopeText = '';
      int luckyNumber = 0;

      if (horoscope != null) {
        // ✅ Bezpieczny dostęp do właściwości z null safety
        try {
          moonPhase = horoscope.moonPhase ?? '';
          horoscopeText = horoscope.text ?? '';
        } catch (e) {
          debugPrint('⚠️ Błąd dostępu do właściwości horoskopu: $e');
          moonPhase = '';
          horoscopeText = '';
        }
      }

      // Fallback: oblicz fazę księżyca bezpośrednio jeśli brak danych
      if (moonPhase.isEmpty) {
        moonPhase = horoscopeService.calculateMoonPhase(DateTime.now());
      }

      // ✅ POPRAWKA: Bezpieczne pobieranie z Firebase
      try {
        final dateString = DateFormat('yyyy-MM-dd').format(DateTime.now());
        final docSnapshot = await FirebaseFirestore.instance
            .collection('horoscopes')
            .doc(dateString)
            .get();

        if (docSnapshot.exists) {
          final data = docSnapshot.data() ?? {};

          // ✅ TERAZ - pobiera JEDNĄ liczbę z Firebase:
          if (zodiacSign != null) {
            final signKey = zodiacSign.toLowerCase();
            if (data.containsKey(signKey)) {
              final signData = data[signKey] as Map<String, dynamic>? ?? {};
              if (signData.containsKey('luckyNumber')) {
                luckyNumber = signData['luckyNumber'] ?? 0;
              }
            }
          }

          if (data.containsKey('lunar')) {
            final lunarData = data['lunar'] as Map<String, dynamic>? ?? {};
            final firebaseMoonPhase = lunarData['moonPhase'] as String?;
            if (firebaseMoonPhase != null && firebaseMoonPhase.isNotEmpty) {
              moonPhase = firebaseMoonPhase;
            }
          }
        }
      } catch (e) {
        debugPrint('⚠️ Nie udało się pobrać lunar data z Firebase: $e');
        // Kontynuuj z lokalnie obliczoną fazą księżyca
      }

      if (mounted) {
        setState(() {
          // Ustaw fazę księżyca
          _currentMoonPhase =
              moonPhase.isNotEmpty ? moonPhase : _calculateSimpleMoonPhase();

          // ✅ Wyświetla jako pojedyncza liczba:
          _luckyNumbers =
              luckyNumber > 0 ? [luckyNumber] : [Random().nextInt(99) + 1];

          _isLoadingHoroscope = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Błąd ładowania danych horoskopu: $e');
      if (mounted) {
        setState(() {
          _currentMoonPhase = _calculateSimpleMoonPhase();
          _luckyNumbers = [Random().nextInt(99) + 1];
          _isLoadingHoroscope = false;
        });
      }
    }
  }

  // ✅ HELPER - wyciągnij szczęśliwe liczby z tekstu horoskopu (POPRAWIONE)
  List<int> _extractLuckyNumbersFromText(String text) {
    final numbers = <int>[];

    // ✅ NAJPIERW: Szukaj konkretnych fraz o szczęśliwych liczbach
    final luckyNumberPatterns = [
      RegExp(r'szczęśliw[a-ząęćłńóśźż]*\s+liczb[a-ząęćłńóśźż]*:?\s*(\d{1,2})',
          caseSensitive: false),
      RegExp(r'liczb[a-ząęćłńóśźż]*:?\s*(\d{1,2})', caseSensitive: false),
      RegExp(r'number:?\s*(\d{1,2})', caseSensitive: false),
    ];

    for (final pattern in luckyNumberPatterns) {
      final matches = pattern.allMatches(text);
      for (final match in matches) {
        final number = int.tryParse(match.group(1) ?? '');
        if (number != null && number >= 1 && number <= 99) {
          numbers.add(number);
          debugPrint('✅ Znaleziono szczęśliwą liczbę: $number');
        }
      }
    }

    // ✅ JEŚLI ZNALEZIONO - zwróć tylko te konkretne
    if (numbers.isNotEmpty) {
      return numbers.take(3).toList();
    }

    // ✅ FALLBACK: Jeśli nie ma explicite szczęśliwych liczb, wygeneruj losowe
    debugPrint(
        '⚠️ Nie znaleziono szczęśliwych liczb w tekście, generuję losowe');
    return _generateRandomLuckyNumbers();
  }

  // ✅ HELPER - wygeneruj losowe szczęśliwe liczby (BEZ POWTÓRZEŃ)
  List<int> _generateRandomLuckyNumbers() {
    final random = Random();
    return [random.nextInt(99) + 1]; // ✅ Tylko jedna liczba
  }

  // ✅ HELPER - prosta kalkulacja fazy księżyca (fallback)
  String _calculateSimpleMoonPhase() {
    final now = DateTime.now();
    final daysSinceNewMoon =
        now.difference(DateTime(2000, 1, 6)).inDays % 29.53;

    if (daysSinceNewMoon < 7.4) return 'Nów Księżyca';
    if (daysSinceNewMoon < 14.8) return 'Pierwsza Kwadra';
    if (daysSinceNewMoon < 22.1) return 'Pełnia';
    return 'Ostatnia Kwadra';
  }

  // ✅ HELPER - pobierz emoji dla fazy księżyca
  String _getMoonPhaseEmoji(String moonPhase) {
    switch (moonPhase.toLowerCase()) {
      case 'nów księżyca':
      case 'new moon':
        return '🌑';
      case 'przybywający sierp':
      case 'waxing crescent':
        return '🌒';
      case 'pierwsza kwadra':
      case 'first quarter':
        return '🌓';
      case 'przybywający garb':
      case 'waxing gibbous':
        return '🌔';
      case 'pełnia':
      case 'full moon':
        return '🌕';
      case 'ubywający garb':
      case 'waning gibbous':
        return '🌖';
      case 'ostatnia kwadra':
      case 'last quarter':
        return '🌗';
      case 'ubywający sierp':
      case 'waning crescent':
        return '🌘';
      default:
        return '🌙';
    }
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _starController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _starAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _starController, curve: Curves.linear),
    );
  }

  Future<void> _loadFortuneCount() async {
    try {
      final count = await _historyService.getFortuneCount();
      if (mounted) {
        setState(() {
          _fortuneCount = count;
        });
      }
    } catch (e) {
      debugPrint('Błąd ładowania liczby wróżb: $e');
    }
  }

  @override
  void dispose() {
    // ✅ PROPER CLEANUP - zapobiega memory leaks
    try {
      _tabController.dispose();
    } catch (e) {
      debugPrint('Error disposing _tabController: $e');
    }

    try {
      _pulseController.dispose();
    } catch (e) {
      debugPrint('Error disposing _pulseController: $e');
    }

    try {
      _starController.dispose();
    } catch (e) {
      debugPrint('Error disposing _starController: $e');
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    try {
      return Scaffold(
        // Usuń AppBar całkowicie
        // appBar: AppBar(
        //   backgroundColor: Colors.transparent,
        //   elevation: 0,
        //   actions: [],
        // ),
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            _buildAnimatedBackground(),
            SafeArea(
              child: Column(
                children: [
                  // Usuń CandleBalanceDisplay z tego miejsca
                  // _buildHeader już będzie zawierał ikonę świec
                  _buildHeader(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildTodayTab(),
                        _buildExploreTab(),
                        _buildProfileTab(),
                        _buildCommunityTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: _buildTabBar(),
      );
    } catch (error, stackTrace) {
      debugPrint('❌ MainMenuScreen Error: $error');
      debugPrint('Stack trace: $stackTrace');
      return _buildErrorFallback();
    }
  }

  // ✅ FALLBACK WIDGET gdy coś się zepsuje
  Widget _buildErrorFallback() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                'Ups! Coś poszło nie tak',
                style: GoogleFonts.cinzelDecorative(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Uruchom aplikację ponownie',
                style: GoogleFonts.cinzelDecorative(
                  fontSize: 14,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Restart app
                  SystemNavigator.pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Zamknij aplikację'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.8,
              colors: [
                Color(0xFF0D1B2A),
                Color(0xFF1B263B),
                Color(0xFF000000),
              ],
            ),
          ),
        ),
        // ✅ WYŁĄCZONA LOTTIE ANIMACJA (może powodować crash)
        /*
        SizedBox.expand(
          child: Lottie.asset(
            'assets/animations/star_bg.json',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
        */
        AnimatedBuilder(
          animation: _starAnimation,
          builder: (context, child) {
            return CustomPaint(
              painter: MenuBackgroundPainter(_starAnimation.value),
              size: Size.infinite,
            );
          },
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      constraints: const BoxConstraints(minHeight: 56, maxHeight: 64),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Search Button
          Container(
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () async {
                await _hapticService.trigger(HapticType.light);
                _showSearchDialog();
              },
              icon: Icon(Icons.search, color: app_colors.AppColors.cyan),
              iconSize: 24,
              padding: const EdgeInsets.all(0),
              constraints: const BoxConstraints(),
            ),
          ),
          const SizedBox(width: 8),

          // App Title (centered, but with space for candles)
          Expanded(
            child: Center(
              child: Text(
                'AI Wróżka',
                style: GoogleFonts.cinzelDecorative(
                  fontSize: 20,
                  color: app_colors.AppColors.cyan,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          // Ikona świec po prawej stronie, powiększona i z paddingiem
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: SizedBox(
              width: 72, // zwiększ szerokość
              height: 40, // zwiększ wysokość
              child: Center(
                child: CandleBalanceDisplay(),
                // Usuń: iconSize: 32, // jeśli widget obsługuje ten parametr
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.9),
            Colors.black,
          ],
        ),
        border: Border(
          top: BorderSide(
            color: app_colors.AppColors.cyan.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: app_colors.AppColors.cyan,
        indicatorWeight: 3,
        labelColor: app_colors.AppColors.cyan,
        unselectedLabelColor: Colors.white54,
        labelStyle: GoogleFonts.cinzelDecorative(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: GoogleFonts.cinzelDecorative(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        onTap: (index) async {
          await _hapticService.trigger(HapticType.selection);
        },
        tabs: const [
          Tab(icon: Icon(Icons.today), text: 'Dziś'),
          Tab(icon: Icon(Icons.explore), text: 'Eksploruj'),
          Tab(icon: Icon(Icons.person), text: 'Ja'),
          Tab(icon: Icon(Icons.people), text: 'Social'),
        ],
      ),
    );
  }

  // ==================== TAB 1: DZIŚ ====================
  Widget _buildTodayTab() {
    String? zodiacSign;
    String zodiacEmoji = '⭐';

    if (_birthDate != null) {
      zodiacSign = getZodiacSign(_birthDate!);
      zodiacEmoji = getZodiacEmoji(zodiacSign);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Header
          _buildWelcomeCard(),

          const SizedBox(height: 16), // Zmniejszone z 20

          // Daily Horoscope (Main Feature)
          _buildDailyHoroscope(zodiacSign, zodiacEmoji),

          const SizedBox(height: 12), // Zmniejszone z 16

          // Tarot Card of the Day
          _buildTarotCardOfDay(),

          const SizedBox(height: 12), // Zmniejszone z 16

          // Moon Phase
          _buildMoonPhase(),

          const SizedBox(height: 12), // Zmniejszone z 16

          // Lucky Numbers
          _buildLuckyNumbers(),

          const SizedBox(height: 12), // Zmniejszone z 16

          // Quick Ritual
          _buildQuickRitual(),

          const SizedBox(height: 80), // ✅ Dodaj bottom padding dla tab bar
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.black.withOpacity(0.8),
            Colors.black.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: app_colors.AppColors.cyan.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: const Icon(
                  Icons.auto_awesome,
                  color: app_colors.AppColors.cyan,
                  size: 32,
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Text(
            'Witaj $_userName!',
            style: GoogleFonts.cinzelDecorative(
              fontSize: 18,
              color: app_colors.AppColors.cyan,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Odkryj co przyniesie Ci ten dzień',
            style: GoogleFonts.cinzelDecorative(
              fontSize: 14,
              color: Colors.white70,
              fontWeight: FontWeight.w300,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDailyHoroscope(String? zodiacSign, String zodiacEmoji) {
    return GestureDetector(
      onTap: () => _navigateToHoroscopeMenu(zodiacSign),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.purple.withOpacity(0.3),
              Colors.purple.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.purple.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.purple.withOpacity(0.4),
                    Colors.purple.withOpacity(0.1),
                  ],
                ),
              ),
              child: Center(
                child: Text(
                  zodiacEmoji,
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
                    'Horoskop Dzienny',
                    style: GoogleFonts.cinzelDecorative(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    zodiacSign != null
                        ? 'Twój znak: $zodiacSign'
                        : 'Sprawdź swoją przepowiednię',
                    style: GoogleFonts.cinzelDecorative(
                      fontSize: 14,
                      color: Colors.white70,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.purple.withOpacity(0.7),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTarotCardOfDay() {
    return _buildFeatureCard(
      title: 'Karta Dnia',
      subtitle: 'Mistyczna przepowiednia',
      icon: Icons.style_outlined,
      color: Colors.deepOrange,
      isAvailable: false,
      onTap: () => _showComingSoon('Karta Tarota dnia'),
    );
  }

  Widget _buildMoonPhase() {
    final moonIcon = _getMoonPhaseEmoji(_currentMoonPhase);

    return GestureDetector(
      onTap: () => _showComingSoon('Kalendarz Lunarny'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.amber.withOpacity(0.3),
              Colors.amber.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.amber.withOpacity(0.4),
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
                gradient: RadialGradient(
                  colors: [
                    Colors.amber.withOpacity(0.3),
                    Colors.amber.withOpacity(0.1),
                  ],
                ),
                border: Border.all(
                  color: Colors.amber.withOpacity(0.6),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  moonIcon,
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
                    'Faza Księżyca',
                    style: GoogleFonts.cinzelDecorative(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isLoadingHoroscope
                        ? 'Ładowanie...'
                        : (_currentMoonPhase.isNotEmpty
                            ? '$moonIcon $_currentMoonPhase'
                            : 'Sprawdź kalendarz lunar'),
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
              color: Colors.amber.withOpacity(0.7),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLuckyNumbers() {
    return GestureDetector(
      onTap: () => _showComingSoon('Numerologia'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.green.withOpacity(0.3),
              Colors.green.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.green.withOpacity(0.4),
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
                gradient: RadialGradient(
                  colors: [
                    Colors.green.withOpacity(0.3),
                    Colors.green.withOpacity(0.1),
                  ],
                ),
                border: Border.all(
                  color: Colors.green.withOpacity(0.6),
                  width: 1,
                ),
              ),
              child: const Center(
                child: Text(
                  '🍀',
                  style: TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Szczęśliwa Liczba',
                    style: GoogleFonts.cinzelDecorative(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isLoadingHoroscope
                        ? 'Ładowanie...'
                        : (_luckyNumbers.isNotEmpty
                            ? '🍀 ${_luckyNumbers.first}'
                            : 'Sprawdź numerologię'),
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
              color: Colors.green.withOpacity(0.7),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickRitual() {
    return _buildFeatureCard(
      title: 'Szybki Rytuał',
      subtitle: '2-minutowa medytacja',
      icon: Icons.spa_outlined,
      color: Colors.teal,
      isAvailable: false,
      onTap: () => _showComingSoon('Rytuały'),
    );
  }

  // ==================== TAB 2: EKSPLORUJ ====================
  Widget _buildExploreTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Odkryj Swoje Przeznaczenie',
            style: GoogleFonts.cinzelDecorative(
              fontSize: 22,
              color: app_colors.AppColors.cyan,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16), // Zmniejszone z 20

          // Grid of features
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12, // Zmniejszone z 16
            crossAxisSpacing: 12, // Zmniejszone z 16
            childAspectRatio: 1.0, // Zwiększone z 0.85 dla lepszych proporcji
            children: [
              _buildExploreCard(
                title: 'Palmistyka',
                subtitle: 'Analiza AI',
                icon: Icons.pan_tool_outlined,
                color: app_colors.AppColors.cyan,
                isAvailable: true,
                onTap: () => _navigateToPalmScan(),
              ),
              _buildExploreCard(
                title: 'Horoskopy',
                subtitle: 'Gwiazdy mówią',
                icon: Icons.stars,
                color: Colors.purple,
                isAvailable: true,
                onTap: () => _navigateToHoroscopeMenu(null),
              ),
              _buildExploreCard(
                title: 'Muzyka w tle',
                subtitle: 'Atmosfera dźwięków',
                icon: Icons.music_note,
                color: Colors.purple,
                isAvailable: true,
                onTap: _navigateToMusicSelection,
              ),
              _buildExploreCard(
                title: 'Tarot',
                subtitle: 'Mistyczne karty',
                icon: Icons.style_outlined,
                color: Colors.deepOrange,
                isAvailable: false,
                onTap: () => _showComingSoon('Tarot'),
              ),
              _buildExploreCard(
                title: 'Astrologia',
                subtitle: 'Mapa urodzenia',
                icon: Icons.public,
                color: Colors.indigo,
                isAvailable: false,
                onTap: () => _showComingSoon('Astrologia'),
              ),
              _buildExploreCard(
                title: 'Numerologia',
                subtitle: 'Magiczne liczby',
                icon: Icons.calculate,
                color: Colors.green,
                isAvailable: false,
                onTap: () => _showComingSoon('Numerologia'),
              ),
              _buildExploreCard(
                title: 'Kalendarz',
                subtitle: 'Cykle Księżyca',
                icon: Icons.calendar_month,
                color: Colors.amber,
                isAvailable: false,
                onTap: () => _showComingSoon('Kalendarz Lunarny'),
              ),
            ],
          ),
          const SizedBox(height: 80), // ✅ Bottom padding dla tab bar
        ],
      ),
    );
  }

  Widget _buildExploreCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isAvailable,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () async {
        await _hapticService.trigger(
          isAvailable ? HapticType.light : HapticType.selection,
        );
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isAvailable
                ? [
                    Colors.black.withOpacity(0.8),
                    Colors.black.withOpacity(0.6),
                  ]
                : [
                    Colors.grey.withOpacity(0.3),
                    Colors.grey.withOpacity(0.2),
                  ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isAvailable
                ? color.withOpacity(0.5)
                : Colors.grey.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isAvailable
                    ? color.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.2),
                border: Border.all(
                  color: isAvailable ? color : Colors.grey,
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                color: isAvailable ? color : Colors.grey,
                size: 20,
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: Text(
                title,
                style: GoogleFonts.cinzelDecorative(
                  fontSize: 14,
                  color: isAvailable ? Colors.white : Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 2),
            Flexible(
              child: Text(
                subtitle,
                style: GoogleFonts.cinzelDecorative(
                  fontSize: 11,
                  color: isAvailable ? Colors.white70 : Colors.grey,
                  fontWeight: FontWeight.w300,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!isAvailable) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: Colors.orange.withOpacity(0.8),
                ),
                child: Text(
                  'Wkrótce',
                  style: GoogleFonts.cinzelDecorative(
                    fontSize: 9,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ==================== TAB 3: JA ====================
  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mój Profil',
            style: GoogleFonts.cinzelDecorative(
              fontSize: 22,
              color: app_colors.AppColors.cyan,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),

          // Profile info
          _buildProfileInfo(),

          const SizedBox(height: 20),

          // Profile options
          _buildProfileOption(
            title: 'Moje Dane',
            subtitle: 'Zarządzaj profilem',
            icon: Icons.person_outline,
            color: Colors.orange,
            onTap: () => _navigateToUserData(),
          ),

          const SizedBox(height: 12),

          _buildProfileOption(
            title: 'Historia Wróżb',
            subtitle: _fortuneCount > 0
                ? '$_fortuneCount zapisanych wróżb'
                : 'Twoje zapisane wróżby',
            icon: Icons.history_outlined,
            color: Colors.green,
            badge: _fortuneCount > 0 ? _fortuneCount.toString() : null,
            onTap: () => _navigateToFortuneHistory(),
          ),

          const SizedBox(height: 12),

          _buildProfileOption(
            title: 'Moje Rytuały',
            subtitle: 'Personalne praktyki',
            icon: Icons.spa_outlined,
            color: Colors.teal,
            onTap: () => _showComingSoon('Moje Rytuały'),
          ),

          const SizedBox(height: 12),

          _buildProfileOption(
            title: 'Kalendarz Lunarny',
            subtitle: 'Nadchodzące wydarzenia',
            icon: Icons.calendar_month,
            color: Colors.amber,
            onTap: () => _showComingSoon('Kalendarz Lunarny'),
          ),

          const SizedBox(height: 12),

          _buildProfileOption(
            title: 'Ustawienia',
            subtitle: 'Preferencje i powiadomienia',
            icon: Icons.settings_outlined,
            color: Colors.grey,
            onTap: () => _showComingSoon('Ustawienia'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfo() {
    String? zodiacSign;
    String zodiacEmoji = '⭐';

    if (_birthDate != null) {
      zodiacSign = getZodiacSign(_birthDate!);
      zodiacEmoji = getZodiacEmoji(zodiacSign);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.black.withOpacity(0.8),
            Colors.black.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: app_colors.AppColors.cyan.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  app_colors.AppColors.cyan.withOpacity(0.3),
                  app_colors.AppColors.cyan.withOpacity(0.1),
                ],
              ),
              border: Border.all(
                color: app_colors.AppColors.cyan.withOpacity(0.5),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                zodiacEmoji,
                style: const TextStyle(fontSize: 32),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // DODAJ LICZNIK ŚWIEC
          CandleCounterWidget(candlesCount: _candlesCount, showLabel: true),
          const SizedBox(height: 12),
          Text(
            _userName,
            style: GoogleFonts.cinzelDecorative(
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (zodiacSign != null) ...[
            const SizedBox(height: 4),
            Text(
              zodiacSign,
              style: GoogleFonts.cinzelDecorative(
                fontSize: 14,
                color: app_colors.AppColors.cyan,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    String? badge,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () async {
        await _hapticService.trigger(HapticType.light);
        onTap();
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
            color: color.withOpacity(0.4),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.2),
                border: Border.all(
                  color: color.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Icon(icon, color: color, size: 20),
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
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.cinzelDecorative(
                      fontSize: 12,
                      color: Colors.white70,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            ),
            if (badge != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: color.withOpacity(0.8),
                ),
                child: Text(
                  badge,
                  style: GoogleFonts.cinzelDecorative(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Icon(
              Icons.arrow_forward_ios,
              color: color.withOpacity(0.7),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  // ==================== TAB 4: SPOŁECZNOŚĆ ====================
  Widget _buildCommunityTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Społeczność',
            style: GoogleFonts.cinzelDecorative(
              fontSize: 22,
              color: app_colors.AppColors.cyan,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          _buildFeatureCard(
            title: 'Zgodność Partnerska',
            subtitle: 'Sprawdź dopasowanie',
            icon: Icons.favorite_border,
            color: Colors.pink,
            isAvailable: false,
            onTap: () => _showComingSoon('Zgodność Partnerska'),
          ),
          const SizedBox(height: 16),
          _buildFeatureCard(
            title: 'Znajomi',
            subtitle: 'Porównaj horoskopy',
            icon: Icons.people_outline,
            color: Colors.blue,
            isAvailable: false,
            onTap: () => _showComingSoon('Znajomi'),
          ),
          const SizedBox(height: 16),
          _buildFeatureCard(
            title: 'Udostępnij Wróżbę',
            subtitle: 'Podziel się przepowiednią',
            icon: Icons.share_outlined,
            color: Colors.orange,
            isAvailable: false,
            onTap: () => _showComingSoon('Udostępnianie'),
          ),
          const SizedBox(height: 16),
          _buildFeatureCard(
            title: 'Społeczność',
            subtitle: 'Forum i dyskusje',
            icon: Icons.forum_outlined,
            color: Colors.teal,
            isAvailable: false,
            onTap: () => _showComingSoon('Forum Społeczności'),
          ),
        ],
      ),
    );
  }

  // ==================== HELPER WIDGETS ====================
  Widget _buildFeatureCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isAvailable,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () async {
        await _hapticService.trigger(
          isAvailable ? HapticType.light : HapticType.selection,
        );
        if (isAvailable) {
          onTap();
        } else {
          _showComingSoon(title);
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isAvailable
                ? [
                    Colors.black.withOpacity(0.8),
                    Colors.black.withOpacity(0.6),
                  ]
                : [
                    Colors.grey.withOpacity(0.3),
                    Colors.grey.withOpacity(0.2),
                  ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isAvailable
                ? color.withOpacity(0.4)
                : Colors.grey.withOpacity(0.3),
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
                    gradient: isAvailable
                        ? RadialGradient(
                            colors: [
                              color.withOpacity(0.3),
                              color.withOpacity(0.1),
                            ],
                          )
                        : null,
                    color: isAvailable ? null : Colors.grey.withOpacity(0.2),
                    border: Border.all(
                      color: isAvailable
                          ? color.withOpacity(0.6)
                          : Colors.grey.withOpacity(0.4),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 24,
                    color: isAvailable ? color : Colors.grey,
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
                          color: isAvailable ? Colors.white : Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.cinzelDecorative(
                          fontSize: 12,
                          color: isAvailable
                              ? Colors.white70
                              : Colors.grey.withOpacity(0.7),
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: isAvailable
                      ? color.withOpacity(0.7)
                      : Colors.grey.withOpacity(0.5),
                ),
              ],
            ),
            if (!isAvailable)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: Colors.orange.withOpacity(0.8),
                  ),
                  child: Text(
                    'Wkrótce',
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

  // ==================== NAVIGATION METHODS ====================

  void _navigateToPalmScan() async {
    await _hapticService.trigger(HapticType.success);
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            PalmIntroScreen(
          userName: _userName,
          userGender: _userGender,
          dominantHand: _dominantHand,
          birthDate: _birthDate,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 0.3),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                  parent: animation, curve: Curves.easeOutCubic)),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  void _navigateToFortuneHistory() async {
    await _hapticService.trigger(HapticType.medium);
    Navigator.of(context)
        .push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                FortuneHistoryScreen(
              userName: _userName,
              userGender: _userGender,
            ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.3, 0.0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                      parent: animation, curve: Curves.easeOutCubic)),
                  child: child,
                ),
              );
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        )
        .then((_) => _loadFortuneCount());
  }

  void _navigateToUserData() async {
    await _hapticService.trigger(HapticType.light);

    try {
      // Pobierz prawdziwe dane z SharedPreferences
      final userData = await UserPreferencesService.getUserData();

      if (userData == null) {
        debugPrint('⚠️ Brak zapisanych danych użytkownika - fallback');
        final fallbackUserData = UserData(
          name: widget.userName,
          birthDate: widget.birthDate ?? DateTime(2000, 1, 1),
          gender: widget.userGender,
          dominantHand: widget.dominantHand ?? 'right',
          registrationDate: DateTime.now(),
        );

        _navigateToUserDataScreen(fallbackUserData);
        return;
      }

      debugPrint('✅ Załadowano prawdziwe dane użytkownika: ${userData.name}');
      _navigateToUserDataScreen(userData);
    } catch (e) {
      debugPrint('❌ Błąd ładowania danych użytkownika: $e');

      final fallbackUserData = UserData(
        name: widget.userName,
        birthDate: widget.birthDate ?? DateTime(2000, 1, 1),
        gender: widget.userGender,
        dominantHand: widget.dominantHand ?? 'right',
        registrationDate: DateTime.now(),
      );

      _navigateToUserDataScreen(fallbackUserData);
    }
  }

  void _navigateToUserDataScreen(UserData userData) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => UserDataScreen(
          userData: userData,
          onUserDataChanged: (newUserData) async {
            if (newUserData != null) {
              setState(() {
                _userName = newUserData.name;
                _userGender = newUserData.gender;
                _birthDate = newUserData.birthDate;
                _dominantHand = newUserData.dominantHand;
              });
            }
          },
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                  parent: animation, curve: Curves.easeOutCubic)),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  void _navigateToHoroscopeMenu(String? zodiacSign) async {
    await _hapticService.trigger(HapticType.light);
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            HoroskopeMenuScreen(
          userName: _userName,
          userGender: _userGender,
          birthDate: _birthDate,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.3, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                  parent: animation, curve: Curves.easeOutCubic)),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  void _navigateToMusicSelection() async {
    await _hapticService.trigger(HapticType.light);

    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            MusicSelectionScreen(
          userName: _userName,
          userGender: _userGender,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.3, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                  parent: animation, curve: Curves.easeOutCubic)),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  // ==================== HELPER METHODS ====================

  String getZodiacSign(DateTime birthDate) {
    final day = birthDate.day;
    final month = birthDate.month;

    if ((month == 1 && day >= 20) || (month == 2 && day <= 18)) return 'Wodnik';
    if ((month == 2 && day >= 19) || (month == 3 && day <= 20)) return 'Ryby';
    if ((month == 3 && day >= 21) || (month == 4 && day <= 19)) return 'Baran';
    if ((month == 4 && day >= 20) || (month == 5 && day <= 20)) return 'Byk';
    if ((month == 5 && day >= 21) || (month == 6 && day <= 20))
      return 'Bliźnięta';
    if ((month == 6 && day >= 21) || (month == 7 && day <= 22)) return 'Rak';
    if ((month == 7 && day >= 23) || (month == 8 && day <= 22)) return 'Lew';
    if ((month == 8 && day >= 23) || (month == 9 && day <= 22)) return 'Panna';
    if ((month == 9 && day >= 23) || (month == 10 && day <= 22)) return 'Waga';
    if ((month == 10 && day >= 23) || (month == 11 && day <= 21))
      return 'Skorpion';
    if ((month == 11 && day >= 22) || (month == 12 && day <= 21))
      return 'Strzelec';
    return 'Koziorożec';
  }

  String getZodiacEmoji(String zodiacSign) {
    switch (zodiacSign.toLowerCase()) {
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

  void _showSearchDialog() async {
    await _hapticService.trigger(HapticType.light);
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1A2332),
                Color(0xFF0B1426),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: app_colors.AppColors.cyan.withOpacity(0.5), width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search,
                  color: app_colors.AppColors.cyan, size: 48),
              const SizedBox(height: 16),
              Text(
                'Wyszukiwanie - Wkrótce',
                style: GoogleFonts.cinzelDecorative(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: app_colors.AppColors.cyan,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Funkcja wyszukiwania będzie dostępna wkrótce.',
                style: GoogleFonts.cinzelDecorative(
                  fontSize: 14,
                  fontWeight: FontWeight.w300,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              HapticButton(
                text: 'Rozumiem',
                hapticType: HapticType.light,
                onPressed: () => Navigator.of(context).pop(),
                backgroundColor: app_colors.AppColors.cyan,
                foregroundColor: Colors.black,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoon(String featureName) async {
    await _hapticService.trigger(HapticType.warning);
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1A2332),
                Color(0xFF0B1426),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.orange.withOpacity(0.5), width: 1),
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
              const Icon(Icons.auto_awesome, color: Colors.orange, size: 48),
              const SizedBox(height: 16),
              Text(
                '$featureName - Wkrótce',
                style: GoogleFonts.cinzelDecorative(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Ta funkcja jest w przygotowaniu.\nMistyczne moce nad nią pracują...',
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
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.black,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== BACKGROUND PAINTER ====================
class MenuBackgroundPainter extends CustomPainter {
  final double animationValue;

  MenuBackgroundPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // ✅ DEFINIUJ WSZYSTKIE PAINT OBIEKTY NA POCZĄTKU
    final paint = Paint()..style = PaintingStyle.fill;
    final cornerPaint = Paint()
      ..color = app_colors.AppColors.cyan.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    try {
      // Floating mystical orbs
      for (int i = 0; i < 20; i++) {
        final angle = (animationValue * math.pi) + (i * 2 * math.pi / 20);
        final radius = 80.0 + (i % 3) * 30.0;
        final centerX = size.width * (0.2 + (i % 4) * 0.2);
        final centerY = size.height * (0.2 + (i % 5) * 0.15);

        final x = centerX + radius * math.cos(angle * 0.4);
        final y = centerY + radius * math.sin(angle * 0.3);

        if (x >= -30 &&
            x <= size.width + 30 &&
            y >= -30 &&
            y <= size.height + 30) {
          final orbSize =
              1.2 + math.sin(animationValue * 2 * math.pi + i) * 0.6;
          final opacity =
              0.08 + math.sin(animationValue * 3 * math.pi + i * 0.5) * 0.04;

          if (orbSize > 0) {
            paint.color = app_colors.AppColors.cyan
                .withOpacity(opacity.clamp(0.02, 0.12));
            canvas.drawCircle(Offset(x, y), orbSize.abs(), paint);
          }
        }
      }

      // Corner decorations - teraz cornerPaint jest zdefiniowany
      if (size.width > 100 && size.height > 100) {
        canvas.drawArc(
          const Rect.fromLTWH(20, 20, 30, 30),
          -math.pi,
          math.pi / 2,
          false,
          cornerPaint,
        );

        canvas.drawArc(
          Rect.fromLTWH(size.width - 50, size.height - 50, 30, 30),
          0,
          math.pi / 2,
          false,
          cornerPaint,
        );
      }
    } catch (e) {
      Logger.error('Błąd w MenuBackgroundPainter: $e');
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
