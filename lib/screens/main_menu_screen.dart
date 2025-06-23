import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'dart:math' as math;
import 'dart:math';
import '../utils/constants.dart';
import '../models/user_data.dart';
import '../services/fortune_history_service.dart';
import '../services/user_preferences_service.dart'; // ✅ DODANY IMPORT
import '../services/haptic_service.dart'; // ✅ NOWY IMPORT
import '../widgets/haptic_button.dart'; // ✅ NOWY IMPORT
import 'palm_intro_screen.dart';
import 'fortune_history_screen.dart';
import 'user_data_screen.dart';
import 'horoskopmenu.dart'; // Import for the horoscope menu screen
import 'horoskopmiesieczny.dart'; // Add import for the monthly horoscope screen

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
  final FortuneHistoryService _historyService = FortuneHistoryService();
  final HapticService _hapticService = HapticService(); // ✅ NOWY SERWIS

  // Przenieś i zainicjalizuj od razu!
  String _userName = '';
  String _userGender = '';
  String? _dominantHand;
  DateTime? _birthDate;

  late AnimationController _fadeController;
  late AnimationController _floatingController;
  late AnimationController _pulseController;
  late AnimationController _starController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _floatingAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _starAnimation;

  int _selectedIndex = -1;
  int _fortuneCount = 0;

  final List<String> _greetings = [
    ', zajrzyj w swoją przyszłość już dziś!',
    ', poznaj, co kryją gwiazdy!',
    ', odkryj sekrety swojej dłoni!',
    ', sprawdź, co przyniesie los!',
    ', Twoja wróżba czeka na Ciebie!'
  ];
  late String _selectedGreeting;

  @override
  void initState() {
    super.initState();
    // Inicjalizuj polami z widgeta
    _userName = widget.userName;
    _userGender = widget.userGender;
    _dominantHand = widget.dominantHand;
    _birthDate = widget.birthDate;
    _selectedGreeting = _greetings[Random().nextInt(_greetings.length)];
    _initializeAnimations();
    _startAnimations();
    _loadFortuneCount();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _floatingController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _starController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _floatingAnimation = Tween<double>(begin: -10.0, end: 10.0).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _starAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _starController, curve: Curves.linear),
    );
  }

  void _startAnimations() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _fadeController.forward();
      }
    });
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
    _fadeController.dispose();
    _floatingController.dispose();
    _pulseController.dispose();
    _starController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          _buildContent(),
        ],
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
        SizedBox.expand(
          child: Lottie.asset(
            'assets/animations/star_bg.json',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
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

  Widget _buildContent() {
    return SafeArea(
      child: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildWelcomeHeader(),
                  const SizedBox(height: 40),
                  _buildMenuOptions(),
                  const SizedBox(height: 40),
                  _buildMysticFooter(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.black.withOpacity(0.8),
            Colors.black.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.cyan.withOpacity(0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.cyan.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.cyan.withOpacity(0.5),
                        AppColors.cyan.withOpacity(0.15),
                        Colors.transparent,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.cyan.withOpacity(0.3),
                        blurRadius: 18,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.auto_awesome,
                    color: AppColors.cyan,
                    size: 32,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Text(
            '$_userName${_selectedGreeting}',
            style: GoogleFonts.cinzelDecorative(
              fontSize: 17,
              color: AppColors.cyan,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.1,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Funkcja: wyznacz znak zodiaku na podstawie daty urodzenia
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

  // Mapowanie znaków zodiaku na ikony Material (przykładowe, możesz podmienić na assety)
  final Map<String, IconData> zodiacIcons = {
    'Wodnik': Icons.water_drop_outlined,
    'Ryby': Icons.set_meal_outlined,
    'Baran': Icons.flash_on_outlined,
    'Byk': Icons.grass_outlined,
    'Bliźnięta': Icons.people_outline,
    'Rak': Icons.brightness_2_outlined,
    'Lew': Icons.wb_sunny_outlined,
    'Panna': Icons.spa_outlined,
    'Waga': Icons.balance_outlined,
    'Skorpion': Icons.bug_report_outlined,
    'Strzelec': Icons.architecture_outlined,
    'Koziorożec': Icons.terrain_outlined,
  };

  // Mapowanie polskiej nazwy znaku na angielską nazwę pliku
  final Map<String, String> zodiacFileNames = {
    'Baran': 'aries',
    'Byk': 'taurus',
    'Bliźnięta': 'gemini',
    'Rak': 'cancer',
    'Lew': 'leo',
    'Panna': 'virgo',
    'Waga': 'libra',
    'Skorpion': 'scorpio',
    'Strzelec': 'sagittarius',
    'Koziorożec': 'capricorn',
    'Wodnik': 'aquarius',
    'Ryby': 'pisces',
  };

  Widget _buildMenuOptions() {
    // Wyznacz znak zodiaku usera (jeśli brak daty, domyślna ikona)
    String? zodiacSign;
    IconData zodiacIcon = Icons.stars_outlined;
    Widget? zodiacWidget;
    if (_birthDate != null) {
      zodiacSign = getZodiacSign(_birthDate!);
      zodiacIcon = zodiacIcons[zodiacSign] ?? Icons.stars_outlined;
      final fileName = zodiacFileNames[zodiacSign] ?? '';
      if (fileName.isNotEmpty) {
        zodiacWidget = Center(
          child: Image.asset(
            'assets/images/$fileName.png',
            width: 30,
            height: 30,
            fit: BoxFit.contain,
          ),
        );
      }
    }
    final options = [
      MenuOption(
        title: 'Skan Dłoni',
        subtitle: 'Odkryj swoją przyszłość',
        icon: Icons.pan_tool_outlined,
        color: AppColors.cyan,
        isAvailable: true,
        onTap: () => _navigateToPalmScan(),
      ),
      MenuOption(
        title: 'Horoskop',
        subtitle: zodiacSign != null
            ? 'Twój znak: $zodiacSign'
            : 'Twoje gwiazdy mówią...',
        icon: zodiacIcon,
        color: Colors.purple,
        isAvailable: true,
        onTap: () => _navigateToHoroscopeMenu(zodiacSign),
        badge: null,
      ),
      MenuOption(
        title: 'Zgodność par',
        subtitle: 'Sprawdź dopasowanie',
        icon: Icons.favorite_border,
        color: Colors.pinkAccent,
        isAvailable: false,
        onTap: () => _showComingSoon('Zgodność par'),
      ),
      MenuOption(
        title: 'Moje Dane',
        subtitle: 'Zarządzaj profilem',
        icon: Icons.person_outline,
        color: Colors.orange,
        isAvailable: true,
        onTap: () => _navigateToUserData(),
      ),
      MenuOption(
        title: 'Moje Wróżby',
        subtitle: _fortuneCount > 0
            ? '$_fortuneCount zapisanych wróżb'
            : 'Historia Twoich wróżb',
        icon: Icons.history_outlined,
        color: Colors.green,
        isAvailable: true,
        badge: _fortuneCount > 0 ? _fortuneCount.toString() : null,
        onTap: () => _navigateToFortuneHistory(),
      ),
    ];

    return Column(
      children: options.asMap().entries.map((entry) {
        final index = entry.key;
        final option = entry.value;

        return AnimatedContainer(
          duration: Duration(milliseconds: 300 + (index * 100)),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.only(bottom: 16),
          child: _buildMenuCard(option, index,
              zodiacWidget: zodiacWidget, zodiacSign: zodiacSign),
        );
      }).toList(),
    );
  }

  // Zamień HapticButton na GestureDetector w _buildMenuCard
  Widget _buildMenuCard(MenuOption option, int index,
      {Widget? zodiacWidget, String? zodiacSign}) {
    final isSelected = _selectedIndex == index;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () async {
          await _hapticService.trigger(
            option.isAvailable ? HapticType.light : HapticType.selection,
          );
          if (option.isAvailable) {
            option.onTap();
          } else {
            _showComingSoon(option.title);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          transform: isSelected
              ? (Matrix4.identity()..scale(0.98))
              : Matrix4.identity(),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 100),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: option.isAvailable
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
                color: option.isAvailable
                    ? (isSelected
                        ? option.color
                        : option.color.withOpacity(0.4))
                    : Colors.grey.withOpacity(0.3),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: option.isAvailable
                  ? [
                      BoxShadow(
                        color:
                            option.color.withOpacity(isSelected ? 0.4 : 0.15),
                        blurRadius: isSelected ? 20 : 10,
                        spreadRadius: isSelected ? 2 : 1,
                      ),
                    ]
                  : [],
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: option.isAvailable
                        ? RadialGradient(
                            colors: [
                              option.color.withOpacity(0.3),
                              option.color.withOpacity(0.1),
                            ],
                          )
                        : null,
                    color: option.isAvailable
                        ? null
                        : Colors.grey.withOpacity(0.2),
                    border: Border.all(
                      color: option.isAvailable
                          ? option.color.withOpacity(0.6)
                          : Colors.grey.withOpacity(0.4),
                      width: 1,
                    ),
                  ),
                  child: (option.title == 'Horoskop na Dzisiaj' &&
                          zodiacWidget != null)
                      ? zodiacWidget
                      : Icon(
                          option.icon,
                          size: 28,
                          color:
                              option.isAvailable ? option.color : Colors.grey,
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: option.isAvailable
                        ? MainAxisAlignment.center
                        : MainAxisAlignment.spaceEvenly,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              option.title,
                              style: GoogleFonts.cinzelDecorative(
                                fontSize: 18,
                                color: option.isAvailable
                                    ? Colors.white
                                    : Colors.grey,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        option.subtitle,
                        style: GoogleFonts.cinzelDecorative(
                          fontSize: 14,
                          color: option.isAvailable
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
                  size: 16,
                  color: option.isAvailable
                      ? option.color.withOpacity(0.7)
                      : Colors.grey.withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMysticFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.6),
            Colors.black.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.cyan.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (index) {
              return AnimatedBuilder(
                animation: _starAnimation,
                builder: (context, child) {
                  final delay = index * 0.2;
                  final rotation = (_starAnimation.value + delay) * 2 * math.pi;
                  return Transform.rotate(
                    angle: rotation,
                    child: Icon(
                      Icons.star_border,
                      size: 16,
                      color: AppColors.cyan.withOpacity(0.6),
                    ),
                  );
                },
              );
            }),
          ),
          const SizedBox(height: 16),
          Text(
            'Mistyczne moce zawsze z Tobą',
            style: GoogleFonts.cinzelDecorative(
              fontSize: 16,
              color: AppColors.cyan,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.8,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Wersja 0.5.0 • AI Wróżka',
            style: GoogleFonts.cinzelDecorative(
              fontSize: 12,
              color: Colors.white54,
              fontWeight: FontWeight.w300,
            ),
            textAlign: TextAlign.center,
          ),
        ],
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

  // ✅ POPRAWIONA METODA - pobiera prawdziwe dane z SharedPreferences
  void _navigateToUserData() async {
    await _hapticService.trigger(HapticType.light);

    try {
      // ✅ KLUCZOWA ZMIANA: Pobierz PRAWDZIWE dane z SharedPreferences
      final userData = await UserPreferencesService.getUserData();

      if (userData == null) {
        // Fallback - jeśli brak danych, stwórz nowe z dostępnych informacji
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

      // ✅ Używaj PRAWDZIWYCH danych z SharedPreferences
      debugPrint('✅ Załadowano prawdziwe dane użytkownika: ${userData.name}');
      debugPrint('📅 Godzina urodzenia: ${userData.birthTime ?? "brak"}');
      debugPrint('📍 Miejsce urodzenia: ${userData.birthPlace ?? "brak"}');

      _navigateToUserDataScreen(userData);
    } catch (e) {
      debugPrint('❌ Błąd ładowania danych użytkownika: $e');

      // Error fallback
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

  // ✅ NOWA HELPER METODA - wykonuje nawigację
  void _navigateToUserDataScreen(UserData userData) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => UserDataScreen(
          userData: userData, // ✅ PRAWDZIWE dane, nie stworzone na nowo
          onUserDataChanged: (newUserData) async {
            if (newUserData != null) {
              debugPrint(
                  '✅ Dane użytkownika zaktualizowane: ${newUserData.name}');
              debugPrint('📅 Nowa godzina: ${newUserData.birthTime ?? "brak"}');
              debugPrint(
                  '📍 Nowe miejsce: ${newUserData.birthPlace ?? "brak"}');

              // Aktualizuj dane w stanie, jeśli się zmieniły
              setState(() {
                _userName = newUserData.name;
                _userGender = newUserData.gender;
                _birthDate = newUserData.birthDate;
                _dominantHand = newUserData.dominantHand;
              });
            } else {
              debugPrint('⚠️ Dane użytkownika usunięte');
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

  // Add a new method to navigate to the monthly horoscope screen
  void _navigateToMonthlyHoroscope(String? zodiacSign) async {
    await _hapticService.trigger(HapticType.light);

    // Get the zodiac emoji for the user's sign
    String zodiacEmoji = '⭐';
    if (zodiacSign != null) {
      switch (zodiacSign.toLowerCase()) {
        case 'koziorożec':
          zodiacEmoji = '♑';
          break;
        case 'wodnik':
          zodiacEmoji = '♒';
          break;
        case 'ryby':
          zodiacEmoji = '♓';
          break;
        case 'baran':
          zodiacEmoji = '♈';
          break;
        case 'byk':
          zodiacEmoji = '♉';
          break;
        case 'bliźnięta':
          zodiacEmoji = '♊';
          break;
        case 'rak':
          zodiacEmoji = '♋';
          break;
        case 'lew':
          zodiacEmoji = '♌';
          break;
        case 'panna':
          zodiacEmoji = '♍';
          break;
        case 'waga':
          zodiacEmoji = '♎';
          break;
        case 'skorpion':
          zodiacEmoji = '♏';
          break;
        case 'strzelec':
          zodiacEmoji = '♐';
          break;
      }
    }

    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            HoroskopMiesiecznyScreen(
          userName: _userName,
          zodiacSign: zodiacSign ?? 'Nieznany',
          zodiacEmoji: zodiacEmoji,
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

  void _showComingSoon(String featureName) async {
    await _hapticService.trigger(HapticType.warning);
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
              Icon(Icons.auto_awesome, color: Colors.orange, size: 48),
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

class MenuOption {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isAvailable;
  final String? badge;
  final VoidCallback onTap;

  MenuOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isAvailable,
    this.badge,
    required this.onTap,
  });
}

class MenuBackgroundPainter extends CustomPainter {
  final double animationValue;

  MenuBackgroundPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final paint = Paint()..style = PaintingStyle.fill;

    try {
      for (int i = 0; i < 15; i++) {
        final angle = (animationValue * math.pi) + (i * 2 * math.pi / 15);
        final radius = 60.0 + (i % 3) * 25.0;
        final centerX = size.width * (0.2 + (i % 4) * 0.2);
        final centerY = size.height * (0.2 + (i % 5) * 0.15);

        final x = centerX + radius * math.cos(angle * 0.5);
        final posY = centerY + radius * math.sin(angle * 0.3);

        if (x >= -20 &&
            x <= size.width + 20 &&
            posY >= -20 &&
            posY <= size.height + 20) {
          final orbSize =
              1.5 + math.sin(animationValue * 2 * math.pi + i) * 0.8;
          final opacity =
              0.1 + math.sin(animationValue * 3 * math.pi + i * 0.5) * 0.05;

          if (orbSize > 0) {
            paint.color = AppColors.cyan.withOpacity(opacity.clamp(0.02, 0.15));
            canvas.drawCircle(Offset(x, posY), orbSize.abs(), paint);
          }
        }
      }

      final cornerPaint = Paint()
        ..color = AppColors.cyan.withOpacity(0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;

      if (size.width > 100 && size.height > 100) {
        canvas.drawArc(
          Rect.fromLTWH(20, 20, 30, 30),
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
      debugPrint('Błąd w MenuBackgroundPainter: $e');
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
