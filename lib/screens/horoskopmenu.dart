// lib/screens/horoskopmenu.dart
// 🔮 MENU HOROSKOPÓW - OSTATECZNA WERSJA BEZ BŁĘDÓW
// Zgodny z wytycznymi projektu AI Wróżka

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../utils/constants.dart';
import '../services/horoscope_service.dart';
import '../services/haptic_service.dart';
import '../models/horoscope_data.dart';
import '../widgets/haptic_button.dart';
import 'horoskoptygodniowy.dart';
import 'horoskopmiesieczny.dart';
import 'extended_horoscope_screen.dart';
import 'package:lottie/lottie.dart';

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

  // Serwisy
  final HoroscopeService _horoscopeService = HoroscopeService();
  final HapticService _hapticService = HapticService();

  // Stan
  HoroscopeData? _todayHoroscope;
  bool _isLoading = true;
  String? _errorMessage;

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

    _initializeData();
  }

  Future<void> _initializeData() async {
    await _horoscopeService.initialize();
    await _loadTodayHoroscope();
  }

  Future<void> _loadTodayHoroscope() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final zodiacSign = _getZodiacSign();
      final englishZodiacSign = _convertPolishToEnglish(zodiacSign);

      print(
          '🔮 Pobieranie horoskopu dla znaku: $zodiacSign ($englishZodiacSign)');

      final horoscope =
          await _horoscopeService.getDailyHoroscope(englishZodiacSign);

      setState(() {
        _todayHoroscope = horoscope;
        _isLoading = false;
      });

      print('✅ Załadowano horoskop: ${horoscope?.text.length} znaków');
    } catch (e) {
      print('❌ Błąd ładowania horoskopu: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Błąd ładowania horoskopu';
      });
    }
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
                    // 1️⃣ HOROSKOP DZIENNY
                    _buildSimpleDailyHoroscopeCard(),
                    const SizedBox(height: 20),

                    // 2️⃣ HOROSKOP ROZBUDOWANY
                    _buildExtendedHoroscopeSection(),
                    const SizedBox(height: 20),

                    // 3️⃣ HOROSKOPY TYGODNIOWY I MIESIĘCZNY
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

                    const SizedBox(height: 20),

                    // 4️⃣ KALENDARZ KSIĘŻYCOWY
                    _buildLunarCalendarCard(),

                    const SizedBox(height: 20),

                    // 5️⃣ ŚWIECA DNIA
                    _buildCandleRecommendationCard(),

                    const SizedBox(height: 16),

                    // 6️⃣ HOROSKOP SPECJALNY
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
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🔮 UPROSZCZONA karta dzisiejszego horoskopu
  Widget _buildSimpleDailyHoroscopeCard() {
    final zodiacSign = _getZodiacSign();
    final zodiacEmoji = _getZodiacEmoji(zodiacSign);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        color: Colors.grey[900]?.withOpacity(0.8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: AppColors.cyan.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header z datą i znakiem zodiaku
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dziś • ${DateTime.now().day}.${DateTime.now().month.toString().padLeft(2, '0')}.${DateTime.now().year}',
                        style: GoogleFonts.cinzelDecorative(
                          fontSize: 14,
                          color: AppColors.cyan,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        zodiacSign,
                        style: GoogleFonts.cinzelDecorative(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.cyan.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: AppColors.cyan.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      zodiacEmoji,
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // TREŚĆ HOROSKOPU
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(
                      color: AppColors.cyan,
                      strokeWidth: 2,
                    ),
                  ),
                )
              else if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.red, size: 24),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        style: GoogleFonts.cinzelDecorative(
                          fontSize: 14,
                          color: Colors.red,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _getDailyHoroscopePreview(zodiacSign),
                        style: GoogleFonts.cinzelDecorative(
                          fontSize: 15,
                          color: Colors.white70,
                          height: 1.6,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else if (_todayHoroscope != null) ...[
                Text(
                  _todayHoroscope!.text,
                  style: GoogleFonts.cinzelDecorative(
                    fontSize: 15,
                    color: Colors.white,
                    height: 1.6,
                  ),
                ),
              ] else ...[
                Text(
                  _getDailyHoroscopePreview(zodiacSign),
                  style: GoogleFonts.cinzelDecorative(
                    fontSize: 15,
                    color: Colors.white,
                    height: 1.6,
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Przycisk "Zobacz więcej"
              SizedBox(
                width: double.infinity,
                child: HapticButton(
                  text: 'Zobacz szczegóły',
                  onPressed: () => _navigateToHoroscope('daily'),
                  hapticType: HapticType.light,
                  backgroundColor: AppColors.cyan.withOpacity(0.1),
                  foregroundColor: AppColors.cyan,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🔮 NOWA SEKCJA - Horoskop Rozbudowany
  Widget _buildExtendedHoroscopeSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.cyan.withOpacity(0.3),
            AppColors.cyan.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.cyan.withOpacity(0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.cyan.withOpacity(0.2),
            blurRadius: 15,
            spreadRadius: 3,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.cyan.withOpacity(0.4),
                      AppColors.cyan.withOpacity(0.1),
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: AppColors.cyan,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Horoskop Rozbudowany',
                      style: GoogleFonts.cinzelDecorative(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Specjalnie dla Ciebie',
                      style: GoogleFonts.cinzelDecorative(
                        fontSize: 14,
                        color: AppColors.cyan.withOpacity(0.8),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: Text(
                  'PREMIUM',
                  style: GoogleFonts.cinzelDecorative(
                    fontSize: 10,
                    color: Colors.orange,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Szczegółowa analiza wszystkich aspektów Twojego życia: kariera, miłość, finanse, zdrowie, rozwój osobisty i relacje rodzinne.',
            style: GoogleFonts.cinzelDecorative(
              fontSize: 14,
              color: Colors.white70,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildFeatureChip('💼', 'Kariera')),
              const SizedBox(width: 8),
              Expanded(child: _buildFeatureChip('❤️', 'Miłość')),
              const SizedBox(width: 8),
              Expanded(child: _buildFeatureChip('💰', 'Finanse')),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildFeatureChip('🏃', 'Zdrowie')),
              const SizedBox(width: 8),
              Expanded(child: _buildFeatureChip('🎨', 'Rozwój')),
              const SizedBox(width: 8),
              Expanded(child: _buildFeatureChip('👨‍👩‍👧‍👦', 'Rodzina')),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: HapticButton(
              text: '🔮 Zobacz szczegółowy horoskop',
              onPressed: () => _navigateToHoroscope('extended'),
              hapticType: HapticType.medium,
              backgroundColor: AppColors.cyan.withOpacity(0.2),
              foregroundColor: AppColors.cyan,
            ),
          ),
        ],
      ),
    );
  }

  /// 🏷️ POMOCNICZA METODA - Chip z cechą
  Widget _buildFeatureChip(String emoji, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.cinzelDecorative(
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// 🌙 KALENDARZ KSIĘŻYCOWY
  Widget _buildLunarCalendarCard() {
    final moonEmoji = _todayHoroscope?.moonEmoji ?? '🌙';
    final moonPhase = _todayHoroscope?.moonPhase ?? 'Faza księżyca';
    final lunarDescription = _todayHoroscope?.lunarDescription;

    return Card(
      color: Colors.grey[900]?.withOpacity(0.8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: Colors.purple.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AnimatedBuilder(
                  animation: _scaleAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: Colors.purple.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          moonEmoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kalendarz Księżycowy',
                        style: GoogleFonts.cinzelDecorative(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        moonPhase,
                        style: GoogleFonts.cinzelDecorative(
                          fontSize: 14,
                          color: Colors.purple,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (lunarDescription != null && lunarDescription.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.indigo.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('🌙', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        Text(
                          'Wpływ Księżyca',
                          style: GoogleFonts.cinzelDecorative(
                            fontSize: 14,
                            color: Colors.indigo[300],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      lunarDescription,
                      style: GoogleFonts.cinzelDecorative(
                        fontSize: 13,
                        color: Colors.white70,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Text(
                _getFallbackLunarDescription(moonPhase),
                style: GoogleFonts.cinzelDecorative(
                  fontSize: 14,
                  color: Colors.white70,
                  height: 1.5,
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: HapticButton(
                text: 'Zobacz kalendarz księżycowy',
                onPressed: () => _navigateToHoroscope('lunar'),
                hapticType: HapticType.light,
                backgroundColor: Colors.purple.withOpacity(0.1),
                foregroundColor: Colors.purple,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🕯️ ŚWIECA DNIA
  Widget _buildCandleRecommendationCard() {
    String candleColor = 'biała';
    String candleReason =
        'Biała świeca symbolizuje czystość i pozytywną energię.';

    if (_todayHoroscope?.recommendedCandle != null) {
      candleColor = _todayHoroscope!.recommendedCandle!;
      candleReason = _todayHoroscope!.recommendedCandleReason ?? candleReason;
    } else if (_todayHoroscope?.moonPhase != null) {
      final moonPhase = _todayHoroscope!.moonPhase!;
      candleColor = _getFallbackCandle(moonPhase);
      candleReason = _getFallbackCandleReason(moonPhase);
    }

    return Card(
      color: Colors.grey[900]?.withOpacity(0.8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: Colors.amber.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: Colors.amber.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: const Text(
                    '🕯️',
                    style: TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Świeca Dnia',
                        style: GoogleFonts.cinzelDecorative(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Kolor: $candleColor',
                        style: GoogleFonts.cinzelDecorative(
                          fontSize: 14,
                          color: Colors.amber,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.amber.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                candleReason,
                style: GoogleFonts.cinzelDecorative(
                  fontSize: 13,
                  color: Colors.white70,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMysticalBackground() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.5,
              colors: [
                Colors.deepPurple.withOpacity(0.1),
                Colors.black,
                Colors.indigo.withOpacity(0.05),
              ],
            ),
          ),
          child: CustomPaint(
            painter: StarsPainter(_rotationAnimation.value),
            size: Size.infinite,
          ),
        );
      },
    );
  }

  Widget _buildCompactHoroscopeOption({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      color: Colors.grey[900]?.withOpacity(0.6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          _hapticService.trigger(HapticType.light);
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: GoogleFonts.cinzelDecorative(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToHoroscope(String type) async {
    await _hapticService.trigger(HapticType.light);

    if (!mounted) return;

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
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ExtendedHoroscopeScreen(
              userName: widget.userName,
              userGender: widget.userGender,
              birthDate: widget.birthDate,
              dominantHand: null,
              relationshipStatus: null,
              primaryConcern: null,
            ),
          ),
        );
        break;
      case 'lunar':
        // Implementacja kalendarza księżycowego
        break;
      default:
        print('Nieznany typ horoskopu: $type');
        break;
    }
  }

  // POMOCNICZE METODY
  String _getZodiacSign() {
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
    return 'Strzelec'; // Default dla testów
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

  String _getDailyHoroscopePreview(String zodiacSign) {
    switch (zodiacSign) {
      case 'Koziorożec':
        return 'Dzisiaj jest dobry dzień na planowanie przyszłości. Twoja ambicja i cierpliwość zostaną wynagrodzone. Szczęśliwy kolor: granatowy.';
      case 'Wodnik':
        return 'Twoja kreatywność osiąga dzisiaj szczyt. Wykorzystaj ten czas na innowacyjne pomysły. Możliwe niespodziewane spotkanie. Szczęśliwa liczba: 7.';
      case 'Ryby':
        return 'Intuicja podpowiada Ci właściwe rozwiązania. Zaufaj swoim uczuciom i nie ignoruj snów. Dziś szczególnie ważna będzie medytacja.';
      case 'Baran':
        return 'Energia i determinacja są Twoimi atutami. Podejmij odważne działania, ale uważaj na impulsywność. Czerwień przyniesie szczęście.';
      case 'Byk':
        return 'Stabilność i praktyczność pomogą Ci osiągnąć cele. Buduj na solidnych podstawach. Dobry dzień na finanse i inwestycje.';
      case 'Bliźnięta':
        return 'Komunikatywność i adaptacyjność otwierają nowe możliwości. Wykorzystaj swoje talenty oratorskie. Możliwa ważna wiadomość.';
      case 'Rak':
        return 'Empatia i intuicja są dzisiaj szczególnie silne. Zadbaj o bliskich i nie zaniedbuj życia rodzinnego. Dom to Twoja siła.';
      case 'Lew':
        return 'Twoje przywództwo i charyzma znajdą uznanie. Inspiruj innych swoją kreatywnością. Złoty kolor przyniesie szczęście.';
      case 'Panna':
        return 'Uwaga na szczegóły i metodyczność przyniosą doskonałe rezultaty. Organizacja i planowanie to klucze do sukcesu.';
      case 'Waga':
        return 'Harmonia i dyplomacja pomogą rozwiązać trudne sytuacje. Sprawiedliwość i równowaga są dzisiaj kluczowe.';
      case 'Skorpion':
        return 'Intensywność i determinacja poprowadzą Cię do sukcesu. Transformacja przyniesie pozytywne zmiany. Zaufaj intuicji.';
      case 'Strzelec':
        return 'Optymizm i poszukiwanie przygód otworzą nowe horyzonty. Podróże i nauka przyniosą inspirację. Szczęśliwa liczba: 9.';
      default:
        return 'Dzisiaj jest dobry dzień na nowe początki i pozytywne zmiany. Energia planet sprzyja Twoim planom.';
    }
  }

  String _getFallbackCandle(String moonPhase) {
    const candles = {
      'Nów': 'biała',
      'Przybywający sierp': 'zielona',
      'Pierwsza kwadra': 'czerwona',
      'Przybywający garb': 'pomarańczowa',
      'Pełnia': 'złota',
      'Ubywający garb': 'niebieska',
      'Ostatnia kwadra': 'fioletowa',
      'Ubywający sierp': 'czarna',
    };
    return candles[moonPhase] ?? 'biała';
  }

  String _getFallbackCandleReason(String moonPhase) {
    const reasons = {
      'Nów':
          'Biała świeca symbolizuje czystość, nowe początki i nieskazitelną energię.',
      'Przybywający sierp':
          'Zielona świeca wspiera wzrost, rozwój i realizację nowych planów.',
      'Pierwsza kwadra':
          'Czerwona świeca daje siłę i determinację do pokonywania przeszkód.',
      'Przybywający garb':
          'Pomarańczowa świeca wspiera kreatywność i pozytywną energię.',
      'Pełnia':
          'Złota świeca symbolizuje obfitość, sukces i manifestację marzeń.',
      'Ubywający garb':
          'Niebieska świeca przynosi spokój, refleksję i głęboką mądrość.',
      'Ostatnia kwadra':
          'Fioletowa świeca wspiera transformację i duchowe oczyszczenie.',
      'Ubywający sierp':
          'Czarna świeca symbolizuje ochronę i usuwanie negatywnej energii.',
    };
    return reasons[moonPhase] ??
        'Ta świeca wspiera Twoje intencje i harmonizuje energię.';
  }

  String _getFallbackLunarDescription(String moonPhase) {
    const lunarDescriptions = {
      'Nów':
          'Dziś panuje energia Nowiu, symbolizująca nowe początki i czystą kartę. To idealny czas na zasiewanie intencji.',
      'Przybywający sierp':
          'Energia przybywającego sierpa wspiera inicjowanie nowych projektów. Czas na pierwsze kroki.',
      'Pierwsza kwadra':
          'Pierwsza kwadra to moment podejmowania ważnych decyzji. Przezwyciężaj przeszkody z determinacją.',
      'Przybywający garb':
          'Energia przybywającego garba zachęca do wytrwałej pracy. Efekty będą wkrótce widoczne.',
      'Pełnia':
          'Pełnia to szczyt energii lunalnej. Czas manifestacji i celebrowania osiągnięć.',
      'Ubywający garb':
          'Czas refleksji nad osiągnięciami. Podziękuj za to, co udało się zrealizować.',
      'Ostatnia kwadra':
          'Ostatnia kwadra to czas puszczenia tego, co już nie służy. Przygotuj miejsce na nowe.',
      'Ubywający sierp':
          'Okres oczyszczenia i przygotowań do nowego cyklu księżycowego.',
    };
    return lunarDescriptions[moonPhase] ??
        'Księżyc wpływa na nasze emocje i energię. Żyj w zgodzie z jego cyklem.';
  }
}

// Custom painter dla gwiazd w tle
class StarsPainter extends CustomPainter {
  final double rotation;

  StarsPainter(this.rotation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1;

    final random = math.Random(42); // Seed dla konsystentnych pozycji

    for (int i = 0; i < 100; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;

      final opacity = (math.sin(rotation + i * 0.1) + 1) / 2 * 0.8 + 0.2;
      paint.color = Colors.white.withOpacity(opacity * 0.3);

      canvas.drawCircle(Offset(x, y), 1, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
