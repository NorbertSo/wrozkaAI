// lib/screens/extended_horoscope_screen.dart
// 🔮 HOROSKOP ROZBUDOWANY - OSTATECZNA WERSJA BEZ BŁĘDÓW
// Zgodny z istniejącą strukturą projektu AI Wróżka

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../utils/constants.dart';
import '../services/haptic_service.dart';
import '../widgets/haptic_button.dart';

class ExtendedHoroscopeScreen extends StatefulWidget {
  final String userName;
  final String userGender;
  final DateTime? birthDate;
  final String? dominantHand;
  final String? relationshipStatus;
  final String? primaryConcern;

  const ExtendedHoroscopeScreen({
    super.key,
    required this.userName,
    required this.userGender,
    this.birthDate,
    this.dominantHand,
    this.relationshipStatus,
    this.primaryConcern,
  });

  @override
  State<ExtendedHoroscopeScreen> createState() =>
      _ExtendedHoroscopeScreenState();
}

class _ExtendedHoroscopeScreenState extends State<ExtendedHoroscopeScreen>
    with TickerProviderStateMixin {
  // 🎯 SERWISY
  final HapticService _hapticService = HapticService();

  // 🎬 ANIMACJE
  late AnimationController _fadeController;
  late AnimationController _shimmerController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _shimmerAnimation;

  // 📊 STAN
  bool _isLoading = true;
  bool _hasAccess = false;
  bool _isSubscriber = false;
  int _candlesCount = 0;
  bool _usedMonthlyFree = false;
  Map<String, String>? _horoscopeData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkAccess();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  /// 🎬 Inicjalizacja animacji
  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));

    _shimmerController.repeat();
  }

  /// 🔐 Sprawdź dostęp użytkownika (symulacja)
  Future<void> _checkAccess() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // SYMULACJA - w rzeczywistej implementacji użyj prawdziwych serwisów
      await Future.delayed(const Duration(seconds: 2));

      // TODO: Implementuj prawdziwe sprawdzanie dostępu
      _isSubscriber = false; // Symulacja
      _candlesCount = 5; // Symulacja
      _usedMonthlyFree = false; // Symulacja

      _hasAccess =
          _isSubscriber || (!_usedMonthlyFree) || (_candlesCount >= 10);

      print('Dostęp do horoskopu rozbudowanego: $_hasAccess');

      if (_hasAccess) {
        await _loadHoroscopeData();
      }

      _fadeController.forward();
    } catch (e) {
      print('Błąd sprawdzania dostępu: $e');
      setState(() {
        _errorMessage = 'Wystąpił błąd podczas sprawdzania dostępu';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 📊 Załaduj dane horoskopu (fallback)
  Future<void> _loadHoroscopeData() async {
    try {
      // FALLBACK DATA - w rzeczywistej implementacji pobierz z Firebase
      final zodiacSign = _getZodiacSign();

      _horoscopeData = {
        'career':
            'Twoja naturalna energia i determinacja przyniosą dziś konkretne rezultaty w pracy. Śmiało przedstaw swoje pomysły przełożonym.',
        'love':
            'W relacjach panuje dziś harmonia i wzajemne zrozumienie. To idealny moment na romantyczne gesty i szczere rozmowy.',
        'finance':
            'Unikaj dziś impulsywnych zakupów, szczególnie dużych wydatków. Twoja intuicja finansowa jest wyostrzona.',
        'health':
            'Energia płynie w Tobie obficie - wykorzystaj ją do aktywności fizycznej. Pamiętaj o odpoczynku i regeneracji.',
        'growth':
            'Dziś szczególnie sprzyjają Ci nowe wyzwania intelektualne. To doskonały moment na rozpoczęcie kursu lub czytanie.',
        'family':
            'Atmosfera w domu jest spokojna i przyjazna. To dobry dzień na rozmowy z bliskimi o przyszłości i wspólnych planach.',
      };

      print('Załadowano horoskop rozbudowany (fallback)');
    } catch (e) {
      print('Błąd ładowania horoskopu: $e');
      setState(() {
        _errorMessage = 'Nie udało się załadować horoskopu';
      });
    }
  }

  /// 🎯 Użyj horoskopu (symulacja)
  Future<void> _useHoroscope() async {
    try {
      await _hapticService.trigger(HapticType.light);

      if (_isSubscriber) {
        await _loadHoroscopeData();
        print('Horoskop rozbudowany użyty - subskrybent');
      } else if (!_usedMonthlyFree) {
        await _loadHoroscopeData();
        setState(() {
          _usedMonthlyFree = true;
          _hasAccess = true;
        });
        print('Horoskop rozbudowany użyty - darmowy miesięczny');
      } else if (_candlesCount >= 10) {
        await _loadHoroscopeData();
        setState(() {
          _candlesCount -= 10;
          _hasAccess = true;
        });
        print('Horoskop rozbudowany użyty - 10 świec');
      } else {
        print('Próba użycia bez dostępu');
      }
    } catch (e) {
      print('Błąd użycia horoskopu: $e');
      setState(() {
        _errorMessage = 'Wystąpił błąd podczas dostępu do horoskopu';
      });
    }
  }

  /// 📱 Główny widget ekranu
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBlue,
      body: Container(
        decoration: _buildMysticalBackground(),
        child: SafeArea(
          child: Column(
            children: [
              _buildCustomAppBar(),
              Expanded(
                child: _isLoading
                    ? _buildLoadingState()
                    : _hasAccess && _horoscopeData != null
                        ? _buildHoroscopeContent()
                        : _buildAccessDeniedState(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🎨 Tło mistyczne
  BoxDecoration _buildMysticalBackground() {
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: AppColors.welcomeGradient,
      ),
    );
  }

  /// 📱 Niestandardowy AppBar
  Widget _buildCustomAppBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          HapticButton(
            text: '',
            onPressed: () => Navigator.of(context).pop(),
            hapticType: HapticType.light,
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            child: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Horoskop Rozbudowany',
              style: GoogleFonts.cinzelDecorative(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _buildCandleCounter(),
        ],
      ),
    );
  }

  /// 🕯️ Licznik świec
  Widget _buildCandleCounter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.withOpacity(0.2),
            Colors.orange.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.orange.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🕯️', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text(
            _candlesCount.toString(),
            style: GoogleFonts.cinzelDecorative(
              fontSize: 14,
              color: Colors.orange,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// ⏳ Stan ładowania
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.cyan, width: 2),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.cyan),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Przygotowuję Twój szczegółowy horoskop...',
            style: GoogleFonts.cinzelDecorative(
              fontSize: 16,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 🚫 Stan braku dostępu
  Widget _buildAccessDeniedState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.cyan.withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 64,
                color: AppColors.cyan,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Horoskop Rozbudowany',
              style: GoogleFonts.cinzelDecorative(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              _getAccessMessage(),
              style: GoogleFonts.cinzelDecorative(
                fontSize: 14,
                color: Colors.white70,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _buildAccessButtons(),
          ],
        ),
      ),
    );
  }

  /// 📝 Zawartość horoskopu
  Widget _buildHoroscopeContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHoroscopeHeader(),
          const SizedBox(height: 24),
          _buildHoroscopeSections(),
        ],
      ),
    );
  }

  /// 🎯 Nagłówek horoskopu
  Widget _buildHoroscopeHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.cyan.withOpacity(0.3),
            AppColors.cyan.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.cyan.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            '✨ ${widget.userName} ✨',
            style: GoogleFonts.cinzelDecorative(
              fontSize: 22,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Twój szczegółowy horoskop na dziś',
            style: GoogleFonts.cinzelDecorative(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _buildInfoChip('🌟', _getZodiacSign()),
                const SizedBox(width: 8),
                _buildInfoChip('🌙', 'Nów'),
                const SizedBox(width: 8),
                _buildInfoChip('🕯️', 'Biała'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 🏷️ Chip z informacją
  Widget _buildInfoChip(String emoji, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.cinzelDecorative(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 📖 Sekcje horoskopu
  Widget _buildHoroscopeSections() {
    if (_horoscopeData == null) return const SizedBox.shrink();

    final sections = [
      {'title': '💼 Kariera i Praca', 'key': 'career', 'color': Colors.blue},
      {'title': '❤️ Miłość i Relacje', 'key': 'love', 'color': Colors.pink},
      {'title': '💰 Finanse', 'key': 'finance', 'color': Colors.green},
      {'title': '🏃 Zdrowie', 'key': 'health', 'color': Colors.orange},
      {'title': '🎨 Rozwój Osobisty', 'key': 'growth', 'color': Colors.purple},
      {
        'title': '👨‍👩‍👧‍👦 Rodzina i Dom',
        'key': 'family',
        'color': Colors.cyan
      },
    ];

    return Column(
      children: sections.map((section) {
        return Column(
          children: [
            _buildHoroscopeSectionCard(
              title: section['title'] as String,
              content: _horoscopeData![section['key']] ?? 'Brak danych',
              color: section['color'] as Color,
            ),
            const SizedBox(height: 16),
          ],
        );
      }).toList(),
    );
  }

  /// 📖 Karta sekcji horoskopu
  Widget _buildHoroscopeSectionCard({
    required String title,
    required String content,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.cinzelDecorative(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: GoogleFonts.cinzelDecorative(
              fontSize: 14,
              color: Colors.white70,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  /// 🔢 Przyciski dostępu
  Widget _buildAccessButtons() {
    if (_isSubscriber) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        if (!_usedMonthlyFree) ...[
          SizedBox(
            width: double.infinity,
            child: HapticButton(
              text: '🎁 Pierwszy darmowy w tym miesiącu',
              onPressed: _useHoroscope,
              hapticType: HapticType.medium,
              backgroundColor: Colors.green.withOpacity(0.2),
              foregroundColor: Colors.green,
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_candlesCount >= 10) ...[
          SizedBox(
            width: double.infinity,
            child: HapticButton(
              text: '🕯️ Użyj 10 świec',
              onPressed: _useHoroscope,
              hapticType: HapticType.medium,
              backgroundColor: Colors.orange.withOpacity(0.2),
              foregroundColor: Colors.orange,
            ),
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          width: double.infinity,
          child: HapticButton(
            text: '⭐ Sprawdź subskrypcję',
            onPressed: () => _showSubscriptionInfo(),
            hapticType: HapticType.light,
            backgroundColor: Colors.blue.withOpacity(0.2),
            foregroundColor: Colors.blue,
          ),
        ),
      ],
    );
  }

  /// 💳 Informacja o subskrypcji
  void _showSubscriptionInfo() async {
    await _hapticService.trigger(HapticType.light);

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.darkBlue,
          title: Text(
            'Premium w przygotowaniu',
            style: GoogleFonts.cinzelDecorative(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'System subskrypcji będzie dostępny wkrótce. Zbieraj świece w codziennych aktywnościach!',
            style: GoogleFonts.cinzelDecorative(
              color: Colors.white70,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Rozumiem',
                style: GoogleFonts.cinzelDecorative(
                  color: AppColors.cyan,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  /// 📝 Pomocnicze metody
  String _getZodiacSign() {
    if (widget.birthDate == null) return 'Nieznany';

    // Prosta implementacja znajdowania znaku zodiaku
    final month = widget.birthDate!.month;
    final day = widget.birthDate!.day;

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
    if ((month == 12 && day >= 22) || (month == 1 && day <= 19))
      return 'Koziorożec';
    if ((month == 1 && day >= 20) || (month == 2 && day <= 18)) return 'Wodnik';
    if ((month == 2 && day >= 19) || (month == 3 && day <= 20)) return 'Ryby';

    return 'Nieznany';
  }

  String _getAccessMessage() {
    if (_isSubscriber) {
      return 'Jako subskrybent masz nieograniczony dostęp do horoskopów rozbudowanych.';
    } else if (!_usedMonthlyFree) {
      return 'Otrzymujesz jeden darmowy horoskop rozbudowany każdego miesiąca. Dodatkowo możesz korzystać z systemu świec.';
    } else if (_candlesCount >= 10) {
      return 'Możesz użyć 10 świec aby uzyskać dostęp do horoskopu rozbudowanego.';
    } else {
      return 'Horoskop rozbudowany dostępny dla subskrybentów lub za 10 świec. Zbieraj świece w codziennych aktywnościach!';
    }
  }
}
