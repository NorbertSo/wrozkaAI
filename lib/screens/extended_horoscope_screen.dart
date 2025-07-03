// lib/screens/extended_horoscope_screen.dart
// 🔮 EKRAN ROZBUDOWANEGO HOROSKOPU - ZAKTUALIZOWANY
// Integracja z nowym systemem płatności świecami

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';
import '../services/haptic_service.dart';
import '../services/candle_manager_service.dart';
import '../widgets/haptic_button.dart';
import '../utils/logger.dart';
import '../widgets/candle_payment_confirmation_widget.dart';

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
  final CandleManagerService _candleService = CandleManagerService();

  // 🎬 ANIMACJE
  late AnimationController _fadeController;
  late AnimationController _shimmerController;
  late Animation<double> _fadeAnimation;

  // 📊 STAN
  bool _isLoading = true;
  bool _hasAccess = false;
  int _candlesCount = 0;
  Map<String, String>? _horoscopeData;

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

    _shimmerController.repeat();
  }

  /// 🔐 Sprawdź dostęp użytkownika
  Future<void> _checkAccess() async {
    try {
      setState(() {
        _isLoading = true;
      });

      await _candleService.initialize();

      final hasAccess = await _candleService.canUseExtendedHoroscope();
      final balance = _candleService.currentBalance;

      setState(() {
        _hasAccess = hasAccess;
        _candlesCount = balance;
        _isLoading = false;
      });

      Logger.info(
          'Sprawdzono dostęp do rozbudowanego horoskopu: $hasAccess, saldo: $balance');

      _fadeController.forward();
    } catch (e) {
      Logger.error('Błąd sprawdzania dostępu: $e');
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Wystąpił błąd podczas sprawdzania dostępu',
            style: GoogleFonts.cinzelDecorative(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 🎯 Użyj horoskopu z płatnością świecami - NAPRAWIONA WERSJA
  Future<void> _showPaymentDialog() async {
    try {
      // Pobierz informacje o funkcji
      final featureInfo = _candleService.getFeatureInfo('extended_horoscope');

      // ✅ UŻYWAJ TEJ SAMEJ METODY CO W PALM_INTRO!
      final confirmed = await CandlePaymentHelper.showPaymentConfirmation(
        context: context,
        featureName: featureInfo.name,
        featureIcon: featureInfo.icon,
        candleCost: featureInfo.cost,
        featureDescription: featureInfo.description,
        currentBalance: _candleService.currentBalance,
        accentColor: AppColors.cyan, // ← ZMIEŃ NA CYAN
      );

      if (!confirmed) {
        Logger.info('Użytkownik anulował płatność za horoskop');
        return;
      }

      // Wykonaj płatność
      setState(() => _isLoading = true);
      final result = await _candleService.useExtendedHoroscope();

      if (result.success) {
        await _loadHoroscopeData();
        await _checkAccess();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.message,
              style: GoogleFonts.cinzelDecorative(color: Colors.white),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.message,
              style: GoogleFonts.cinzelDecorative(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      Logger.error('Błąd płatności za horoskop: $e');
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Wystąpił błąd podczas przetwarzania płatności',
            style: GoogleFonts.cinzelDecorative(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 📊 Załaduj dane horoskopu
  Future<void> _loadHoroscopeData() async {
    try {
      await Future.delayed(const Duration(seconds: 2));

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

      setState(() => _isLoading = false);
      Logger.info('Załadowano horoskop rozbudowany');
    } catch (e) {
      Logger.error('Błąd ładowania horoskopu: $e');
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Nie udało się załadować horoskopu',
            style: GoogleFonts.cinzelDecorative(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
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
                    : _horoscopeData != null
                        ? _buildHoroscopeContent()
                        : _buildPaymentPrompt(),
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

  /// 🚫 Stan braku dostępu - zaktualizowany
  Widget _buildPaymentPrompt() {
    return SingleChildScrollView(
      // ← DODAJ TO!
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
              'Szczegółowa analiza wszystkich sfer Twojego życia na dziś',
              style: GoogleFonts.cinzelDecorative(
                fontSize: 14,
                color: Colors.white70,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // 💰 Informacje o koszcie
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.orange.withOpacity(0.2), // ← ZMIEŃ NA ORANGE
                    Colors.orange.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.5), // ← ZMIEŃ NA ORANGE
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🕯️', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 8),
                      Text(
                        '15 świec',
                        style: GoogleFonts.cinzelDecorative(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange, // ← ZMIEŃ NA ORANGE
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Twój balans: $_candlesCount świec',
                    style: GoogleFonts.cinzelDecorative(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            _buildAccessButtons(),

            // Dodaj dodatkowy padding na dole
            const SizedBox(height: 50), // ← DODAJ TO żeby nie było overflow
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
      children: [
        ...sections.map((section) {
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
        }),

        // 🎯 Przycisk udostępnienia
        SizedBox(
          width: double.infinity,
          child: HapticButton(
            text: '📤 Udostępnij horoskop (+3 świece)',
            onPressed: _shareHoroscope,
            hapticType: HapticType.light,
            backgroundColor: Colors.orange.withOpacity(0.2),
            foregroundColor: Colors.orange,
          ),
        ),
      ],
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

  /// 🔢 Przyciski dostępu - NAPRAWIONA WERSJA
  Widget _buildAccessButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: HapticButton(
            text: _candlesCount >= 15
                ? '🔮 Odbierz horoskop'
                : '🚫 Brak wystarczających świec',
            onPressed: _candlesCount >= 15
                ? _showPaymentDialog
                : null, // ← UŻYWAJ NOWEJ METODY!
            hapticType: HapticType.medium,
            backgroundColor: _candlesCount >= 15
                ? AppColors.cyan.withOpacity(0.2)
                : Colors.grey.withOpacity(0.2),
            foregroundColor: _candlesCount >= 15 ? AppColors.cyan : Colors.grey,
          ),
        ),

        const SizedBox(height: 16),

        // Informacje o kosztach
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.purple.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Koszt:',
                    style: GoogleFonts.cinzelDecorative(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  Row(
                    children: [
                      const Text('🕯️', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 4),
                      Text(
                        '15',
                        style: GoogleFonts.cinzelDecorative(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.purple,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Twoje saldo:',
                    style: GoogleFonts.cinzelDecorative(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  Row(
                    children: [
                      const Text('🕯️', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 4),
                      Text(
                        '$_candlesCount',
                        style: GoogleFonts.cinzelDecorative(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color:
                              _candlesCount >= 15 ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (_candlesCount < 15) ...[
                const SizedBox(height: 12),
                Text(
                  'Potrzebujesz ${15 - _candlesCount} więcej świec',
                  style: GoogleFonts.cinzelDecorative(
                    fontSize: 12,
                    color: Colors.red.withOpacity(0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 12),

        Text(
          'Zbieraj świece w codziennych aktywnościach!',
          style: GoogleFonts.cinzelDecorative(
            fontSize: 12,
            color: Colors.white70,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// 📤 Udostępnij horoskop
  Future<void> _shareHoroscope() async {
    try {
      final success =
          await _candleService.rewardForSharing('rozbudowany horoskop');

      if (success) {
        await HapticService.triggerSuccess();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Otrzymałeś 3 świece za udostępnienie!',
              style: GoogleFonts.cinzelDecorative(color: Colors.white),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        await _checkAccess();
      }
    } catch (e) {
      Logger.error('Błąd udostępniania horoskopu: $e');
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
}
