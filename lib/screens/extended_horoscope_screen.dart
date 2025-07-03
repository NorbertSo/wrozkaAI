// lib/screens/extended_horoscope_screen.dart
// 🔮 EKRAN ROZBUDOWANEGO HOROSKOPU - ZAKTUALIZOWANY
// Integracja z nowym systemem płatności świecami

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';
import '../services/haptic_service.dart';
import '../services/candle_manager_service.dart';
import '../services/horoscope_cache_service.dart';
import '../models/cached_horoscope.dart';
import '../widgets/haptic_button.dart';
import '../utils/logger.dart';
import '../utils/responsive_utils.dart';

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
  final HoroscopeCacheService _cacheService = HoroscopeCacheService();

  // 🎬 ANIMACJE
  late AnimationController _fadeController;
  late AnimationController _shimmerController;
  late Animation<double> _fadeAnimation;

  // 📊 STAN
  bool _isLoading = true;
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

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _shimmerController.repeat();
  }

  /// 🔐 Sprawdź dostęp użytkownika - NAJPIERW SPRAWDŹ CACHE
  Future<void> _checkAccess() async {
    try {
      setState(() {
        _isLoading = true;
      });

      await _candleService.initialize();
      await _cacheService.initialize();

      // 🧹 Wyczyść wygasłe horokorty
      await _cacheService.cleanupExpiredHoroscopes();

      final balance = _candleService.currentBalance;

      setState(() {
        _candlesCount = balance;
      });

      Logger.info('Sprawdzono saldo świec: $balance');

      // ✅ KROK 1: Sprawdź czy użytkownik ma już dziś zakupiony horoskop
      final cachedHoroscope = await _cacheService.getTodaysHoroscope();

      if (cachedHoroscope != null) {
        // 🎉 MAMY ZAKUPIONY HOROSKOP - ZAŁADUJ GO
        Logger.info(
            'Znaleziono cachowany horoskop: ${cachedHoroscope.validityInfo}');
        setState(() {
          _horoscopeData = cachedHoroscope.horoscopeData;
          _isLoading = false;
        });
        _fadeController.forward();
        return;
      }

      // ✅ KROK 2: Brak cachowanego horoskopu - pokaż dialog płatności
      setState(() {
        _isLoading = false;
      });
      _fadeController.forward();

      // Małe opóźnienie aby UI się wyrenderowało
      await Future.delayed(const Duration(milliseconds: 500));
      await _showPaymentDialogImmediately();
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

  /// 📊 Załaduj dane horoskopu i zapisz do cache
  Future<void> _loadAndCacheHoroscopeData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      await Future.delayed(const Duration(seconds: 2));

      // 🔮 WYGENERUJ HOROSKOP (w przyszłości będzie to AI)
      final horoscopeData = {
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

      // 💾 ZAPISZ DO CACHE
      final cachedHoroscope = await _cacheService.createHoroscopeForUser(
        horoscopeData: horoscopeData,
        userName: widget.userName,
        userGender: widget.userGender,
        birthDate: widget.birthDate,
        dominantHand: widget.dominantHand,
        relationshipStatus: widget.relationshipStatus,
        primaryConcern: widget.primaryConcern,
      );

      final saved = await _cacheService.saveHoroscope(cachedHoroscope);

      if (saved) {
        Logger.info(
            'Horoskop zapisany do cache: ${cachedHoroscope.validityInfo}');
      } else {
        Logger.warning('Nie udało się zapisać horoskopu do cache');
      }

      // 🎨 ZAKTUALIZUJ UI
      setState(() {
        _horoscopeData = horoscopeData;
        _isLoading = false;
      });

      Logger.info('Załadowano i zapisano horoskop rozbudowany');
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
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 800.0),
                    child: _isLoading
                        ? _buildLoadingState()
                        : _horoscopeData != null
                            ? _buildHoroscopeContent()
                            : _buildLoadingState(), // Jeśli nie ma danych, pokaż loading (płatność już się wyświetla)
                  ),
                ),
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
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800.0),
        padding: EdgeInsets.all(context.isSmallScreen ? 12 : 16),
        child: Row(
          children: [
            // 🔙 Ujednolicony przycisk cofnij
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () async {
                  await HapticService.triggerLight();
                  Navigator.of(context).pop();
                },
                child: Container(
                  width: context.isSmallScreen ? 44 : 48,
                  height: context.isSmallScreen ? 44 : 48,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.cyan.withOpacity(0.5),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.cyan.withOpacity(0.12),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                      size: context.isSmallScreen ? 20 : 24,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Horoskop Rozbudowany',
                style: GoogleFonts.cinzelDecorative(
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, 20),
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            _buildCandleCounter(),
          ],
        ),
      ),
    );
  }

  /// 🕯️ Licznik świec
  Widget _buildCandleCounter() {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: context.isSmallScreen ? 10 : 12,
          vertical: context.isSmallScreen ? 6 : 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.withOpacity(0.2),
            Colors.orange.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.withOpacity(0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('🕯️',
              style: TextStyle(fontSize: context.isSmallScreen ? 14 : 16)),
          const SizedBox(width: 6),
          Text(
            _candlesCount.toString(),
            style: GoogleFonts.cinzelDecorative(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
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
            width: context.isSmallScreen ? 100 : 120,
            height: context.isSmallScreen ? 100 : 120,
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
          SizedBox(height: context.isSmallScreen ? 20 : 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              'Przygotowuję Twój szczegółowy horoskop...',
              style: GoogleFonts.cinzelDecorative(
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, 16),
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  ///  Zawartość horoskopu
  Widget _buildHoroscopeContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ListView(
        padding: EdgeInsets.all(context.isSmallScreen ? 12 : 16),
        children: [
          _buildHoroscopeHeader(),
          const SizedBox(height: 24),
          _buildHoroscopeSections(),
        ],
      ),
    );
  }

  /// 🎯 Nagłówek horoskopu z informacją o ważności
  Widget _buildHoroscopeHeader() {
    return Container(
      padding: EdgeInsets.all(context.isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.cyan.withOpacity(0.3),
            AppColors.cyan.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cyan.withOpacity(0.5), width: 1),
      ),
      child: Column(
        children: [
          Text(
            '✨ ${widget.userName} ✨',
            style: GoogleFonts.cinzelDecorative(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, 22),
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Twój szczegółowy horoskop na dziś',
            style: GoogleFonts.cinzelDecorative(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
              color: Colors.white70,
            ),
          ),

          // 📅 INFORMACJA O WAŻNOŚCI HOROSKOPU
          FutureBuilder<CachedHoroscope?>(
            future: _cacheService.getTodaysHoroscope(),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data != null) {
                final horoscope = snapshot.data!;
                return Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.orange.withOpacity(0.4), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('⏰', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text(
                        horoscope.validityInfo,
                        style: GoogleFonts.cinzelDecorative(
                          fontSize: ResponsiveUtils.getResponsiveFontSize(
                              context, 12),
                          color: Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
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
      padding: EdgeInsets.symmetric(
          horizontal: context.isSmallScreen ? 10 : 12,
          vertical: context.isSmallScreen ? 4 : 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji,
              style: TextStyle(fontSize: context.isSmallScreen ? 14 : 16)),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.cinzelDecorative(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, 12),
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
        'color': Colors.cyan,
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
      padding: EdgeInsets.all(context.isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.cinzelDecorative(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, 18),
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: context.isSmallScreen ? 8 : 12),
          Text(
            content,
            style: GoogleFonts.cinzelDecorative(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
              color: Colors.white70,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  ///  Udostępnij horoskop
  Future<void> _shareHoroscope() async {
    try {
      final success = await _candleService.rewardForSharing(
        'rozbudowany horoskop',
      );

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

  ///  Natychmiastowe wyświetlenie płatności i zapis do cache
  Future<void> _showPaymentDialogImmediately() async {
    try {
      final success = await CandleManagerService.showPaymentDialog(
        context,
        'extended_horoscope',
      );

      if (success) {
        // ✅ PŁATNOŚĆ ZAKOŃCZONA SUKCESEM - WYGENERUJ I ZAPISZ HOROSKOP
        await _loadAndCacheHoroscopeData();
      } else {
        // Użytkownik anulował - wróć do poprzedniego ekranu
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      Logger.error('Błąd płatności za horoskop: $e');
      if (mounted) {
        Navigator.of(context).pop();
      }
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
